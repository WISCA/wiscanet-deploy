%% this is a test %%

function usrpJRCSystem(start_epoch_time, radioflag, params_file)

%% Load parameters for experiments
load(params_file);

%% Time stamp the date and time of the experiment
expDateTime = datestr(now,'mmddyyyy_HHMMSS');
   
%% USRP Settings
localUSRP = initUSRPDevice(host, tcp_socket_port, usrpSettings);

switch radioflag
    
    case 'chirptx'
        
        chirpWav = ...
            usrpChirpTx(localUSRP, params, usrpSettings, start_epoch_time);%#ok
        
        saveFileName = ['chirpWaveform_', expDateTime,'.mat'];
        save(fullfile('collectedData', saveFileName), 'chirpWav');
    
    case 'qpsktx'
        
        [truMsgBits, qpskWavs] = ...
            usrpQPSKTx(localUSRP, codeBook, params, usrpSettings, start_epoch_time); %#ok
        
        saveFileName = ['qpskData_', expDateTime, '.mat'];
        save(fullfile('./sharedData', saveFileName), 'truMsgBits', 'qpskWavs');
        
        
    case 'rxprocess'
        
        [rxSyms, decodeBits, sicSyms] = ...
            usrpJRCRx(localUSRP, codeBook, params, usrpSettings, start_epoch_time);%#ok
        
        saveFileName = ['rxProcData_', expDateTime,'.mat'];
        save(fullfile('collectedData', saveFileName), 'rxSyms', 'decodeBits', 'sicSyms');
      
    case 'rxcollect'
        
        rxSyms = ...
            usrpJRCRxCollect(localUSRP, params, usrpSettings, start_epoch_time);%#ok
        
        saveFileName = ['rxCollectData_', expDateTime, '.mat'];
        save(fullfile('collectedData', saveFileName), 'rxSyms');	
        
    otherwise
        
        error(...
            'Radio option not supported. Valid options: chirptx, qpsktx, rxprocess, or rxcollect.');
        
end



end

function localUSRP = initUSRPDevice(host, tcp_socket_port, usrp_settings)

    %
    localUSRP = usrp_device(host,tcp_socket_port,usrp_settings.usrp_address);
    
    %
    localUSRP = localUSRP.set_usrp(...
        usrp_settings.type, ...
        usrp_settings.ant, ...
        usrp_settings.subdev, ...
        usrp_settings.ref, ...
        usrp_settings.wirefmt, ...
        usrp_settings.buff_samps, ...
        usrp_settings.sample_rate, ...
        usrp_settings.freq, ...
        usrp_settings.rx_gain, ...
        usrp_settings.tx_gain, ...
        usrp_settings.bw, ...
        usrp_settings.setup_time);

end


