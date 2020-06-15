function testSuccess = unitTestJRCSystemFeedBack()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    clc; close all;
    addpath(genpath('../'));
    
    %% Initialize parameters
    % Set parameters
    paramsFile = setParameters('./');
    
    % Load Params file
    load(paramsFile);
    
    % 
    testSuccess = false;
    
    %%
    % Radar Waveform Initialization
    %
    chirpWav = dchirp(params.chirpLen/usrpSettings.sample_rate, usrpSettings.sample_rate/2, 2).'; 
    
    %%
    %   Comms Waveform Initialization
    %
    
    % Transmitter definitions
    [modulator, txFilter] = initCommsTXMod(params);
    
    [encoder, intrlvr] = initCommsTXErrorCorrection(...
        codeBook.permSeqEncoder, codeBook.permSeqIntrlvr, codeBook.trellisStruct);
    
    % Generate a noise training slots
    noiseTrn = zeros(params.chirpLen, 1);
    noiseIdxs = (1:params.chirpLen)';
    
    %%
    % Channel generation
    %
    
    % AWGN channel for now
    awgnChan = comm.AWGNChannel(...
        'EbNo', 15, ...
        'BitsPerSymbol', params.bitsPerSym);
    
    % Zeros to tack onto end to account for different size waveforms 
    endZeros = zeros(params.modPktSize - params.chirpLen, 1);
    
    
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
    
    % 
    msgBits = zeros(length(codeBook.permSeqIntrlvr)/params.nPackets, params.nPackets);
   
    % Allocate size for received waveforms
    rxWav = zeros(params.modPktSize + params.chirpLen, params.nTXPulses);
    
    for n = 1:params.nCPI
        
        %%
        %   Generate transmission waveform
        %
        
        % Generate message bits
        [encdBits, truMsgBits] = genMsgBits(encoder, intrlvr, params.nMsgBits);     
    
        nEncdBits = length(encdBits) / params.nPackets;        
        
        % Process each packet/pulse
        for nn = 1:params.nTXPulses
            
            if ~mod(nn, params.snrInterval)
              
                % Receive 
                
                
            
                
            else
            
                msgIdx = (nn-1) * nEncdBits + (1:nEncdBits);
            
                txMsg = encdBits(msgIdx);
        
                % Generate waveform packets
                commsWav = generateWaveform(...
                    codeBook.trnSymbols, txMsg, codeBook.spreadIdx, ...
                    modulator, txFilter, params); 
            
            end

%%
% Channel
%

            % Add Chirp and QPSK waveform together
            txWav = [noiseTrn; commsWav + [chirpWav; endZeros]];
            
            % Implement AWGN Channel
            rxWav(:,nn) = step(awgnChan, txWav);
            
            
%%
%   Receiver
%
            if ~mod(nn, params.snrInterval)
                
                % Check current SNR and broadcast
                
                
                
                
            else
                
                % Receive

                % Estimate noise variance
                noiseVar = var(rxWav(noiseIdxs, nn));

                % Compensate for frequency offset and matched filter
                rxFiltSyms = commsRXFilt(...
                        rxWav(:,nn), freqEstimator, freqCompensator, rxFilter);

                % Correct frequency offset and synchronized
                syncSyms = commsRXSync(rxFiltSyms, upTrnSymbols, params);

                % Place equalizer here if needed


                % Demodulate symbols to bits

                % Generate modulated spread sequence
                modSpreadSeq = genModSpreadSeq(...
                    params.spreadVal, codeBook.spreadIdx, modulator);


                msgBits(:,nn) = commsRXDemod(...
                    syncSyms, modSpreadSeq, noiseVar, ...
                    demodulator, params);
                
            end 

        end

        % Error correction
        decodeBits = commsRXDecode(msgBits(:), decoder, deIntrlvr);

        ber = sum(decodeBits~=truMsgBits)/params.nMsgBits;
        display(['BER is ', num2str(ber)]);

        % Re-encode bits
        encodeBits = commsRXEncode(decodeBits, encoder, intrlvr);
        
        nEncodeBits = length(encodeBits) / params.nPackets;

        for nn = 1:params.nPackets
            
            msgIdx = (nn - 1) * nEncodeBits + (1:nEncodeBits);
            
            txHatMsg = encodeBits(msgIdx);
            
            % Estimate TX waveform
            commsWavHat = generateWaveform(...
                codeBook.trnSymbols, txHatMsg, codeBook.spreadIdx, ...
                modulator, txFilter, params);

            % Do SIC (remove chirp signal from composite)
            sicWav(:,nn) = commsRXSIC(commsWavHat, rxWav(:,nn)); 

        end
    
    end
    
    genFigures(sicWav(1:300,1), rxWav(1:300,1));
        
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
    title('Spectrogram of received waveform');
    
    subplot(2,1,2);
    spectrogram(sicWav, [], [], [], 10e6, 'center', 'yaxis');
    title('Spectrogram of waveform after SIC');
    
    % Extract axes handles of all subplots from the figure
    axesHandles = findobj(get(gcf,'Children'), 'flat','Type','axes');

    % Set the axis property to square
    axis(axesHandles,'square');
  
end
