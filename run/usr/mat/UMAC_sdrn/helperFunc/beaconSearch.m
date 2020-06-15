function [estimates, caf, hN, foundbeacon] = ...
    beaconSearch(data, seq, maxlags, lag_range, fs, showplot)

    % Processing window length
    winlen = length(data);

    % Zeropad length
    zpad = ceil(winlen/maxlags)*maxlags - winlen; 

    % Calculate cross ambiguity function
    [hN, caf, lags, frac_freqs] = calcXamb(...
        [data; zeros(zpad, 1)], [seq; zeros(zpad, 1)], maxlags, lag_range);
    
    % Detect global peak of caf surface
    [delayEst, freqEst, peakVal, foundbeacon] = cafPeakEst(...
        abs(caf), lags, frac_freqs, [], []);

    % Remove bulk offset from impulse response
%     hN = circshift(hN, -delayEst, 1);

    % 
    if showplot
                
        if foundbeacon
            
            peakidx = find(lags==delayEst);
            pltidxs = peakidx-25:peakidx+25;
            
            pcolorPlot(db(caf(pltidxs,:)), lags(pltidxs)*(1e6/fs), frac_freqs*fs, 'Frequency (Hz)', ...
             'Delay (x10^{-6} s)', [-30 max(db(caf(:)))]);
            pause(0.5);
        
        else
            
            pcolorPlot(db(caf), lags*(1e6/fs), frac_freqs*fs, 'Frequency (Hz)', ...
                'Delay (x10^{-6} s)', [-30 max(db(caf(:)))]);
            pause(0.5);
            
        end
        
    end

    % Return output structure
    estimates = [delayEst, freqEst, db(peakVal)];

end

function [impresp, caf, lags, frac_freqs] = calcXamb(...
    sig1, sig2, max_lags, lag_range)
% Computes the scattering function (downsampled CAF) of a channel given the
% transmitted and received signals
%
% Inputs
% -------
%   sig1 - Received or Transmitted sequence samples 
%
%   sig2 - Received or Transmitted sequence samples
%
%   max_lags - Number of lags (in samples) to compute caf and impulse
%   response (N)
%
%   lag_range - Range (samples) to trim the lags to in CAF and impulse
%   response (M)
%
% Outputs
% -------
%   impresp - Impulse response matrix of the channel
% 
%   caf - The scattering function (CAF) surface
%
%   lags - lag values in samples
%
%   frac_freqs - Fractional frequency values of the CAF surface
%
% NOTES:
% =======
%   * sig1 and sig2 must be of equal length and 
%     floor(max_lags/length(sig1))=0
%  

    % Window coefficients to apply when computing scattering function
    win = blackman(2*max_lags + 1);   % Use blackman-harris 

    % Shape sequences into signal matrix whose rows contain max_lags 
    % samples
    sig1_block = reshape(sig1, max_lags, []);
    sig2_block = reshape(sig2, max_lags, []);
    
    % Derived variables
    [~, num_proc_cols] = size(sig1_block);
    
    % Memory allocation
    hN = zeros(2*max_lags + 1, num_proc_cols);
    
    % Compute correlation down the columns of matrix to form a lag x
    % deltaTime matrix
    for k = 1:num_proc_cols
        [hN(:,k), ~] = xcorr(...
            sig1_block(:,k), sig2_block(:,k), max_lags, 'biased');
    end
        
    % Apply window and select positive and negative lags to keep 
    lags = -lag_range:lag_range;
    hN   = bsxfun(@times, hN, win);
    zlag = max_lags + 1;    % index of zero lag
   
    % Select and return values we want
    impresp = hN(zlag-lag_range:zlag+lag_range, :);
        
    % Compute scattering function (downsampled CAF) surface by computing 
    % the fft across columns (deltaTime variable) of channel impulse 
    % response matrix
    caf = fftshift(fft( impresp , [], 2), 2);
    
    % FFT bin resolution is fs/(max_lags*nFFT) since we are computing 
    % fft across columns of hN
    frac_freqs = (1/max_lags)*linspace(-0.5, 0.5, num_proc_cols);
  
end

function pcolorPlot(surface, yvals, xvals, labelx, labely, climits)
    
    % Use pseudocolor plot
    pcolor(xvals, yvals, surface);
    colorbar;
    shading(gca, 'flat');
    caxis(climits);
    xlabel(labelx);
    ylabel(labely);
    drawnow;

end
