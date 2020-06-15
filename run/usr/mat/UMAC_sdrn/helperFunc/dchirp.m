function y = dchirp(T,W,p)
%CHIRP  Stepped frequency chirp waveform generator. 
%   Y = DCHIRP(T,W,p) generates complex samples of a stepped-frequency
%   chirp signal, exp(j(W/T)pi*t^2)  -T/2 <= t <= T/2, with time support T, 
%   bandwidth W (Nyquist rate), and oversample rate, p. 
%
%   EXAMPLE 1: Compute the spectrogram of a linear chirp.
%     W  = 3e6;     % Sample frequency (Hz)
%     T  = 1e3;     % Chirp duration (samples)
%     p  = 2;       % Oversample rate
%     y  = dchirp(T/W, W/2, p);

% Number of samples
N=round(p*T*W);

% Index ramp
n=(0:1:N-1)';

%  
y= exp(1j*pi*(W/T)*((n/(p*W))-.5*T).^2);

