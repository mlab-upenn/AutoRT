% This script simulates a supervisory controller for an HVAC system. The
% controller computes the zone temperature set-point based on the current
% time and the outdoor dry-bulb temperature. The building is simulated by
% EnergyPlus. This simulation is the same as that implemented in
% simple.mdl, but uses plain Matlab code instead of Simulink.
%
% This script illustrates the usage of class mlepProcess in the MLE+
% toolbox for feedback control which involves whole building simulation.
% It has been tested with Matlab R2009b and EnergyPlus 6.0.0.
%
% This example is taken from an example distributed with BCVTB version
% 0.8.0 (https://gaia.lbl.gov/bcvtb).
%
% This script is free software.
%
% (C) 2010-2014 by Truong Nghiem (nghiem@seas.upenn.edu)
%
% CHANGES:
%   2014-08-26  Update to E+ 8.1.0.
%   2012-04-23  Fix an error with E+ 7.0.0: Matlab must read data from E+
%               before sending any data to E+.
%   2011-07-13  Update to new version of MLE+ which uses mlepInit for
%               system settings.
%   2011-04-28  Update to new version of MLE+ which uses Java for running
%               E+.

%% Create an mlepProcess instance and configure it

ep = mlepProcess;
%ep.arguments = {'LargeOfficeFUN', 'USA_IL_Chicago-OHare.Intl.AP.725300_TMY3'};
ep.arguments = {'LargeOfficeBAS', 'SPtMasterTable_587017_2013_amy'};
ep.acceptTimeout = 20000; % in milliseconds

VERNUMBER = 2;  % version number of communication protocol (2 as of
                % E+ 8.1.0)


%% Start EnergyPlus cosimulation
[status, msg] = ep.start;

if status ~= 0
    error('Could not start EnergyPlus: %s.', msg);
end

%% The main simulation loop

% Specify building mode
% 0 = run baseline
% 1 = run functional testing
baseline = 1;

EPTimeStep = 12;
SimDays = 1;
deltaT = (60/EPTimeStep)*60;  % time step = 12 minutes
kStep = 1;  % current simulation step
MAXSTEPS = SimDays*24*EPTimeStep;  % max simulation time = 7 days

clglow = 24;
clghigh = 28;
cwlow = 6.7;
cwhigh = 10;
lilow = 0;
lihigh = 1;
minchange = 0.5;

% variables for plotting:
xx = 1:MAXSTEPS;
yyclg = nan(1,MAXSTEPS);
yycw = nan(1,MAXSTEPS);
yylit = nan(1,MAXSTEPS);


% logdata stores set-points, outdoor temperature, and zone temperature at
% each time step.
logdata = zeros(MAXSTEPS,32);

while kStep <= MAXSTEPS    
    % Read a data packet from E+
    packet = ep.read;
    if isempty(packet)
        error('Could not read outputs from E+.');
    end
    
    % Parse it to obtain building outputs
    [flag, eptime, outputs] = mlepDecodePacket(packet);
    if flag ~= 0, break; end
        
    % BEGIN Compute next set-points
    dayTime = mod(eptime, 86400);  % time in current day

        SP = [24 6.7 0.7];
        
        if(baseline)
            
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
            if((dayTime > 8*3600)&&(dayTime <= 17*3600))
                
                newclg = 24;
                newcw = 6.7;
                newlit = 0.9;
                SP = [newclg newcw newlit];
            end
            if((dayTime > 17*3600)&&(dayTime <= 18*3600))
                
                newclg = 24;
                newcw = 6.7;
                newlit = 0.7;
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
        end
        
        

    % END Compute next set-points
    
    oldclg = SP(1);
    oldcw = SP(2);
    oldlit = SP(3);
    
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

sim_duration =  1:MAXSTEPS; 
% 12 steps per hour
sim_duration = floor(sim_duration./EPTimeStep);

figure
plot(sim_duration,yyclg);
figure
plot(sim_duration,yycw);
figure
plot(sim_duration,yylit);

