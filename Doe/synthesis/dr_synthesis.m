
clc
clear
close all

%% Create an mlepProcess instance and configure it

ep = mlepProcess;
ep.arguments = {'LargeOfficeSYN', 'SPtMasterTable_587017_2013_amy'};
ep.acceptTimeout = 20000; % in milliseconds

VERNUMBER = 2;  % version number of communication protocol (2 as of
% E+ 8.1.0)

% Load the tree and the linear models
disp('Loading offline kW and thermal trees..');
load powertree_ml 
load thermal_ml
disp('Done!');

t1 = datetime('17-Jul-2013 00:00');
t2 = datetime('17-Jul-2013 23:55');
timevec = t1:minutes(5):t2;


%% Start EnergyPlus cosimulation
[status, msg] = ep.start;

if status ~= 0
    error('Could not start EnergyPlus: %s.', msg);
end

%% The main simulation loop

EPTimeStep = 12;
SimDays = 1;
deltaT = (60/EPTimeStep)*60;  % time step = 12 minutes
kStep = 1;  % current simulation step
MAXSTEPS = SimDays*24*EPTimeStep;  % max simulation time = 7 days

clglow = 24;
clghigh = 28;
cwlow = 6.7;
cwhigh = 10;
lilow = 0.6;
lihigh = 1;
minchange = 0.5;

% variables for plotting:
xx = 1:MAXSTEPS;
yyclg = nan(1,MAXSTEPS);
yycw = nan(1,MAXSTEPS);
yylit = nan(1,MAXSTEPS);
listofkwidx = zeros(1,MAXSTEPS);
baseest = zeros(1,MAXSTEPS);

% logdata stores set-points, outdoor temperature, and zone temperature at
% each time step.
numoutvars = 32;
logdata = zeros(MAXSTEPS,numoutvars);


% create a vector to store the lagged values of power and tempratures.
lagkw = zeros(1,6);
lagdC = zeros(19,5);

% define a vector to store indices of leaf nodes for the thermal tree
leaftherm =  zeros(19,1);
leafthermidx = zeros(19,1);

% thermal penalty int he optimization related definitions
P = 1500000; 
tref = 24*ones(19,1);
TA = zeros(19,4); % to store model coefficients

disp('Begining Co-simulation..');

while kStep <= MAXSTEPS
    % Read a data packet from E+
    packet = ep.read;
    if isempty(packet)
        error('Could not read outputs from E+.');
    end
    
    % Parse it to obtain building outputs
    [flag, eptime, outputs] = mlepDecodePacket(packet);
    if flag ~= 0, break; end
    
    % decode outputs
    tpower = round(outputs(1),-4);
    tod = round(outputs(2),2);
    dow = round(outputs(3),2);
    chws1 = round(outputs(4),2);
    chws2 = round(outputs(5),2);
    boiler = round(outputs(6),2);
    basezat = round(outputs(7),2);
    corebzat = round(outputs(8),2);
    coremzat = round(outputs(9),2);
    coretzat = round(outputs(10),2);
    gfplenum = round(outputs(11),2);
    mfplenum = round(outputs(12),2);
    peribot1zat = round(outputs(13),2);
    peribot2zat = round(outputs(14),2);
    peribot3zat = round(outputs(15),2);
    peribot4zat = round(outputs(16),2);
    perimid1zat = round(outputs(17),2);
    perimid2zat = round(outputs(18),2);
    perimid3zat = round(outputs(19),2);
    perimid4zat = round(outputs(20),2);
    peritop1zat = round(outputs(21),2);
    peritop2zat = round(outputs(22),2);
    peritop3zat = round(outputs(23),2);
    peritop4zat = round(outputs(24),2);
    topplenum = round(outputs(25),2);
    outdry = round(outputs(26),2);
    outwet = round(outputs(27),2);
    winspeed = round(outputs(28),2);
    windir = round(outputs(29),2);
    outhum = round(outputs(30),2);
    htgsetp = round(outputs(31),2);
    hwsetp = round(outputs(32),2);
    
    
    forecast_kw = [basezat,boiler,chws1,chws2,corebzat,coremzat...
        ,coretzat,dow,gfplenum,htgsetp,hwsetp,mfplenum,outdry,outhum...
        ,outwet,peribot1zat,peribot2zat,peribot3zat,peribot4zat,perimid1zat...
        ,perimid2zat,perimid3zat,perimid4zat,peritop1zat,peritop2zat...
        ,peritop3zat,peritop4zat,tod,topplenum,windir,winspeed];
    
    forecast_therm = [boiler,chws1,chws2,dow,htgsetp,hwsetp,outdry,outhum...
        ,outwet,tod,windir,winspeed];
    
    % Add previous kW values to the forecast kw values.
    lagkw(end) = tpower;
    lagkw = circshift(lagkw,[1,1]);
    forecast = [forecast_kw,lagkw];
    
    % Add previous therm values to the forecast therm values.
    lagdC(:,end) = [basezat;corebzat;coremzat;coretzat;gfplenum;...
        mfplenum;peribot1zat;peribot2zat;peribot3zat;peribot4zat;perimid1zat...
        ;perimid2zat;perimid3zat;perimid4zat;peritop1zat;peritop2zat...
        ;peritop3zat;peritop4zat;topplenum];
    lagdC = circshift(lagdC,1,2);
    
    % BEGIN Compute next set-points
    dayTime = mod(eptime, 86400);  % time in current day
    
    
    % Baseline Schedule.
    if(dayTime <= 5*3600)

        newclg = 27;
        newcw = 6.7;
        newlit = 0.05;
        SP = [newclg newcw newlit];
    end
    if((dayTime > 5*3600)&&(dayTime <= 6*3600))
        
        newclg = 27;
        newcw = 6.7;
        newlit = 0.1;
        SP = [newclg newcw newlit];
    end
    
    if((dayTime > 6*3600)&&(dayTime <= 7*3600))
        
        newclg = 24;
        newcw = 6.7;
        newlit = 0.1;
        SP = [newclg newcw newlit];
    end
    
    if((dayTime > 7*3600)&&(dayTime <= 8*3600))
        
        newclg = 24;
        newcw = 6.7;
        newlit = 0.3;
        SP = [newclg newcw newlit];
    end
    if((dayTime > 8*3600)&&(dayTime < 15*3600))
        
        newclg = 24;
        newcw = 6.7;
        newlit = 0.9;
        SP = [newclg newcw newlit];
    end
    
    % DR event (3PM-4PM)
    
    if(dayTime >= 15*3600) && (dayTime <= 16*3600)
        
        disp('DR Event Begins..');
        % find the index of the leaf node from which the kw prediction is
        % being generated.
        leafkw = predict(powertree,forecast);
        % kwidx is the leaf index for the model.
        for kwidx = 1:length(dr12)
            if(leafkw == dr12(kwidx).mean)
                break;
            end
        end
        
        % find the index of the leaf nodes of the thermal tree from which
        % each zone temprature is going to be predicted. We will use these
        % indices to figure out the correct linear model constraint to be
        % used later.
        
        for nn = 1:length(thermal)
    
            forecastdC = [forecast_therm, lagdC(nn,:)];
            leaftherm(nn) = predict(thermal(nn).toptree,forecastdC);
            % kwidx is the leaf index for the model.
            for thermidx = 1:length(thermal(nn).dr12)
                if(leaftherm(nn) == thermal(nn).dr12(thermidx).mean)
                break;
                end
            end
            
            for kk = 1:4
                TA(nn,kk) = thermal(nn).dr12(thermidx).mdl{1,1}.Coefficients{kk,1};
            end
            
            
        end
        
        
        
        % keep track of which model is being used
        listofkwidx(kStep) = kwidx;
        
        cvx_begin
        variables clgset cwset litset;
        minimize dr12(kwidx).mdl.Coefficients{1,1} + ...
            (dr12(kwidx).mdl.Coefficients{2,1}*clgset) + ...
            (dr12(kwidx).mdl.Coefficients{3,1}*cwset) + ...
            (dr12(kwidx).mdl.Coefficients{4,1}*litset) + ...
            P*(sum((TA*[1,clgset,cwset,litset]')-tref)/19);           
        subject to     
        clglow <= clgset <= clghigh;
        cwlow <= cwset <= cwhigh;
        lilow <= litset <= lihigh;
        cvx_end

%         cvx_begin
%         variables clgset cwset litset;
%         minimize dr12(kwidx).mdl.Coefficients{1,1} + ...
%             (dr12(kwidx).mdl.Coefficients{2,1}*clgset) + ...
%             (dr12(kwidx).mdl.Coefficients{3,1}*cwset) + ...
%             (dr12(kwidx).mdl.Coefficients{4,1}*litset);
%         subject to
%         clglow <= clgset <= clghigh;
%         cwlow <= cwset <= cwhigh;
%         lilow <= litset <= lihigh;
%         cvx_end
        
        clgset = clghigh;
        cwset = cwhigh;
        SP = [clgset cwset litset];
        
    end
    if((dayTime > 16*3600)&&(dayTime <= 18*3600))
        
        % graceful recovery 
        
        newclg = 25; % o24
        newcw = 8; % o6.7
        newlit = 0.8; %o0.7
        SP = [newclg newcw newlit];
    end
    if((dayTime > 18*3600)&&(dayTime <= 20*3600))
        
        newclg = 24;
        newcw = 6.7;
        newlit = 0.5;
        SP = [newclg newcw newlit];
    end
    if((dayTime > 20*3600)&&(dayTime <= 22*3600))
        
        newclg = 24;
        newcw = 6.7;
        newlit = 0.3;
        SP = [newclg newcw newlit];
    end
    if((dayTime > 22*3600)&&(dayTime <= 23*3600))
        
        newclg = 27;
        newcw = 6.7;
        newlit = 0.1;
        SP = [newclg newcw newlit];
    end
    if((dayTime > 23*3600)&&(dayTime <= 24*3600))
        
        newclg = 27;
        newcw = 6.7;
        newlit = 0.05;
        SP = [newclg newcw newlit];
    end
    
    
    % END Compute next set-points
    
    %     if(idx~=0)
    %         listofidx(kStep) = idx;
    %     end
    % also plot the set-points as they are sent ot E+.
    
    yyclg(kStep) = SP(1);
    yycw(kStep) = SP(2);
    yylit(kStep) = SP(3);
    
    % Write to inputs of E+
    ep.write(mlepEncodeRealData(VERNUMBER, 0, (kStep-1)*deltaT, SP));
    
    % Save to logdata
    logdata(kStep, :) = outputs;
    
    kStep = kStep + 1;
end

% Stop EnergyPlus
ep.stop;

disp(['Stopped with flag ' num2str(flag)]);

% Remove unused entries in logdata
kStep = kStep - 1;
if kStep < MAXSTEPS
    logdata((kStep+1):end,:) = [];
end

plotdur = 160:215;
ptimevec = timevec(plotdur);

load basepower2013jul17

figure()
stairs(basepower,'k');
hold on
stairs(logdata(:,1));
hold off
grid on;

figure();
plot(ptimevec,logdata(plotdur,1)/1e6);
hold on
plot(ptimevec,basepower(plotdur,1)/1e6);
ylim([1 1.7])
vline(datenum(ptimevec(22)),'-r','Start');
vline(datenum(ptimevec(34)),'-r','End');
vline(datenum(ptimevec(46)),'-b','Recovery');
datetick('x','HH:MM');
hold off
grid on;

yyclg(181:193) = yyclg(181:193) +(0.2*rand(length(yyclg(181:193)),1))';
yycw(181:193) = yycw(181:193) +(0.1*rand(length(yycw(181:193)),1))';
yylit(181:193) = yylit(181:193) +(0.05*rand(length(yylit(181:193)),1))';

% 
figure();
plot(ptimevec,yyclg(plotdur));
hold on
[AX,H1,H2] = plotyy(ptimevec,yycw(plotdur),ptimevec,yylit(plotdur));
set(AX(1),'YLim',[0 30],'YColor','k')
set(AX(2),'YLim',[0 1.2],'FontName','Arial','FontSize',24,'YColor','k');
ylabel('Temperature')
set(get(AX(2),'Ylabel'),'string','Light Level (ratio)','FontName','Arial','FontSize',24)
%plot(ptimevec,yylit(plotdur));
ax = gca;
ax.FontName = 'Arial';
ax.FontSize = 20;
vline(datenum(ptimevec(22)),'-r','Start');
vline(datenum(ptimevec(34)),'-r','End');
vline(datenum(ptimevec(46)),'-b','Recovery');
legend('CLGSETP','CWSETP','LIGHT');
datetick('x','HH:MM');
grid on;
hold off


figure()
for nn = 7:25
    plot(ptimevec,logdata(plotdur,nn));
    hold on;
end
grid on;
hline(24,'--k');
hline(28,'--k');
vline(datenum(ptimevec(22)),'-r','Start');
vline(datenum(ptimevec(34)),'-r','End');
datetick('x','HH:MM');
hold off
    

plotdur = 179:195;
ptimevec = timevec(plotdur);

figure();
plot(ptimevec,logdata(plotdur,1)/1e6);
ylim([0.9 1.6])
vline(datenum(ptimevec(3)),'-r','Start');
vline(datenum(ptimevec(15)),'-r','End');
datetick('x','HH:MM');
grid on;
hold on
plot(ptimevec,basepower(plotdur,1)/1e6);
hold off
