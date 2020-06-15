function testSuccess = unitTestTxRxWave()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    clc; close all;
    addpath(genpath('../'));
    
    %% Initialize parameters
    % Set parameters
    paramsFile = setParameters([]);
    
    % Load Params file
    load(paramsFile);
    
    % 
    testSuccess = false;
    
    %%
    % Chirp signal 
    %
    chirpWav = dchirp(params.chirpLen/usrpSettings.sample_rate, usrpSettings.sample_rate/2, 2);
        
    %%
    %   Transmitter
    %
    % Transmitter definitions
    [modulator, txFilter] = initCommsTXMod(params);
    
    [encoder, intrlvr] = initCommsTXErrorCorrection(...
        codeBook.permSeqEncoder, codeBook.permSeqIntrlvr, codeBook.trellisStruct);
    
    % Generate message bits
    [encdBits, truMsgBits] = genMsgBits(encoder, intrlvr, params.nMsgBits);    

    % Generate waveform packets
    packetSyms = generateWaveforms(...
        codeBook.trnSymbols, encdBits, codeBook.spreadIdx, ...
        modulator, txFilter, params);
    
    
    %%
    %   Receiver
    %
    
    % Initialization for synchronization and acquisition
    [freqEstimator, freqCompensator, rxFilter] = initCommsRXSync(params);
    
    % Initialization for error correction
    [decoder, deIntrlvr] = initCommsRXErrorCorrection(...
        codeBook.permSeqEncoder, codeBook.permSeqIntrlvr, codeBook.trellisStruct);
    
    % Initialization for demodulation 
    [demodulator, modulatorRX] = initCommsRXDemod(params);
    
    % Upsample training symbols for synchronization
    upTrnSymbols  = upsample(codeBook.trnSymbols, params.upsampFactor);
    
    % Generate modulated spread sequence
    modSpreadSeq = genModSpreadSeq(...
        params.spreadVal, codeBook.spreadIdx, modulatorRX);
    
    % 
    msgBits = zeros(length(codeBook.permSeqIntrlvr)/params.nPackets, params.nPackets);
   
    % Process each packet/pulse
    for n = 1:params.nPackets
        
        % Compensate for any frequency offset that might occur
        rxFiltSyms = commsRXFilt(...
            packetSyms(:,n), freqEstimator, freqCompensator, rxFilter);
        
        % Perform acquisition and synchronization of comms and chirp signal
        [syncdSyms, ~] = rxSync(...
            rxFiltSyms, upTrnSymbols, chirpWav, [], params);
        
        % Place equalizer here if needed
        

        % 
        msgBits(:,n) = commsRXDemod(...
            syncdSyms, modSpreadSeq, 1, ...
            demodulator, params);
        
    end
    
    % Error correction
    decodeBits = commsRXDecode(msgBits(:), decoder, deIntrlvr);
    
    ber = sum(decodeBits~=truMsgBits)/params.nMsgBits;
    
    if ber == 0
        
        testSuccess = true;
        
    end
        
    % Release objects
    releaseObjs(...
        modulator, txFilter, encoder, ...
        intrlvr, freqEstimator, freqCompensator, ...
        rxFilter, decoder, deIntrlvr, ...
        demodulator, modulatorRX);

end

