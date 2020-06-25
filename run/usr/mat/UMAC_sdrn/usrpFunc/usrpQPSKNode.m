function eof = usrpQPSKNode(sys_start_time)

% Add relevant paths
addpath(genpath('../../lib'));
addpath(genpath('../'));

% Constant variable definitions
commsParams.nUsrs        = 2;
commsParams.nCycles      = 100;
commsParams.nTrnSyms     = 128;
commsParams.nSfxSyms     = commsParams.nTrnSyms;
commsParams.nNzeSyms     = 512;
commsParams.upsampFactor = 2;
commsParams.sampFreq     = 20e6;
commsParams.modOrder     = 4;
commsParams.bitsPerSym   = log2(commsParams.modOrder);
commsParams.nUsrBits     = 102;
commsParams.nMsgBits     = 2004;
commsParams.zeroPad      = 200;

% Control spectral efficiency with this (fix FEC rate)spread
commsParams.spreadVal = 12;

% Set number of bits for feedforward message
msgBitsTotal =  commsParams.nUsrBits + commsParams.nMsgBits;
msgCodeBook.permSeqIntrlvr = randperm(msgBitsTotal)';

% Generate training symbols for each transmitter
msgCodeBook.trnSymbols = complex((-1).^randi([0 1], commsParams.nTrnSyms, 1));

% Generates random numbers w/o replacement on interval [0, 5] for Kasami
msgCodeBook.spreadIdx = randperm(6, 1) - 1;

% Set number of message bits
msgCodeBook.nMsgBits  = commsParams.nMsgBits;

commsParams.msgBits = [ones(3, 1); randi([0 1],commsParams.nMsgBits - 3, 1)];

% Initialize Radio
[usrpSettings, usrpRadio] = initUSRPRadio(commsParams);

% Start time from control system
startTime = sys_start_time;

% Get configured node ID
lId = usrpRadio.logicalId();
lIdStr = num2str(lId);

% Experiment Options
nCycles        = commsParams.nCycles;
sampFreq       = commsParams.sampFreq;
upsampFactor   = commsParams.upsampFactor;
procTime       = usrpSettings.proc_time;

% Modulation Options
modOrder       = commsParams.modOrder;
bitsPerSym     = commsParams.bitsPerSym;
spreadVal      = commsParams.spreadVal;
% Frame Options
nSfxSyms       = commsParams.nSfxSyms;
sfxSyms        = complex(zeros(nSfxSyms,1));
nUsrBits	   = commsParams.nUsrBits;
nMsgBits	   = commsParams.nMsgBits;
msgBits        = commsParams.msgBits;
initMsgBits    = msgBits;
modMsgSyms     = ((nMsgBits+nUsrBits)/bitsPerSym)*(spreadVal/bitsPerSym);
modMsgSize     = modMsgSyms*upsampFactor;
msgHat         = zeros(nMsgBits+nUsrBits,1);
encdBits       = msgHat;
numErrs        = zeros(nCycles,1);

% User (Node) Parameters
nUsrs          = commsParams.nUsrs;
txFlag         = false;

% Message variables
trnSyms        = msgCodeBook.trnSymbols;
spreadIdx      = msgCodeBook.spreadIdx;
permSeqIntrlvr = msgCodeBook.permSeqIntrlvr;

% Allocate data buffers
buffSize       = usrpSettings.buff_samps;
buffEnd        = 2*buffSize;
buffErrs       = zeros(nCycles,1);
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

% Randomize next user to send to
nextUsrId = randi([2 nUsrs]);

% Initialize message counter
count = 1;

% This is here for compatibility with the X310, set to 0 for B210 if you
% want
rampOffset = 2*12500; % 2 times the number of padding samples

%Transmit/Receive Loop
for nn = 1:nCycles
    
    if (lId == 1 && nn == 1) || (txFlag == true) % Transmit
        
        fprintf('\nFrame Number: %i\n', count)
        fprintf('Transmitting to User %i\n\n', nextUsrId)
        
        % Generate new message bits with updated nxtUsr
        % Message bits
        nextUsrBits = binMsgEncode(nUsrBits,nextUsrId)';
        
        % Concatenate message bits with next user bits
        truMsgBits = [msgBits; nextUsrBits];
        
        % Interleave bits
        encdBits = intrlv(truMsgBits, permSeqIntrlvr);
        
        % Generate waveform packets
        nNoiseSyms = length(trnSyms);
        filterSampFactor = txFilter.OutputSamplesPerSymbol;
        
        % Generate Kasami Sequence
        modSpreadSeq = genModSpreadSeq(spreadVal, spreadIdx, modulator);
        
        % Apply modulation to interleaved (possibly encoded) bits
        modMsgBits = step(modulator, encdBits);
               
        % Apply Kasami Sequence to modulated bits
        spreadMsgBits = modMsgBits*modSpreadSeq';
              
        % Concatenate training symbols, spread bits and suffix symbols
        % (zeros)
        modPacket = [trnSyms; spreadMsgBits(:); sfxSyms];
        
        % Apply Raised Cosine transmit filter
        commsWav = step(txFilter, modPacket);
        commsWav = [zeros(filterSampFactor*nNoiseSyms,1); commsWav];
        
        % Normalize output waveform
        commsWav = commsWav/max(abs(commsWav));
        
        % Pick next user to transmit to
        nextUsrId = randi([2 nUsrs]);
        
        % Save last transmitted waveform
        fileName = ['usrpQPSKNode_txWav_',lIdStr, '.mat'];
        save(fullfile('./', fileName));
        
        % Put transmit waveform into USRP format
        len = numel(commsWav);
        txBuff(1+rampOffset:2:2*len+rampOffset) = (real(commsWav));
        txBuff(2+rampOffset:2:2*len+rampOffset) = (imag(commsWav));
        
        % Transmit waveform packets through USRP
        usrpRadio.tx_usrp(startTime, txBuff);
        
        % Mark that we have transmitted
        txFlag = false;
        % Iterate through nCycles
        count = count+1;
    else % Receive
        fprintf('\nFrame Number: %d\n', count)
        fprintf('Receiving...\n\n')
        
        % Receive
        rxBuff = (usrpRadio.rx_usrp(startTime)).';
        
        % Convert to complex format
        rxWav = complex(rxBuff(1:2:end),rxBuff(2:2:end));
        
        estSNR = snr(abs(rxWav(1+(rampOffset/2):14000+(rampOffset/2))),abs(rxWav(14001+(rampOffset/2):14001+13999+(rampOffset/2))));
        fprintf('Approx SNR: %f dB\n',estSNR);
        
        f = figure('visible','off');
        plot(abs(rxWav));
        xlabel("Samples");
        ylabel("Amplitude");
        title(['RX Waveform Node: ',lIdStr,', Cycle: ', num2str(nn)]);
        print(['RXWaveformNode_',lIdStr,'_Cycle_',num2str(nn),'.png'],'-dpng');
        close(f);
        
        % Save last received waveform
        fileName = ['usrpQPSKsys_start_timeNode_rxWav_',lIdStr, '.mat'];
        save(fullfile('./', fileName));
        
        % Compensate for frequency offset and apply matched filter
        rxFiltWav = commsRXFilt(...
            rxWav, freqCompensator, rxFilter);
        
        % Perform acquisition and synchronization of comms and chirp signal
        [rxMsg, rxTrn, rxNzeTrn] = commsRXSync(...
            rxFiltWav, trnSyms, modMsgSize, commsParams);
        
        % Estimate noise power
        noisePwr = (rxNzeTrn'*rxNzeTrn)/length(rxNzeTrn);
        
        % Downsample
        msgSyms = rxMsg(1:commsParams.upsampFactor:end);
                  
        % Generate spread sequence
        spreadSeq = genModSpreadSeq(spreadVal, spreadIdx, modulator);
        
        % Despread message symbols
        despreadMsgSyms = reshape(msgSyms, [], spreadVal/commsParams.bitsPerSym) * spreadSeq;
        
        % Demodulate symbols (soft decision using true noise power)
        rxFullMsgBits = step(demodulator, despreadMsgSyms, noisePwr);
        
        % Make hard decisions
        rxFullMsgBits(rxFullMsgBits>0) = 0;
        rxFullMsgBits(rxFullMsgBits<0) = 1;
        
        % Msg Decode
        msgHat = deintrlv(rxFullMsgBits(:),permSeqIntrlvr);
        
        % Extract User Data
        % Convert binary to decimal values
        rxMsgBits = msgHat(1:nMsgBits);
        rxUsrBits = msgHat(nMsgBits+1:end);
        rxUsrId = binMsgDecode(rxUsrBits.');
        
        [numErrs(nn), BER] = biterr(rxMsgBits, initMsgBits);
        fprintf('Bit Error Rate = %f (%d errors)\n',BER,numErrs(nn))
        
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

function [ usrpSettings, usrpRadio ] = initUSRPRadio(p)

usrpSettings.bw             = 100e6;        %bw
usrpSettings.sample_rate    = 20e6;         %rate
usrpSettings.rx_gain        = 40;           %rx_gain
usrpSettings.tx_gain        = 50;           %tx_gain
usrpSettings.usrp_address   = 'type=b200';
usrpSettings.type           = 'double'; 	%type
usrpSettings.ant            = 'TX/RX';      %ant
usrpSettings.subdev         = 'A:B';        %subdev
usrpSettings.ref            = 'gpsdo';  	%ref
usrpSettings.wirefmt        = 'sc16';   	%wirefmt
usrpSettings.buff_samps     = 50000;
usrpSettings.freq           = 900e6;        %freq
usrpSettings.setup_time     = 2;          %setup_time2
usrpSettings.proc_time 	= 6;            %MATLAB processing time (seconds)


usrpRadio = local_usrp;

usrpRadio  =   usrpRadio.set_usrp(...
    usrpSettings.type, usrpSettings.ant, usrpSettings.subdev, ...
    usrpSettings.ref, usrpSettings.wirefmt, usrpSettings.buff_samps,...
    usrpSettings.sample_rate, usrpSettings.freq, usrpSettings.rx_gain, ...
    usrpSettings.tx_gain, usrpSettings.bw, usrpSettings.setup_time);

end
