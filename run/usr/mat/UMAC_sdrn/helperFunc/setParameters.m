function paramsFile = setParameters(saveDataFolder)
 
    if ~exist('saveDataFolder','var') || isempty(saveDataFolder)
        saveDataFolder = 'paramsFiles/';
    end
      
    [commsParams, fdfwdMsgCodeBook, fdbckMsgCodeBook] = setCommsParams();
    
    radarParams = setRadarParams(commsParams.sampFreq);
    
    targetParams = setTargetParams();
    
    fileName = ['params',datestr(now, 'ddmmmyyyy'),'.mat'];
    
    paramsFile = fullfile(saveDataFolder, fileName);
    
    % Save codebook data 
    save(paramsFile, 'commsParams', 'radarParams', ...
        'targetParams', 'fdbckMsgCodeBook', 'fdfwdMsgCodeBook');
    
end

function [commsParams, fdfwdMsgCodeBook, fdbckMsgCodeBook] = setCommsParams()

    
    commsParams.nTrnSyms     = 128;
    commsParams.nSfxSyms     = commsParams.nTrnSyms;
    commsParams.nNzeSyms     = commsParams.nTrnSyms;
    commsParams.upsampFactor = 2;    
    commsParams.fdbckInterval  = 6;
    commsParams.sampFreq     = 30e6;
    commsParams.modOrder     = 4;
    commsParams.bitsPerSym   = log2(commsParams.modOrder);
     
    % Gain settings (use these to adjust power values)
    commsParams.qpskGain     = 0.5;
    
%     Use divisor(nEncodeBits) for long message to determine nPackets value
%     Note: This is also the number of CPI intervals
    commsParams.nPackets   = 233; 
    commsParams.nPulses    = ...
        commsParams.nPackets+floor(commsParams.nPackets/(commsParams.fdbckInterval-1));
    
    % Control spectral efficiency with this (fix FEC rate)
    commsParams.spreadVal = 12;
    % spreadFactor = chipRate/bitRate
    
    % Set number of bits for feedback message
    fdbckMsgBits = 128;
    fdbckMsgCodeBook = setMsgParams(commsParams.nTrnSyms, fdbckMsgBits); %#ok
    
    % Set number of bits for feedforward message
    fdfwdMsgBits = 100e3;
    fdfwdMsgCodeBook = setMsgParams(commsParams.nTrnSyms, fdfwdMsgBits); %#ok

end

function [radarParams] = setRadarParams(fs)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    radarParams.c  = 3e8;
    radarParams.fc = 0.9e9;
    radarParams.chirpGain = 0.5;
    radarParams.lambda = radarParams.c/radarParams.fc;
    radarParams.pri = 2.5e-5;
    radarParams.chirpLen = 100*round(radarParams.pri*fs); 
    radarParams.prf = 1/radarParams.pri;

end

function [targetParams] = setTargetParams()
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    targetParams.velocity = 150;    % m/s
    targetParams.range = 2e3;       % m
    targetParams.returnEnergy = 40; % dB

end

function [codeBook] = setMsgParams(nTrnSyms, nMsgBits)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    
    %% Generate code book
    [codeBook, nEncodeBits] = genCodeBook(nMsgBits, nTrnSyms);%#ok   
    
    % Set number of message bits
    codeBook.nMsgBits  = nMsgBits;
    
    % Save number of encoded msg bits
    codeBook.nEncdBits = nEncodeBits;

end

function [codeBook, nEncodeBits] = genCodeBook( nMsgBits, nTrnSyms )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
   
    [codeBook.trellisStruct, nEncodeBits] = trellisGen(nMsgBits);%#ok

    codeBook.permSeqEncoder = randperm(nMsgBits)';
    
    codeBook.permSeqIntrlvr = randperm(nEncodeBits)';
    
    % Generate training symbols for each transmitter
    codeBook.trnSymbols = complex((-1).^randi([0 1], nTrnSyms, 1));
    
    % Generates random numbers w/o replacement on interval
    % [0, 5] for Kasami
    codeBook.spreadIdx = randperm(6, 1) - 1;
    
end

function [codeStruct, nEncodedBits] = trellisGen(numMsgBits)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    constLen = 4;
    codeGen = [13 15 17]; % [k, n] = size(codeGen) --> codeRate = k/n;
    feedBack = 13;
    codeStruct = poly2trellis(constLen, codeGen, feedBack);
    
    [~, n] = size(codeGen);
    nEncodedBits = numMsgBits*(2*n-1)+2*log2(codeStruct.numStates)*n;
    
end
