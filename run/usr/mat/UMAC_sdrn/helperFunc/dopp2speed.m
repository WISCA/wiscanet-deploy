function [speed] = dopp2speed(doppler_shift, fc)
    
    c = 299792548;
    lambda = c / fc;
    
    speed = lambda * doppler_shift;
   
end