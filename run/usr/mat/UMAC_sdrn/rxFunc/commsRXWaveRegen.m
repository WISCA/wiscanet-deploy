function [ txPackets ] = commsRXWaveRegen( ...
    msgBits, hEncoder, hIntrlv, codeBook, params )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    % Encode bits
    encdBits = step(hEncoder, msgBits);
    
    % Interleave bits
    encdBits = step(hIntrlv, encdBits);
    
    % Generate suffix bits
    sfxBits = ones(params.nSfxBits, 1);
    
    % Regenerate packets
    packetSyms = generateWaveforms(...
        codeBook.trnSymbols, encdBits, codeBook.spreadIdx, ...
        modulator, txFilter, params);

end

