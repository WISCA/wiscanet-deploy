function [modObj, bitsPerSym] = setPSKModulator(modOrder, phaseOffset)

    modObj = comm.PSKModulator(...
        'ModulationOrder', modOrder, ...
        'PhaseOffset',     phaseOffset,...
        'BitInput',        true);
    
    bitsPerSym = log2(modOrder);
    
end