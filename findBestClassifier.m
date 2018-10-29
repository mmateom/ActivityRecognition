function [mdl,loss] = findBestClassifier(dataTrain,bestF)
%findBestModel Summary of this function goes here
%   INPUT
%       dataTrain:  partition of the whole data to train the classifiers
%   OUTPUT
%       mdl:    is model object of the best model of the best classifier
%       loss:   model error
%
%Explanation:

%See this link for info on how to CV:
%https://stackoverflow.com/questions/37082266/predict-labels-for-new-dataset-test-data-using-cross-validated-knn-classifier

% You can then use the kfoldLoss function to also get the CV loss for each
% fold and then choose the trained model 
% that gives you the least CV loss in the following way
% modelLosses = kfoldLoss(mdl,'mode','individual');
% The above code will give you a vector of length 10 (10 CV error values) if 
% you have done 10-fold cross-validation while learning. Assuming the trained 
% model with least CV error is the 'k'th one, you would then use:
% testSetPredictions = predict(Mdl.Trained{k}, testSetFeatures);

%% Train classifiers

labs = dataTrain(:,end);

%get selected features only
dataTrain = dataTrain(:,bestF(1:3));
dataTrain = [dataTrain,labs];%build table with selected features

% Try different classifiers...
mdlKNN = fitcknn(dataTrain,'activities');
mdlLDA = fitcdiscr(dataTrain,'activities');

template = templateSVM('KernelFunction','gaussian');
mdlSVM = fitcecoc(dataTrain,'activities','Learners',template); %'CrossVal','on'

%%Optimization of classifiers - once done, comment this
%mdlSVM = fitcecoc(dataTrain,'activities','OptimizeHyperparameters','auto','Learners','linear');
%OptimizeHyperparameters - default method: bayesian. Can perform gradient
%descent and grid search
%% Evaluate model performance

%train error
trainErrorKNN = resubLoss(mdlKNN);
trainErrorLDA = resubLoss(mdlLDA);
trainErrorSVM = resubLoss(mdlSVM);

%cross validate smv
mdlKNN = crossval(mdlKNN);
mdlLDA = crossval(mdlLDA);
mdlSVM = crossval(mdlSVM);%cross-validate SVM. Default - 10-fold

%dev errors: average error of all folds
lossDevKNN = kfoldLoss(mdlKNN);%dev error
lossDevLDA = kfoldLoss(mdlLDA);%dev error
lossDevSVM = kfoldLoss(mdlSVM);%dev error

%% Make a table with train and dev errors

modelNames = {'kNN','Discriminant Analysis','SVM'};

disp('------ Different Classifier Errors -----');
results = table([trainErrorKNN;trainErrorLDA;trainErrorSVM]...
                ,[lossDevKNN;lossDevLDA;lossDevSVM]...
                ,'RowNames',modelNames...
                ,'VariableNames',{'Train_Error','Dev_Error'})

figure;
subplot(3,1,1)
x = categorical({'Train','Dev'});
x = reordercats(x,{'Train' 'Dev'});
y = [trainErrorKNN,lossDevKNN];
b = bar(x,y);
b.FaceColor = 'flat';
b.CData(2,:) = [.5 0 .5];
set(gca,'FontSize',18) 
title('KNN')
subplot(3,1,2)
x = categorical({'Train','Dev'});
x = reordercats(x,{'Train' 'Dev'});
y = [trainErrorLDA,lossDevLDA];
b = bar(x,y);
b.FaceColor = 'flat';
b.CData(2,:) = [.5 0 .5];
set(gca,'FontSize',18) 
title('LDA')
subplot(3,1,3)
x = categorical({'Train','Dev'});
x = reordercats(x,{'Train' 'Dev'});
y = [trainErrorSVM,lossDevSVM];
b = bar(x,y);
b.FaceColor = 'flat';
b.CData(2,:) = [.5 0 .5];
set(gca,'FontSize',18) 
title('SVM')
%% Find classifiers' best model

%Get each model from each classifier

mdlLossKNN = kfoldLoss(mdlKNN,'mode','individual');
mdlLossLDA = kfoldLoss(mdlLDA,'mode','individual');
mdlLossSVM = kfoldLoss(mdlSVM,'mode','individual');

%Find the best model from each classifier
[lossBestKNN,idxMinLossKNN] = min(mdlLossKNN);
[lossBestLDA,idxMinLossLDA] = min(mdlLossLDA);
[lossBestSVM,idxMinLossSVM] = min(mdlLossSVM);

%% Find best trained model for each classifier

%Select model with least loss: best model f
bestModels = [lossBestKNN,lossBestLDA,lossBestSVM];
[loss, idxBestModelLoss] = min(bestModels);

if idxBestModelLoss == 1                    %KNN
    mdl = mdlKNN.Trained{idxMinLossKNN};
    mdlName = 'kNN';
elseif idxBestModelLoss == 2                %LDA
    mdl = mdlLDA.Trained{idxMinLossLDA};
    mdlName = 'LDA';
else
    mdl = mdlSVM.Trained{idxMinLossSVM};    %SVM
    mdlName = 'SVM';
   
formatSpec = 'Best model is %s with loss %f';
fprintf(formatSpec,mdlName,loss);

end

