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

% Input Variables
InputData = {};

% Training Features without autoregressive contribution
% Specify the features from EnergyPlus .idf output variables
% TrainingData{end+1}.Name = '';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](TimeStep)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Air System Sensible Heating Rate [W](TimeStep)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Air Heat Balance Air Energy Storage Rate [W](TimeStep)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Total Internal Total Heating Rate [W](TimeStep)';
% InputData{end+1}.Name = 'Environment:Site Direct Solar Radiation Rate per Area [W/m2](TimeStep)';
InputData{end+1}.Name = 'FRONT-1:Surface Outside Face Incident Solar Radiation Rate per Area [W/m2](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](TimeStep)';
InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](TimeStep)';
InputData{end+1}.Name = 'SPACE1-1:Zone People Occupant Count [](TimeStep)';
InputData{end+1}.Name = 'SPACE1-1:Zone Lights Total Heating Energy [J](TimeStep)';
InputData{end+1}.Name = 'SPACE1-1 BASEBOARD:Baseboard Total Heating Rate [W](TimeStep)';

for idx = 1:size(InputData,2)
    for idy = 1:size(RawData,2)
        if strcmp(RawData{1,idy}, InputData{idx}.Name)
            InputData{idx}.Data = RawData(StartIndex:end,idy);
        end
    end
end

NoOfDataPoints = size(InputData{1}.Data,1);

% Reference for day of week
% Example: Start Day  = Monday
% Mon = 0, Tue = 1, Wed = 2, Thur = 3, Fri = 4, Sat = 5, Sun = 6

NoOfDays = NoOfDataPoints/(24*60/TimeStep);
InputData{end+1}.Name = 'Day';

x1 = [0:NoOfDataPoints-1]'; %#ok<NBRAK>
x2 = mod(x1,(24*60/TimeStep));
InputData{end}.Data = mod((x1-x2)/(24*60/TimeStep),7);

% Time of day
InputData{end+1}.Name = 'Time';
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
OutputData{end+1}.Name = 'SPACE1-1:Zone Air Temperature [C](TimeStep)';
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
TestingOutput = Output(1+(24*60/TimeStep)*TrainingDays:end,:);

%% Optimal ARMAX model
% Caution training data without autoregression features should be used
% i.e. OrderOfAR = 0;
NoOfInputs = size(InputData,2);

ARMAXTrainingdata = iddata(TrainingOutput, TrainingInput, 3600);
ARMAXTestingdata = iddata(TestingOutput, TestingInput, 3600);

% V = arxstruc(ARMAXTestingdata, ARMAXTestingdata, struc(10:5:20, 1*ones(1, NoOfInputs), 0*ones(1, NoOfInputs)));
% V = arxstruc(ARMAXTrainingdata, ARMAXTestingdata, struc(100:25:500, 1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0));
% V = arxstruc(ARMAXTrainingdata, ARMAXTestingdata, struc(1:10, 2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0));
% nn = selstruc(V,0);

% na = 0:5:25; nb = 1:5:26; nc = 0:5:25; nk = 0;
na = OrderOfAR; nb = OrderOfAR+1; nc = OrderOfAR; nk = 0;

models = cell(1,length(na));
MSE = zeros(1,length(na));
for idx = 1:length(na)
%     for ib = 1:length(nb)
%         for ic = 1:length(nc)
            models{idx} = armax(ARMAXTrainingdata, [na(idx), [nb(idx)*ones(1, NoOfInputs-2) 1 1], nc(idx), nk*ones(1, NoOfInputs)],...
                'Focus','prediction','Display','off');
            MSE(idx) = models{idx}.Report.Fit.MSE;
            disp(['Order of Regression:' num2str(OrderOfAR(idx))])
%         end
%     end
end


% models = stack(1, models{:});
% compare(ARMAXTrainingdata, models)
% compare(ARMAXTestingdata, models{1,1,1});

%% Predict results

% ARMAXOutput = sim(models, TestingInput);                                  % Fails to work
% ARMAXOutput = SimulateARMAX(models, TestingInput, TestingOutput);         % Again, the results are slightly different

% Inefficient Approach
% keyboard
% h = figure(4);
% axesObjs = get(h, 'Children');  %axes handles
% dataObjs = get(axesObjs, 'Children'); %handles to low-level graphics objects in axes
% linedataObjs = get(dataObjs, 'Children');
% ARMAXOutput = linedataObjs{1}.YData;
% ActualOutput = linedataObjs{2}.YData;

% Best Approach to predict using ARMAX
ARMAXOutput = cell(1,length(na));
ARMAXNRMSE = zeros(1,length(na));
ActualOutput = TestingOutput;
for idx = 1:length(na)
%     for ib = 1:length(nb)
%         for ic = 1:length(nc)
            ARMAXOutput{idx} = predict(models{idx}, ARMAXTestingdata, 1);
            ARMAXNRMSE(idx) = sqrt(mean((ARMAXOutput{idx}.OutputData-ActualOutput).^2))/mean(ActualOutput);
%         end
%     end
end
% 
figure; hold on;
idAR = 5;
title(['Order of AR: na = ' num2str(OrderOfAR(idAR))]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'r');
h2 = plot(1:length(ActualOutput), ARMAXOutput{idAR}.OutputData, 'b');
legend([h1, h2], 'Actual', ['ARMAX ' num2str(ARMAXNRMSE(idAR),2)])

figure; hold on;
title(['Timestep: ' num2str(TimeStep)]);
plot(OrderOfAR, ARMAXNRMSE);
