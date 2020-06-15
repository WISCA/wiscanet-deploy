function eof = usrpQPSKNode(sys_start_time)

    %%
    % Add relevant paths
    %
    addpath(genpath('../../lib'));
    addpath(genpath('../'));
    
    %%
    % Initialize radio
    %

    % Load params file
      load('../paramsFiles/params17Sep2018.mat'); % Commented for
      %debugging
      %load('paramsFiles/params17Sep2018.mat');
   
      [usrpSettings, usrpRadio] = initUSRPRadio(commsParams);
   
    % '2017-05-11 00:00:00'
    if 0
       startTime = setStartTime();%#ok
    else 
       startTime = sys_start_time; %time from manager
    end%
    
    %%
    % Constant variable definitions
    %
    lId = usrpRadio.logicalId();
    lIdStr = num2str(lId);
   
    % Misc Initializations
    
    sampFreq       = commsParams.sampFreq;
    upsampFactor   = commsParams.upsampFactor;
    modOrder       = commsParams.modOrder;
    bitsPerSym     = commsParams.bitsPerSym;
    nCycles        = commsParams.nCycles;
    nSfxSyms       = commsParams.nSfxSyms;
    sfxSyms        = complex(zeros(nSfxSyms,1));
    qpskGain       = commsParams.qpskGain;
    spreadVal      = commsParams.spreadVal;
    nUsrs          = commsParams.nUsrs;
    nUsrBits	   = commsParams.nUsrBits;
    nMsgBits	   = commsParams.nMsgBits;
    msgBits        = commsParams.msgBits;    
    initMsgBits    = msgBits;
    modMsgSyms     = ((nMsgBits+nUsrBits)/bitsPerSym)*(spreadVal/bitsPerSym);
    modMsgSize     = modMsgSyms*upsampFactor;
    msgHat         = zeros(nMsgBits+nUsrBits,1);
    encdBits       = msgHat;
    
    buffSize       = usrpSettings.buff_samps;
    buffEnd        = 2*buffSize;
    buffErrs       = zeros(nCycles,1);    
    bitErrs        = zeros(nCycles,1);
    txFlag         = false;
    procTime       = usrpSettings.proc_time;
    
    
    %%
    % Variable per User
    % 

    % Message variables
    trnSyms        = msgCodeBook.trnSymbols;
    spreadIdx      = msgCodeBook.spreadIdx;
    permSeqIntrlvr = msgCodeBook.permSeqIntrlvr;
        
    % Allocate data buffer 
    txBuff  = zeros(buffEnd, 1);
    rxBuff  = zeros(buffEnd, 1);
    rxWav = zeros(buffSize, 1);
    
    %%
    %   Transmitter Initialization
    %
    
    [modulator, txFilter] = initCommsTXMod(upsampFactor, modOrder);    
    [intrlvr] = initCommsTXErrorCorrection(permSeqIntrlvr);
    
    %%
    %   Receiver InitializationQPSKT
    %
                %[rxMsg, rxTrn, rxNzeTrn] = commsRXSync(...
              %rxFiltWav, trnSyms, modMsgSize, commsParams); %#ok

    % Initialization for synchronization and acquisition OK
    [freqEstimator, freqCompensator, rxFilter] = initCommsRXSync(...
        modOrder, upsampFactor, sampFreq);
    
    [deIntrlvr] = initCommsRXErrorCorrection(permSeqIntrlvr);
    [demodulator] = initCommsRXDemod(modOrder);    
    nextUsrId = randi([2 nUsrs]);
    % Initialize message counter
    count = 1;
    
    %%    addpath(genpath('../'));
    %Transmit/Receive Loop
    
    

    for nn = 1:nCycles

        %Transmit
        if (lId == 1 && nn == 1) || (txFlag == true) 
            
            fprintf('\nFrame Number: %i\n', count)
            fprintf('Transmitting to User %i\n\n', nextUsrId)
            
            % Generate new message bits with updated nxtUsr  
            [encdBits, fullMsgBits] = genMsgBits(...
                intrlvr, msgBits, nUsrBits, nextUsrId);  

            % Generate waveform packets
            commsWav = generateWaveform(...
            	trnSyms, sfxSyms, encdBits, ...
                spreadIdx, spreadVal, modulator, txFilter);
                nextUsrId = randi([2 nUsrs]);
            
	        commsWav = commsWav/max(abs(commsWav));
            
            % save last Tx Wave
             fileName = ['usrpQPSKNode_txWav_',lIdStr, '.mat'];
             save(fullfile('~/Data', fileName), 'commsWav');

            % Transmit waveform packets
            len = numel(commsWav);
            txBuff(1:2:2*len) = (real(commsWav));
            txBuff(2:2:2*len) = (imag(commsWav));

            % Transmit waveform packets
            usrpRadio.tx_usrp(startTime, txBuff);        
 	
	    txFlag = false;		
 
	    count = count+1;
 
        else
            		   
	    fprintf('\n\nFrame Number %i\n', count)
        fprintf('Receiving\n')

            % Receive 
            %

            rxBuff = (usrpRadio.rx_usrp(startTime)).';
            %[rxBuff, buffErrs(nn)] = buffErrorCorrect(rxBuff, buffEnd);              

            % Convert to complex format
            rxWav = complex(rxBuff(1:2:end),rxBuff(2:2:end));
            
              % save last Rx Wave
              fileName = ['usrpQPSKsys_start_timeNode_rxWav_',lIdStr, '.mat'];
              save(fullfile('~/Data', fileName), 'rxWav');
            
             % Generate spread sequence
             spreadSeq = genModSpreadSeq(...
                         spreadVal, spreadIdx, modulator);

            % Compensate for frequency offset and apply matched filter
            rxFiltWav = commsRXFilt(...
                rxWav, freqEstimator, freqCompensator, rxFilter);

            % Perform acquisition and synchronization of comms and chirp signal
            [rxMsg, rxTrn, rxNzeTrn] = commsRXSync(...
                rxFiltWav, trnSyms, modMsgSize, commsParams); %#ok

            noisePwr = (rxNzeTrn'*rxNzeTrn)/length(rxNzeTrn);

            % Demodulate packets
            rxFullMsgBits = commsRXDemod(...
                rxMsg, spreadSeq, noisePwr, ...
                spreadVal, commsParams, demodulator);

            % Msg Decode
            msgHat = commsRXDecode(rxFullMsgBits(:), deIntrlvr);

            %%
            %Extract User Data
            % Convert binary to decimal values
            
            rxMsgBits = msgHat(1:nMsgBits);
            rxUsrBits = msgHat(nMsgBits+1:end);
            rxUsrId = binMsgDecode(rxUsrBits.');    % Debugging-This feels like the culprit! The operands are not integers after running th demo for a while 

            [bitErrs, BER] = biterr(rxMsgBits, initMsgBits);
           %fprintf('Bit Errors = %i\n', bitErrs)
	    fprintf('Bit Error Rate = %i\n',BER)
            
            % set Tx flag
            
            [txFlag, nextUsrId] = setTxFlag(lId, rxUsrId, nUsrs);

         if txFlag == true
			fprintf('TX FLAG = HIGH\nNEXT USER = %i\n', nextUsrId)
		 	msgBits = rxMsgBits;
            
		 else
			fprintf('TX FLAG = LOW\nIDLE\n')
		 end
                       
            count = count+1;

        end 

        startTime = startTime+procTime; 
    end 

                
    % Release allocated objects
    releaseObjs(modulator, demodulator, txFilter, ...
        rxFilter, intrlvr, deIntrlvr, freqEstimator, ...
        freqCompensator);
       
    dateStr  = datestr(now, 'mmddyyyy_HHMMSS');
    fileName = ['usrpQPSKNode', dateStr, '.mat'];
    save(fullfile('../Data', fileName), 'rxWav');
         
        
    % Stop server 
    usrpRadio.terminate_usrp();
    
    % Set end of function flag
    eof = true;

    success = true;

end

function [ usrpSettings, usrpRadio ] = initUSRPRadio(p)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
        
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
    usrpSettings.proc_time 	= 4;            %MATLAB processing time (seconds)

    
    usrpRadio = local_usrp;
    
	usrpRadio  =   usrpRadio.set_usrp(...
        usrpSettings.type, usrpSettings.ant, usrpSettings.subdev, ... 
        usrpSettings.ref, usrpSettings.wirefmt, usrpSettings.buff_samps,...
        usrpSettings.sample_rate, usrpSettings.freq, usrpSettings.rx_gain, ...
        usrpSettings.tx_gain, usrpSettings.bw, usrpSettings.setup_time);

end

function posixTime = setStartTime(dateTimeStr) %#ok

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

