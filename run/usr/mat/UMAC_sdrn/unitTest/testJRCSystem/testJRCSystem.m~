function [ output_args ] = testJRCSystem()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    % Initialize parameters
    initParamsScript;
     
    % 
    dataDir = '~/Data/SDR/JointCommsRadar/900MHz/06012017/CommsRadar/125344';
    dataFiles = {'usrpQPSKTx.mat', 'usrpJRCRx.mat'};
    for n = 1:length(dataFiles)
       
        load(fullfile(dataDir, dataFiles{n}));
        
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
        
    for n = 1:nPackets

        % Compensate for any frequency offset that might occur
        rxFiltWav = commsRXFilt(...
                rxWav(:,n), freqEstimator, freqCompensator, rxFilter);

        % Perform acquisition and synchronization of comms and chirp signal
        [rxFwdMsg, rxFwdTrn, rxFwdNzeTrn] = commsRXSync(...
                rxFiltWav, fwdTrnSyms, fwdModPktSize, commsParams);

        % Do SNR and channel estimation
        noisePwr = (rxFwdNzeTrn'*rxFwdNzeTrn)/length(rxFwdNzeTrn);
%         [h, sigPwr, noisePwr] = ...
%             chanEstimate(rxFwdTrn, rxFwdNzeTrn, Ps, delayMtx);

        % Demodulate synchronized syms to message bits
        fwdMsgBits(:,n) = commsRXDemod(...
            rxFwdMsg, modSpreadSeq, noisePwr, ...
            spreadVal, commsParams, demodulator);

    end

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
        sicWav = commsRXSIC(...
            estCommsWav(nNzeSyms*upsampFactor+1:end), rxWav(:,n));

        % Do radar processing  
       [doppEstimate(n), rangeEstimate(n)] = ...
           radarRXPulseDopProc(sicWav, radarWav, sampFreq, radarParams);

    end
        
    % Release objects
    releaseObjs(...
        modulator, txFilter, bkEncoder, ...
        bkIntrlvr, freqEstimator, freqCompensator, ...
        rxFilter, fwdDecoder, fwdDeIntrlvr, ...
        fwdEncoder, fwdIntrlvr, demodulator);
    
end

% function genFigures(sicWav, recWav)
% 
%     figure();
%     subplot(2,2,1);
%     plot(abs([zeros(10e3,1); recWav]).^2);
%     ylim([0 0.04]);
%     grid on;
%     xlabel('Samples')
%     ylabel('Power (Linear)')
%     title('Composite Power')
%     
%     subplot(2,2,2);
%     plot(abs([zeros(10e3,1); sicWav]).^2);
%     ylim([0 0.04]);
%     grid on;
%     xlabel('Samples')
%     ylabel('Power (Linear)')
%     title('Composite Power after SIC')
%     
%     subplot(2,2,3);
%     spectrogram(recWav(1:300), [], [], [], 10e6, 'center', 'yaxis');
%     caxis([-100 -70]);
%     title('Spectrogram of Composite waveform');
%         
%     subplot(2,2,4);
%     spectrogram(sicWav(1:300), [], [], [], 10e6, 'center', 'yaxis');
%     caxis([-100 -70]);
%     title('Spectrogram of SIC waveform');  
%     
%     % Extract axes handles of all subplots from the figure
% %     axesHandles = findobj(get(gcf,'Children'), 'flat','Type','axes');
% % 
% %     % Set the axis property to square
% %     axis(axesHandles,'square');
%   
% end
