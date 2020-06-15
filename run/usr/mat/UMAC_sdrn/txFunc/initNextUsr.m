function [txWav] = initNextUsr(rxWav, nextUsrMsgLen, nextUsrDeviceId )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

initNextUsrBits = binMsgEncode(nextUsrMsgLen,nextUsrDeviceId)';

txWav = rxWav;
txWav(end-nextUsrMsgLen+1:end) = initNextUsrBits;

end

