function [estimate_doppler, estimate_speed, estimate_range] = ...
    radarRXPulseDopProc(rxWav, radarWav, fs, params)

    sampsCPI = params.pri*fs*params.cpiLen;
    sampsPerRPI = round(params.pri*fs);
            
    [xcAmp, ~] = xcorr(rxWav(1:sampsCPI),radarWav);

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%Initially wrote code to anchor the "starting" point of the signal to an arbitrary point in the waveform
	%based on the ideal sicWav. It turned out that the shift was ALWAYS 83 samples so I just hardcoded that in.
	%TBD what explicitly causes that delay.

   	xcAmp = circshift(xcAmp, -83); %%%%% Shifts each entry in waveform 83 indices
        
    compPulses = xcAmp(sampsCPI:end);
    
    compPulsesMtx = reshape(compPulses,sampsPerRPI,params.cpiLen);
    
    [~,fast_time_index_range_cell] = max(abs(compPulsesMtx(:,1)));
    
    range_doppler_bin = fftshift(fft(compPulsesMtx.'),1);
    
    freq_bin =-(0.5/params.pri)+(1/params.pri)/params.cpiLen:(1/params.pri)/params.cpiLen:(0.5/params.pri);
    
    [~,freq_bin_index] = max(abs((range_doppler_bin(:,fast_time_index_range_cell))));
    
    corse_doppler = freq_bin(freq_bin_index);
        
    doppler_resolution = params.prf/params.cpiLen;
        
    doppler_search_range = corse_doppler-2*doppler_resolution+1:0.01:corse_doppler+2*doppler_resolution;
    
    fine_doppler = zeros(1,length(doppler_search_range));
        
    for i=1:length(doppler_search_range)


        aliased_sinc=sin(pi*(doppler_search_range(i)/params.prf-(-params.cpiLen/2:params.cpiLen/2-1)/params.cpiLen)*params.cpiLen)./sin(pi*(doppler_search_range(i)/params.prf-(-params.cpiLen/2:params.cpiLen/2-1)/params.cpiLen));


        if(sum(isnan(aliased_sinc)))

            aliased_sinc(isnan(aliased_sinc))=params.cpiLen;

        end


        interpolating_kernel = 1/params.cpiLen*exp(-1i*pi*(doppler_search_range(i)/params.prf-(-params.cpiLen/2:params.cpiLen/2-1)/params.cpiLen)*(params.cpiLen-1)).*aliased_sinc;


        fine_doppler(i)=interpolating_kernel*range_doppler_bin(:,fast_time_index_range_cell);

    end

    [~,I] = max(fine_doppler);
    estimate_doppler = doppler_search_range(I)/2;
    estimate_speed = estimate_doppler * params.lambda;

    range_search_range = (fast_time_index_range_cell-1)*3e8/fs/2-50:0.01:(fast_time_index_range_cell-1)*3e8/fs/2+49;
        
    fine_range = zeros(1,length(range_search_range));
    for i=1:length(range_search_range)

        fine_range(i)=range_doppler_bin(freq_bin_index,:)*sinc((range_search_range(i)*2/3e8-(0:sampsPerRPI-1)/fs)*fs)';

    end
    [~,II] = max(fine_range);
    estimate_range = range_search_range(II);
    
end
