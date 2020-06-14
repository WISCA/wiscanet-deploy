function objDemod = initCommsRXDemod(modOrder)

    % Create demodulator object
    objDemod = comm.PSKDemodulator('ModulationOrder', modOrder,...
            'PhaseOffset',0,'BitOutput',true,'DecisionMethod',...
            'Approximate log-likelihood ratio','VarianceSource',...
            'Input port');

end

