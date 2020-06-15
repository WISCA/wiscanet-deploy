function [crsDoppEst, crsRangeEst] = radarRXChirpProc(rxWav, radarWav, fs, params)

    sampsPerCPI = round(params.pri*fs*params.cpiLen);
    
    [~, caf, lags, fracFreqs] = pulseDoppProc(...
        rxWav(1:sampsPerCPI), radarWav, params.cpiLen);

    % Estimate time offset
    [rangeIdx, freqIdx, ~, foundPeak] = cafPeakEstimate(...
        abs(caf), [], false);
    
    crsDoppEst  = fracFreqs(freqIdx)*fs;
    crsRangeEst = lags(rangeIdx);
    
    
    
end

function [impresp, caf, lags, frac_freqs] = pulseDoppProc(...
    rxWav, radarWav, cpiLen)
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

    % Shape sequence into matrix whose rows contain raw data 
    % and columns represent pulses
    pulseMtx = reshape(rxWav, [], cpiLen);
    
    % Number of samples per pulse
    [nSamps, ~] = size(pulseMtx);
    
    % Fix lagRange to nSamps (this can be modified to be smaller
    lagRange = nSamps;

    % Window coefficients to apply when computing scattering function
    win = ones(2*nSamps+1,1);   % Use blackman-harris      
     
    % Memory allocation
    hN = zeros(2*nSamps+1, cpiLen);
    
    % Compute correlation down the columns of matrix to form range x
    % pulse map (matched filtering)
    for k = 1:cpiLen
        [hN(:,k), ~] = xcorr(...
            pulseMtx(:,k), radarWav, nSamps);
    end
        
    % Apply window and select positive and negative lags to keep 
    lags = -lagRange:lagRange;
    hN   = bsxfun(@times, hN, win);
    zlag = nSamps+1;    % index of zero lag
   
    % Select and return values specified by lagRange
    impresp = hN(zlag-lagRange:zlag+lagRange,:)/lagRange;
        
    % Compute range doppler map by computing fft across columns (slow-time)
    % of range-pulse map
    caf = fftshift(fft(impresp, [], 2), 2);
    
    % FFT bin resolution is fs/(max_lags*nFFT) since we are computing 
    % fft across columns of hN
    frac_freqs = (1/nSamps)*linspace(-0.5, 0.5, cpiLen);
  
end

function fineEstimate(crsDopp,crsRange,params)

    dopRes = params.prf/params.cpiLen;

    dopSrchRng = crsDopp-2*dopRes+1:0.01:crsDopp+2*dopRes;
    
    fineDop = zeros(1,length(dopSrchRng));
        
    for i=1:length(dopSrchRng)


        sincInterp=sin(pi*(dopSrchRng(i)/params.prf-(-params.cpiLen/2:params.cpiLen/2-1)/params.cpiLen)*params.cpiLen)./sin(pi*(dopSrchRng(i)/params.prf-(-params.cpiLen/2:params.cpiLen/2-1)/params.cpiLen));


        if(sum(isnan(sincInterp)))

            sincInterp(isnan(sincInterp))=params.cpiLen;

        end


        interpolating_kernel = 1/params.cpiLen*exp(-1i*pi*(dopSrchRng(i)/params.prf-(-params.cpiLen/2:params.cpiLen/2-1)/params.cpiLen)*(params.cpiLen-1)).*sincInterp;


        fineDop(i)=interpolating_kernel*range_doppler_bin(:,fast_time_index_range_cell);

    end

    [~,I] = max(fineDop);
    estimate_doppler = dopSrchRng(I)/2;
    
    range_search_range = (fast_time_index_range_cell-1)*3e8/fs/2-50:0.01:(fast_time_index_range_cell-1)*3e8/fs/2+49;
        
    fine_range = zeros(1,length(range_search_range));
    for i=1:length(range_search_range)

        fine_range(i)=range_doppler_bin(freq_bin_index,:)*sinc((range_search_range(i)*2/3e8-(0:sampsPerRPI-1)/fs)*fs)';

    end
    [~,II] = max(fine_range);
    estimate_range = range_search_range(II);

end