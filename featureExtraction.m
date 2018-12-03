function dataTable = featureExtraction(dataSeg,activityLabels,extraFeatures,fs)
%featureExtraction extracts the following features from normalized, filtered raw data.
%
% Time features:
%   meanVars:      mean of the window
%   stdVars:       standard dev. of the window
%   minVars:       minimum value on window
%   maxVars:       maximum value on window 
%   rangeVars:     max-min. on window
%   zcrVars:       Zero Crossing Rate: how many times zero is passed in a
%                  window
%   skewness:
%   kurtosis:

% Frequency features:
%   energy:
%   entropy:
%   first and second dominant frequecies and their amps.:
%
%INPUTS: 
%   dataSegStruct:  struct containing:
%                     segNames:   names of each cell 
%                     dataSeg:    windows for x,y,z components, SMV and labels
%                                 in the form of:
%                                     ------->one window with Y samples
%                                    |
%                                    |
%                                    |
%                                all the windows
%   activityLabels: cell array containing labels of the activities

%OUTPUTS:   
%   dataTable:  table containing features as columns (1:i-1) for  
%               x,y,z and SMV for total acceleration. 
%               i'th column are labels.
%
% by Mikel Mateo - University of Twente - October 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna         


extra = extraFeatures;
%% Compute features

%data = dataSegStruct.dataSeg;
data = dataSeg;

%get sizes
numVars = size(data,2)-1;   % how many variables: x,y,z and smv. -1 because 
                            % last cell are labels
windows = size(data{1},1);  % rows are the number of windows



%initialize features
meanVars = nan(windows,numVars); %each column is a variable (x,y,z,smv)
stdVars  = nan(windows,numVars);
minVars  = nan(windows,numVars);
maxVars  = nan(windows,numVars);
rangeVars = nan(windows,numVars);
skewVars  = nan(windows,numVars);
kurtVars  = nan(windows,numVars);
energyVars = nan(windows,numVars);
entropyVars = nan(windows,numVars);
firstDomFreqVars = nan(windows,numVars);
firstDomFreqAmpVars = nan(windows,numVars);
secondDomFreqVars = nan(windows,numVars);
secondDomFreqAmpVars = nan(windows,numVars);

for vars = 1:numVars   %for each variable: acc/gyro: x,y,z or smv
    for w = 1:windows %calculate features for each window
        
        %%--Current window in current variable--
        
        varWindow = data{vars}(w,:);
        
        %%---------Time domain features------------
       
        
        meanVars(w,vars) =   mean(varWindow);
        stdVars(w,vars)  =   std(varWindow);
        if extra
        minVars(w,vars)  =   min(varWindow);
        maxVars(w,vars)  =   max(varWindow);
        rangeVars(w,vars)=   maxVars(w,vars) - minVars(w,vars);
        zcrVars(w,vars)  =   zcr(varWindow);
        skewVars(w,vars) =   skewness(varWindow);
        kurtVars(w,vars) =   kurtosis(varWindow);
        
        %%---------Frequency domain features--------
        
        [windowFreq,NFFT] = getFFT(varWindow,fs); %get fft of window
        
        energyVars(w,vars)   = sum(windowFreq.^2); %see ATSA Ex1.7
        entropyVars(w,vars)  = mean(pentropy(varWindow,fs));
        
        [domFreq, domFreqAmps]= getDominantFreqs(windowFreq,2,NFFT,fs); %first two dom freqs. 
        firstDomFreqVars(w,vars)    = domFreq(1);
        firstDomFreqAmpVars(w,vars) = domFreqAmps(1);
        secondDomFreqVars(w,vars)   = domFreq(2);
        secondDomFreqAmpVars(w,vars)= domFreqAmps(2);

        
        end
        
    end
    
end





%% Get mode of labels for each window
labelsMode = nan(windows,1);%initialize
for w = 1:windows
    labelsMode(w) = mode(data{end}(w,:));
end

%% Create table with features and labels

%arrange activity labels
%associate numbers 1-6 with labels
activity = categorical(labelsMode,1:64,activityLabels);
%activity = labelsMode; %can't concatenate a double array and a categorical array...

       
%Create table with variables
if extra, toTable = [meanVars,stdVars,minVars,maxVars,rangeVars,...
                    zcrVars,skewVars,kurtVars];
else, toTable = [meanVars,stdVars]; end
       
%with toTable array      
dataTable = array2table(toTable);

dataTable = [dataTable,table(activity)];

%name features
for feat = 1:size(dataTable,2)-1
    names{:,feat} = strcat('F',num2str(feat));
end

%add labels' name in the table
names = [names,'activities'];
%too much work to name everything for now...
% meansGA = repmat({'mean_XGA', 'mean_YGA', 'mean_ZGA','mean_SMVGA'},1,12);
% meanBA = repmat({'mean_XBA', 'mean_YBA', 'mean_ZBA','mean_SMVBA'},1,12);
% meanGyros = repmat({'mean_X_gyr', 'mean_Y_gyr', 'mean_ZBA','mean_SMVBA'},1,9);
%Give variables a name

dataTable.Properties.VariableNames = names;
end

