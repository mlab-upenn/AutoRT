%% DR Synthesis with single tree

filenameTrain = 'LargeOfficeFUN2012.csv';
[~,~,RawDataTrain] = xlsread(filenameTrain);

filenameTest = 'LargeOfficeFUN2013.csv';
[~,~,RawDataTest] = xlsread(filenameTest);

% First 48*60/TimeStep numeric entries in the excel file correspond to design days
% These must be excluded. Higher start index can be chosen to account for
% autoregrssive part

TimeStep = 5; % In mins
OrderOfAR = 0.5*60/TimeStep; % less than 24 hrs here
ARinInput = 0; % 0 => No terms from previous inputs
StartIndex = 1+24*60/TimeStep+1; % 1 for string names, then autoregressive terms, then 1 for next index

%% Organize the data

% Input training Features: uncontrollable
InputData = {};

% Training Features without autoregressive contribution
% Specify the features from EnergyPlus .idf output variables
% TrainingData{end+1}.Name = '';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Wetbulb Temperature [C](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](TimeStep)';

InputData{end+1}.Name = 'EMS:currentDayOfMonth [](TimeStep)';
InputData{end+1}.Name = 'EMS:currentDayOfWeek [](TimeStep)';
InputData{end+1}.Name = 'EMS:currentTimeOfDay [](TimeStep)';

InputData{end+1}.Name = 'BASEMENT:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'CORE_BOTTOM:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'CORE_MID:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'CORE_TOP:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'GROUNDFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'MIDFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_1:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_2:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_3:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_BOT_ZN_4:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_1:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_2:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_3:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_MID_ZN_4:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_1:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_2:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_3:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'PERIMETER_TOP_ZN_4:Zone Air Temperature [C](TimeStep)';
InputData{end+1}.Name = 'TOPFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)';

InputData{end+1}.Name = 'HTGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'HW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';

InputData{end+1}.Name = 'COOLSYS1 CHILLER 1:Chiller Evaporator Outlet Temperature [C](TimeStep)';
% InputData{end+1}.Name = 'COOLSYS1 CHILLER 2:Chiller Evaporator Outlet Temperature [C](TimeStep)';
InputData{end+1}.Name = 'HEATSYS1 BOILER:Boiler Outlet Temperature [C](TimeStep) ';

for idx = 1:size(InputData,2)
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, InputData{idx}.Name)
            InputData{idx}.TrainData = RawDataTrain(StartIndex:end,idy);
            InputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
        end
    end
end

NoOfTrainDataPoints = size(InputData{1}.TrainData,1);
NoOfTestDataPoints = size(InputData{1}.TestData,1);

% set ARinInput = 1 to enable autoregression in inputs
if ARinInput
    for idx = 1:OrderOfAR %#ok<UNRCH>
        for idname = 1:size(InputData,2)
            for idy = 1:size(RawDataTrain,2)
                if strcmp(RawDataTrain{1,idy}, InputData{idname}.Name)
                    InputData{end+1}.Name = [InputData{idname}.Name '(k-' num2str(idx) ')'];
                    InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
                    InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
                end
            end
        end
    end
end

% Input training Features for previous time instances of desired output
ARVariable.Name = 'Whole Building:Facility Total Electric Demand Power [W](TimeStep)';
 
for idx = 1:OrderOfAR
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, ARVariable.Name)
            InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')']; %#ok<SAGROW>
            InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
            InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
        end
    end
end

% Input training Features: controllable
NoOfUncontrolVars = size(InputData,2);
NoOfControlVars = 3;
InputData{end+1}.Name = 'CW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'CLGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'BLDG_LIGHT_SCH:Schedule Value [](TimeStep)';

for idx = NoOfUncontrolVars+1:NoOfUncontrolVars+NoOfControlVars
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, InputData{idx}.Name)
            InputData{idx}.TrainData = RawDataTrain(StartIndex:end,idy);
            InputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
        end
    end
end

% Output Variables
NoOfOutput = 1;
OutputData = {};
OutputData{end+1}.Name = 'Whole Building:Facility Total Electric Demand Power [W](TimeStep)';
for idx = 1:NoOfOutput
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, OutputData{idx}.Name)
            OutputData{idx}.TrainData = RawDataTrain(StartIndex:end,idy);
            OutputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
        end
    end
end

%% Preprocess training and testing data

NoOfFeatures = size(InputData,2);
TrainingInput = zeros(NoOfTrainDataPoints, NoOfFeatures);
TestingInput = zeros(NoOfTestDataPoints, NoOfFeatures);

for idx = 1:NoOfFeatures
    if iscell(InputData{idx}.TrainData)
        TrainingInput(:,idx) = cell2mat(InputData{idx}.TrainData);
        TestingInput(:,idx) = cell2mat(InputData{idx}.TestData);
    else
        TrainingInput(:,idx) = InputData{idx}.TrainData;
        TestingInput(:,idx) = InputData{idx}.TestData;
    end
end

TrainingOutput = cell2mat(OutputData{1}.TrainData);
TestingOutput = cell2mat(OutputData{1}.TestData);

%% Fit regression tree

rtree = fitrtree(TrainingInput(:,1:end-NoOfControlVars), TrainingOutput, 'MinLeafSize',50);
[~,~,~,bestLevel] = cvloss(rtree, 'SubTrees', 'all', 'KFold', 5);
% view(rtree, 'Mode', 'graph');

prunedrtree = prune(rtree, 'Level', bestLevel);
% view(prunedtree, 'Mode', 'graph');

%% Predict results on training set

ActualOutput = TrainingOutput;

rtreeOutput = predict(prunedrtree, TrainingInput(:,1:end-NoOfControlVars));

rtreeNRMSE = sqrt(mean((rtreeOutput-ActualOutput).^2))/mean(ActualOutput);

%% linear regressio n at each leaf of the tree
rtreeUnique = unique(rtreeOutput);
NoOfLeaves = length(rtreeUnique);
B = cell(1,NoOfLeaves);
for idi = 1:NoOfLeaves
    idxUnique = find(rtreeOutput==rtreeUnique(idi));
    y = TrainingOutput(idxUnique);
    X = [ones(length(y),1) TrainingInput(idxUnique,end-NoOfControlVars+1:end)];
    
    % choose regression model at leaves
    B{idi}.coeff = regress(y, X);
    B{idi}.error = abs(y-X*B{idi}.coeff);

end

%% control synthesis
% solve linear programming

optimalOutput = mbCRTOpt(prunedrtree, rtreeUnique, B{idi}.coeff, TestInput);
    