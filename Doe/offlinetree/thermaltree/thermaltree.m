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

holdout = 0.8;
total_samples = length(XDR);

train_samples = floor(holdout*total_samples);


XDRtrain = XDR(1:train_samples, :);
XDRctrltrain = XDRctrl(1:train_samples, :);
OutputVarstrain = OutputVars(1:train_samples,:);

XDRtest = XDR(train_samples+1:end,:);
XDRctrltest = XDRctrl(train_samples+1:end,:);
OutputVarstest = OutputVars(train_samples+1:end,:);

disp('Done.');

%{
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
        thermal(jj).dr12(kk).xdata = {XDRctrltrain(thermal(jj).dr12(kk).leaves{1,1},:)};
        
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
%}

load compare_control.mat

Yorig = OutputVarstest(:,12);
lag_tempt = lagmatrix(Yorig,[1,2,3,4,5]);
lag_temp_nanidxt = find(isnan(lag_tempt));
lag_tempt(lag_temp_nanidxt) = 0;

% Augment training matrix with lagged kw columns
XDRtest = [XDRtest,lag_tempt];

leaftherm = predict(thermal(12).toptree,XDRtest);

Yout = zeros(length(leaftherm),1);

for nn = 1:length(leaftherm)
for thermidx = 1:length(thermal(12).dr12)
    if(leaftherm(nn) == thermal(12).dr12(thermidx).mean)
        break;
    end
end

clgset = XDRctrltest(nn,1);
cwset =  XDRctrltest(nn,2);
litset =  XDRctrltest(nn,3);

% thermidx is the leaf node
 Yout(nn) = thermal(12).dr12(thermidx).mdl{1,1}.Coefficients{1,1} + ...
            (thermal(12).dr12(thermidx).mdl{1,1}.Coefficients{2,1}*clgset) + ...
            (thermal(12).dr12(thermidx).mdl{1,1}.Coefficients{3,1}*cwset) + ...
            (thermal(12).dr12(thermidx).mdl{1,1}.Coefficients{4,1}*litset);

end

