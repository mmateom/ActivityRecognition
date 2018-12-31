function dataSeg = segmentData(dataIMU,winSize,fs)
%segmentAccData segments 3D normalized ACC data, computes SMV (total acc) and labels
%NOTE: NO overlap
%
%   INPUTS
%       dataNorm:   normalized 3D data array
%       winSize:    desired window size in SECONDS
%       fs:         sampling frequency of the recording
%
%   OUTPUT
%       dataSegStruct:  struct containing:
%                        segNames:   names of each cell 
%                        dataSeg:    windows for x,y,z components, SMV and labels
%                                    in the form of:
%                                     ------->one window with Y samples
%                                    |
%                                    |
%                                    |
%                                all the windows
%
% by Mikel Mateo - University of Twente - October 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna



%Ts = 0.0313, which means each samples lasts 0.0313.
%if I want a window of X seconds,then X/0.0313 = Y samples per window.
disp('Windowing data...')
%%
Ts = 1/fs;
samplesPerWindow = ceil(winSize/Ts);

numVars = size(dataIMU,2); %columns are variables: accS1x, gyro...labels
                             
%also segments labels!!
for var = 1:numVars
    %dataSegStruct.
    dataSeg{var} =buffer(dataIMU(:,var),samplesPerWindow)';
end

disp('Data windowed')
end

