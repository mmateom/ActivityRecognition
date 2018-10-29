function zeroXRate = zcr(dataWin)
%zcr Calculates Zero Cross Rate in a window: how many times zero
%    (the mean in this case, because data is filtered) is crossed in a window
%    See: https://en.wikipedia.org/wiki/Zero-crossing_rate (has another formula)
%   INPUTS
%       dataWin:    a window from the data for var = x,y,z or smv
%
%   OUTPUT
%       zeroXRate:  rate for a window
%
% Process:
%   x>0:  returns a logical array for numbers that are greater than 0 in x
%   diff: find the difference for values x>0 --> crossing
%   abs:  make it absolute values
%   sum and devide by the length of the window to get the reate.
%   inspired by: https://nl.mathworks.com/matlabcentral/fileexchange/31663-zero-crossing-rate

    zeroXRate= sum(abs(diff(dataWin>0)))/length(dataWin); %zero cross rate per window

end

