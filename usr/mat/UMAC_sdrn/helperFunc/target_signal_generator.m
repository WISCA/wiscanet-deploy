function [ target_response,delayed_radar_waveform_with_doppler] = target_signal_generator( channel_matrix, radar_waveform,target_range,relative_velocity,...
    target_return_energy,pulse_repetition_interval,coherent_process_interval,sampling_frequency,carrier_wave_length )
%TARGET_SIGNAL_GENERATOR Summary of this function goes here
%   generate target response
%   channel_matrix: Rx by Tx
%   radar_waveform: Tx by p, p is the waveform samples length
%   sine_angle: look direction
%   velocity: target relative velocity on looking direction
%   target_response: Rx by p+t
[num_Rx,num_Tx]=size(channel_matrix);
radar_waveform_length=length(radar_waveform);
coherent_process_interval_length=length(coherent_process_interval);
delayed_sample_number=round(2*target_range/(3*10^8)*sampling_frequency);
total_sample_number_per_RPI=round(pulse_repetition_interval*sampling_frequency);
doppler_step=(1/pulse_repetition_interval)/num_Tx;

delayed_radar_waveform_with_doppler=repmat([zeros(num_Tx,delayed_sample_number),zeros(num_Tx,radar_waveform_length),zeros(num_Tx,total_sample_number_per_RPI-delayed_sample_number-radar_waveform_length)],1,coherent_process_interval_length);
doppler_frequency=2*relative_velocity/carrier_wave_length;
% doppler_response=exp(1i*2*pi*doppler_frequency*pulse_repetition_interval.*coherent_process_interval);
%                   exp(1i*2*pi*2*doppler_frequency*pulse_repetition_interval.*coherent_process_interval)
%                   exp(1i*2*pi*3*doppler_frequency*pulse_repetition_interval.*coherent_process_interval)
%                   exp(1i*2*pi*4*doppler_frequency*pulse_repetition_interval.*coherent_process_interval)
%                   exp(1i*2*pi*5*doppler_frequency*pulse_repetition_interval.*coherent_process_interval)];

for j=1:num_Tx
    for i=1:coherent_process_interval_length
        delayed_radar_waveform_with_doppler(j,(i-1)*total_sample_number_per_RPI+1+delayed_sample_number:(i-1)*total_sample_number_per_RPI+delayed_sample_number+radar_waveform_length)=radar_waveform;
%                  (exp(1i*2*pi*(j-1)*doppler_step*pulse_repetition_interval*coherent_process_interval(i))*doppler_response(i)).*radar_waveform;
    %             doppler_response(i).*radar_waveform;
        
    end
end
delayed_radar_waveform_with_doppler =delayed_radar_waveform_with_doppler .*exp(1i*2*pi*doppler_frequency*(0:coherent_process_interval_length*total_sample_number_per_RPI-1)/sampling_frequency);

% figure;
% plot(abs(delayed_radar_waveform_with_doppler(1,:)));
%
% radar_waveform2=1i*normrnd(0,sqrt(1/2),[1,round(total_sample_number_per_RPI*0.1)])+normrnd(0,sqrt(1/2),[1,round(total_sample_number_per_RPI*0.1)]);
% for j=1:num_Tx
%     for i=1:coherent_process_interval_length
%         delayed_radar_waveform_with_doppler2(j,(i-1)*total_sample_number_per_RPI+1+delayed_sample_number:(i-1)*total_sample_number_per_RPI+delayed_sample_number+radar_waveform_length)=...
%             (exp(1i*2*pi*(j-1)*doppler_step*pulse_repetition_interval*coherent_process_interval(i))*doppler_response(i)).*radar_waveform2;
%     end
% end
% target_response2=(1i*sqrt(target_return_energy/2)+sqrt(target_return_energy/2)).*channel_matrix*delayed_radar_waveform_with_doppler2;
% target_response=(1i*normrnd(0,sqrt(target_return_energy/2))+normrnd(0,sqrt(target_return_energy/2))).*channel_matrix*delayed_radar_waveform_with_doppler;
target_response=sqrt(target_return_energy/2).*channel_matrix*delayed_radar_waveform_with_doppler+1/sqrt(2)*randn(size(delayed_radar_waveform_with_doppler))+1i/sqrt(2)*randn(size(delayed_radar_waveform_with_doppler));


end

