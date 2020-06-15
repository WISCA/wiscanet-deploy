function sicSyms = commsRXSimpleSIC(txHatWav, rxWav)

    % Align signals
    alignWav = alignWaveform(rxWav, txHatWav);

    % Perform SIC
    sicSyms = doSIC(alignWav, txHatWav);

end

function sicSyms = doSIC(wavRX, wavComp)

    % Match power and remove signal from composite
    xc = xcorr(wavComp, wavRX, 50);
    maxChanPwr = max(xc);
    wavComp = wavComp/maxChanPwr;
    wavComp = wavComp*(sqrt(wavRX'*wavRX)/sqrt(wavComp'*wavComp));
    
    sicSyms = wavRX - wavComp; 

end

function outSig = alignWaveform(rxWav, txWav)
    

    nSamples = length(txWav);
    
    %
    [xcamp, lags] = xcorr(txWav, rxWav);
    
    % Estimate time offset
    [maxlagidx, foundPeak] = peakEstimation(abs(xcamp), [], []);
    
    if foundPeak
    
        offset = lags(maxlagidx);
    
        if offset < 0
            
            rxWav = circshift(rxWav, [offset 0]);
            outSig = rxWav(1:nSamples);
        
        else
    
            outSig = rxWav(offset + (1:nSamples));
        
        end

    else
        
        warning('No waveform detected to perform SIC. Returning zero vector.');
        outSig = zeros(nSamples,1);
        
    end       
        
end
