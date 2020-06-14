function packetSyms = generateWaveform(...
    trnSyms, sfxSyms, msgBits, ...
    spreadIdx, spreadVal, hModulator, hTXFilter)

    % Number of noise symbols
    nNoiseSyms = length(trnSyms);
    
    % Extract upsample factor
    upsamp = hTXFilter.OutputSamplesPerSymbol;

    % Generate modulated spread sequence
    modSpreadSeq = genModSpreadSeq(spreadVal, spreadIdx, hModulator);
               
    % Modulate current message bit sequence
    modMsgBits = step(hModulator, msgBits);

    % Apply spreading sequence to message 
    spreadMsgBits = modMsgBits*modSpreadSeq';

    % Concatenate modulated data
    modPacket = [trnSyms; spreadMsgBits(:); sfxSyms];

    % ... and apply transmit filter to make waveform
    packetSyms = step(hTXFilter, modPacket);
    packetSyms = [zeros(upsamp*nNoiseSyms,1); packetSyms];  
        
end



