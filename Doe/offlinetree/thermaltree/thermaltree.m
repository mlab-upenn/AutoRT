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
    EnvironmentSiteWindSpeedmsTimeStep(2:end)];
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

XDRctrl = [CLGSETP_SCHScheduleValueTimeStep(2:end), ...
    CWLOOPTEMPSCHEDULEScheduleValueTimeStep(2:end),...
    BLDG_LIGHT_SCHScheduleValueTimeStep(2:end)];
XDRctrl = round(XDRctrl,2);


% Column names and indicies of the columns which are categorical

colnames={'boiler','chws1','chws2','dow','htgsetp','hwsetp'...
    ,'outdry','outhum','outwet','tod','windir','winspeed'};
catcol = [4,10];


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
    
    Xtrain = XDR;
    Ytrain = OutputVars(:,jj);
    
    lag_temp = lagmatrix(Ytrain,[1,2,3,4,5]);
    lag_temp_nanidx = find(isnan(lag_temp));
    lag_temp(lag_temp_nanidx) = 0;
    
    % Augment training matrix with lagged kw columns
    Xtrain = [Xtrain,lag_temp];
    
    colnames={'boiler','chws1','chws2','dow','htgsetp','hwsetp'...
        ,'outdry','outhum','outwet','tod','windir','winspeed', 'lagT1'...
        , 'lagT2', 'lagT3', 'lagT4', 'lagT5'};
    catcol = [4,10];
    
    sprintf('Learning Regression four output %d',jj);
    
    tic
    thermal(jj).toptree = fitrtree(Xtrain,Ytrain,'PredictorNames',colnames,...
        'ResponseName',OutputVarsNames(jj),'CategoricalPredictors',...
        catcol,'MinLeafSize',minleaf);
    toc
    
    % predict on training and testing data and plot the fits
    [Yfit,node] = resubPredict(thermal(jj).toptree);
    thermal(jj).node = node;
        
    % Need to find the indices of the nodes of the tree which are
    % leaves i.e zero children in the left and right branches of the node.
    
    leaf_index = find((thermal(jj).toptree.Children(:,1)==0)&(thermal(jj).toptree.Children(:,2)==0));
    numleafs = length(leaf_index);
    %fprintf('The tree for output %d has %d leaf nodes \n',jj,numleafs);
    
    %{
    For each leaf of the tree:
        1) Obtain the indices and hence the values of the data points in the
        partition
        2) Obtain and store the prediction from tree 1 ( use NodeMean)
    %}
        
    % show the waitbar
    
    h = waitbar(0,'Sythesis Tree'); 

    
    for kk=1:numleafs
        
        progress = kk/numleafs;
        
        waitbar(progress,h,sprintf('Output #%d : Leaf %d of %d',jj, kk, numleafs));
        
        % find indices of samples which end up in this leaf
        thermal(jj).dr12(kk).leaves = {find(node==leaf_index(kk))};
        
        % mean prediction at this leaf
        thermal(jj).dr12(kk).mean = thermal(jj).toptree.NodeMean(leaf_index(kk));
        
        % the control variables sample values which contribute to this leaf (support)
        thermal(jj).dr12(kk).xdata = {XDRctrl(thermal(jj).dr12(kk).leaves{1,1},:)};
        
        % the response variable value which contribute to this leaf
        thermal(jj).dr12(kk).ydata = {Ytrain(thermal(jj).dr12(kk).leaves{1,1})};
        
        %         % train a linear model
        
        choose_cvx = 0;
        
        if(~choose_cvx)
            
            tbl = table(thermal(jj).dr12(kk).xdata{1,1}(:,1),thermal(jj).dr12(kk).xdata{1,1}(:,2)...
                ,thermal(jj).dr12(kk).xdata{1,1}(:,3),thermal(jj).dr12(kk).ydata{1,1},'VariableNames'...
                ,{'CLG','CHWS','LIT','dC'});
            thermal(jj).dr12(kk).mdl =  fitlm(tbl,'dC~CLG+CHWS+LIT');
             thermal(jj).dr12(kk).mdl = {LinearModel.fit(thermal(jj).dr12(kk).xdata{1,1},thermal(jj).dr12(kk).ydata{1,1})};
            
        else
            
            % we will perform a constrained least squares optimization to fit
            % the linear model
            
            A = [thermal(jj).dr12(kk).xdata{1,1}(:,1),...
                thermal(jj).dr12(kk).xdata{1,1}(:,2),...
                thermal(jj).dr12(kk).xdata{1,1}(:,3),...
                ones(length(thermal(jj).dr12(kk).xdata{1,1}(:,3)),1)];
            b = thermal(jj).dr12(kk).ydata{1,1};
            
            n = 4;
            
            cvx_begin
            variable x(n)
            minimize( norm(A*x-b) )
            subject to
            x(1) <= 0
            x(2) <= 0
            x(3) >= 0
            cvx_end
            
            thermal(jj).dr12(kk).mdl.fit = x;
            thermal(jj).dr12(kk).mdl.lab = ['CLG','CWL','LIT','iCEP'];
            
        end
        
    end
    
    close(h)
    
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
