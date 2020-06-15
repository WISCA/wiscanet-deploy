function eof = usrpQPSKTx(sys_start_time)

    %%
    % Add relevant paths
    %
    addpath(genpath('../../lib'));
    addpath(genpath('../'));
    
    %%
    % Initialize radio
    %

    % Load params file
    load('../paramsFiles/params04Aug2017.mat');
    
    [usrpSettings, usrpRadio] = initUSRPRadio(commsParams);
    
    % '2017-05-11 00:00:00'
    if 0
       startTime = setStartTime();
    else 
       startTime = sys_start_time; %time from manager
    end
    
    %%
    % Constant variable definitions
    %
    
    % Misc
    buffSize     = usrpSettings.buff_samps;
    buffEnd      = 2*buffSize;
    
    nUsrs 	   = commsParams.nUsrs;
    sampFreq       = commsParams.sampFreq;
    upsampFactor   = commsParams.upsampFactor;
    modOrder       = commsParams.modOrder;
    fdbckInterval  = commsParams.fdbckInterval;
    bitsPerSym     = commsParams.bitsPerSym;
    nPackets       = commsParams.nPackets;
    nTxCycles      = commsParams.nTxCycles;
    nSfxSyms       = commsParams.nSfxSyms;
    sfxSyms        = complex(ones(nSfxSyms,1));
    qpskGain       = commsParams.qpskGain;
    spreadVal      = commsParams.spreadVal;
    
    procTime     = usrpSettings.proc_time;
   
    for n = 1:(nUsrs/nUsrs)     %tmp until better methods 
 
    % Feedback message variables
    nBkEncBits       = fdbckMsgCodeBook{1,n}.nEncdBits;
    bkTrnSyms        = fdbckMsgCodeBook{1,n}.trnSymbols;
    bkSpreadIdx      = fdbckMsgCodeBook{1,n}.spreadIdx;
    bkPermSeqEncoder = fdbckMsgCodeBook{1,n}.permSeqEncoder;
    bkPermSeqIntrlvr = fdbckMsgCodeBook{1,n}.permSeqIntrlvr;
    bkTrellisStruct  = fdbckMsgCodeBook{1,n}.trellisStruct;
    nBkModMsgSyms    = (nBkEncBits/bitsPerSym)*(spreadVal/bitsPerSym);
    bkModPktSize     = nBkModMsgSyms*upsampFactor;
    
    % Feedforward message variables
    nFwdMsgBits       = fdfwdMsgCodeBook{1,n}.nMsgBits;
    nFwdEncBits       = fdfwdMsgCodeBook{1,n}.nEncdBits;
    fwdTrnSyms        = fdfwdMsgCodeBook{1,n}.trnSymbols;
    fwdSpreadIdx      = fdfwdMsgCodeBook{1,n}.spreadIdx;
    fwdPermSeqEncoder = fdfwdMsgCodeBook{1,n}.permSeqEncoder;
    fwdPermSeqIntrlvr = fdfwdMsgCodeBook{1,n}.permSeqIntrlvr;
    fwdTrellisStruct  = fdfwdMsgCodeBook{1,n}.trellisStruct;
    fwdMsgSize        = nFwdEncBits/nPackets;
         
    end

    %%
    %   Variable vector definitions
    %
        
    % Allocate data buffer and specify indices for data entry into buffer
    txBuff  = zeros(buffEnd, 1);
    
    gainVec = zeros(8, 1);
    spreadVec = gainVec;
    
    %%
    %   Transmitter
    %
    
    % Transmitter definitions
    [modulator, txFilter] = initCommsTXMod(upsampFactor, modOrder);
    
    [fwdEncoder, fwdIntrlvr] = initCommsTXErrorCorrection(...
        fwdPermSeqEncoder, fwdPermSeqIntrlvr, fwdTrellisStruct);
    
    %%
    %   Receiver
    %
    
    % Initialization for synchronization and acquisition
    [freqEstimator, freqCompensator, rxFilter] = initCommsRXSync(...
        modOrder, upsampFactor, sampFreq);
    
    % Initialization for demodulation 
    demodulator = initCommsRXDemod(modOrder);
    
    % Initialization for error correction
    [bkDecoder, bkDeIntrlvr] = initCommsRXErrorCorrection(...
        bkPermSeqEncoder, bkPermSeqIntrlvr, bkTrellisStruct);
    
    % Generate new message bits every nth CPI
    [encdBits, truMsgBits] = genMsgBits(...
        fwdEncoder, fwdIntrlvr, nFwdMsgBits);%#ok  

    % Initialize message counter
    fwdMsgCount = 0;
    count = 1;

    for nn = 1:nTxCycles

        if mod(nn, fdbckInterval)

            % Index for current message bits
            msgIdx = fwdMsgCount*fwdMsgSize+(1:fwdMsgSize);
            
            % Increment message counter
            fwdMsgCount = fwdMsgCount+1;

            % Generate waveform packets
            commsWav = generateWaveform(...
                fwdTrnSyms, sfxSyms, encdBits(msgIdx), ...
                fwdSpreadIdx, spreadVal, modulator, txFilter);

            % Transmit waveform packets
            len = numel(commsWav);
            txBuff(1:2:2*len) = qpskGain*normData(real(commsWav));
            txBuff(2:2:2*len) = qpskGain*normData(imag(commsWav));

            % Transmit waveform packets
            usrpRadio.tx_usrp(startTime, txBuff);        

        else

            % Receive data from USRP
            rxBuff = usrpRadio.rx_usrp(startTime);

            % Convert to complex format
            rxWav = rxBuff(1:2:end)+1j*rxBuff(2:2:end);

            % Generate modulated spread sequence
            bkSpreadSeq = genModSpreadSeq(...
                spreadVal, bkSpreadIdx, modulator);

            % Compensate for frequency offset and apply matched filter
            rxFiltWav = commsRXFilt(...
                rxWav, freqEstimator, freqCompensator, rxFilter);

            % Perform acquisition and synchronization of comms and chirp signal
            [rxBkMsg, rxBkTrn, rxBkNzeTrn] = commsRXSync(...
                rxFiltWav, bkTrnSyms, bkModPktSize, commsParams);

            noisePwr = (rxBkNzeTrn'*rxBkNzeTrn)/length(rxBkNzeTrn);
            sigPwr   = (rxBkTrn'*rxBkTrn)/length(rxBkTrn);

            % Demodulate packets
            msgBits = commsRXDemod(...
                rxBkMsg, bkSpreadSeq, noisePwr, ...
                spreadVal, commsParams, demodulator);

            % Error correction
            bkMsgHat = commsRXDecode(msgBits(:), bkDecoder, bkDeIntrlvr);

            % Convert binary to decimal values
            [~, qpskGain, spreadVal] = binMsgDecode(bkMsgHat');

            % Adjust constants if needed
            nBkModMsgSyms = (nBkEncBits/bitsPerSym)*(spreadVal/bitsPerSym);
            bkModPktSize  = nBkModMsgSyms*upsampFactor;

            % 
            gainVec(count)   = qpskGain;
            spreadVec(count) = spreadVal;

            count = count+1;

        end

        startTime = startTime+procTime;

    end   
                
    % Release allocated objects
    releaseObjs(modulator, txFilter, fwdEncoder, ...
        fwdIntrlvr, freqEstimator, freqCompensator, ...
        rxFilter, demodulator, bkDecoder, bkDeIntrlvr);
    
    % Save data
    dateStr  = datestr(now, 'mmddyyyy_HHMMSS');
    fileName = ['usrpQPSKTx_', dateStr, '.mat'];    
    save(fullfile('~/Data', fileName), 'truMsgBits', 'gainVec', 'spreadVec');
    
    % Stop server 
    usrpRadio.terminate_usrp();
    
    % Set end of function flag
    eof = true;

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
