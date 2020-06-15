function [ output_args ] = unitTestGenBPSKWav()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    qpskGain = 0.7;
    spreadVal = 20;
    
    % Initialize BPSK modulator (for tuning TX gain)
    [bpskMod, txFilter] = initCommsTXMod(2, 2);
    
    

    % 
    bpskWav = genBPSKWaveform(...
                0, qpskGain, spreadVal, bpskMod, txFilter);
    
end

