function paramsFile = setParameters(saveDataFolder)
    if ~exist('saveDataFolder','var') || isempty(saveDataFolder)
        saveDataFolder = 'paramsFiles/';	   %Changed this path
    end;
    
    %Declare number of comms users 
    nUsrs = 2;    				           
    [commsParams,msgCodeBook] = setCommsParams(nUsrs); %#ok
    fileName = ['params',datestr(now, 'ddmmmyyyy'),'.mat'];
    paramsFile = fullfile(saveDataFolder, fileName);
    
    % Save codebook dadta 
    clear ans;
    save(paramsFile, 'commsParams', 'msgCodeBook');
    
end


function [commsParams, msgCodeBook] = setCommsParams(numUsers)

    commsParams.nUsrs        = numUsers;
    commsParams.nCycles      = 200;
    commsParams.nTrnSyms     = 128;
    commsParams.nSfxSyms     = commsParams.nTrnSyms;
    commsParams.nNzeSyms     = 512;
    commsParams.upsampFactor = 2;    
    commsParams.sampFreq     = 20e6;
    commsParams.modOrder     = 4;
    commsParams.bitsPerSym   = log2(commsParams.modOrder);
    commsParams.nUsrBits     = 102;
    commsParams.nMsgBits     = 2004;     
    commsParams.zeroPad      = 200; 
    % Gain settings (use these to adjust amplitude values)
    commsParams.qpskGain     = 1;

    % Control spectral efficiency with this (fix FEC rate)spread
    commsParams.spreadVal = 12;

    % Set number of bits for feedforward message
    msgBitsTotal =  commsParams.nUsrBits + commsParams.nMsgBits;       
    msgCodeBook = setMsgParams(commsParams.nTrnSyms, msgBitsTotal);
    
    commsParams.msgBits = [ones(3, 1); randi([0 1],commsParams.nMsgBits - 3, 1)];


end

function [codeBook] = setMsgParams(nTrnSyms, nMsgBits)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    
    % Generate code book
    [codeBook, ~] = genCodeBook(nMsgBits, nTrnSyms);   
    
    % Set number of message bits
    codeBook.nMsgBits  = nMsgBits;
    
    % Save number of encoded msg bits
    %codeBook.nEncdBits = codeBook.nmsgBits;

end

function [codeBook, nEncodeBits] = genCodeBook( nMsgBits, nTrnSyms )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
   
%     [codeBook.trellisStruct, nEncodeBits] = trellisGen(nmsgBits);
%     codeBook.permSeqEncoder = randperm(nMsgBits)';   
    codeBook.permSeqIntrlvr = randperm(nMsgBits)';
    nEncodeBits = nMsgBits;
   
    % Generate training symbols for each transmitter
    codeBook.trnSymbols = complex((-1).^randi([0 1], nTrnSyms, 1));
    
    % Generates random numbers w/o replacement on interval
    % [0, 5] for Kasami
    codeBook.spreadIdx = randperm(6, 1) - 1;
    
end
% 
% function [codeStruct, nEncodedBits] = trellisGen(numMsgBits)
 %UNTITLED2 Summary of this function goes here
 %   Detailed explanation goes here
 %
 %    constLen = 4;
 %    codeGen = [13 15 17]; % [k, n] = size(codeGen) --> codeRate = k/n;
 %    feedBack = 13;
 %    codeStruct = poly2trellis(constLen, codeGen, feedBack);
     
 %    [~, n] = size(codeGen);
 %    nEncodedBits = numMsgBits*(2*n-1)+2*log2(codeStruct.numStates)*n;
     
% end
