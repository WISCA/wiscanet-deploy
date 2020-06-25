function [rxMsgSyms, rxTrnSyms, rxNzeSyms] = ...
    commsRXSync(rxSyms, trnSyms, modPktSize, params)

    % Upsample training sequence
    trnSyms = upsample(trnSyms, params.upsampFactor);

    % Time Phase Sync
    [rxMsgSyms, rxTrnSyms, rxNzeSyms] = timePhaseSynchronization(...
        rxSyms, trnSyms, params.nNzeSyms, modPktSize);

end

function [msgSyms, trnSyms, nzeSyms] = timePhaseSynchronization(...
    in_syms, trn_syms, nNzeSyms, modPktSize)

    nTrnSyms = length(trn_syms);

    % Correlate input symbols and training symbols
    [xcorrsyms, lags] = xcorr(in_syms, trn_syms);

    % Estimate time offset
    [maxlagidx, foundPeak] = peakEstimation(abs(xcorrsyms), [], []);
    if (maxlagidx>100000)
        fprintf("Max Lag Index: %d\n", maxlagidx);
        error('Invalid Lag Index, SNR possibly too low, lots of interference...');
    end
    if (foundPeak) % Changed to debug should be only foundPeak
        fprintf("Sync Peak found at: %d\n", maxlagidx);

        % Time offset estimate
        toffset = lags(maxlagidx);

        msgSyms = in_syms(toffset + nTrnSyms + (1:modPktSize));
        trnSyms = in_syms(toffset + (1:nTrnSyms));
        nzeSyms = in_syms(1:toffset);

        % Estimated phase offset
        phaseofst = angle(xcorrsyms(maxlagidx));

        % Apply estimated phase offset and time correction to input symbols
        msgSyms = exp(-1j*phaseofst)*msgSyms;

    else
        error('Unable to acquire signal. No waveform detected or PFA value set too small.');
    end
end
