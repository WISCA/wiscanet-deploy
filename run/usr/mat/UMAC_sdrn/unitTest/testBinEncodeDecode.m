%5.23.2017 Edits adds ability to use variable number of arguments of
%different data types. Adds ability to dictate the length of the encoded
%data.

function testBinEncodeDecode()

    %test encode / decode functions

    %encode - converts decimal values for TxGain and SpVal into binary sequences for
    %transmission over a channel6807
    %decode - converts binary representations for TxGain and SpVal into their
    %decimal values
    
    %set the desired packet size. it can be anything as long as it is
    %larger than 16*(number of arguments passing through function)
    pckSize = 888;
    %the transmitter gain takes a value -1:1 (float)
    TxGain = -0.34953;
    %the spread value takes a value 1:30 (integer)
    SpVal = -14.000;
    %other values of interest
    TestVal1 = 12.21;
    TestVal2 = 0.8125;
    
    %call encode / decode functions
    %if there are an inconsistent amount of arguments between the
    %two functions, it will not return any of the values properly
    [encSig] = binEncode(pckSize, TxGain, SpVal, TestVal1, TestVal2);
    [decTxGain, decSpVal, decTestVal1, decTestVal2] = binDecode(encSig);
        
    %print values of interest - this is just proof of concept
    fprintf('Sent Argument 1: %i \nReceived Argument 1: %i\n\n',TxGain,decTxGain)
    fprintf('Sent Argument 2: %i \nReceived Argument 2: %i\n\n',SpVal,decSpVal)
    fprintf('Sent Argument 3: %i \nReceived Argument 3: %i\n\n',TestVal1,decTestVal1)
    fprintf('Sent Argument 4: %i \nReceived Argument 4: %i\n\n',TestVal2,decTestVal2)

end


%read in the desired size of the packet in bits
%read in the variable numerical arguments for conversion to binary
%convert to binary sequence for feedback transmittance 
%the first argument is always the desired packet size. Subsequent arguments
%can be in any order, no matter the class type.
function [binSignal] = binEncode(packetSize, varargin)

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


%read in binary signal 
%return numerical values
function [varargout] = binDecode(binSignal)

    %everything in here is just an inverse of the binEncode function

    nBits = 8;
    packetSize = length(binSignal);
    binremBits = binSignal(packetSize-3:end);
    remBits = binremBits*pow2(3:-1:0).';
    nArgs = nargout;
    
    buffSize = (packetSize - (nArgs*2*nBits) - remBits ) / (nArgs + 1);

        for n = 1:nArgs

            binArg = binSignal((n)*buffSize+1:(n)*(buffSize)+2*nBits);
            varargout{n} = binArg*pow2(nBits-1:-1:-nBits).';
            
        end
        
  end

