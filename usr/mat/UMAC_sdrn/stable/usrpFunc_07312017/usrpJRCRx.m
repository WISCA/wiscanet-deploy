function eof = usrpJRCRx(sys_start_time)

%%
% Add relevant paths
%
    addpath(genpath('../../lib'));
    addpath(genpath('../'));

%%
% Initialize radio
%

    % Load params file
    load('../paramsFiles/params06Jun2017.mat');

    [usrpSettings, usrpRadio] = initUSRPRadio(commsParams);

    % '2017-05-11 00:00:00'
    if 0
       startTime = setStartTime();
    else
       startTime = sys_start_time; %time from manager
    end

    %%
    %   Scalar variable definitions

    % Misc
    buffSize      = usrpSettings.buff_samps;
    buffEnd       = 2*buffSize;
    sampFreq      = commsParams.sampFreq;
    upsampFactor  = commsParams.upsampFactor;
    modOrder      = commsParams.modOrder;
    fdbckInterval = commsParams.fdbckInterval;
    bitsPerSym    = commsParams.bitsPerSym;
    procTime      = usrpSettings.proc_time;
    
    chirpGain     = radarParams.chirpGain;
    chirpLen      = radarParams.chirpLen;
    
    %
    nPackets  = commsParams.nPackets;
    nTxCycles = commsParams.nTxCycles;
    nSfxSyms  = commsParams.nSfxSyms;
    sfxSyms   = complex(ones(nSfxSyms,1));
    qpskGain  = commsParams.qpskGain;
    spreadVal = commsParams.spreadVal;  
    
    % Feedback message variables
    bkTrnSyms        = fdbckMsgCodeBook.trnSymbols;
    bkSpreadIdx      = fdbckMsgCodeBook.spreadIdx;
    bkPermSeqEncoder = fdbckMsgCodeBook.permSeqEncoder;
    bkPermSeqIntrlvr = fdbckMsgCodeBook.permSeqIntrlvr;
    bkTrellisStruct  = fdbckMsgCodeBook.trellisStruct;
    
    % Feedforward message variables
    nFwdEncBits       = fdfwdMsgCodeBook.nEncdBits;
    fwdTrnSyms        = fdfwdMsgCodeBook.trnSymbols;
    fwdSpreadIdx      = fdfwdMsgCodeBook.spreadIdx;
    fwdPermSeqEncoder = fdfwdMsgCodeBook.permSeqEncoder;
    fwdPermSeqIntrlvr = fdfwdMsgCodeBook.permSeqIntrlvr;
    fwdTrellisStruct  = fdfwdMsgCodeBook.trellisStruct;
    fwdMsgSize        = nFwdEncBits/nPackets;
    nFwdModMsgSyms    = (nFwdEncBits/(nPackets*bitsPerSym))...
        *(spreadVal/bitsPerSym);
    fwdModPktSize     = nFwdModMsgSyms*upsampFactor;
    
    %%
    %   Vector variable definitions
    %
    
    % Allocate data buffer and specify indices for data entry into buffer
    txBuff  = zeros(buffEnd, 1);
    
    %%
    %   Transmitter Initialization
    %

    % Transmitter definitions
    [modulator, txFilter] = initCommsTXMod(upsampFactor, modOrder);

    [bkEncoder, bkIntrlvr] = initCommsTXErrorCorrection(...
        bkPermSeqEncoder, bkPermSeqIntrlvr, bkTrellisStruct);
    
    %%
    %   Receiver Initialization
    %
    
    % Initialization for synchronization and acquisition
    [freqEstimator, freqCompensator, rxFilter] = initCommsRXSync(...
        modOrder, upsampFactor, sampFreq);
    
    % Initialization for error correction
    [fwdDecoder, fwdDeIntrlvr] = initCommsRXErrorCorrection(...
        fwdPermSeqEncoder, fwdPermSeqIntrlvr, fwdTrellisStruct);
    
    % Generate chirp waveform and null matrix
    radarWav = dchirp(chirpLen/sampFreq, sampFreq, 1);

    % Initialization for demodulation objects
    demodulator = initCommsRXDemod(modOrder);

%%
%   SIC component initialization
%

    % Initialize encoder and interleaver (for regenerating packets)
    [fwdEncoder, fwdIntrlvr] = initCommsTXErrorCorrection(...
        fwdPermSeqEncoder, fwdPermSeqIntrlvr, fwdTrellisStruct);

%%
%   Mallocs
%
    
    rxWav = zeros(buffSize, nPackets);

    fwdMsgBits = zeros(fwdMsgSize, nPackets);

    %%
    %   Do receiver processing for current CPI
    %
        
    % Initialize message counter
    fwdMsgCount = 0;

    % Update spread sequence based on new spreading value
    modSpreadSeq = genModSpreadSeq(...
        spreadVal, fwdSpreadIdx, modulator);

    for n = 1:nTxCycles

        if mod(n, fdbckInterval)

            % Receive data from USRP
            rxBuff = usrpRadio.rx_usrp(startTime);

            % Convert to MATLAB format
            rxWav(:,fwdMsgCount+1) = complex(rxBuff(1:2:end), rxBuff(2:2:end));


	% Copy to user loop
            % Compensate for any frequency offset that might occur
            rxFiltWav = commsRXFilt(...
                rxWav(:,fwdMsgCount+1), freqEstimator, freqCompensator, rxFilter);

            % Perform acquisition and synchronization of comms and chirp signal
            [rxFwdMsg, rxFwdTrn, rxFwdNzeTrn] = commsRXSync(...
                rxFiltWav, fwdTrnSyms, fwdModPktSize, commsParams);

            % Place equalizer here if needed
            noisePwr = (rxFwdNzeTrn'*rxFwdNzeTrn)/length(rxFwdNzeTrn);
%             sigPwr = (rxFwdTrn'*rxFwdTrn)/length(rxFwdTrn);

            % Demodulate synchronized syms to message bits
            fwdMsgBits(:,fwdMsgCount+1) = commsRXDemod(...
                    rxFwdMsg, modSpreadSeq, noisePwr, ...
                    spreadVal, commsParams, demodulator);
	% end copy to user loop
            fwdMsgCount = fwdMsgCount+1;

        else

            % Adjust gain and spread values then relay to transmitter
            qpskGain  = qpskGain+0;
            chirpGain = chirpGain+0;
            spreadVal = spreadVal+0;

            if (qpskGain>1) || (chirpGain>1)

                qpskGain  = 1;
                chirpGain = 1;

            end

            % Update message size based on new spreading value
            nFwdModMsgSyms = (nFwdEncBits/(nPackets*bitsPerSym))...
                *(spreadVal/bitsPerSym);
            fwdModPktSize = nFwdModMsgSyms*upsampFactor;

            % Update spread sequence based on new spreading value
            modSpreadSeq = genModSpreadSeq(...
                spreadVal, fwdSpreadIdx, modulator);

            % Generate message describing above values
            bkMsgBits = genInfoMsg(chirpGain, qpskGain, spreadVal, ...
                bkEncoder, bkIntrlvr);

            % Generate waveform packets
            bkCommsWav = generateWaveform(...
                bkTrnSyms, sfxSyms, bkMsgBits, ...
                bkSpreadIdx, spreadVal, modulator, txFilter); 

            % Transmit waveform packets
            len = numel(bkCommsWav);
            txBuff(1:2:2*len) = normData(real(bkCommsWav));
            txBuff(2:2:2*len) = normData(imag(bkCommsWav));

            % Transmit waveform packets
            usrpRadio.tx_usrp(startTime, txBuff);

        end

        % Increment start timer
        startTime = startTime+procTime;

    end


% start user loop here


    % Error correction
    decodeBits = commsRXDecode(fwdMsgBits(:), fwdDecoder, fwdDeIntrlvr);

%%
% Perform SIC
%

    % Re-encode bits
    encodeBits = commsRXEncode(decodeBits, fwdEncoder, fwdIntrlvr);
 
    for n = 1:nPackets
            
        % Index for current message bits
        msgIdx = (n-1)*fwdMsgSize+(1:fwdMsgSize);
            
        % Estimate TX waveform
        estCommsWav = generateWaveform(...
            fwdTrnSyms, sfxSyms, encodeBits(msgIdx), ...
            fwdSpreadIdx, spreadVal, modulator, txFilter);

        % Do SIC (remove chirp signal from composite)
        sicWav = commsRXSIC(estCommsWav, rxWav(:,n));

        % Do doppler processing - test for params passed in to function 
       [doppEstimate(n), velEstimate(n),  rangeEstimate(n)] = ...
           radarRXPulseDopProc(sicWav, radarWav, sampFreq, radarParams); 
                         
    end
    
    % Save data
    dateStr  = datestr(now, 'mmddyyyy_HHMMSS');
    fileName = ['usrpJRCRx_', dateStr, '.mat'];    
    save(fullfile('~/Data', fileName), ...
        'encodeBits', 'decodeBits', 'rxWav', ...
        'doppEstimate', 'velEstimate', 'rangeEstimate', ...
	'sicWav', 'radarWav', 'sampFreq', 'radarParams')

    % Stop server
    usrpRadio.terminate_usrp();

    % Release objects
    releaseObjs(...
        modulator, txFilter, bkEncoder, ...
        bkIntrlvr, freqEstimator, freqCompensator, ...
        rxFilter, fwdDecoder, fwdDeIntrlvr, ...
        fwdEncoder, fwdIntrlvr, demodulator);

    eof = true;

format longG;

targetParams.velocity
targetParams.range

velEstimate
rangeEstimate

end

function [ usrpSettings, usrpRadio ] = initUSRPRadio(p)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    usrpSettings.bw             = 5e6;          %bw
    usrpSettings.sample_rate    = p.sampFreq;   %rate
    usrpSettings.rx_gain        = 40;           %rx_gain
    usrpSettings.tx_gain        = 50;           %tx_gain
    usrpSettings.usrp_address   = 'type=b200';
    usrpSettings.type           = 'double';		%type
    usrpSettings.ant            = 'TX/RX';      %ant
    usrpSettings.subdev         = 'A:B';		%subdev
    usrpSettings.ref            = 'gpsdo';		%ref
    usrpSettings.wirefmt        = 'sc16';		%wirefmt
    usrpSettings.buff_samps     = 200e3;
    usrpSettings.freq           = 900e6;        %freq
    usrpSettings.setup_time     = 0.1;          %setup_time2
    usrpSettings.proc_time = 5;                 %MATLAB processing time (seconds)

    usrpRadio = local_usrp;

    usrpRadio.set_usrp(...
        usrpSettings.type, usrpSettings.ant, usrpSettings.subdev, ...
        usrpSettings.ref, usrpSettings.wirefmt, usrpSettings.buff_samps,...
        usrpSettings.sample_rate, usrpSettings.freq, usrpSettings.rx_gain, ...
        usrpSettings.tx_gain, usrpSettings.bw, usrpSettings.setup_time);

end

function posixTime = setStartTime(dateTimeStr)

    if ~exist('dateTimeStr','var') || isempty(dateTimeStr)

        p = posixtime(datetime('now', 'Timezone', 'America/Phoenix'));
        posixTime = double(uint64(p)+5);

    else

        p = posixtime(datetime(...
            dateTimeStr, 'InputFormat', 'yyy-MM-dd HH:mm:ss', ...
            'Timezone','America/Phoenix'));

        posixTime = double(uint64(p));

    end

end
