function [modObj, bitsPerSym] = setPSKModulator(modOrder, phaseOffset)

    % Create PSK Modulator object
    modObj = comm.PSKModulator(...
        'ModulationOrder', modOrder, ...
        'PhaseOffset',     phaseOffset,...
        'BitInput',        true);

    bitsPerSym = log2(modOrder);

end
