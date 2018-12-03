function [domFreqs,domFreqsAmp] = getDominantFreqs(windowFFT,freqs,NFFT,fs)
%dominantFreqs Computes 1st and 2nd dominant frequencies
%   INPUT
%       windowFFT:  FFT of window
%       freqs:      number of dominant frequencies wanted
%   OUTPUT
%       domFreqs:       dominant frequencies
%       domFreqsAmp:    amplitude of each dominant frequency

NFFT = 2^11;
%f_grid = (linspace(0,NFFT/2,length(windowFFT))/NFFT*fs)';
f_grid = (0:NFFT/2)/NFFT*fs;

[pks,locs] = findpeaks(abs(windowFFT),'SortStr','descend');
domFreqsAmp = pks(1:freqs);
domFreqs = f_grid(locs(1:freqs));

end

