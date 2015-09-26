%% Read the output file
clear

filenameTrain = 'LargeOfficeFUN2012.csv';
[~,~,RawDataTrain] = xlsread(filenameTrain);

filenameTest = 'LargeOfficeFUN2013.csv';
[~,~,RawDataTest] = xlsread(filenameTest);

TimeStep = 5; % In mins
OrderOfAR = 8; %0.5*60/TimeStep; % less than 24 hrs here
StartIndex = 1+24*60/TimeStep+1; % 1 for string names, then autoregressive terms, then 1 for next index

%% Organize the data

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
InputData{end+1}.Name = 'CW-LOOP-TEMP-SCHEDULE:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'CLGSETP_SCH:Schedule Value [](TimeStep)';
InputData{end+1}.Name = 'BLDG_LIGHT_SCH:Schedule Value [](TimeStep)';

InputData{end+1}.Name = 'COOLSYS1 CHILLER 1:Chiller Evaporator Outlet Temperature [C](TimeStep)';
% InputData{end+1}.Name = 'COOLSYS1 CHILLER 2:Chiller Evaporator Outlet Temperature [C](TimeStep)';
InputData{end+1}.Name = 'HEATSYS1 BOILER:Boiler Outlet Temperature [C](TimeStep) ';

InputData{end+1}.Name = 'EMS:currentDayOfMonth [](TimeStep)';
InputData{end+1}.Name = 'EMS:currentDayOfWeek [](TimeStep)';
InputData{end+1}.Name = 'EMS:currentTimeOfDay [](TimeStep)';

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

%% Optimal ARMAX model
% Caution training data without autoregression features should be used
% i.e. OrderOfAR = 0;
NoOfInputs = size(InputData,2);

ARMAXTrainingdata = iddata(TrainingOutput, TrainingInput, 3600);
ARMAXTestingdata = iddata(TestingOutput, TestingInput, 3600);

na = OrderOfAR; nb = OrderOfAR+1; nc = OrderOfAR; nk = 0;

models = cell(length(na));

for ix = 1:length(na)
%     for ib = 1:length(nb)
%         for ic = 1:length(nc)
            models{ix} = armax(ARMAXTrainingdata, [na(ix), nb(ix)*ones(1, NoOfInputs), nc(ix), nk*ones(1, NoOfInputs)],...
                'Focus','prediction','Display','off');
            disp(['Order of Regression:' num2str(OrderOfAR(ix))])
%             [ia,ib,ic]
%         end
%     end
end

%% Predict results on testing set
ARMAXOutput = cell(length(na));
ARMAXNRMSETest = zeros(1,length(na));
ActualOutput = TestingOutput;
for ix = 1:length(na)
%     for ib = 1:length(nb)
%         for ic = 1:length(nc)
            ARMAXOutput{ix} = predict(models{ix}, ARMAXTestingdata, 1);
            ARMAXNRMSETest(ix) = sqrt(mean((ARMAXOutput{ix}.OutputData-ActualOutput).^2))/mean(ActualOutput);
%             [ia,ib,ic]
%         end
%     end
end

figure; hold on;
title(['Testing Data July 2013, Order of AR = ' num2str(OrderOfAR)]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'b');
h2 = plot(1:length(ActualOutput), ARMAXOutput{ix}.OutputData, 'r');
legend([h1, h2], 'Actual', ['ARMAX ' num2str(ARMAXNRMSETest(ix),2)])

figure; hold on;
title(['Testing Data July 2013, Order of AR = ' num2str(OrderOfAR)]);
h1 = plot(ActualOutput, ActualOutput, '--b', 'MarkerSize', 2);
h2 = plot(ARMAXOutput{ix}.OutputData, ActualOutput, 'dr', 'MarkerSize', 2);
xlabel('Actual Power [W]');
ylabel('Predicted Power [W]');
legend(h2, ['ARMAX ' num2str(ARMAXNRMSETest(ix),2)], 'Location', 'Best')

%% Predict results on training set
ARMAXNRMSETrain = zeros(1,length(na));
ActualOutput = TrainingOutput;
for ix = 1:length(na)
%     for ib = 1:length(nb)
%         for ic = 1:length(nc)
            ARMAXOutput{ix} = predict(models{ix}, ARMAXTrainingdata, 1);
            ARMAXNRMSETrain(ix) = sqrt(mean((ARMAXOutput{ix}.OutputData-ActualOutput).^2))/mean(ActualOutput);
%             [ia,ib,ic]
%         end
%     end
end

figure; hold on;
title(['Training Data July 2012, Order of AR = ' num2str(OrderOfAR)]);
h1 = plot(1:length(ActualOutput), ActualOutput, 'b');
h2 = plot(1:length(ActualOutput), ARMAXOutput{ix}.OutputData, 'r');
legend([h1, h2], 'Actual', ['ARMAX ' num2str(ARMAXNRMSETrain(ix),2)])

figure; hold on;
title(['Training Data July 2012, Order of AR = ' num2str(OrderOfAR)]);
h1 = plot(ActualOutput, ActualOutput, '--b', 'MarkerSize', 2);
h2 = plot(ARMAXOutput{ix}.OutputData, ActualOutput, 'dr', 'MarkerSize', 2);
xlabel('Actual Power [W]');
ylabel('Predicted Power [W]');
legend(h2, ['ARMAX ' num2str(ARMAXNRMSETrain(ix),2)], 'Location', 'Best')