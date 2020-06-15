function [encdBits, truMsgBits] = genMsgBits(hIntrlv, msgBits, nextUsrLen, nextUsrId)
      
    % Message bits    
    nextUsrBits = binMsgEncode(nextUsrLen,nextUsrId)';
    
    % Concatenate message bits with next user bits
    truMsgBits = [msgBits; nextUsrBits];

    % Encode bits - we are not doing this
    %encdBits = step(hEncoder, truMsgBits);
    
    % Interleave bits
    encdBits = step(hIntrlv, truMsgBits);
    
end

