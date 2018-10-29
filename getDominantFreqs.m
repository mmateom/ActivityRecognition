function [domFreqs,domFreqsAmp] = getDominantFreqs(windowFFT,freqs)
%dominantFreqs Computes 1st and 2nd dominant frequencies
%   INPUT
%       windowFFT:  FFT of window
%       freqs:      number of dominant frequencies wanted
%   OUTPUT
%       domFreqs:       dominant frequencies
%       domFreqsAmp:    amplitude of each dominant frequency

[pks,locs] = findpeaks(abs(windowFFT),'SortStr','descend');
domFreqsAmp = pks(1:freqs);
domFreqs = freqs(locs(1:freqs));

end

