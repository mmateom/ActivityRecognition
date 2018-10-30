%% Preprocess & Process of data for HAR

clear;clc;
%close all;
% Data and process based in the following paper:

% A Tutorial on Human activities Recognition Using Body-worn Inertial Sensors
% Andreas Bulling, Ulf Blanke and Bernt Schiele
% ACM Computing Surveys 46, 3, Article 33 (January 2014), 33 pages
% DOI: http://dx.doi.org/10.1145/2499621
% 
% Original data order: 
% SETTINGS.SENSORS_AVAILABLE = {'acc_1_x', 'acc_1_y', 'acc_1_z', ...
%                               'gyr_1_x', 'gyr_1_y', ...
%                               'acc_2_x', 'acc_2_y', 'acc_2_z', ...
%                               'gyr_2_x', 'gyr_2_y', ...
%                               'acc_3_x', 'acc_3_y', 'acc_3_z', ...
%                               'gyr_3_x', 'gyr_3_y'};

% https://github.com/andreas-bulling/ActRecTut
%
% by Mikel Mateo - University of Twente - October 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 
set(0,'defaultfigurewindowstyle','docked')

%% Define (pre)processing parameters

%params is a struct containing all parameters
params.fs = 32;        %as in the paper
params.winSize = 0.5;  %seconds
params.activityLabels = {'NULL', 'Open window', 'Drink', 'Water plant',...
              'Close window', 'Cut', 'Chop', 'Stir', 'Book', 'Forehand',...
              'Backhand', 'Smash'};

%-------------------------------------------------
params.dataPlots     = 0;    %change to 1 to activate accel. plots
params.nullDelete    = 0;    %delete 'NULL' instances
params.pcaReduct     = 0;    %perform dimens reduction with PCA
params.smv           = 1;    %take data with calculated SMV
params.extraFeatures = 0;

%% Load raw data files

if params.smv  %take SMV too
    load('dataLabeledAccGyroOrderedSMV');
    dataIMURawLabeled = data.sensorsSignals; %data.variableNames also available
    dataNames = data.variableNames;
    
    params.getGA = 'ba';  
    %params.getGA = 'gaba';  %get gravity and body component
    
else    %no SMV
    data = load('dataLabeledAccGyroOrdered');
    dataIMURawLabeled = data.dataLabeledAccGyroOrdered;
    
    params.getGA = 'ba';  
    %params.getGA = 'gaba';  %get gravity and body component    

end

%% Plot raw data

if (params.dataPlots)
figure;
subplot(3,1,1);plot(dataIMURawLabeled(:,1),'r');title('Acceleration in x');
subplot(3,1,2);plot(dataIMURawLabeled(:,2),'g');title('Acceleration in y');
subplot(3,1,3);plot(dataIMURawLabeled(:,10),'b');title('Gyroscope in x');
suptitle('SAMPLE RAW DATA FROM S1')
end


%% Filter 

%'gaba' = gravity component separated in acc - DEFAULT
%'ba'   = only body component in acc
dataFiltStruct = filterData(dataIMURawLabeled,params.fs,params.getGA); %gaba = ROWSx34; ba = ROWSx16
dataFilt = dataFiltStruct.filtData;
dataFiltNames = dataFiltStruct.filtNames;

%% Plot filtered data

if (params.dataPlots)
figure;
subplot(3,2,1);plot(dataFilt(:,1),'r');title('Acceleration in x');
subplot(3,2,3);plot(dataFilt(:,2),'g');title('Acceleration in y');
subplot(3,2,5);plot(dataFilt(:,3),'b');title('Acceleration in z');
subplot(3,2,2);plot(dataIMURawLabeled(:,1),'r');title('Acceleration in x');
subplot(3,2,4);plot(dataIMURawLabeled(:,2),'g');title('Acceleration in y');
subplot(3,2,6);plot(dataIMURawLabeled(:,3),'b');title('Acceleration in z');
suptitle('FILTERED                ACC                      RAW');

figure;
subplot(3,2,1);plot(dataFilt(:,10),'r');title('Acceleration in x');
subplot(3,2,3);plot(dataFilt(:,11),'g');title('Acceleration in y');
subplot(3,2,5);plot(dataFilt(:,12),'b');title('Acceleration in z');
subplot(3,2,2);plot(dataIMURawLabeled(:,10),'r');title('Acceleration in x');
subplot(3,2,4);plot(dataIMURawLabeled(:,12),'g');title('Acceleration in y');
subplot(3,2,6);plot(dataIMURawLabeled(:,12),'b');title('Acceleration in z');
suptitle('FILTERED       GYRO                                 RAW');

end
%% Normalize data

dataNorm = normalizeData(dataFilt);

%% Segmentation

dataSegStruct = segmentData(dataNorm,params.winSize,params.fs);

%% Features Extraction

dataTable = featureExtraction(dataSegStruct,params.activityLabels,params.extraFeatures);

if params.nullDelete %delete NULL instances
toDelete = dataTable.activities == 'NULL';
dataTable(toDelete,:) = [];
end
%% Feature Transformation - Dimensionality reduction (1) - OPTIONAL

if params.pcaReduct
numData = dataTable{:,1:end-1};
%Perform PCA and fit model on the reduced data
[pcs,scrs,~,~,pexp] = pca(numData);
%pareto(pexp)%visualize variance contribution of components


bestFeatures = scrs(:,1:10);


dataTable = table(bestFeatures(:,1),bestFeatures(:,2),bestFeatures(:,3),bestFeatures(:,4),bestFeatures(:,5)...
    ,bestFeatures(:,6),bestFeatures(:,7),bestFeatures(:,8),bestFeatures(:,9),bestFeatures(:,10),dataTable{:,end});
dataTable.Properties.VariableNames = {'var1', 'var2', 'var3','var4',...
                                       'var5','var6','var7','var8','var9','var10'...
                                       'activities'};
end
%% Split into train (will contain dev set), test sets

c = cvpartition(dataTable.activities,'HoldOut',0.3);
idxTrain = training(c);
dataTrain = dataTable(idxTrain,:);
idxTest = test(c);
dataTest = dataTable(idxTest,:);

n = size(dataTrain,1);
d = size(dataTrain,2);
params.ratio = n/d;

if params.ratio<10
    warning(['The ratio between instances and features is less than 10.\n',...
            'Successful model training not guaranteed']);
end

%% Feature Selection  - Dimensionality reduction (2)
% X_train = double(dataTrain{:,1:end-1});   %predictors
% y_train = double(dataTrain{:,end});       %labels
% numF = size(X_train,2);                   %number of features
% 
% %remember to compile feat selec. library if it does not work
% [bestFeatures,scores] = mRMR(X_train, y_train, numF);


%% Find best classifier

%[mdl,lossDev] = findBestClassifier(dataTrain,bestFeatures);


%% Training and classification

[mdl, train_error] = classifyData(dataTrain);%SVM classifier


%% Validate with dataTest

testPred = predict(mdl, dataTest);

%% Test error

lossTest    = loss(mdl,dataTest);

[cm, grp]   = confusionmat(dataTest.activities,testPred);
stats       = confusionmatStats(cm);%custom function from community
accuracy    = stats.accuracy*100;%make it a percentage

%% Display the results

figure(3);
%plotconfusion(data{:,end}',validationPredictions')%always row vectors
heatmap(grp,grp,cm);
title('Confusion Matrix');
set(gca,'FontSize',18) 
colormap summer

figure(4);
x = categorical({'train','test'});
x = reordercats(x,{'train' 'test'});
y = [train_error,lossTest];
b = bar(x,y);
b.FaceColor = 'flat';
b.CData(2,:) = [.5 0 .5];
set(gca,'FontSize',18) 
title('Train vs. Test Error')

figure(5);
x = categorical(params.activityLabels);
x = reordercats(x,params.activityLabels);
y = accuracy';%now it's a row vector
b = bar(x,y);
set(gca,'FontSize',18) 
title('Accuracy')