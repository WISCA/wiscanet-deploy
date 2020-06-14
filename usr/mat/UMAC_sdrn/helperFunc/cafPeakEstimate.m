function [delayIdx, freqIdx, peak, foundPeak] = ...
    cafPeakEstimate(M,SNR_dB,verbose)

    % Define the Pfa to give one false alarm per day at 960 kcps
    pFA = 3e-12;
    
    % Define the similarity threshold between the chosen value and the
    %   value for frequency offsets on either side of the chosen tap.
    simThresh = 0.75;

    if ~exist('SNR_dB', 'var')
        SNR_dB = [];
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = 0;
    end
    
    if isempty(SNR_dB)
        % delay - rows
        % doppler - columns
        sigma = sqrt( var(M(:)) / ((4-pi)/2) );
        peak = max(M(:));
        
        
       % Assuming amplitude is Rayleigh distributed, the probability that 
       % the amplitude exceeds some level
        pFACaLc = exp( -peak^2 / (2*sigma^2) );
    
        wasDetected = pFACaLc < pFA;
        
    else
        
        % Calculate the detection threshold
        No = 10^(-SNR_dB/10);
        detectionThreshold = -log(pFA)*No*Lseq;

        % Add in a fudge factor
        detectionThreshold = max(sqrt(detectionThreshold)/Lseq, 0.3);
        
        % Test if the peak is above the threshold
        wasDetected = max(M(:)) > detectionThreshold;
        
    end
    
    if wasDetected
        
        foundPeak = true;
        
        % Get row and column index of global maximum
        [delayIdx, freqIdx] = find(ismember(M, peak));
            
        if verbose
            fprintf('CAF detection! max = %f\n', max(M(:)));
        end
                              
    else
        
        display('       No Peak Found!');
        foundPeak = false;
        delayIdx = NaN;
        freqIdx = NaN;
        peak = NaN;
        
    end
        
end