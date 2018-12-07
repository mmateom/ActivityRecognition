function [f,NFFT,f_grid] = getFFT(window,fs)
%getFFT gets FFT of window
% 
% by Mikel Mateo - University of Twente - October 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna

samples = length(window);  % samples in a window

%t = 1:1/fs:samples;

%NFFT=2^(2+nextpow2(samples));%padding+computation speed
NFFT = 2^11;
windHann = hanning(length(window))';
x_w = windHann.*window;
f = fft(x_w,NFFT)/fs;
f=abs(f(1+(0:NFFT/2))); %only the first half 

f_grid = (0:NFFT/2)/NFFT*fs;
end

