function msgBits = commsRXDemod(rxSyms, modSpreadSeq, nzPwrEst, ...
    spreadVal, params, hDemod)

    % Downsample
    msgSyms = rxSyms(1:params.upsampFactor:end);

    % Despread message symbols
    despreadMsgSyms = ...
        reshape(msgSyms, [], spreadVal/params.bitsPerSym) * modSpreadSeq;

    % Demodulate symbols (soft decision using true noise power)
    msgBits = step(hDemod, despreadMsgSyms, nzPwrEst);

    msgBits(find(msgBits>0)) = 0;
    msgBits(find(msgBits<0)) = 1;

end


