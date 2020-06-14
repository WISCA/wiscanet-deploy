function rxFiltSyms = commsRXFilt(rxSyms, hFreqEst, hFreqComp, hRXFilt)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    %disp(length(rxSyms));
    % Coarse frequency offset estimation 
    freqOffsetEst = step(hFreqEst, rxSyms);
         
    % Coarse frequency compensation
    coarseCompSyms = step(hFreqComp, rxSyms, -freqOffsetEst);
    
    % Pass signal through RX Filter
    rxFiltSyms = step(hRXFilt, coarseCompSyms);

end

