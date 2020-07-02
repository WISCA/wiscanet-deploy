function  [s_hat, w] = mmseEqualizer(msgSyms, trnSyms, rxTrn, eqLen, eqDelay)
% Inputs:
%        msgSyms: Received Message Symbols
%        trnSyms: Transmitted Training Symbols
%        rxTrn: Received Training Symbols
%        eqLen: # of equalizer taps (filter length)
%        eqDelay: Expected channel & equalizer delay
% Outputs:
%        w: Equalizer coefficients
%        s_hat: Equalized signal
R = toeplitz([rxTrn(1) zeros(1,eqLen-1)],rxTrn);

Sd = [zeros(1,eqDelay),trnSyms(1:end-eqDelay).'];

epsilon_load = 10e-6;

% Equalizer coefficients (Weiner filter)
w = (Sd*R')*inv(R*R' + epsilon_load^2*eye(eqLen,eqLen));
%w = (Sd*R')*inv(R*R');

% Filter received message symbols
s_hat = filter(w,1,msgSyms);
end