function dataFilt = filterData(dataIMURawLabeled,fs,getGA)
%filterData filters raw IMU data
%           for ACC data one can choose to divide the signal into
%           gravity component (GA) and body component (BA) or: raw and ba component
%   INPUTS 
%       data:       3D raw data array
%       fs:         sampling frequency from recording
%   OUTPUT
%       dataFilt:   filtered 3D data array
%                   for 'ba': | BA | gyro | Lables
%                   for 'gaba': GA[(x1,y1,z1),(x2,y2,z2),(x3,y3,z3),(smv1,smv2,smv3)] | BA | gyro | Lables
%
%if not specified, get body component only
 if nargin < 3
        getGA = 'ba';
 end
 
 dataFilt.filtNames = {
                        'acc1xBA','acc1yBA','acc1zBA',...
                        'acc2xBA','acc2yBA','acc2zBA',...
                        'acc3xBA','acc3yBA','acc3zBA',...
                        'acc1smvBA','acc2smvBA','acc3smvBA'...
                        'gyr1x','gyr1y',...
                        'gyr2x','gyr2y',...
                        'gyr3x','gyr3y',...
                        'gyr1smv','gyr2smv','gyr3smv',...
                        'labels'};
%%

signals = dataIMURawLabeled(:,1:end-1);
labels = dataIMURawLabeled(:,end);

switch getGA
      %TODO: change this depending on if I need a separate signal for GA.
      %Ask ANDREA    
    case 'gaba' %get GA,BA signals separated
     
        [GA,BA,gyro] = filterMyData(signals,fs);
        dataFilt.filtData = [GA,BA,gyro,labels];  %12,12,6,1 = 31 rows

    case 'ba'
        [~,BA,gyro] = filterMyData(signals,fs);
        dataFilt.filtData = [BA,gyro,labels];  
end

function [dataAccGA,dataAccBA,dataGyro] = filterMyData(signalRaw,fs)

Ts = 1/fs;

lfc = 0.3;
hfc = 15; %high cutoff freq. In this case can't be higher cause of fNyq.
nlfc = 2*Ts*lfc; %normalized cutoff freq.: nfc = fc/fnyq; fnyq = 1/2*fs=2*Ts
nhfc = 2*Ts*hfc;

    
        %get BA component AND also raw signal with GA+BA components
        
        %First, filter everything at 15 or 20Hz
        [B,A] = butter(4,nhfc,'low');  %low pass        
        numVars = size(signalRaw,2); %columns are variables: accS1x, gyro...
        for var = 1:numVars
            dataAllFilt(:,var)   =  filtfilt(B,A,signalRaw(:,var));
        end
        
        %Get gyro filtered data
        dataGyro = dataAllFilt(:,[10:15,19:21]);
        accData = [1:9,16:18]; %x,y,z and smv of acc data

        %Second, filter ACC data at 0.3 
        [B,A] = butter(4,nlfc,'low');  %low pass at 0.3 to get GA componenet only 
        
        
        for var = accData
            dataAccGA(:,var)   =  filtfilt(B,A,signalRaw(:,var));
        end
        
        %take zeros out
        dataAccGA( :, ~any(dataAccGA,1) ) = [];  %columns
        
        %take raw acc, also smv
        accRaw = signalRaw(:,accData);
        %substract GA from Raw to get BA
        dataAccBA = accRaw-dataAccGA; %get BA component

end

%--------------------------------------------------------------------------------------
% Maybe in the future I need this.
%
%         [B,A] = butter(4,[nlfc nhfc],'bandpass'); %get Body Acc component (BA or AC component)
%         %[B,A] = butter(4,nhfc,'low');
%         data_x_filt =filtfilt(B,A,dataIMURaw(:,1)); %filtered x acceleration signal
%         data_y_filt =filtfilt(B,A,dataIMURaw(:,2)); %filtered y acceleration signal
%         data_z_filt =filtfilt(B,A,dataIMURaw(:,3)); %filtered z acceleration signal
% 
%         dataFilt = [data_x_filt,data_y_filt,data_z_filt];
%--------------------------------------------------------------------------------------
end
