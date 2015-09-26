%% Read the output file

clear

filename = '5ZoneSteamBaseboard.csv';
[~,~,RawData] = xlsread(filename);

% First 48*60/TimeStep numeric entries in the excel file correspond to design days
% These must be excluded. Higher start index can be chosen to account for
% autoregrssive part

TimeStep = 60; % In mins
OrderOfAR = (0:1:20)*60/TimeStep; % less than 24 hrs here
StartIndex = 1+2*24*60/TimeStep+24*60/TimeStep+1; % 1 for string names, 2 days for design days data, then autoregressive terms, then 1 for next index

%% Organize the data

rtree = cell(1, length(OrderOfAR));
brtree = cell(1, length(OrderOfAR));

rtreeNRMSE = zeros(1, length(OrderOfAR));
brtreeNRMSE = zeros(1, length(OrderOfAR));

rtreeOutput = cell(1, length(OrderOfAR));
brtreeOutput = cell(1, length(OrderOfAR));

for idAR = 1:length(OrderOfAR)
    disp(['Order of Regression:' num2str(OrderOfAR(idAR))])
    % Input Variables
    InputData = {};
    
    % Training Features without autoregressive contribution
    % Specify the features from EnergyPlus .idf output variables
    % TrainingData{end+1}.Name = '';
    InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](TimeStep)'; %#ok<SAGROW>
    % InputData{end+1}.Name = 'SPACE1-1:Zone Air System Sensible Heating Rate [W](TimeStep)';
    % InputData{end+1}.Name = 'SPACE1-1:Zone Air Heat Balance Air Energy Storage Rate [W](TimeStep)';
    % InputData{end+1}.Name = 'SPACE1-1:Zone Total Internal Total Heating Rate [W](TimeStep)';
    % InputData{end+1}.Name = 'Environment:Site Direct Solar Radiation Rate per Area [W/m2](TimeStep)';
    InputData{end+1}.Name = 'FRONT-1:Surface Outside Face Incident Solar Radiation Rate per Area [W/m2](TimeStep)'; %#ok<SAGROW>
    InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](TimeStep)'; %#ok<SAGROW>
    InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](TimeStep)'; %#ok<SAGROW>
    InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](TimeStep)'; %#ok<SAGROW>
    InputData{end+1}.Name = 'SPACE1-1:Zone People Occupant Count [](TimeStep)'; %#ok<SAGROW>
    InputData{end+1}.Name = 'SPACE1-1:Zone Lights Total Heating Energy [J](TimeStep)'; %#ok<SAGROW>
    InputData{end+1}.Name = 'SPACE1-1 BASEBOARD:Baseboard Total Heating Rate [W](TimeStep)'; %#ok<SAGROW>
    
    
    for idx = 1:size(InputData,2)
        for idy = 1:size(RawData,2)
            if strcmp(RawData{1,idy}, InputData{idx}.Name)
                InputData{idx}.Data = RawData(StartIndex:end,idy);
            end
        end
    end
    
    NoOfDataPoints = size(InputData{1}.Data,1);
    
    for idx = 1:OrderOfAR(idAR)
        for idname = 1:size(InputData,2)
            for idy = 1:size(RawData,2)
                if strcmp(RawData{1,idy}, InputData{idname}.Name)
                    InputData{end+1}.Name = [InputData{idname}.Name '(k-' num2str(idx) ')']; %#ok<SAGROW>
                    InputData{end}.Data = RawData(StartIndex-idx:StartIndex-idx+NoOfDataPoints-1,idy);
                end
            end
        end
    end
    
    % Training Features for previous time stances of desired output
    % 'SPACE1-1:Zone Air Temperature [C](TimeStep)';
    
    ARVariable.Name = 'SPACE1-1:Zone Air Temperature [C](TimeStep)';
    
    for idx = 1:OrderOfAR(idAR)
        for idy = 1:size(RawData,2)
            if strcmp(RawData{1,idy}, ARVariable.Name)
                InputData{end+1}.Name = [ARVariable.Name '(k-' num2str(idx) ')']; %#ok<SAGROW>
                InputData{end}.Data = RawData(StartIndex-idx:StartIndex-idx+NoOfDataPoints-1,idy);
            end
        end
    end
    % Reference for day of week
    % Example: Start Day  = Monday
    % Mon = 0, Tue = 1, Wed = 2, Thur = 3, Fri = 4, Sat = 5, Sun = 6
    
    NoOfDays = NoOfDataPoints/(24*60/TimeStep);
    InputData{end+1}.Name = 'Day'; %#ok<SAGROW>
    
    x1 = [0:NoOfDataPoints-1]'; %#ok<NBRAK>
    x2 = mod(x1,(24*60/TimeStep));
    InputData{end}.Data = mod((x1-x2)/(24*60/TimeStep),7);
    
    % Time of day
    InputData{end+1}.Name = 'Time'; %#ok<SAGROW>
    for idy = 1:size(RawData,2)
        if strcmp(RawData{1,idy}, 'Date/Time')
            InputData{end}.Data = RawData(StartIndex:end,idy);
            chartime = char(InputData{end}.Data);
            InputData{end}.Data = str2num(chartime(:,9:10))*60+str2num(chartime(:,12:13)); %#ok<ST2NM>
        end
    end
    
    % Output Variables
    NoOfOutput = 1;
    OutputData = {};
    OutputData{end+1}.Name = 'SPACE1-1:Zone Air Temperature [C](TimeStep)'; %#ok<SAGROW>
    for idx = 1:NoOfOutput
        for idy = 1:size(RawData,2)
            if strcmp(RawData{1,idy}, OutputData{idx}.Name)
                OutputData{idx}.Data = RawData(StartIndex:end,idy);
            end
        end
    end
    
    %% Divide into training and testing data
    
    NoOfFeatures = size(InputData,2);
    Input = zeros(NoOfDataPoints, NoOfFeatures);
    for idx = 1:NoOfFeatures
        if iscell(InputData{idx}.Data)
            Input(:,idx) = cell2mat(InputData{idx}.Data);
        else
            Input(:,idx) = InputData{idx}.Data;
        end
    end
    
    TrainingDays = 60;
    TrainingInput = Input(1:(24*60/TimeStep)*TrainingDays,:);
    TestingInput = Input(1+(24*60/TimeStep)*TrainingDays:end,:);
    
    Output = cell2mat(OutputData{1}.Data);
    TrainingOutput = Output(1:(24*60/TimeStep)*TrainingDays,:);
    
    %% Fit regression tree
    
    rtree{idAR} = fitrtree(TrainingInput, TrainingOutput, 'MinLeafSize',20);
    [~,~,~,bestLevel] = cvloss(rtree{idAR}, 'SubTrees', 'all', 'KFold', 5);
    % view(rtree, 'Mode', 'graph');
    
    % prunedrtree{idAR} = prune(rtree, 'Level', bestLevel);
    % view(prunedtree, 'Mode', 'graph');
    
    
    %% Fit boosted tree
    
    brtree{idAR} = fitensemble(TrainingInput, TrainingOutput, 'LSBoost', 500, 'Tree');
    
    %% Predict results
    
    ActualOutput = Output(1+(24*60/TimeStep)*TrainingDays:end,:);
    
    rtreeOutput{idAR} = predict(rtree{idAR}, TestingInput);
    brtreeOutput{idAR} = predict(brtree{idAR}, TestingInput);
    
    rtreeNRMSE(idAR) = sqrt(mean((rtreeOutput{idAR}-ActualOutput).^2))/mean(ActualOutput);
    brtreeNRMSE(idAR) = sqrt(mean((brtreeOutput{idAR}-ActualOutput).^2))/mean(ActualOutput);
    
end

%% Plots
figure; hold on; idAR = 1;
title(['Order of AR = ' num2str(OrderOfAR(idAR))]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'b');
h2 = plot(1:length(ActualOutput), rtreeOutput{idAR}, 'r');
h3 = plot(1:length(ActualOutput), brtreeOutput{idAR}, '--g');
% h4 = plot(1:length(ActualOutput), ActualOutput, 'b');
legend([h1, h2, h3], 'Actual', ['Single Tree ' num2str(rtreeNRMSE(idAR),2)], ['Boosted Tree ' num2str(brtreeNRMSE(idAR),2)])

% figure; hold on;
% title(['Timestep: ' num2str(TimeStep)]);
% h1 = plot(OrderOfAR, rtreeNRMSE);
% h2 = plot(OrderOfAR, brtreeNRMSE);
% legend([h1, h2], 'Single Tree', 'Boosted Tree')

