function f = getFFT(window,fs)
%getFFT gets FFT of window
% 

samples = length(window);  % samples in a window


NFFT=2^(2+nextpow2(samples));%padding+computation speed

windHann = hanning(length(window))';
x_w = windHann.*window;
f = fft(x_w,NFFT)/fs;
f=abs(f(1+(0:NFFT/2))); %only the first half 
end

