%% Read the output file

% clear

filenameTrain = 'LargeOfficeFUN2012.csv';
[~,~,RawDataTrain] = xlsread(filenameTrain);

filenameTest = 'LargeOfficeOPT3.csv';
[~,~,RawDataTest] = xlsread(filenameTest);

TimeStep = 5; % In mins
OrderOfAR = 8; %0.5*60/TimeStep; % less than 24 hrs here
ARinInput = 0; % 0 => Auto-reg terms from output only i.e no terms from previous inputs
StartIndex = 1+24*60/TimeStep+1; % 1 for string names, then autoregressive terms, then 1 for next index

%% Organize the data for kW tree

% Input Variables
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

InputData{end+1}.Name = 'HTGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'HW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'CW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'CLGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'BLDG_LIGHT_SCH:Schedule Value [](TimeStep)';

InputData{end+1}.Name = 'COOLSYS1 CHILLER 1:Chiller Evaporator Outlet Temperature [C](TimeStep)';
% InputData{end+1}.Name = 'COOLSYS1 CHILLER 2:Chiller Evaporator Outlet Temperature [C](TimeStep)';
InputData{end+1}.Name = 'HEATSYS1 BOILER:Boiler Outlet Temperature [C](TimeStep) ';

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

% Training Features for previous time instances of desired output
ARVariable.Name = 'Whole Building:Facility Total Electric Demand Power [W](TimeStep)';

for idx = OrderOfAR:-1:1
    for idy = 1:size(RawDataTrain,2)
        if strcmp(RawDataTrain{1,idy}, ARVariable.Name)
            InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')'];
            InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
            InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
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

% Preprocess training and testing data

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

TrainingInput(:,8) = round(TrainingInput(:,8),2);
TestingInput(:,8) = round(TestingInput(:,8),2);
% kWTree.TrainingInput = TrainingInput;
% kWTree.TrainingOutput = TrainingOutput;
kWTree.TestingInput = TestingInput;
kWTree.DRTestingInput = kWTree.TestingInput; % This is updated during DR Event
kWTree.TestingOutput = TestingOutput;
kWTree.Name = OutputData{1}.Name;

%% Fit kW trees
catcol = [6,7,8];
leafsize = 5;

trainmany = 0;

if trainmany
    % 1) Single tree
    kWTree.singletree = fitrtree(TrainingInput, TrainingOutput,...
        'MinLeafSize', leafsize, 'CategoricalPredictors', catcol);
    
    % 2) Boosted tree
    kWTree.boosttree = fitensemble(TrainingInput, TrainingOutput,...
        'LSBoost', 500, 'Tree', 'CategoricalPredictors', catcol, 'LearnRate', 0.1);
end

% 3) Random Forest
kWTree.rforest = TreeBagger(500, TrainingInput, TrainingOutput,...
    'Method', 'regression', 'OOBPred', 'On', 'OOBVarImp', 'on',...
    'CategoricalPredictors', catcol, 'MinLeaf', leafsize);

clearvars -except kWTree TimeStep ARinInput OrderOfAR NoOfZones catcol leafsize RawDataTrain RawDataTest StartIndex trainmany
%% Organize the data for thermal tress

NoOfZones = 19;
% ThermalTree = cell(1,NoOfZones);

for OutputVarIdx = 1:NoOfZones
    % Input Variables
    InputData = {};
    
    % Training Features without autoregressive contribution
    % Specify the features from EnergyPlus .idf output variables
    % TrainingData{end+1}.Name = '';
    InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](TimeStep)'; %#ok<*SAGROW>
    InputData{end+1}.Name = 'Environment:Site Outdoor Air Wetbulb Temperature [C](TimeStep)';
    InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](TimeStep)';
    InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](TimeStep)';
    InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](TimeStep)';
    
    InputData{end+1}.Name = 'EMS:currentDayOfMonth [](TimeStep)';
    InputData{end+1}.Name = 'EMS:currentDayOfWeek [](TimeStep)';
    InputData{end+1}.Name = 'EMS:currentTimeOfDay [](TimeStep)';
    
    InputData{end+1}.Name = 'HTGSETP_SCH:Schedule Value [](TimeStep)';
    InputData{end+1}.Name = 'HW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
    InputData{end+1}.Name = 'CW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
    InputData{end+1}.Name = 'CLGSETP_SCH:Schedule Value [](TimeStep)';
    InputData{end+1}.Name = 'BLDG_LIGHT_SCH:Schedule Value [](TimeStep)';
    
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
    
    % Training Features for previous time instances of desired output
    OutputVars = {'BASEMENT:Zone Air Temperature [C](TimeStep)',...
        'CORE_BOTTOM:Zone Air Temperature [C](TimeStep)',...
        'CORE_MID:Zone Air Temperature [C](TimeStep)',...
        'CORE_TOP:Zone Air Temperature [C](TimeStep)',...
        'GROUNDFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)',...
        'MIDFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_BOT_ZN_1:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_BOT_ZN_2:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_BOT_ZN_3:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_BOT_ZN_4:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_MID_ZN_1:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_MID_ZN_2:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_MID_ZN_3:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_MID_ZN_4:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_TOP_ZN_1:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_TOP_ZN_2:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_TOP_ZN_3:Zone Air Temperature [C](TimeStep)',...
        'PERIMETER_TOP_ZN_4:Zone Air Temperature [C](TimeStep)',...
        'TOPFLOOR_PLENUM:Zone Air Temperature [C](TimeStep)'};
    
    % Select a number from 1-19 from above
    SelectedOutputVar = OutputVars{OutputVarIdx};
    
    ARVariable.Name = SelectedOutputVar;
    
    for idx = OrderOfAR:-1:1
        for idy = 1:size(RawDataTrain,2)
            if strcmp(RawDataTrain{1,idy}, ARVariable.Name)
                InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')'];
                InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
                InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
            end
        end
    end
    
    % Training Features for previous time instances of building power demand
%     ARVariable.Name = 'Whole Building:Facility Total Electric Demand Power [W](TimeStep)';
%     
%     for idx = OrderOfAR:-1:1
%         for idy = 1:size(RawDataTrain,2)
%             if strcmp(RawDataTrain{1,idy}, ARVariable.Name)
%                 InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')'];
%                 InputData{end}.TrainData = RawDataTrain(StartIndex-idx:StartIndex-idx+NoOfTrainDataPoints-1,idy);
%                 InputData{end}.TestData = RawDataTest(StartIndex-idx:StartIndex-idx+NoOfTestDataPoints-1,idy);
%             end
%         end
%     end
    
    % Output Variables
    NoOfOutput = 1;
    OutputData = {};
    OutputData{end+1}.Name = SelectedOutputVar;
    for idx = 1:NoOfOutput
        for idy = 1:size(RawDataTrain,2)
            if strcmp(RawDataTrain{1,idy}, OutputData{idx}.Name)
                OutputData{idx}.TrainData = RawDataTrain(StartIndex:end,idy);
                OutputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
            end
        end
    end
    
    % Preprocess training and testing data
    
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
    TrainingInput(:,8) = round(TrainingInput(:,8),2);
    TestingInput(:,8) = round(TestingInput(:,8),2);
%     ThermalTree{OutputVarIdx}.TrainingInput = TrainingInput;
%     ThermalTree{OutputVarIdx}.TrainingOutput = TrainingOutput;
    ThermalTree{OutputVarIdx}.TestingInput = TestingInput;
    ThermalTree{OutputVarIdx}.DRTestingInput = TestingInput; % This is updated during DR Event
    ThermalTree{OutputVarIdx}.TestingOutput = TestingOutput;
    ThermalTree{OutputVarIdx}.Name = SelectedOutputVar;
    
end



%% Fit thermal trees

for OutputVarIdx = 1:NoOfZones
    
    if trainmany
        % 1) Single tree
        ThermalTree{OutputVarIdx}.singletree = fitrtree(TrainingInput, TrainingOutput,...
            'MinLeafSize', leafsize, 'CategoricalPredictors', catcol);
        
        % 2) Boosted tree
        ThermalTree{OutputVarIdx}.boosttree = fitensemble(TrainingInput, TrainingOutput,...
            'LSBoost', 500, 'Tree', 'CategoricalPredictors', catcol, 'LearnRate', 0.1);
    end
    
    % 3) Random Forest
    ThermalTree{OutputVarIdx}.rforest = TreeBagger(500, TrainingInput, TrainingOutput,...
        'Method', 'regression', 'OOBPred', 'On', 'OOBVarImp', 'on',...
        'CategoricalPredictors', catcol, 'MinLeaf', leafsize);
    
    OutputVarIdx 
    
end

%% Select a day for DR Event from 2:31 (data from day 1 will be used for the lag variabales)
clearvars -except kWTree ThermalTree TimeStep ARinInput OrderOfAR NoOfZones catcol leafsize

DRDay = 1;
DRStartHour = 15;
DEEndHour = 16;
DREventRange = (DRDay-1)*(60/TimeStep*24)+60/TimeStep*DRStartHour+1:(DRDay-1)*(60/TimeStep*24)+60/TimeStep*DEEndHour;

%% Specify control strategies here

NoOfControlStrat = 3;
ControlStrategy = cell(1,NoOfControlStrat);

% ControlStrategy{1} =  kWTree.TestingInput(DREventRange,11:13);
% ControlStrategy{2} =  kWTree.TestingInput(DREventRange,11:13) + [0*ones(length(DREventRange),1), 1*ones(length(DREventRange),1), 0*ones(length(DREventRange),1)];
% ControlStrategy{3} =  kWTree.TestingInput(DREventRange,11:13) + [0*ones(length(DREventRange),1), -1*ones(length(DREventRange),1), 0*ones(length(DREventRange),1)];

% ControlStrategy{1} = [6.7*ones(length(DREventRange),1), 24*ones(length(DREventRange),1), 0.85*ones(length(DREventRange),1)];
% ControlStrategy{1}(1:12,3) = linspace(0.8,0.4,12);
% ControlStrategy{1}(6:12,1) = linspace(6.7,9,7);
% ControlStrategy{2}(9:12,3) = 0.8;
% 
% ControlStrategy{2} = [6.7*ones(length(DREventRange),1), 24*ones(length(DREventRange),1), 0.85*ones(length(DREventRange),1)];
% ControlStrategy{2}(7:12,2) = 28.5;
% ControlStrategy{2}(7:12,1) = 8;
% ControlStrategy{2}(9:12,3) = 0.9;
% 
% ControlStrategy{3} = [6.7*ones(length(DREventRange),1), 24*ones(length(DREventRange),1), 0.85*ones(length(DREventRange),1)];
% ControlStrategy{3}(1:12,2) = linspace(25,28,12);
% ControlStrategy{3}(5:8,1) = linspace(6.7,9,4);
% ControlStrategy{3}(8:12,1) = linspace(9,6.7,5);
% ControlStrategy{3}(5:8,3) = 0.6;
% ControlStrategy{3}(9:12,3) = 0.9;

ControlStrategy{1} = [9*ones(length(DREventRange),1), 26*ones(length(DREventRange),1), 0.6*ones(length(DREventRange),1)];

ControlStrategy{2} = [8*ones(length(DREventRange),1), 26*ones(length(DREventRange),1), 0.6*ones(length(DREventRange),1)];

ControlStrategy{3} = [9*ones(length(DREventRange),1), 26*ones(length(DREventRange),1), 0.8*ones(length(DREventRange),1)];
%% Predict results during DR Event step by step for all the strategies

ZoneTempAllStrat = cell(1,NoOfControlStrat);
BuildPowerAllStrat = cell(1,NoOfControlStrat);

for ControlIdx = 1:NoOfControlStrat
    
    ZoneTemp = zeros(length(DREventRange), NoOfZones);    
    
    for OutputVarIdx = 1:NoOfZones
        
        ThermalTree{OutputVarIdx}.DRTestingInput = ThermalTree{OutputVarIdx}.TestingInput;
        ThermalTree{OutputVarIdx}.DRTestingInput(DREventRange,11:13) = ControlStrategy{ControlIdx};
        TestZoneTemp = ThermalTree{OutputVarIdx}.DRTestingInput(DREventRange,:);
        ZoneTemp(1,OutputVarIdx) = ThermalTree{OutputVarIdx}.TestingOutput(DREventRange(1));
        
        for DRidx = 2:length(DREventRange)
            
            ZoneTemp(DRidx,OutputVarIdx) = predict(ThermalTree{OutputVarIdx}.rforest, TestZoneTemp(DRidx,:));
            
            for idi = 1:OrderOfAR
                if DRidx+idi<=length(DREventRange)
                    TestZoneTemp(DRidx+idi, end+1-idi) = ZoneTemp(DRidx, OutputVarIdx);
                end
            end
        end 
        
    end
    
    ZoneTempAllStrat{ControlIdx} = ZoneTemp;
    
end

for ControlIdx = 1:NoOfControlStrat
    
    kWTree.DRTestingInput = kWTree.TestingInput;
    kWTree.DRTestingInput(DREventRange,11:13) = ControlStrategy{ControlIdx};
    
    BuildPower = zeros(length(DREventRange), 1);
    TestBuildPower = kWTree.DRTestingInput(DREventRange,:);
    TestBuildPower(:,end-OrderOfAR-19+1:end-OrderOfAR-19+19) = ZoneTempAllStrat{ControlIdx}(:,:);
    
    for DRidx = 1:length(DREventRange)
        
        BuildPower(DRidx,1) = predict(kWTree.rforest, TestBuildPower(DRidx,:));
        
        for idi = 1:OrderOfAR
            if DRidx+idi<=length(DREventRange)
                TestBuildPower(DRidx+idi, end+1-idi) = BuildPower(DRidx,1);
                
            end
        end
        
    end
    
    BuildPowerAllStrat{ControlIdx} = BuildPower;
    
end

%% Choose best strategy

PowerOpt = zeros(length(DREventRange),1);
ControlOpt = zeros(length(DREventRange),3);

for ibest = 1:length(DREventRange)

    [a,b] = min([BuildPowerAllStrat{1}(ibest), BuildPowerAllStrat{2}(ibest), BuildPowerAllStrat{3}(ibest)]);
    PowerOpt(ibest,1) = a;
    ControlOpt(ibest,:) = ControlStrategy{b}(ibest,:);
    
end

%% Performance Analysis

figure; hold on;
title('Control Inputs');

h11 = plot(1:length(DREventRange), ControlStrategy{1}(:,1), 'ob');
h12 = plot(1:length(DREventRange), ControlStrategy{1}(:,2), 'db');
h13 = plot(1:length(DREventRange), ControlStrategy{1}(:,3), 'sb');
plot(1:length(DREventRange), ControlOpt(:,1), '-c')

h21 = plot(1:length(DREventRange), ControlStrategy{2}(:,1), 'or');
h22 = plot(1:length(DREventRange), ControlStrategy{2}(:,2), 'dr');
h23 = plot(1:length(DREventRange), ControlStrategy{2}(:,3), '+r');
plot(1:length(DREventRange), ControlOpt(:,2), '-c')

h31 = plot(1:length(DREventRange), ControlStrategy{3}(:,1), 'og');
h32 = plot(1:length(DREventRange), ControlStrategy{3}(:,2), 'dg');
h33 = plot(1:length(DREventRange), ControlStrategy{3}(:,3), 'sg');
plot(1:length(DREventRange), ControlOpt(:,3), '-c')

% plot(1:length(DREventRange), kWTree.TestingInput(DREventRange,11), 'c');
% plot(1:length(DREventRange), kWTree.TestingInput(DREventRange,12), 'c');
% plot(1:length(DREventRange), kWTree.TestingInput(DREventRange,13), 'c');

legend([h11, h12, h13, h21, h22, h23, h31, h32, h33], 'S1: CHWTR', 'S1: CLGTP', 'S1: LGTNG',...
                                                      'S2: CHWTR', 'S2: CLGTP', 'S2: LGTNG',...
                                                      'S3: CHWTR', 'S3: CLGTP', 'S3: LGTNG', 'Location', 'Best');

figure; hold on;
title('Building Power Demand during DR Event');
h1 = plot(1:length(DREventRange), BuildPowerAllStrat{1}, 'b', 'MarkerSize', 2);
h2 = plot(1:length(DREventRange), BuildPowerAllStrat{2}, 'r', 'MarkerSize', 2);
h3 = plot(1:length(DREventRange), BuildPowerAllStrat{3}, 'g', 'MarkerSize', 2);
h4 = plot(1:length(DREventRange), PowerOpt, '--c', 'MarkerSize', 2);
plot(1:length(DREventRange),kWTree.TestingOutput(DREventRange))
legend([h1, h2, h3], 'S1', 'S2', 'S3', 'Location', 'Best')