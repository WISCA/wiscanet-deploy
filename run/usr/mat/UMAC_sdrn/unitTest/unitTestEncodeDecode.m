function unitTestEncodeDecode()

    %test encode / decode functions

    %encode - converts decimal values for TxGain and SpVal into binary sequences for
    %transmission over a channel
    %decode - converts binary representations for TxGain and SpVal into their
    %decimal values

    %the transmitter gain takes a value -1:1 (float)
    TxGain = -0.349680753;
    %the spread value takes a value 1:30 (integer)
    SpVal = 14.000;
    
    %call encode / decode functions
    [encSig] = TxSpencode(TxGain, SpVal);
    [decTxGain, decSpVal] = TxSpdecode(encSig);
    
    %print values of interest
    fprintf('TxGain = %i \ndecTxGain = %i \n',TxGain,decTxGain)
    fprintf('SpVal = %i \ndecSpVal = %i \n',decSpVal,decSpVal)
    
end

%create two functions to encode two numerical values into one binary
%signal for transmittance over a channel. Subsequently decode the signal at
%a receiver to obtain the transmitted values.

%read in numerical values for transmitter gain and spread value
%convert to binary sequence for feedback transmittance 
function [EncodedSignal] = TxSpencode(TransmitterGain, SpreadValue)

    buffLen = 37;

    buffer = randi([0 1], 3, buffLen);

    %bit resolution for each TxGain and SpVal
    nBits = 8;               

    %test for sign of TxGain (1 = positive, 0 = negative)
    isPositive = ((sign(TransmitterGain)+1)/2);
    %convert TxGain to binary sequence
    binTxGain = abs(fix(rem(TransmitterGain*pow2((1):nBits),2)));

    %convert SpVal to binary sequence (standard binary)
    binSpVal = abs(fix(rem(SpreadValue*pow2((1-nBits):0),2)));

    %concatenate signals to create 16 word packet containing
    %buff(1:37) Sign(38) Gain(39:46) buff(47:83) SpVal(84:91) buff(91:128)
    EncodedSignal = ...
        [buffer(1,:) isPositive binTxGain buffer(2,:) binSpVal buffer(3,:)];

end


%read in encoded signal representing transmitter gain and spread value
%convert back to numerical values
%not very robust
function [decTxGain, decSpVal] = TxSpdecode(EncodedSignal)

    buffLen = 37;
    
    %bit resolution for each TxGain and SpVal
    nBits = 8;
    
    %index binary sequences from signal as function of buffer and nBits
    isPositive = EncodedSignal(buffLen+1);
    binTxGain = EncodedSignal(buffLen+2:buffLen+2+nBits-1); 
    binSpVal = EncodedSignal(2*buffLen+2+nBits:2*buffLen+2+2*nBits-1);
    
    %convert binary sequences into their decimal representations
    decSpVal = binSpVal*pow2(nBits-1:-1:0).';
    decTxGain = (binTxGain*pow2(-1:-1:-nBits).')*(2*isPositive-1)  

end



