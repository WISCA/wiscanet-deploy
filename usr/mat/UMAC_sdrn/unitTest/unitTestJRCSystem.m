function testSuccess = unitTestJRCSystem()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    clc; close all;
    addpath(genpath('../'));
    
    %% Initialize parameters
    % Set parameters
    paramsFile = setParameters('../paramsFiles');
    
    % Load Params file
    load(paramsFile);
    
    % 
    testSuccess = false;
    
    % Suffix symbols
    sfxSymbols = complex(ones(params.nSfxSyms, 1));
    
    %%
    % Chirp signal 
    %
    chirpWav = dchirp(params.chirpLen/params.sampFreq, params.sampFreq/2, 2).'; 
%     zeroVec = zeros(params.modPktSize - params.chirpLen, 1);
    
    %%
    %   Transmitter
    %
    % Transmitter definitions
    [modulator, txFilter] = initCommsTXMod(params.upsampFactor, params.modOrder);
    
    [encoder, intrlvr] = initCommsTXErrorCorrection(...
        codeBook.permSeqEncoder, codeBook.permSeqIntrlvr, codeBook.trellisStruct);
    
    % Generate message bits
    [encdBits, truMsgBits] = genMsgBits(encoder, intrlvr, params.nMsgBits);    

    nEncdBits = length(encdBits) / params.nPackets;
    
    % Generate channel
    awgnChan = comm.AWGNChannel(...
        'EbNo', 15, ...
        'BitsPerSymbol', params.bitsPerSym);    
    
    %%
    %   Receiver
    %
    
    % Initialization for synchronization and acquisition
    [freqEstimator, freqCompensator, rxFilter] = initCommsRXSync(params);
    
    % Initialization for error correction
    [decoder, deIntrlvr] = initCommsRXErrorCorrection(...
        codeBook.permSeqEncoder, codeBook.permSeqIntrlvr, codeBook.trellisStruct);
    
    % Initialization for demodulation 
    demodulator = initCommsRXDemod(params);
    
    % Upsample training symbols for synchronization
    upTrnSymbols  = upsample(codeBook.trnSymbols, params.upsampFactor);
    
    % Generate modulated spread sequence
    modSpreadSeq = genModSpreadSeq(...
        params.spreadVal, codeBook.spreadIdx, modulator);
    
    % 
    msgBits = zeros(length(codeBook.permSeqIntrlvr)/params.nPackets, params.nPackets);
   
    % Process each packet/pulse
    for nn = 1:params.nPackets
        
        msgIdx = (nn-1) * nEncdBits + (1:nEncdBits);
            
        txMsg = encdBits(msgIdx);
        
        % Generate waveform packets
        commsWav = generateWaveform(...
                codeBook.trnSymbols, sfxSymbols, txMsg, ...
                codeBook.spreadIdx, params.spreadVal, modulator, txFilter); 
        
        % Implement AWGN channel 
        rxWav(:,nn) = step(awgnChan, commsWav + [chirpWav; zeroVec]);

        % Compensate for frequency offset and matched filter
        rxFiltSyms = commsRXFilt(...
                rxWav(:,nn), freqEstimator, freqCompensator, rxFilter);
        
        % Correct frequency offset and synchronized
        syncSyms = commsRXSync(rxFiltSyms, upTrnSymbols, params);
               
        % Place equalizer here if needed
        

        % Demodulate symbols to bits
        msgBits(:,nn) = commsRXDemod(...
            syncSyms, modSpreadSeq, 1, ...
            demodulator, params);
        
    end
    
    % Error correction
    decodeBits = commsRXDecode(msgBits(:), decoder, deIntrlvr);
    
    ber = sum(decodeBits~=truMsgBits)/params.nMsgBits;
    display(['BER is ', num2str(ber)]);
     
    % Re-encode bits
    encodeBits = commsRXEncode(decodeBits, encoder, intrlvr);
        
    % Estimate TX waveform
    estCommsWavs = generateWaveforms(...
            codeBook.trnSymbols, encodeBits, codeBook.spreadIdx, ...
            modulator, txFilter, params);
        
    for nn = 1:params.nPackets
    
        % Do SIC (remove chirp signal from composite)
        sicSyms(:,nn) = commsRXSIC(estCommsWavs(:,nn), rxWav(:,nn)); 
     
    end
    
    genFigures(sicSyms(1:300,1), rxWav(1:300,1));
        
    % Release objects
    releaseObjs(...
        modulator, txFilter, encoder, ...
        intrlvr, freqEstimator, freqCompensator, ...
        rxFilter, decoder, deIntrlvr, ...
        demodulator);

end

function genFigures(sicWav, recWav)

    figure();
    subplot(2,1,1);
    spectrogram(recWav, [], [], [], 10e6, 'center', 'yaxis');
    caxis([-90 -60]);
    title('Spectrogram of received waveform');
    
    subplot(2,1,2);
    spectrogram(sicWav, [], [], [], 10e6, 'center', 'yaxis');
    caxis([-90 -60]);
    title('Spectrogram of waveform after SIC');
    
    % Extract axes handles of all subplots from the figure
    axesHandles = findobj(get(gcf,'Children'), 'flat','Type','axes');

    % Set the axis property to square
    axis(axesHandles,'square');
  
end
