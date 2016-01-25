%{

Variables:

DateTime     clgsetp      gfplenum     outwet       perimid2zat  peritop4zat
basezat      corebzat     htgsetp      peribot1zat  perimid3zat  tod
boiler1      coremzat     hwsetp       peribot2zat  perimid4zat  topplenum
chws1        coretzat     mfplenum     peribot3zat  peritop1zat  tpower
chws2        dom          outdry       peribot4zat  peritop2zat  windir
chwsetp      dow          outhum       perimid1zat  peritop3zat  winspeed


%}

clc
clear
close all

%% Prepare Training data, i.e from 2012
disp('Preparing data..');
load FUNtest_data.mat

XDR = [HEATSYS1BOILERBoilerOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER1ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    COOLSYS1CHILLER2ChillerEvaporatorOutletTemperatureCTimeStep(2:end),...
    EMScurrentDayOfWeekTimeStep(2:end),...
    HTGSETP_SCHScheduleValueTimeStep(2:end),...
    HWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    EnvironmentSiteOutdoorAirDrybulbTemperatureCTimeStep(2:end),...
    EnvironmentSiteOutdoorAirRelativeHumidityTimeStep(2:end),...
    EnvironmentSiteOutdoorAirWetbulbTemperatureCTimeStep(2:end),...
    EMScurrentTimeOfDayTimeStep(2:end),...
    EnvironmentSiteWindDirectiondegTimeStep(2:end),...
    EnvironmentSiteWindSpeedmsTimeStep(2:end),...
    CLGSETP_SCHScheduleValueTimeStep(2:end), ...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    BLDG_LIGHT_SCHScheduleValueTimeStep(2:end)];
XDR = round(XDR,2);

OutputVars = [BASEMENTZoneAirTemperatureCTimeStep(2:end),...
    CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end),...
    CORE_MIDZoneAirTemperatureCTimeStep(2:end),...
    CORE_TOPZoneAirTemperatureCTimeStep(2:end),...
    GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
    MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end),...
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
    TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end)];
OutputVars = round(OutputVars,2);
% Kepp track of the output variable names

OutputVarsNames = ['BASEMENTZoneAirTemperatureCTimeStep(2:end)',...
    'CORE_BOTTOMZoneAirTemperatureCTimeStep(2:end)',...
    'CORE_MIDZoneAirTemperatureCTimeStep(2:end)',...
    'CORE_TOPZoneAirTemperatureCTimeStep(2:end)',...
    'GROUNDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end)',...
    'MIDFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_BOT_ZN_1ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_BOT_ZN_2ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_BOT_ZN_3ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_BOT_ZN_4ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_MID_ZN_1ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_MID_ZN_2ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_MID_ZN_3ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_MID_ZN_4ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_TOP_ZN_1ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_TOP_ZN_2ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_TOP_ZN_3ZoneAirTemperatureCTimeStep(2:end)',...
    'PERIMETER_TOP_ZN_4ZoneAirTemperatureCTimeStep(2:end)',...
    'TOPFLOOR_PLENUMZoneAirTemperatureCTimeStep(2:end)'];

% Column names and indicies of the columns which are categorical

colnames={'boiler','chws1','chws2','dow','htgsetp','hwsetp'...
    ,'outdry','outhum','outwet','tod','windir','winspeed', 'clg','cwloop','light'};
catcol = [4,10];

holdout = 0.7;
total_samples = length(XDR);

train_samples = floor(holdout*total_samples);


XDRtrain = XDR(1:train_samples, :);
OutputVarstrain = OutputVars(1:train_samples,:);

XDRtest = XDR(train_samples+1:end,:);
OutputVarstest = OutputVars(train_samples+1:end,:);

disp('Done.');

%% Start Tree Regression
disp('Learning Regression Trees ...');

%{
 
    For each output variable
    - create the lagged values of the output..
    - add them to input feature vector
    - train the disturbance tree
    - store the synthesis tree for the input
   
%}

minleaf = 5;   % minimium number of leaf node observations


warning off stats:LinearModel:RankDefDesignMat
for jj = 1:size(OutputVars,2)
    
    Xtrain = XDRtrain;
    Ytrain = OutputVarstrain(:,jj);
    
    lag_temp = lagmatrix(Ytrain,[1,2,3,4,5]);
    lag_temp_nanidx = find(isnan(lag_temp));
    lag_temp(lag_temp_nanidx) = 0;
    
    % Augment training matrix with lagged kw columns
    Xtrain = [Xtrain,lag_temp];
    
    colnames={'boiler','chws1','chws2','dow','htgsetp','hwsetp'...
        ,'outdry','outhum','outwet','tod','windir','winspeed', 'clg','cwloop','light','lagT1'...
        , 'lagT2', 'lagT3', 'lagT4', 'lagT5'};
    catcol = [4,10];
    
    sprintf('Learning Regression four output %d',jj);
    
    tic
    thermal(jj).toptree = fitrtree(Xtrain,Ytrain,'PredictorNames',colnames,...
        'ResponseName',OutputVarsNames(jj),'CategoricalPredictors',...
        catcol,'MinLeafSize',minleaf);
    toc
    
    % predict on training and testing data and plot the fits
    [Yfit] = resubPredict(thermal(jj).toptree);
    
end

testdates = DateTime(train_samples+1:end-1);

plotdates = datenum(testdates);


Yorig = OutputVarstest(:,12);

lag_tempt = lagmatrix(Yorig,[1,2,3,4,5]);
lag_temp_nanidxt = find(isnan(lag_tempt));
lag_tempt(lag_temp_nanidxt) = 0;

% Augment training matrix with lagged kw columns
XDRtest = [XDRtest,lag_tempt];

Ypredict = predict(thermal(12).toptree,XDRtest);


% RMSE
[a,b]=rsquare(Yorig,Ypredict);
fprintf('2013(Testing) RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(Yorig)),(100*b/(max(Yorig)-min(Yorig))));

    
Xtrain = XDRtrain;
Ytrain = OutputVarstrain(:,12);

lag_temp = lagmatrix(Ytrain,[1,2,3,4,5]);
lag_temp_nanidx = find(isnan(lag_temp));
lag_temp(lag_temp_nanidx) = 0;

% Augment training matrix with lagged kw columns
Xtrain = [Xtrain,lag_temp];
tic;
B = TreeBagger(200,Xtrain,Ytrain,'Method','regression','MinLeaf',minleaf);
toc;
Ybag = predict(B,XDRtest);

[a,b]=rsquare(Yorig,Ybag);
fprintf('RF RMSE(W): %.2f, R2: %.3f, RMSE/peak %0.4f, NRMSD: %0.2f \n'...
    ,b,a,(b/max(Yorig)),(100*b/(max(Yorig)-min(Yorig))));


figure();
plot(plotdates,Yorig,'k');
hold on;
plot(plotdates,Ypredict,'b');
plot(plotdates,Ybag,'r');
datetick('x','ddd:HH', 'keepticks');
hold off;