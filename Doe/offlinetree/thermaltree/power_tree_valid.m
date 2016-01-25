clc 
clear 
close all

%% Prepare Training data, i.e from 2012
disp('Preparing data..');

load FUNtest_data.mat

XDR = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end),...
    PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end),...                   
    PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end),... 
    EMScurrentTimeOfDayTimeStep(2:end),...
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end), ...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    BLDG_LIGHT_SCHScheduleValueTimeStep(2:end)];
XDR = round(XDR,2);

YDR = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);
YDR = round(YDR,-4);

lag_kw = lagmatrix(YDR,[1,2,3,4,5,6]);
lag_kw_nanidx = find(isnan(lag_kw));
lag_kw(lag_kw_nanidx) = 0;

% Augment training matrix with lagged kw columns
XDR = [XDR,lag_kw];

holdout = 0.8;
total_samples = length(XDR);

train_samples = floor(holdout*total_samples);


XDRtrain = XDR(1:train_samples, :);
OutputVarstrain = YDR(1:train_samples,:);

XDRtest = XDR(train_samples+1:end,:);
OutputVarstest = YDR(train_samples+1:end,:);

% Column names and indicies of the columns which are categorical

colnames={'basezat','boiler','chws1','chws2','corebzat','coremzat'...
    ,'coretzat','dow','gfplenum','htgsetp','hwsetp','mfplenum','outdry','outhum'...
    ,'outwet','peribot1zat','peribot2zat','peribot3zat','peribot4zat','perimid1zat'...
    ,'perimid2zat','perimid3zat','perimid4zat','peritop1zat','peritop2zat'...
    ,'peritop3zat','peritop4zat','tod','topplenum','windir','winspeed',...
    'clg','cwloop','light','lagkw1','lagkw2','lagkw3','lagkw4','lagkw5','lagkw6'};
catcol = [11,28];


disp('Done.');

%% Start Tree Regression
disp('Learning Regression Tree');

minleaf = 5;   % minimium number of leaf node observations
tic
drtree2k12 = fitrtree(XDRtrain,OutputVarstrain,'PredictorNames',colnames,'ResponseName','Total Power','CategoricalPredictors',catcol,'MinLeafSize',minleaf);
toc

% predict on training and testing data and plot the fits
[Yfit,node] = resubPredict(drtree2k12);

% RMSE
[a,b]=rsquare(OutputVarstrain,Yfit);
fprintf('Training RMSE(W): %.2f, R2: %.3f, RMSE/peak: %.4f, CV: %.2f \n\n'...
    ,b,a,(b/max(OutputVarstrain)),(100*b/mean(OutputVarstrain)));

Ypredict = predict(drtree2k12,XDRtest);

% RMSE
[a,b]=rsquare(OutputVarstest,Ypredict);
fprintf('Single tree RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(OutputVarstest)),(100*b/(max(OutputVarstest)-min(OutputVarstest))));


tic;
Rforest = TreeBagger(500,XDRtrain,OutputVarstrain,'Method','regression','MinLeaf',minleaf);
toc;
Ybag = predict(Rforest,XDRtest);

% RMSE
[a,b]=rsquare(OutputVarstest,Ybag);
fprintf('Random Forest RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(OutputVarstest)),(100*b/(max(OutputVarstest)-min(OutputVarstest))));

