function outWav = commsRXSIC(txWav, rxWav)
%ALIGNWAVEFORM Summary of this function goes here
%   Detailed explanation goes here    

    nSamples = length(txWav);
    
    outWav = rxWav;
    
    %
    [xcamp, lags] = xcorr(txWav, rxWav);
    
    % Estimate time offset
    [maxlagidx, foundPeak] = peakEstimation(abs(xcamp), [], []);
    
    % Estimate phase offset
    phaseofst = angle(xcamp(maxlagidx));
    
    if foundPeak
    
        offset = lags(maxlagidx);
    
        txWav = exp(-1j*phaseofst)*circshift(txWav, [-offset 0]);
        
    else
        
        warning('No waveform detected to perform SIC. Returning original composite waveform.');
        
    end    
    
    wavSIC = doSIC(rxWav(1:nSamples), txWav);
    
    outWav(1:nSamples) = wavSIC;
        
end

function wavSIC = doSIC(wavRX, wavTX)
%DOSIC Summary of this function goes here
%   Detailed explanation goes here

    nTaps = 10;

    % Compute channel estimate
    h = lseChanEstimate(wavTX, wavRX, 0:nTaps-1);

    % Match power and remove signal from composite
    wavFilt = filter(h, 1, wavTX);

    % Subtract from composite
    wavSIC = wavRX - wavFilt; 

end