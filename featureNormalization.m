function [dataTrain,dataTest] = featureNormalization(dataTrain, dataTest)
%featureNormalization normalizes features
%   INPUT: 
%       dataTrain: table containing non-normalized features of training
%       phase
%       dataTest: table containing non-normalized features of training
%       phase
%   OUTPUT:
%       dataTrain: table containing normalized features of training phase
%       dataTest: table containing normalized features of training phase
%
% https://www.researchgate.net/post/How_to_normalize_feature_vectors
% Normalization per feature
% I would even go one step further: splitting into train and blind test set.
% Normalization of train set and storing of normalization parameters. 
% Then independent normalization of the test set with the parameters 
% determined from the training set. 
% So you come closest to the scenario where you want to classify unseen data.
% Needless to say that unseen data needs to be normalized with the parameters 
% from the train set aswell.
%
% by Mikel Mateo - University of Twente - December 2018 
% for The BioRobotics Institute - Scuola Superiore Sant'Anna
disp('Normalizing features...')
%%
labelsTrain = dataTrain.activities;
labelsTest = dataTest.activities;

for f = 1:size(dataTrain,2)-1 %don't take labels
    featureTrain = dataTrain{:,f};
    featureTest = dataTest{:,f};
    meanF = mean(featureTrain);
    stdF = std(featureTrain);
    
    
    normFeatTrain(:,f) = (featureTrain-meanF/stdF);
    normFeatTest(:,f) = (featureTest-meanF/stdF);%normalize test with train values
    
%     meanStd = [meanF,stdF];
%     meanStdFeatures = [meanStdFeatures,meanStd];
end

%create table TRAIN
dataTrain = array2table(normFeatTrain);
dataTrain = [dataTrain,table(labelsTrain)];

%create table TEST
dataTest = array2table(normFeatTest);
dataTest = [dataTest,table(labelsTest)];

%name features
for feat = 1:size(dataTrain,2)-1
    names{:,feat} = strcat('F',num2str(feat));
end

%add labels' name in the table
names = [names,'activities'];

dataTrain.Properties.VariableNames = names;
dataTest.Properties.VariableNames = names;
disp('Features Normalized...')
end

