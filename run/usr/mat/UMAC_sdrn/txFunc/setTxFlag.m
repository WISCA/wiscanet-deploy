function [flag, nextUsr] = setTxFlag(lId, usrId, nUsrs)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if lId == usrId
   
    rng('shuffle');
    flag = true;
    
    while usrId == lId
        usrId = randi([1 nUsrs]);
    end
    
    nextUsr = usrId;
    
else
    
   flag = false;
   nextUsr = 0;
    
end

end

