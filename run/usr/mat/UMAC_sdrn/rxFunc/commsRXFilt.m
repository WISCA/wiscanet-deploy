function rxFiltSyms = commsRXFilt(rxSyms, hFreqComp, hRXFilt)

    % Coarse frequency compensation
    %coarseCompSyms = step(hFreqComp, rxSyms);

    % Pass signal through RX Filter
    rxFiltSyms = step(hRXFilt, rxSyms);

end

