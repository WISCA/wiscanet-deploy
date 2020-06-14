function [rxCompSyms, decodeBits, sicSyms] = analysisGenFigures()
    clc; close all;

    setupPaths();

    % Load parameters and code book structure
    load('~/iCloud/Documents/Code/MATLAB/Projects/jointCommsRadar/sharedData/params18Apr2017.mat')

    % Initialize received signal matrix
    rxSyms = zeros(usrpSettings.buff_samps, params.nPackets);
    
    genFigures(sicSyms(:,1), rxSyms(50e3:145e3,1));
    


end

function genFigures(sicWav, recWav)

    figure();
    subplot(2,2,1);
    plot(abs([zeros(10e3,1); recWav]).^2);
    ylim([0 0.04]);
    grid on;
    xlabel('Samples')
    ylabel('Power (Linear)')
    title('Composite Power')
    
    subplot(2,2,2);
    plot(abs([zeros(10e3,1); sicWav]).^2);
    ylim([0 0.04]);
    grid on;
    xlabel('Samples')
    ylabel('Power (Linear)')
    title('Composite Power after SIC')
    
    subplot(2,2,3);
    spectrogram(recWav(1:300), [], [], [], 10e6, 'center', 'yaxis');
    caxis([-100 -70]);
    title('Spectrogram of Composite waveform');
        
    subplot(2,2,4);
    spectrogram(sicWav(1:300), [], [], [], 10e6, 'center', 'yaxis');
    caxis([-100 -70]);
    title('Spectrogram of SIC waveform');  
    
    % Extract axes handles of all subplots from the figure
%     axesHandles = findobj(get(gcf,'Children'), 'flat','Type','axes');
% 
%     % Set the axis property to square
%     axis(axesHandles,'square');
  
end


