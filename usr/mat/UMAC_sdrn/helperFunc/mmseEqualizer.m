function  [s_hat, g] = mmseEqualizer(x, xtrn, s, Kg, d)
%Input:  x: Output of channel to a (training) data sequence a
%        s: Message data, Kg=# of equalizer taps
%        d: Expected channel & equalizer delay 
%Output: 
%        g: Equalizer coefficients
% L = length(x); 
% phi_x = xcorr(x, 'unbiased'); 
% phi_sx = xcorr(s, x, 'unbiased');   
% Rxx = zeros(Kg,Kg);
% rsx = zeros(Kg,1);
% d = 0;
% for i=1:Kg
%    Rxx(i,:) = phi_x(L-i+1:L-i+Kg);    % Eq.(6.2.10)
%    rsx(i) = phi_sx(L+i-1-d);          % Eq.(6.2.11)
% end

    % Compute Autocovariance estimate 
    tmp = xcorr(xtrn, Kg);
    Rxx = toeplitz(tmp(Kg+1:end-1));

    % Compute cross-covariance vector
    tmp = circshift(xcorr(s, xtrn, Kg), [-d 0]);
    rsx = tmp(Kg+1:end-1);

    % Equalizer coefficients (Weiner filter)
    g = Rxx\rsx;

    % Output equalized signal
    s_hat = filter(g, 1, x);
    
end