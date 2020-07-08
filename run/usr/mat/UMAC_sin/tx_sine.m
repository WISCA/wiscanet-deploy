function err = tx_sine(sys_start_time)

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

fc = 0.1e6;
fc2 = 0.75e6;
t=0:1/sample_rate:(1/sample_rate*(num_samps - 1));
sine = exp(1i*2*pi*fc*t).';
sine2 = exp(1i*2*pi*fc2*t).';
numChans = 2;
sineChan = [sine sine2];

cycle_number=5;
start_time = sys_start_time;

%Send out a carrier every 3 seconds
for i = 1:cycle_number
    usrpRadio.tx_usrp(start_time,sineChan,numChans);
    start_time = start_time + 10;
end

usrpRadio.terminate_usrp();

end