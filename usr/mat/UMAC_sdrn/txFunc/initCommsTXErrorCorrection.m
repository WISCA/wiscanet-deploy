function [objIntrlv] = ...
    initCommsTXErrorCorrection(permSeqIntrlvr)

    % Generate interleaver object
    objIntrlv  = comm.BlockInterleaver(permSeqIntrlvr);

end


