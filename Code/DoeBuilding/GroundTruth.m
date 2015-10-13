%% Read the output file

filenameTrain = 'LargeOfficeFUN2012.csv';
[~,~,RawDataTrain] = xlsread(filenameTrain);

file{1} = 'LargeOfficeOPT3.csv';
file{2} = 'LargeOfficeOPT10.csv';
file{3} = 'LargeOfficeOPT11.csv';

INP = cell(1,3);
OUTP = cell(1,3);

for idi = 1:3
    
    filenameTest = file{idi};
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
                
                InputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
                
            end
        end
    end
    
    NoOfTestDataPoints = size(InputData{1}.TestData,1);
    
    if ARinInput
        for idx = 1:OrderOfAR %#ok<UNRCH>
            for idname = 1:size(InputData,2)
                for idy = 1:size(RawDataTrain,2)
                    if strcmp(RawDataTrain{1,idy}, InputData{idname}.Name)
                        InputData{end+1}.Name = [InputData{idname}.Name '(k-' num2str(idx) ')'];
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
                OutputData{idx}.TestData = RawDataTest(StartIndex:end,idy);
            end
        end
    end
    
    % Preprocess training and testing data
    
    NoOfFeatures = size(InputData,2);
    TestingInput = zeros(NoOfTestDataPoints, NoOfFeatures);
    
    for idx = 1:NoOfFeatures
        if iscell(InputData{idx}.TestData)
            TestingInput(:,idx) = cell2mat(InputData{idx}.TestData);
        else
            TestingInput(:,idx) = InputData{idx}.TestData;
        end
    end
    
    TestingOutput = cell2mat(OutputData{1}.TestData);
    TestingInput(:,8) = round(TestingInput(:,8),2);
    
    INP{idi} = TestingInput;
    OUTP{idi} = TestingOutput;
end


%% Select a day for DR Event from 2:31 (data from day 1 will be used for the lag variabales)

DREventRange = 175:198;
for idi = 1:3
    PowerGroundTruth{idi} = OUTP{idi}(DREventRange);
    DefaultControlStrategy{idi} = INP{idi}(DREventRange,11:13);
    
end
