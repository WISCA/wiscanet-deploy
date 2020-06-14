function [ encdBits ] = commsRXEncode(msgBits, hEncoder, hIntrlv)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    % Encode bits
    encdBits = step(hEncoder, msgBits);
    
    % Interleave bits
    encdBits = step(hIntrlv, encdBits);
    
end

