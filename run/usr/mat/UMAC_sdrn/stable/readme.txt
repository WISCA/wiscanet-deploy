README

note* the working directory should have the latest iteration of stable code loaded onto it unless otherwise specified

usrpFunc_07312017:
stable version of JRC system running 1 comms user (usrp3 or usrp10) 1 radar chirp (usrp9) and 1 receiver (usrp4)
uses setParams that only creates one codebook for 1 user, not optimized for new setParams that creates a cell array for each user





usrpFunc_08072017:
runs all radios with the two comms sending identical messages. last step before implementing dual reception at the receiver.
usrpQPSKTx.m and usrpQPSKTxN.m are instaled on each of the two comms radios. The only difference between them is that they each pull different codebooks from the params files. 




