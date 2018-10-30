function dataNorm = normalizeData(dataFilt)
%normalizeAccData normalizes filtered IMU data
%   INPUT
%       dataFilt: filtered data array
%   OUTPUT
%       dataNorm: normalized data array
%
% by Mikel Mateo - University of Twente - October 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna

numVars = size(dataFilt,2)-1; %columns are variables: accS1x, gyro...
                              %-1 to not take labels
numSamples = size(dataFilt,1);% rows are samples

labels = dataFilt(:,end);

dataNormSignals = nan(numSamples,numVars); 

for var = 1:numVars
    dataNormSignals(:,var)   =  zscore(dataFilt(:,var));
end

%pack normalized data with labels
dataNorm = [dataNormSignals,labels];

end

