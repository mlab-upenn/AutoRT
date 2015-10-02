%% Read the output file

% clear

filenameTrain = 'LargeOfficeFUN2012.csv';
[~,~,RawDataTrain] = xlsread(filenameTrain);

filenameTest = 'LargeOfficeFUN2013.csv';
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

kWTree.TrainingInput = TrainingInput;
kWTree.TrainingOutput = TrainingOutput;
kWTree.TestingInput = TestingInput;
kWTree.DRTestingInput = kWTree.TestingInput; % This is updated during DR Event
kWTree.TestingOutput = TestingOutput;
kWTree.Name = OutputData{1}.Name;

%% Organize the data for thermal tress

NoOfZones = 19;
ThermalTree = cell(1,NoOfZones);

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
    
    ThermalTree{OutputVarIdx}.TrainingInput = TrainingInput;
    ThermalTree{OutputVarIdx}.TrainingOutput = TrainingOutput;
    ThermalTree{OutputVarIdx}.TestingInput = TestingInput;
    ThermalTree{OutputVarIdx}.DRTestingInput = TestingInput; % This is updated during DR Event
    ThermalTree{OutputVarIdx}.TestingOutput = TestingOutput;
    ThermalTree{OutputVarIdx}.Name = SelectedOutputVar;
    
end

clearvars -except kWTree ThermalTree TimeStep ARinInput OrderOfAR NoOfZones

%% Fit kW trees

% 1) Single tree
kWTree.singletree = fitrtree(kWTree.TrainingInput, kWTree.TrainingOutput, 'MinLeafSize',50);
[~,~,~,bestLevel] = cvloss(kWTree.singletree , 'SubTrees', 'all', 'KFold', 5);
kWTree.prunedstree = prune(kWTree.singletree, 'Level', bestLevel);
% view(prunedtree, 'Mode', 'graph');

% 2) Boosted tree
kWTree.boosttree = fitensemble(kWTree.TrainingInput, kWTree.TrainingOutput, 'LSBoost', 500, 'Tree');

clearvars -except kWTree ThermalTree TimeStep ARinInput OrderOfAR NoOfZones
%% Fit thermal trees

for OutputVarIdx = 1:NoOfZones
    
    % 1) Single tree
    ThermalTree{OutputVarIdx}.singletree = fitrtree(ThermalTree{OutputVarIdx}.TrainingInput, ThermalTree{OutputVarIdx}.TrainingOutput,...
        'MinLeafSize',50);
    [~,~,~,bestLevel] = cvloss(ThermalTree{OutputVarIdx}.singletree, 'SubTrees', 'all', 'KFold', 5);
    ThermalTree{OutputVarIdx}.prunedstree = prune(ThermalTree{OutputVarIdx}.singletree, 'Level', bestLevel);
    % view(prunedtree, 'Mode', 'graph');
    
    % 2) Boosted tree
    ThermalTree{OutputVarIdx}.boosttree = fitensemble(ThermalTree{OutputVarIdx}.TrainingInput, ThermalTree{OutputVarIdx}.TrainingOutput,...
        'LSBoost', 500, 'Tree');
    
end

%% Select a day for DR Event from 2:31 (data from day 1 will be used for the lag variabales)
clearvars -except kWTree ThermalTree TimeStep ARinInput OrderOfAR NoOfZones

DRDay = 5;
DRStartHour = 14;
DEEndHour = 18;
DREventRange = (DRDay-1)*(60/TimeStep*24)+60/TimeStep*DRStartHour+1:(DRDay-1)*(60/TimeStep*24)+60/TimeStep*DEEndHour;

%% Specify control strategies here

NoOfControlStrat = 3;
ControlStrategy = cell(1,NoOfControlStrat);
% ControlStrategy{1} = [9*ones(length(DREventRange),1), 26*ones(length(DREventRange),1), 0.5*ones(length(DREventRange),1)];
ControlStrategy{1} =  kWTree.TestingInput(DREventRange,11:13);
ControlStrategy{2} =  kWTree.TestingInput(DREventRange,11:13);
ControlStrategy{3} =  kWTree.TestingInput(DREventRange,11:13);
% ControlStrategy{2} = [8*ones(length(DREventRange),1), 25*ones(length(DREventRange),1), 0.6*ones(length(DREventRange),1)];
% ControlStrategy{3} = [7*ones(length(DREventRange),1), 27*ones(length(DREventRange),1), 0.7*ones(length(DREventRange),1)];

%% Predict results during DR Event step by step for all the strategies

ZoneTempAllStrat = cell(1,NoOfControlStrat);
BuildPowerAllStrat = cell(1,NoOfControlStrat);

for ControlIdx = 1:NoOfControlStrat
    
    kWTree.DRTestingInput = kWTree.TestingInput;
    kWTree.DRTestingInput(DREventRange,11:13) = ControlStrategy{ControlIdx};
    
    for OutputVarIdx = 1:NoOfZones
       
        ThermalTree{OutputVarIdx}.DRTestingInput = ThermalTree{OutputVarIdx}.TestingInput;
        ThermalTree{OutputVarIdx}.DRTestingInput(DREventRange,11:13) = ControlStrategy{ControlIdx};
        
    end
    
    ZoneTemp = zeros(length(DREventRange), NoOfZones);
    BuildPower = zeros(length(DREventRange), 1);
    
    for DRidx = 1:length(DREventRange)
        
        for OutputVarIdx = 1:NoOfZones
            
            % Update buildpower in thermal trees inputs
            if DRidx>1
                for idi = 0:OrderOfAR-1
                    ThermalTree{OutputVarIdx}.DRTestingInput(DREventRange(DRidx)+idi, end-idi) = BuildPower(DRidx-1,1);
                end
            end
            
            TestZoneTemp = ThermalTree{OutputVarIdx}.DRTestingInput(DREventRange(DRidx),:);
            ZoneTemp(DRidx,OutputVarIdx) = predict(ThermalTree{OutputVarIdx}.boosttree, TestZoneTemp);
            
            % Update zone temp in kW tree inputs
            kWTree.DRTestingInput(DREventRange(DRidx),end-OrderOfAR(1+ARinInput*15)-19+OutputVarIdx) = ZoneTemp(DRidx, OutputVarIdx);
            
            % Update zone temp in thermal trees inputs
            for idi = 1:OrderOfAR
                ThermalTree{OutputVarIdx}.DRTestingInput(DREventRange(DRidx)+idi, end-OrderOfAR+1-idi) = ZoneTemp(DRidx, OutputVarIdx);
            end
            
        end
        
        TestBuildPower = kWTree.DRTestingInput(DREventRange(DRidx),:);
        BuildPower(DRidx,1) = predict(kWTree.boosttree, TestBuildPower);
        
        % Update buildpower in kW tree inputs
        for idi = 1:OrderOfAR
            kWTree.DRTestingInput(DREventRange(DRidx)+idi, end+1-idi) = BuildPower(DRidx,1);
        end
    end
    
    ZoneTempAllStrat{ControlIdx} = ZoneTemp;
    BuildPowerAllStrat{ControlIdx} = BuildPower;
    
end

%% Performance Analysis

figure; hold on;
title('Control Inputs');
h11 = plot(1:length(DREventRange), ControlStrategy{1}(:,1), 'ob');
h12 = plot(1:length(DREventRange), ControlStrategy{1}(:,2), '-b');
h13 = plot(1:length(DREventRange), ControlStrategy{1}(:,3), '+b');

h21 = plot(1:length(DREventRange), ControlStrategy{2}(:,1), 'or');
h22 = plot(1:length(DREventRange), ControlStrategy{2}(:,2), '-r');
h23 = plot(1:length(DREventRange), ControlStrategy{2}(:,3), '+r');

h31 = plot(1:length(DREventRange), ControlStrategy{3}(:,1), 'og');
h32 = plot(1:length(DREventRange), ControlStrategy{3}(:,2), '-g');
h33 = plot(1:length(DREventRange), ControlStrategy{3}(:,3), '+g');

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
h4 = plot(1:length(DREventRange), kWTree.TestingOutput(DREventRange), '--c', 'MarkerSize', 2);
legend([h1, h2, h3, h4], 'S1', 'S2', 'S3', 'EnergyPlus', 'Location', 'Best')

% figure; hold on;
% plot(brtreeOutput(DREventRange), 'r')
% plot(BuildPower, 'b')
% plot(kWTree.TestingOutput(DREventRange), 'g')