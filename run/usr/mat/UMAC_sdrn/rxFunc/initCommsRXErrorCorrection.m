function [objDeInterleave] = ...
    initCommsRXErrorCorrection(permSeqIntrlvr)

    % De-interleave bits
    objDeInterleave = comm.BlockDeinterleaver(permSeqIntrlvr);

end


