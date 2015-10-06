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
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];
XDR = round(XDR,2);

YDR = WholeBuildingFacilityTotalElectricDemandPowerWTimeStep(2:end);
YDR = round(YDR,-4);

XDRctrl = [CLGSETP_SCHScheduleValueTimeStep(2:end), ...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    BLDG_LIGHT_SCHScheduleValueTimeStep(2:end)];
XDRctrl = round(XDRctrl,2);

lag_kw = lagmatrix(YDR,[1,2,3,4,5,6]);
lag_kw_nanidx = find(isnan(lag_kw));
lag_kw(lag_kw_nanidx) = 0;

% Augment training matrix with lagged kw columns
XDR = [XDR,lag_kw];

% Column names and indicies of the columns which are categorical

colnames={'basezat','boiler','chws1','chws2','corebzat','coremzat'...
    ,'coretzat','dow','gfplenum','htgsetp','hwsetp','mfplenum','outdry','outhum'...
    ,'outwet','peribot1zat','peribot2zat','peribot3zat','peribot4zat','perimid1zat'...
    ,'perimid2zat','perimid3zat','perimid4zat','peritop1zat','peritop2zat'...
    ,'peritop3zat','peritop4zat','tod','topplenum','windir','winspeed'...
    ,'lagkw1','lagkw2','lagkw3','lagkw4','lagkw5','lagkw6'};
catcol = [11,28];


disp('Done.');

%% Start Tree Regression
disp('Learning Regression Tree');

minleaf = 5;   % minimium number of leaf node observations
tic
drtree2k12 = fitrtree(XDR,YDR,'PredictorNames',colnames,'ResponseName','Total Power','CategoricalPredictors',catcol,'MinLeafSize',minleaf);
toc

% predict on training and testing data and plot the fits
[Yfit,node] = resubPredict(drtree2k12);

% RMSE
[a,b]=rsquare(YDR,Yfit);
fprintf('Training RMSE(W): %.2f, R2: %.3f, RMSE/peak: %.4f, CV: %.2f \n\n'...
    ,b,a,(b/max(YDR)),(100*b/mean(YDR)));

% Need to find the indices of the nodes of the tree which are
% leaves i.e zero children in the left and right branches of the node.

leaf_index = find((drtree2k12.Children(:,1)==0)&(drtree2k12.Children(:,2)==0));
numleafs = length(leaf_index);
fprintf('The tree has %d leaf nodes \n',numleafs);

%{
    For each leaf of the tree:
        1) Obtain the indices and hence the values of the data points in the
        partition
        2) Obtain and store the prediction from tree 1 ( use NodeMean)
%}


for ii=1:numleafs
    
    % find indices of samples which end up in this leaf
    dr12(ii).leaves = {find(node==leaf_index(ii))};
    
    % mean prediction at this leaf
    dr12(ii).mean = drtree2k12.NodeMean(leaf_index(ii));
    
    % the control variables sample values which contribute to this leaf (support)
    dr12(ii).xdata = {XDRctrl(dr12(ii).leaves{1,1},:)};
    
    dr12(ii).xtree = {XDR(dr12(ii).leaves{1,1},:)};
    
    % the response variable value which contribute to this leaf
    dr12(ii).ydata = {YDR(dr12(ii).leaves{1,1})};
    
    % train a linear model 
    tbl = table(dr12(ii).xdata{1,1}(:,1),dr12(ii).xdata{1,1}(:,2)...
        ,dr12(ii).xdata{1,1}(:,3),dr12(ii).ydata{1,1},'VariableNames'...
        ,{'CLG','CHWS','LIT','kW'});
    dr12(ii).mdl =  fitlm(tbl,'kW~CLG+CHWS+LIT');
    %dr12(ii).mdl = {LinearModel.fit(dr12(ii).xdata{1,1},dr12(ii).ydata{1,1})};  
    
end

%% Resolve rank deficient linear models
% train only between functional testing periods

% todidx=find((EMScurrentTimeOfDayTimeStep>=15) & ...
%     (EMScurrentTimeOfDayTimeStep<=17));
% 
% Xtrain = XDR(todidx,:);
% Xctrl = XDRctrl(todidx,:);
% Ytrain = YDR(todidx);
% 
% disp('Done.');

% %% Start Tree Regression
% disp('Learning Regression Tree');
% 
% minleaf = 5;   % minimium number of leaf node observations
% tic
% drtree2k12tod = fitrtree(Xtrain,Ytrain,'PredictorNames',colnames,'ResponseName','Total Power','CategoricalPredictors',catcol,'MinLeafSize',minleaf);
% toc
% 
% % predict on training and testing data and plot the fits
% [Yfittod,nodetod] = resubPredict(drtree2k12tod);
% 
% % RMSE
% [a,b]=rsquare(Ytrain,Yfittod);
% fprintf('Training RMSE(W): %.2f, R2: %.3f, RMSE/peak: %.4f, CV: %.2f \n\n'...
%     ,b,a,(b/max(Ytrain)),(100*b/mean(Ytrain)));
% 
% % Need to find the indices of the nodes of the tree which are
% % leaves i.e zero children in the left and right branches of the node.
% 
% leaf_index = find((drtree2k12.Children(:,1)==0)&(drtree2k12.Children(:,2)==0));
% numleafs = length(leaf_index);
% fprintf('The tree has %d leaf nodes \n',numleafs);
% 
% %{
%     For each leaf of the tree:
%         1) Obtain the indices and hence the values of the data points in the
%         partition
%         2) Obtain and store the prediction from tree 1 ( use NodeMean)
% %}
% 
% 
% for ii=1:numleafs
%     
%     % find indices of samples which end up in this leaf
%     dr12tod(ii).leaves = {find(nodetod==leaf_index(ii))};
%     
%     % mean prediction at this leaf
%     dr12tod(ii).mean = drtree2k12tod.NodeMean(leaf_index(ii));
%     
%     % the control variables sample values which contribute to this leaf (support)
%     dr12tod(ii).xdata = {Xctrl(dr12tod(ii).leaves{1,1},:)};
%     
%     % the response variable value which contribute to this leaf
%     dr12tod(ii).ydata = {Ytrain(dr12tod(ii).leaves{1,1})};
%     
%     % train a linear model 
%     tbl = table(dr12tod(ii).xdata{1,1}(:,1),dr12tod(ii).xdata{1,1}(:,2)...
%         ,dr12tod(ii).xdata{1,1}(:,3),dr12tod(ii).ydata{1,1},'VariableNames'...
%         ,{'CLG','CHWS','LIT','kW'});
%     dr12tod(ii).mdl =  fitlm(tbl,'kW~CLG+CHWS+LIT');
%     %dr12(ii).mdl = {LinearModel.fit(dr12(ii).xdata{1,1},dr12(ii).ydata{1,1})};  
%     
% end
