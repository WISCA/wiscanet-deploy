function testPulseDoppler()
    clc; close all;
    addpath(genpath('../'));

    % Load parameters and code book structure
    paramsDir = '../paramsFiles';
    paramsFile = 'params31May2017.mat';
    load(fullfile(paramsDir,paramsFile));
    
    %
    fs = commsParams.sampFreq;
    
    %
    chirpLen   = radarParams.chirpLen;
    chirpGain  = radarParams.chirpGain;           % Chirp gain
    pri        = radarParams.pri;
    lambda     = radarParams.lambda;
    pwp        = radarParams.pwp;
    cpiLen     = radarParams.cpiLen; 
    rangeBinWidth = radarParams.c/fs;
    
    tgtRange   = targetParams.range;
    tgtVel     = targetParams.velocity;
    tgtEnergy  = targetParams.returnEnergy;
    tgtRespLen = round(chirpLen/pwp)*cpiLen;
    
    cpi = (1:100)';
    
    % Generate radar waveform
    radarWav = dchirp(chirpLen/fs, fs, 1);

    % Generate target response
    [~,targetResponse]= target_signal_generator(...
        1, radarWav, tgtRange, ...
        tgtVel, 10^(tgtEnergy/10), pri, ...
        cpi, fs, lambda);
    
    [crsDoppEst, crsRangeEst] = radarRXChirpProc(...
        targetResponse.', radarWav, fs, radarParams);
    
    velEst = dop2speed(crsDoppEst,lambda)
    
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

