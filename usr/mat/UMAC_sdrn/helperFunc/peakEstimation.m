function [max_idx, found_peak, peak] = peakEstimation(...
    xcorrvec, SNR_dB, verbose)

    % Define the Pfa to give one false alarm per day at 960 kcps
    pfa = 3e-3;
    
    % Initialize outputs
    found_peak = false;
    max_idx = NaN;
    
    if ~exist('SNR_dB', 'var')
        
        SNR_dB = [];
        
    end
    
    if ~exist('verbose', 'var') || isempty(verbose)
        
        verbose = 0;
        
    end
    
    if isempty(SNR_dB)
        
        sigma = sqrt( var(xcorrvec) / ((4 - pi) / 2) );
        
        [peak, max_idx] = max(xcorrvec);

        pfacalc = exp( -peak^2 / (2 * sigma^2) );
    
        wasdetected = pfacalc < pfa;
        
    else
        
        Lseq = length(xcorrvec);
        
        % Calculate the detection threshold
        No = 10^(-SNR_dB / 10);
        
        detectthreshold = -log(pfa) * No * Lseq;

        % Add in a fudge factor
        detectthreshold = max(sqrt(detectthreshold) / Lseq, 0.3);
        
        % Test if the peak is above the threshold
        wasdetected = max(xcorrvec) > detectthreshold;
        
    end
    
    if wasdetected
        
        found_peak = true;
        
    else
        
%        warning('No peak found.');  
       
       % Set max_idx to initial sample in sequence
       max_idx = ceil(length(xcorrvec)/2);

    end
        
end
