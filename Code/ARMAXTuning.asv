%% Read the output file

clear

filename = '5ZoneSteamBaseboard.csv';
[~,~,RawData] = xlsread(filename);

% First 48 numeric entries in the excel file correspond to design days.
% These must be excluded.
StartIndex = 242;

%% Organize the data

% Input Variables
InputData = {};

% Training Features without autoregressive contribution
% Specify the features from EnergyPlus .idf output variables
% TrainingData{end+1}.Name = '';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Drybulb Temperature [C](Hourly)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Air System Sensible Heating Rate [W](Hourly)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Air Heat Balance Air Energy Storage Rate [W](Hourly)';
% InputData{end+1}.Name = 'SPACE1-1:Zone Total Internal Total Heating Rate [W](Hourly)';
% InputData{end+1}.Name = 'Environment:Site Direct Solar Radiation Rate per Area [W/m2](Hourly)';
InputData{end+1}.Name = 'FRONT-1:Surface Outside Face Incident Solar Radiation Rate per Area [W/m2](Hourly)';
InputData{end+1}.Name = 'Environment:Site Outdoor Air Relative Humidity [%](Hourly)';
InputData{end+1}.Name = 'Environment:Site Wind Speed [m/s](Hourly)';
InputData{end+1}.Name = 'Environment:Site Wind Direction [deg](Hourly)';
InputData{end+1}.Name = 'SPACE1-1:Zone People Occupant Count [](Hourly)';
InputData{end+1}.Name = 'SPACE1-1:Zone Lights Total Heating Energy [J](Hourly)';
InputData{end+1}.Name = 'SPACE1-1 BASEBOARD:Baseboard Total Heating Rate [W](Hourly)';

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

NoOfDays = NoOfDataPoints/24;
InputData{end+1}.Name = 'Day';

x1 = [0:NoOfDataPoints-1]';
x2 = mod(x1,24);
InputData{end}.Data = mod((x1-x2)/24,7);

% Time of day
InputData{end+1}.Name = 'Time';
for idy = 1:size(RawData,2)
    if strcmp(RawData{1,idy}, 'Date/Time')
        InputData{end}.Data = RawData(StartIndex:end,idy);
        chartime = char(InputData{end}.Data);
        InputData{end}.Data = str2num(chartime(:,9:10)); %#ok<ST2NM>
    end
end

% Output Variables
NoOfOutput = 1;
OutputData = {};
OutputData{end+1}.Name = 'SPACE1-1:Zone Air Temperature [C](Hourly)';
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
TrainingInput = Input(1:24*TrainingDays,:);
TestingInput = Input(1+24*TrainingDays:end,:);

Output = cell2mat(OutputData{1}.Data);
TrainingOutput = Output(1:24*TrainingDays,:);
TestingOutput = Output(1+24*TrainingDays:end,:);

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
na = 10; nb = 10; nc = 10; nk = 0;

models = cell(length(na),length(nb),length(nc));
MSE = zeros(length(na),length(nb),length(nc));
for ia = 1:length(na)
    for ib = 1:length(nb)
        for ic = 1:length(nc)
            models{ia,ib,ic} = armax(ARMAXTrainingdata, [na(ia), [nb(ib)*ones(1, NoOfInputs-2) 1 1], nc(ic), nk*ones(1, NoOfInputs)]);
            MSE(ia,ib,ic) = models{ia,ib,ic}.Report.Fit.MSE;
            [ia,ib,ic]
        end
    end
end


% models = stack(1, models{:});
% compare(ARMAXTrainingdata, models)
compare(ARMAXTestingdata, models{1,1,1});

%% Predict results

% ARMAXOutput = sim(models, TestingInput);                                  % Fails to work
% ARMAXOutput = SimulateARMAX(models, TestingInput, TestingOutput);         % Again, the results are slightly different

keyboard

h = figure(6);
axesObjs = get(h, 'Children');  %axes handles
dataObjs = get(axesObjs, 'Children'); %handles to low-level graphics objects in axes
linedataObjs = get(dataObjs, 'Children');
ARMAXOutput = linedataObjs{1}.YData;
ActualOutput = linedataObjs{2}.YData;

ARMAXNRMSE = sqrt(mean((ARMAXOutput-ActualOutput).^2))/mean(ActualOutput);
close(h);
figure; hold on;
title(['Order of AR: na = ' num2str(na)]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'r');
h2 = plot(1:length(ActualOutput), ARMAXOutput, 'b');
legend([h1, h2], 'Actual', ['ARMAX ' num2str(ARMAXNRMSE,2)])