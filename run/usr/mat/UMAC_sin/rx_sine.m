function rx_sine(sys_start_time)

close all;
addpath(genpath('../lib'));

usrp_address='type=b200';
type = 'double';            %type
ant  = 'TX/RX';             %ant
subdev = 'A:B';             %subdev
ref = 'gpsdo';              %ref
wirefmt = 'sc16';           %wirefmt
freq    = 5.8e9;            %freq
rx_gain = 60;               %rx_gain
tx_gain = 80;               %tx_gain
bw      = 20e6;             %bw
setup_time = 0.1;           %setup_time
num_samps = 50000;
sample_rate = 10e6;

usrpRadio = local_usrp;

usrpRadio = usrpRadio.set_usrp(type, ant, subdev, ref, wirefmt, num_samps,...
    sample_rate, freq, rx_gain, tx_gain, bw, setup_time);

cycle_number = 5;
start_time = sys_start_time;
numChans = 2;

% Receive a carrier every 3 seconds
rxdat = [];
for i = 1:cycle_number
    rx_buff = usrpRadio.rx_usrp(start_time,numChans);
    rxdat = [rxdat; rx_buff];
    start_time = start_time + 10;
end
fprintf('-- Dump log: RxDat\n');
save('RxDat.mat');

usrpRadio.terminate_usrp();

end