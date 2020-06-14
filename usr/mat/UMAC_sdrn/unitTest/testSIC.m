function testSIC()
    clc; close all;
    addpath(genpath('../'));

    % Load parameters and code book structure
    load('~/iCloud/Documents/Code/MATLAB/Projects/jointCommsRadar/sharedData/params18Apr2017.mat')
    load('/Users/xactscience/Data/SDR/JointCommsRadar/900MHz/04212017/rxCollectDataChirp_04212017_112231.mat')
    
    % Generate chirp waveform and null matrix 
    chirpWav = ...
        dchirp(params.chirpLen/usrpSettings.sample_rate, usrpSettings.sample_rate/2, 2).';
    
    nTaps = 50;
    procSyms = radarRXChirpProc(rxSyms(:,1), chirpWav);
    hChirp = chanEstimate( procSyms, chirpWav, nTaps, 0);
    hChirp = hChirp / max(hChirp);
    figure();
    plot(0:49, 10*log10(abs(hChirp)));
    grid on;
    hold on;

    load('~/iCloud/Documents/Code/MATLAB/Research/Papers/asilomar2017_jointcommsradar/compSIC.mat');
    procSyms = radarRXChirpProc(sicSyms(:,1), chirpWav);
    hSIC = chanEstimate( procSyms, chirpWav, nTaps, 0);
    hSIC = hSIC / max(hSIC);
    plot(0:49, 10*log10(abs(hSIC)));
    hold off;
    grid on;
    hSICPlot = gcf;
    genPlot(hSICPlot);
    print('~/Desktop/chanestimates', '-depsc');
    
end

function genPlot(hfig)

    opt.BoxDim = [5, 5]; %[width, height] (cm)
    opt.FontSize = 10;
    opt.XLabel = 'Delay (Samples)';
    opt.YLabel = 'Normalized Channel Power (dB)';
    opt.XTick = (0:9);
    opt.YTick = (-30:5:0);
    opt.LegendBox = 'on';
    opt.Legend = {'Radar Only', 'Joint System'}; % legends
    opt.LegendLoc = 'NorthEast';
    opt.AxisLineWidth = 1.0;
    opt.LineStyle = {'-', '-'}; % three line styles
    opt.Markers = {'^', 'o'};
    opt.LineWidth = 2;
%     opt.MarkerSpacing = 10;
    opt.XLim = [-0.5 9];
    opt.YLim = [-30 0];
    setPlotProp(opt, hfig);
    [legh,~,~,~] = legend;
    legh.FontSize = 10;
    set(gca,'LooseInset', get(gca,'TightInset'));

end

