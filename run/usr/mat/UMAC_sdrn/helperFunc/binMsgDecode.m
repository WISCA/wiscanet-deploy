%read in binary signal
%return numerical values
function [varargout] = binMsgDecode(binSignal)

    %everything in here is just an inverse of the binEncode function

    nBits = 8;
    packetSize = length(binSignal);
    binremBits = binSignal(packetSize-3:end);
    remBits = fix(binremBits*pow2(3:-1:0).');
    nArgs = nargout;

    buffSize = (packetSize - (nArgs*2*nBits) - remBits ) / (nArgs + 1);
    buffSize = floor(buffSize); % Added for debugging;

        for n = 1:nArgs

            binArg = fix(binSignal((n)*buffSize+1:(n)*(buffSize)+2*nBits)); %%%%%%%%%%%%
            varargout{n} = binArg*pow2(nBits-1:-1:-nBits).';

        end

end
