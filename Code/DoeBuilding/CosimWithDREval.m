
% clc
% clear
% close all

%% Create an mlepProcess instance and configure it

ep = mlepProcess;
ep.arguments = {'LargeOfficeOPT', 'SPtMasterTable_587017_2013_amy'};
ep.acceptTimeout = 20000; % in milliseconds

VERNUMBER = 2;  % version number of communication protocol (2 as of
% E+ 8.1.0)

% Load the tree and the linear models
disp('Loading offline kW and thermal trees..');
% load Trees_50leaves

disp('Done!');

t1 = datetime('17-Jul-2013 00:00');
t2 = datetime('17-Jul-2013 23:55');
timevec = t1:minutes(5):t2;
idk = 1;

%% Start EnergyPlus cosimulation
[status, msg] = ep.start;

if status ~= 0
    error('Could not start EnergyPlus: %s.', msg);
end

%% The main simulation loop

EPTimeStep = 12;
SimDays = 2;
deltaT = (60/EPTimeStep)*60;  % time step = 12 minutes
kStep = 1;  % current simulation step
MAXSTEPS = SimDays*24*EPTimeStep;  % max simulation time = 7 days

clglow = 24;
clghigh = 28;
cwlow = 6.7;
cwhigh = 10;
lilow = 0.8;
lihigh = 1;
minchange = 0.5;

% variables for plotting:
xx = 1:MAXSTEPS;
yyclg = nan(1,MAXSTEPS);
yycw = nan(1,MAXSTEPS);
yylit = nan(1,MAXSTEPS);
listofkwidx = zeros(1,MAXSTEPS);
baseest = zeros(1,MAXSTEPS);

% create a vector to store the lagged values of power and tempratures.
lagkw = zeros(1,8);
lagdC = zeros(19,8);

% logdata stores set-points, outdoor temperature, and zone temperature at
% each time step.
numoutvars = 32;
logdata = zeros(MAXSTEPS,numoutvars);


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
    
    
    forecast_kw = [outdry,outwet,outhum,winspeed,windir,...
                   dow,tod,htgsetp,hwsetp,chws1,boiler,...
                   basezat,corebzat,coremzat,coretzat,...
                   gfplenum,mfplenum,...
                   peribot1zat,peribot2zat,peribot3zat,peribot4zat,...
                   perimid1zat,perimid2zat,perimid3zat,perimid4zat,...
                   peritop1zat,peritop2zat,peritop3zat,peritop4zat,...
                   topplenum];
    
    forecast_therm = [outdry,outwet,outhum,winspeed,windir,...
                   dow,tod,htgsetp,hwsetp,chws1,boiler];
    
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
    
    if(dayTime >= 15*3600) && (dayTime < 16*3600)
        
        disp('DR Event Begins..');
    
%         OptInput = [linspace(7,9,12)', linspace(25,27.5,12)', linspace(0.8,0.6,12)'];


%         OptInput = [9.0000   27.5000    0.3000;...
%                     9.0000   27.5000    0.3000;...
%                     7.0000   26.0000    0.5000;...
%                     7.0000   26.0000    0.5000;...
%                     7.0000   26.0000    0.5000;...
%                     7.0000   26.0000    0.5714;...
%                     6.5000   25.9444    0.6000;...
%                     6.5000   25.5556    0.6000;...
%                     6.5000   25.1667    0.6000;...
%                     6.5000   24.7778    0.6000;...
%                     8.0000   25.5000    0.8000;...
%                     8.0000   25.5000    0.8000];
                
        OptInput = [8*ones(12,1), 26*ones(12,1), 0.6*ones(12,1)];

        SP = [OptInput(idk,2), OptInput(idk,1), OptInput(idk,3)];
        idk = idk+1;
        
    end
    if((dayTime >= 16*3600)&&(dayTime <= 18*3600))
        
        idk=1;
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

plotdur = 160:220;
ptimevec = timevec(plotdur);

load basepower2013jul17

figure()
plot(basepower,'k');
hold on
plot(logdata(:,1));
hold off
grid on;

figure();
plot(ptimevec,logdata(plotdur,1)/1e6);
hold on
ylim([1.1 1.9])
vline(datenum(ptimevec(22)),'-r','Start');
vline(datenum(ptimevec(34)),'-r','End');
vline(datenum(ptimevec(46)),'-b','Recovery');
datetick('x','HH:MM');
hold off
grid on;

% 
figure();
plot(ptimevec,yyclg(plotdur));
hold on
[AX,H1,H2] = plotyy(ptimevec,yycw(plotdur),ptimevec,yylit(plotdur));
set(AX(1),'YLim',[0 30])
set(AX(2),'YLim',[0 1.2])
ylabel('Temperature')
set(get(AX(2),'Ylabel'),'string','Light Level (ratio)')
%plot(ptimevec,yylit(plotdur));
vline(datenum(ptimevec(22)),'-r','Start');
vline(datenum(ptimevec(34)),'-r','End');
vline(datenum(ptimevec(46)),'-b','Recovery');
legend('CLGSETP','CWSETP','LIGHT');
datetick('x','HH:MM');
grid on;
hold off
% 
% plotdur = 193:206;
% ptimevec = timevec(plotdur);
% 
% figure();
% plot(ptimevec,logdata(plotdur,1)/1e6);
% ylim([0 0.85])
% vline(datenum(ptimevec(1)),'-r','Start');
% vline(datenum(ptimevec(13)),'-r','End');
% datetick('x','HH:MM');
% grid on;
