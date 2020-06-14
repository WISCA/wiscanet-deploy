function [objMod, objTXFilter] = initCommsTXMod(usamp, order)

    % Initialize transmit filter
    objTXFilter = setTXFilter(usamp, 0.25, 10);
        
    % Initial modulator
    [objMod, ~] = setPSKModulator(order, 0);

end

function modObj = setTXFilter(usamp, rollOff, filtSpan)

    modObj = comm.RaisedCosineTransmitFilter(...
        'OutputSamplesPerSymbol', usamp,     ...
        'RolloffFactor',          rollOff,   ...
        'FilterSpanInSymbols',    filtSpan);

end
