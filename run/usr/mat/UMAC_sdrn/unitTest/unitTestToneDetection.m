function unitTestToneDetection()

fs = 10e6;
N  = 20e3;
f  = 1e6;

tone1MHz = exp(2j*pi*(f/fs)*(0:N-1));


[freq, foundFlag] = toneDetect(tone1MHz, f, fs);



end

function [freq, foundTone] = toneDetect(wav, toneHz, fs)

    foundTone = false;

    N = length(wav);

    % 
    f = fs * linspace(-0.5, 0.5, N);
    
    % Indexes to restrict search for tone
    lowFreqHz  = toneHz - 10e3;
    hiFreqHz   = toneHz + 10e3;
    
    %
    specRange = find(lowFreqHz < f & f < hiFreqHz);
    
    % Compute spectrum
    spec = abs(fftshift(goertzel(wav,specRange)));
    
    % 
    spec = spec / max(spec);
    
    [pks, locs, ~, ~] = findpeaks(...
        spec, f(specRange), 'MinPeakProminence', 0.5);
    
   
    if length(locs) > 1
        
        [~, maxIdx] = max(pks);
        
        freq = locs(maxIdx);
        
        foundTone = true;
        
    else
        
        foundTone = true;
        
        freq = locs;
    end
    
    
    
end