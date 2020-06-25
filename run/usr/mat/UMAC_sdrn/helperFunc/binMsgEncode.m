function [binSignal] = binMsgEncode(packetSize, varargin)

%caluclate number of arguments
nArgs = length(varargin);

    if packetSize < nArgs*16

        fprintf('error:\n the packet size must be large enough to contain %i 16bit values\n',nArgs)
        return

    else

        %bit resolution for each fraction and decimal part of each argument
        %each argument will require 2*nBits bits (they are all coded as floats,
        %even if they have no fractional value. The first 8 bits represent the decimal
        %part of the number, the last 8 bits represent the fractional part.
        %[d d d d d d d d f f f f f f f f]
        nBits = 8;

        %calculates the necessary size of each fluffer to ensure proper
        %indexing. remBits ensures that buffSize is a whole number
        remBits = rem((packetSize - (nArgs*2*nBits)) , ( nArgs + 1));
        binremBits = fix(rem(remBits*pow2(-3:0),2));
        buffSize = (packetSize - (nArgs*2*nBits) - remBits ) / (nArgs + 1);

        %initialize the binary signal as a column vector of random binary values
        binSignal = randi([0 1],1,packetSize);

            %for loop fills in binSignal with the binary representations for each
            %argument. Equal sized buffers calcluated above seperate each piece of data
            for n = 1:nArgs

                binArg = fix(rem(varargin{n}*pow2(-(nBits-1):nBits),2));
                binSignal((n)*buffSize+1:(n)*(buffSize)+2*nBits) = binArg;

            end

        %last 4 bits of the packet are the binary of remBits so that binDecode
        %can figure out the buffer size without have to explicitly pass
        %that information into the function
        binSignal(packetSize-3:end) = binremBits;

    end
end
