%% Preprocess & Process of data for HAR

clear;clc;
%close all;
% Process based on the following paper:

% A Tutorial on Human activities Recognition Using Body-worn Inertial Sensors
% Andreas Bulling, Ulf Blanke and Bernt Schiele
% ACM Computing Surveys 46, 3, Article 33 (January 2014), 33 pages
% DOI: http://dx.doi.org/10.1145/2499621
% https://github.com/andreas-bulling/ActRecTut
%
% by Mikel Mateo - University of Twente - October/December 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna 
set(0,'defaultfigurewindowstyle','docked')

%% Define (pre)processing parameters

%params is a struct containing all parameters
params.fs = 100;       %Hz
params.winSize = 1;  %seconds
params.activityLabels = {
             %//hand grasp movements
        'Power';...
        'Pinch';...
        'Lateral';...
        'Wrist Flexion';...
        'Wrist Extension';...
        'Pronation';...
        'Supination';...
        %//Activities
        'Fork and knife';...
        'Drink water';...
        'Drink coffee';...
        'Use scissors';...
        'Standing eating';...
        'Standing drinking';...
        'Cutting with a knife';
        'Chopping with a knife';...
        'Open/close bottle cap';...
        'Open/close jam(bigger cap)';...
        'Do/undo shirt buttons';...
        'Do/undo trousers zip';...
        'Put socks';...
        'Tie shoes';...
        'Scrubbing';...
        'Folding laundry';...
        'Vacuuming';...
        'Washing dishes';...
        'Setting table';...
        'Ironing';...
        'Dusting';...
        'Sweep';...
        'Making the bed';...
        'Window cleaning';...
        'Mopping';...
        'Open/close window';...
        'Open/close door';...
        'Push door';...
        'Brush teeth';...
        'Grooming';...
        'Wash face';...
        'Wash hands';...
        'Running';'Cycling';...
        'Jumping';...
        'Walk';'Walk carrying items';'Standing still';...
        'Watching TV';'Reading';'Sitting';'Typing in computer';'Lying down';'Lying down using computer';
 };


%-------------------------------------------------
params.dataPlots     = 0;    %change to 1 to activate accel. plots
params.pcaReduct     = 0;    %perform dimens reduction with PCA
params.extraFeatures = 0;
%% Load raw data files

defpath = 'yourPath';
PathName = [defpath,'Step3_ReadyToProcess/'];
FileName = 'dataIMUS';
data = load([PathName,FileName]);  %Data from all subjects

dataIMULabeled = data.dataIMUS.sensorData; %data.variableNames also available
varNames       = data.dataIMUS.varNames;

%% Plot raw data
if (params.dataPlots)
figure;
subplot(3,1,1);plot(dataIMULabeled(:,1),'r');title('Acceleration in x');
subplot(3,1,2);plot(dataIMULabeled(:,2),'g');title('Acceleration in y');
subplot(3,1,3);plot(dataIMULabeled(:,3),'b');title('Acceleration in z');
suptitle('SAMPLE RAW DATA FROM S1')
end
%% Segmentation

% dataSegStruct = segmentData(dataNorm,params.winSize,params.fs);
dataSeg = segmentData(dataIMULabeled,params.winSize,params.fs);

%% Features Extraction

dataTable = featureExtraction(dataSeg,params.activityLabels,params.extraFeatures,params.fs);

%% Feature Transformation - Dimensionality reduction (1) - OPTIONAL

if params.pcaReduct
numData = dataTable{:,1:end-1};
%Perform PCA and fit model on the reduced data
[pcs,scrs,~,~,pexp] = pca(numData);
%pareto(pexp)%visualize variance contribution of components


bestFeatures = scrs(:,1:10);

%this one changes so use it for the final transformation
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

if params.ratio<10 %Mannini 2010
    warning(['The ratio between instances and features is less than 10.\n',...
            'Successful model training not guaranteed']);
end

%% Feature Normalization

[dataTrain,dataTest] = featureNormalization(dataTrain,dataTest);

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
disp('Predicting...')
testPred = predict(mdl, dataTest);
disp('Prediction done')
%% Test error
disp('Evaluting model...')
lossTest    = loss(mdl,dataTest);

[cm, grp]   = confusionmat(dataTest.activities,testPred);
stats       = confusionmatStats(cm);%custom function from community
accuracy    = stats.accuracy*100;%make it a percentage
disp('Model evaluated')
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