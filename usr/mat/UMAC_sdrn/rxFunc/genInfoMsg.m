function encdBits = genInfoMsg(chirpGain, qpskGain, spreadVal, hEncoder, hIntrlv)

    msgBits = binMsgEncode(128, chirpGain, qpskGain, spreadVal);
    
    % Encode bits
    encdBits = step(hEncoder, msgBits');
    
    % Interleave bits
    encdBits = step(hIntrlv, encdBits);   

end