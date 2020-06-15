function testSuccess = unitTestInfoMsg()
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
    clc; close all;
    addpath(genpath('../'));
    
    %% Initialize parameters
    % Set parameters
    paramsFile = setParameters([]);
    
    % Load Params file
    load(paramsFile);

    nPackets  = params.nPackets;
    qpskGain  = params.qpskGain;
    spreadVal = params.spreadVal;
    pktLen    = params.nEncdBits/nPackets;
    testSuccess = false;
    trnSymbols = codeBook.trnSymbols;
    spreadIdx  = codeBook.spreadIdx;
    sfxSymbols = ones(params.nSfxSyms,1);
    upsampFactor   = params.upsampFactor;
    
    %%
    %
    %

    [bpskMod, txFilter] = initCommsTXMod(upsampFactor, 2);
    
    infoMsg = genInfoMsg(qpskGain, spreadVal)';

    txMsg = [infoMsg; randi([0 1], pktLen - 128, 1)];

    % Generate waveform packets
    commsWav = generateWaveform(...
        trnSymbols, sfxSymbols, txMsg, ...
        spreadIdx, spreadVal, bpskMod, txFilter);


    pwelch(commsWav, [] ,[], [], 10e6, 'center');
    
    %%
    %   Receiver
    %
    
    
        
    % Release objects
    releaseObjs(bpskMod, txFilter);

end

