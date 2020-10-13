load('RxDat');
figure; grid on;
subplot(2,1,1);
plot(real(cRxDat));
title("Real part of RX Signal");
subplot(2,1,2);
plot(imag(cRxDat));
title("Imaginary part of RX Signal");
figure(2);
pwelch(cRxDat,[],[],[],sample_rate,'centered')
