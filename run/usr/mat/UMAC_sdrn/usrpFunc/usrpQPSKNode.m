function eof = usrpQPSKNode(sys_start_time)

% Add relevant paths
addpath(genpath('../../lib'));
addpath(genpath('../'));

%% Experiment Options and Parameters
nCycles        = 10;
procTime = 6; % Allow 6 seconds for processing to occur each loop
commsParams.sampFreq     = 20e6;
commsParams.usrpSamples = 50000;
sampFreq       = commsParams.sampFreq;

% Communications Waveform Parameters
commsParams.nTrnSyms     = 128;
commsParams.nSfxSyms     = commsParams.nTrnSyms;
commsParams.nNzeSyms     = 512;
commsParams.upsampFactor = 2;
commsParams.modOrder     = 4;
commsParams.bitsPerSym   = log2(commsParams.modOrder);
commsParams.nUsrBits     = 102;
commsParams.nMsgBits     = 2002;
commsParams.zeroPad      = 200;
upsampFactor   = commsParams.upsampFactor;
% Modulation Options
modOrder       = commsParams.modOrder;
bitsPerSym     = commsParams.bitsPerSym;
% Frame Options
nSfxSyms       = commsParams.nSfxSyms;
sfxSyms        = complex(zeros(nSfxSyms,1));
nUsrBits	   = commsParams.nUsrBits;
nMsgBits	   = commsParams.nMsgBits;

% Error Correcting Code Definitions
codeN = 7;
codeK = 4;
codeRate = codeK/codeN;

% Reed Solomon Definitions
%rsCoder = comm.RSEncoder(codeN,codeK,'BitInput', true);
%rsDecoder = comm.RSDecoder(codeN,codeK,'BitInput',true);

% BCH Coding Definitions
%bchCoder = comm.BCHEncoder(codeN,codeK);
%bchDecoder = comm.BCHDecoder(codeN,codeK);

% Calculate Message Parameters based on coding rate
modMsgSyms     = (((nMsgBits+nUsrBits)*(1/codeRate))/bitsPerSym);
modMsgSize     = modMsgSyms*upsampFactor;
msgHat         = zeros(nMsgBits+nUsrBits,1);
encdBits       = msgHat;
numErrs        = zeros(nCycles,1);

% Total number of bits in the message, generate interleaver pattern
msgBitsTotal =  commsParams.nUsrBits + commsParams.nMsgBits;
permSeqIntrlvr = randperm(msgBitsTotal*(1/codeRate))';

% Generate random bit stream for the message
commsParams.msgBits = [ones(3, 1); randi([0 1],commsParams.nMsgBits - 3, 1)];
msgBits        = commsParams.msgBits;
initMsgBits    = msgBits;

%% Initialization
% Initialize Radio
[usrpRadio] = initUSRPRadio(commsParams);

% Start time from control system
startTime = sys_start_time;

% Get configured node ID
lId = usrpRadio.logicalId();
lIdStr = num2str(lId);

% User (Node) Parameters
nUsrs          = 2;
txFlag         = false;

% Allocate data buffers
buffSize       = commsParams.usrpSamples;
buffEnd        = 2*buffSize;
txBuff  = zeros(buffEnd, 1);
rxBuff  = zeros(buffEnd, 1);
rxWav = zeros(buffSize, 1);

%   Transmitter Initialization
modulator = comm.PSKModulator(...
    'ModulationOrder', modOrder, ...
    'PhaseOffset',     0,...
    'BitInput',        true);
txFilter = comm.RaisedCosineTransmitFilter(...
    'OutputSamplesPerSymbol', upsampFactor,     ...
    'RolloffFactor',          0.25,   ...
    'FilterSpanInSymbols',    10);

%   Receiver Initialization
freqCompensator = comm.CoarseFrequencyCompensator( ...
    'Modulation', 'QPSK', ...
    'Algorithm', 'FFT-based', ...
    'FrequencyResolution', 10, ...
    'SampleRate', sampFreq);
rxFilter = comm.RaisedCosineReceiveFilter(...
    'InputSamplesPerSymbol',  upsampFactor, ...
    'DecimationFactor',       1, ...
    'RolloffFactor',          0.25, ...
    'FilterSpanInSymbols',    10);
demodulator = comm.PSKDemodulator('ModulationOrder', modOrder,...
    'PhaseOffset',0,'BitOutput',true,'DecisionMethod',...
    'Approximate log-likelihood ratio','VarianceSource',...
    'Input port');

% Generate training symbols for each transmitter
load training.mat; % Ensure training is identical across all nodes

% Randomize next user to send to
nextUsrId = randi([2 nUsrs]);

% Initialize message counter
count = 1;

% This is here for compatibility with the X310, set to 0 for B210 if you
% want
rampOffset = 2*12500; % 2 times the number of padding samples

% Modulate the training symbols
trnSyms = step(modulator,trn_data);
%trnSys = qammod(trn_data,modOrder,'BitInput',true);

%Transmit/Receive Loop
for nn = 1:nCycles

    if (lId == 1 && nn == 1) || (txFlag == true) % Transmit
        %% Transmit
        fprintf('\nFrame Number: %i\n', count)
        fprintf('Transmitting to User %i\n\n', nextUsrId)

        % Generate new message bits with updated nxtUsr
        % Message bits
        nextUsrBits = binMsgEncode(nUsrBits,nextUsrId)';

        % Concatenate message bits with next user bits
        truMsgBits = [msgBits; nextUsrBits];

        % Forward Error Correction
        % Hamming Coding
        encodedBits = encode(truMsgBits,codeN,codeK,'hamming');
        % Reed Solomon Coding
        % encodedBits = step(rsCoder,truMsgBits);
        % BCH Coding
        % encodedBits = step(bchCoder,truMsgBits);

        % Interleave bits
        encdBits = intrlv(encodedBits, permSeqIntrlvr);

        % Generate waveform packets
        nNoiseSyms = commsParams.nTrnSyms;
        filterSampFactor = txFilter.OutputSamplesPerSymbol;

        % Apply modulation to interleaved (possibly encoded) bits
        % PSK Modulation
        encdBits = [trn_data; encdBits];
        modMsgBits = step(modulator, encdBits);
        % QAM Modulation
        %modMsgBits = qammod(encdBits,modOrder,'InputType','bit');

        % Concatenate training symbols, bits and suffix symbols
        % (zeros)
        modPacket = [modMsgBits(:); sfxSyms];

        % Apply Raised Cosine transmit filter
        commsWav = step(txFilter, modPacket);
        commsWav = [zeros(filterSampFactor*nNoiseSyms,1); commsWav];

        % Normalize output waveform
        commsWav = commsWav/max(abs(commsWav));

        % Pick next user to transmit to
        nextUsrId = randi([2 nUsrs]);

        % Save last transmitted waveform
        fileName = ['usrpQPSKNode_txWav_node',lIdStr, '_cycle_',num2str(nn),'.mat'];
        save(fullfile('./', fileName));

        % Put transmit waveform into USRP format
        len = numel(commsWav);
        txBuff(1+rampOffset:2:2*len+rampOffset) = (real(commsWav));
        txBuff(2+rampOffset:2:2*len+rampOffset) = (imag(commsWav));

        %% Apply (Interesting?) Channel before going OTA
        outWav = complex(txBuff(1:2:end),txBuff(2:2:end));
        chtaps = [1 0.5*exp(1i*pi/6) 0.1*exp(-1i*pi/8)];
        %chtaps = [0.1,-0.3i,1,0.3i,0.2-0.7i,0.1i];
        outWav = filter(chtaps,1,outWav);
        txBuff(1:2:end) = real(outWav);
        txBuff(2:2:end) = imag(outWav);

        %% Transmit waveform packets through USRP
        usrpRadio.tx_usrp(startTime, txBuff);

        % Mark that we have transmitted
        txFlag = false;
        % Iterate through nCycles
        count = count+1;
    else
        %% Receive
        fprintf('\nFrame Number: %d\n', count)
        fprintf('Receiving...\n\n')

        % Receive
        rxBuff = (usrpRadio.rx_usrp(startTime)).';

        % Convert to complex format
        rxWav = complex(rxBuff(1:2:end),rxBuff(2:2:end));

        estSNR = snr(abs(rxWav(1+(rampOffset/2):14000+(rampOffset/2))),abs(rxWav(14001+(rampOffset/2):14001+13999+(rampOffset/2))));
        fprintf('Approx SNR: %f dB\n',estSNR);

        % Compensate for frequency offset and apply matched filter
        rxFiltWav = commsRXFilt(...
            rxWav, freqCompensator, rxFilter);

        % Perform acquisition and synchronization of comms signal
        [rxMsg, rxTrn, rxNzeTrn] = commsRXSync(...
            rxFiltWav, trnSyms, modMsgSize, commsParams);

        % Estimate noise power
        noisePwr = (rxNzeTrn'*rxNzeTrn)/length(rxNzeTrn);

        % Downsample
        msgSyms = downsample(rxMsg,commsParams.upsampFactor);
        rxTrn = downsample(rxTrn,commsParams.upsampFactor);

        % MMSE Equalizer
        eqLen = 15;
        eqDelay = 0;
        [msgSymsEq, mmseWeights] = mmseEqualizer(msgSyms,trnSyms,rxTrn,eqLen,eqDelay);
        %msgSymsEq = msgSyms;

        % Demodulate symbols (soft decision using true noise power)
        % PSK Demodulation
        rxFullMsgBits = step(demodulator, msgSymsEq, noisePwr);
        % QAM Demodulation
        %rxFullMsgBits = qamdemod(msgSymsEq,modOrder,'OutputType','bit','NoiseVariance',noisePwr);

        % Make hard decisions (PSK Only)
        rxFullMsgBits(rxFullMsgBits>0) = 0;
        rxFullMsgBits(rxFullMsgBits<0) = 1;

        % De-interleave bits
        msgHat = deintrlv(rxFullMsgBits(:),permSeqIntrlvr);

        % Perform Error Correction
        % Hamming Error Correction
        msgHat = decode(msgHat,codeN,codeK,'hamming');
        % Reed Solomon Error Correction
        % msgHat = step(rsDecoder,msgHat);
        % BCH Error Correction
        % msgHat = step(bchDecoder,msgHat);

        % Extract User Data
        % Convert binary to decimal values
        rxMsgBits = msgHat(1:nMsgBits);
        rxUsrBits = msgHat(nMsgBits+1:end);
        rxUsrId = binMsgDecode(rxUsrBits.');

        [numErrs(nn), BER] = biterr(rxMsgBits, initMsgBits);
        fprintf('Bit Error Rate = %f (%d errors)\n',BER,numErrs(nn))

        fileName = ['usrpQPSKNode_rxWav_node',lIdStr, '_cycle_',num2str(nn),'.mat'];
        save(fullfile('./', fileName));

        % Set next cycle transmit flag
        [txFlag, nextUsrId] = setTxFlag(lId, rxUsrId, nUsrs);

        if txFlag == true
            fprintf('TX FLAG = HIGH\nNEXT USER = %d\n', nextUsrId)
            msgBits = rxMsgBits;
        else
            fprintf('TX FLAG = LOW\nIDLE\n')
        end

        % Iterate through nCycles
        count = count+1;
    end
    startTime = startTime+procTime;
end

% Release allocated objects
releaseObjs(modulator, demodulator, txFilter, ...
    rxFilter, freqCompensator);

dateStr  = datestr(now, 'mmddyyyy_HHMMSS');
fileName = ['usrpQPSKNode', dateStr, '.mat'];
save(fullfile('./', fileName));

% Stop radio server
usrpRadio.terminate_usrp();

% Set end of function flag
eof = true;
end

function [ usrpRadio ] = initUSRPRadio(p)

usrpRadio = local_usrp;

% The inputs to set_usrp don't matter except for the number of samples
usrpRadio  =   usrpRadio.set_usrp(...
    0, 0, 0, ...
    0, 0, p.usrpSamples,...
    0, 0, 0, ...
    0, 0, 0);

end
