function eof = usrpRadarTx(sys_start_time)

    addpath(genpath('../../lib'));
    addpath(genpath('../'));
	
    %% 
    %   Initialize radio
    %
    
    % Load simParams file
    load('../paramsFiles/params06Jun2017.mat');
    
    [usrpSettings, usrpRadio] = initUSRPRadio(commsParams);
    
    % '2017-05-11 00:00:00'
    if 0
       startTime = setStartTime();
    else 
       startTime = sys_start_time; %time from manager
    end
    
    %%
    %   Constant variable declarations
    %
    chirpLen   = radarParams.chirpLen;
    chirpGain  = radarParams.chirpGain;           % Chirp gain
    pri        = radarParams.pri;
    lambda     = radarParams.lambda;
    pwp        = radarParams.pwp;
    cpiLen     = radarParams.cpiLen; 
    
    tgtRange   = targetParams.range;
    tgtVel     = targetParams.velocity;
    tgtEnergy  = targetParams.returnEnergy;
    tgtRespLen = round(chirpLen/pwp)*cpiLen;
    
    fdbckInterval = commsParams.fdbckInterval;
    sampleFreq    = commsParams.sampFreq;
    
    buffSize   = usrpSettings.buff_samps;
    buffEnd     = buffSize*2;
    procTime    = usrpSettings.proc_time;       
   
    nTxCycles   = commsParams.nTxCycles;
    
    %%
    %   Vector declarations
    %
    
    % Allocate data buffer and specify indices for data entry into buffer
    radarBuff = zeros(buffEnd, 1);
    
    % Coherent processing interval vector
    cpi = 1:100;
    
    %%
    %
    
    % Generate radar waveform
    radarWav = dchirp(chirpLen/sampleFreq, sampleFreq, 1);
     
    % Generate target response
    [~,targetResponse]= target_signal_generator(...
        1, radarWav, tgtRange, ...
        tgtVel, 10^(tgtEnergy/10), pri, ...
        cpi, sampleFreq, lambda);
    
    targetResponse = targetResponse./max(abs(targetResponse));
        
    for nn = 1:nTxCycles

        if mod(nn, fdbckInterval)

            % Transmit waveform packets
            radarBuff(1:2:2*tgtRespLen) = chirpGain*real(targetResponse);
            radarBuff(2:2:2*tgtRespLen) = chirpGain*imag(targetResponse);

            % Transmit waveform packets
            usrpRadio.tx_usrp(startTime, radarBuff);

        end

        startTime = startTime+procTime;

    end
    
    dateStr  = datestr(now, 'mmddyyyy_HHMMSS');
    fileName = ['usrpRadarTx_', dateStr, '.mat'];    
    save(fullfile('~/Data', fileName), 'targetResponse');

    format longG;
    tgtRange
    tgtVel	

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
