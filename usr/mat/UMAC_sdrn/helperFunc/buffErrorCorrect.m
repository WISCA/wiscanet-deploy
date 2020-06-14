function [rxBufferOut, buffErr] = buffErrorCorrect(rxBufferIn, truRxBufferSize)
%Buffer Error Correction
%   Function takes the rxBuff in, tests that it is of the proper size, and
%   returns the function. Previously, if some data was lost in
%   transmission, objects handling the rxBuff data would error the entire
%   system out. If some data was lost in transmission, this function
%   returns an rxBuff of the proper size in order to avoid error out.
%   However, the data has been corrupted and the feedback parameters should
%   be thrown out until the next cycle.
                                                 
                         [rxBuffSizeIn,~] = size(rxBufferIn);  
                         
                         if rxBuffSizeIn < truRxBufferSize
     
                              buffPadding = zeros(1,truRxBufferSize-rxBuffSizeIn).';
                              rxBufferOut = [buffPadding; rxBufferIn];
     
                              buffErr = 1; %buffer is short
                              
                              %if error occurs, generate new random message
                              %because we will not be able to demod the
                              %original
                              %if error occurs, initialize a new next in
                              %line receiver
                              
                              
                         else
                              rxBufferOut = rxBufferIn;
                              buffErr = 0; %no error
                         end
     

end

