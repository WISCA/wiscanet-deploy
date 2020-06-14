function eof = procRxDataLog(paramsFile, rxFilesDir)
    clc; close all;
    
    if ~exist('paramsFile','var') || isempty(paramsFile)
        
        % Choose the master node data folder
        [fname, fdir] = fileChooser([], 'Select the configuration file');
        paramsFile = fullfile(fdir, fname);
        
    end
    
    if ~exist('rxFilesFolder', 'var') || isempty(rxFilesDir)
        
        % Choose the master node data folder
        msgStr  =  'Select the folder to store analysis data';
        randStr = 'ubfubfebiufdbiufedsdsfqa';
        
        dataDir = folderChooser(msgStr, randStr);
        
    end

%%
%   Load data files and parameters files
    dataFiles = sort_nat(dir2cell(fullfile(dataDir, '*.mat')));
    
    % Load parameters and code book structure
    load(paramsFile);
    
    % Initialize variables
    initVarsScript;
    
    % Load in data files for analysis
    for nn = 1:length(dataFiles)
       
        load(fullfile(dataDir, dataFiles{nn}));
        
    end
    
    %%
    %   Transmitter Initialization
    %

    % Transmitter initialization
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
    
    % Initialization for demodulation objects
    demodulator = initCommsRXDemod(modOrder);
    
    % Generate radar waveform
    radarWav = dchirp(chirpLen/sampFreq, sampFreq, 1);
    
    %%
    %   SIC component initialization
    %

    % Initialize encoder and interleaver (for regenerating packets)
    [fwdEncoder, fwdIntrlvr] = initCommsTXErrorCorrection(...
        fwdPermSeqEncoder, fwdPermSeqIntrlvr, fwdTrellisStruct);
        
    % Update spread sequence based on new spreading value
    modSpreadSeq = genModSpreadSeq(...
            spreadVal, fwdSpreadIdx, modulator);
        
    for nn = 1:nPackets

        % Compensate for any frequency offset that might occur
        rxFiltWav = commsRXFilt(...
                rxWav(:,nn), freqEstimator, freqCompensator, rxFilter);

        % Perform acquisition and synchronization of comms and chirp signal
        [rxFwdMsg, ~, rxFwdNzeTrn] = commsRXSync(...
                rxFiltWav, fwdTrnSyms, fwdModPktSize, commsParams);

        % Do SNR and channel estimation
        noisePwr = (rxFwdNzeTrn'*rxFwdNzeTrn)/length(rxFwdNzeTrn);

        % Demodulate synchronized syms to message bits
        fwdMsgBits(:,nn) = commsRXDemod(...
            rxFwdMsg, modSpreadSeq, noisePwr, ...
            spreadVal, commsParams, demodulator);%#ok<AGROW>

    end    
        
    % Error correction
    decodeBits = commsRXDecode(fwdMsgBits(:), fwdDecoder, fwdDeIntrlvr);

    %%
    % Perform SIC
    %

    % Re-encode bits
    encodeBits = commsRXEncode(decodeBits, fwdEncoder, fwdIntrlvr);
    
    for nn = 1:nPackets

        % Index for current message bits
        msgIdx = (nn-1)*fwdMsgSize+(1:fwdMsgSize);

        % Estimate TX waveform
        estCommsWav = generateWaveform(...
            fwdTrnSyms, sfxSyms, encodeBits(msgIdx), ...
            fwdSpreadIdx, spreadVal, modulator, txFilter);

        % Do SIC (remove chirp signal from composite)
        sicWav = commsRXSIC(...
            estCommsWav(nNzeSyms*upsampFactor+1:end), rxWav(:,nn));

        %
        % Do doppler processing here
        % 
        [dopEstimates(nn), rngEstimates(nn)] = radarRXPulseDopProc(...
            sicWav, radarWav, sampFreq, radarParams);

    end
       
    % Release objects
    releaseObjs(...
        modulator, txFilter, bkEncoder, ...
        bkIntrlvr, freqEstimator, freqCompensator, ...
        rxFilter, fwdDecoder, fwdDeIntrlvr, ...
        fwdEncoder, fwdIntrlvr, demodulator);
    
    eof = true;

end

function genFigures(sicWav, recWav)

    figure();
    subplot(2,2,1);
    plot(abs([zeros(10e3,1); recWav]).^2);
    ylim([0 0.04]);
    grid on;
    xlabel('Samples')
    ylabel('Power (Linear)')
    title('Composite Power')
    
    subplot(2,2,2);
    plot(abs([zeros(10e3,1); sicWav]).^2);
    ylim([0 0.04]);
    grid on;
    xlabel('Samples')
    ylabel('Power (Linear)')
    title('Composite Power after SIC')
    
    subplot(2,2,3);
    spectrogram(recWav(1:300), [], [], [], 10e6, 'center', 'yaxis');
    caxis([-100 -70]);
    title('Spectrogram of Composite waveform');
        
    subplot(2,2,4);
    spectrogram(sicWav(1:300), [], [], [], 10e6, 'center', 'yaxis');
    caxis([-100 -70]);
    title('Spectrogram of SIC waveform');  
    
    % Extract axes handles of all subplots from the figure
%     axesHandles = findobj(get(gcf,'Children'), 'flat','Type','axes');
% 
%     % Set the axis property to square
%     axis(axesHandles,'square');
  
end


