
%% Plot control variables and switching between strategies

hf = figure;
xmin = 0;
xmax = 13;

t1 = datetime('17-Jul-2013 00:00');
t2 = datetime('17-Jul-2013 23:55');
timevec = t1:minutes(5):t2;
ptimemin = datenum(timevec(179));
ptimemax = datenum(timevec(193));
x = timevec(181:194);
x1 = timevec(176:199);
linewidth = 1.5;
markersize = 10;
hs1 = subplot(3,1,1);  hold on; box on; grid on;
plot(x1, DefaultControlStrategy{1}(:,1)', '-k', 'LineWidth', linewidth);
h11 = plot(x, [DefaultControlStrategy{1}(6,1), ControlStrategy{1}(:,1)', DefaultControlStrategy{1}(19,1)], '-+b', 'LineWidth', linewidth);
h21 = plot(x, [DefaultControlStrategy{2}(6,1), ControlStrategy{2}(:,1)', DefaultControlStrategy{2}(19,1)], '--dg', 'LineWidth', linewidth);
h31 = plot(x, [DefaultControlStrategy{3}(6,1), ControlStrategy{3}(:,1)', DefaultControlStrategy{3}(19,1)], '--sr','MarkerSize', markersize);
% plot(x, ControlOpt(:,1), '-k')
ymin = 6;
ymax = 10;
plot(datenum(timevec(181))*ones(1,10), linspace(ymin,ymax,10),'--k');
plot(datenum(timevec(193))*ones(1,10), linspace(ymin,ymax,10),'--k');
ylabel(hs1,'CHSTP [^{\circ}C]')
set(hs1, 'Xlim', [ptimemin, ptimemax], 'Ylim', [ymin,ymax]);
datetick('x','HH:MM');

hs2 = subplot(3,1,2);  hold on; box on; grid on;
plot(x1, DefaultControlStrategy{1}(:,2)', '-k', 'LineWidth', linewidth);
h12 = plot(x, [DefaultControlStrategy{1}(6,2), ControlStrategy{1}(:,2)', DefaultControlStrategy{1}(19,2)], '-+b', 'LineWidth', linewidth);
h22 = plot(x, [DefaultControlStrategy{2}(6,2), ControlStrategy{2}(:,2)', DefaultControlStrategy{2}(19,2)], '--dg', 'LineWidth', linewidth);
h32 = plot(x, [DefaultControlStrategy{3}(6,2), ControlStrategy{3}(:,2)', DefaultControlStrategy{3}(19,2)], '--sr','MarkerSize', markersize);
% h12 = plot(x, ControlStrategy{1}(:,2), '-ob');
% h22 = plot(x, ControlStrategy{2}(:,2), '--or');
% h32 = plot(x, ControlStrategy{3}(:,2), '--og');
% plot(x, ControlOpt(:,2), '-k')
ymin = 23.5;
ymax = 26.5;
plot(datenum(timevec(181))*ones(1,10), linspace(ymin,ymax,10),'--k');
plot(datenum(timevec(193))*ones(1,10), linspace(ymin,ymax,10),'--k');
ylabel(hs2,'CLGSTP [^{\circ}C]')
set(hs2, 'Xlim', [ptimemin, ptimemax], 'Ylim', [ymin,ymax]);
datetick('x','HH:MM');

hs3 = subplot(3,1,3);  hold on; box on; grid on;
plot(x1, DefaultControlStrategy{1}(:,3)', '-k', 'LineWidth', linewidth);
h13 = plot(x, [DefaultControlStrategy{1}(6,3), ControlStrategy{1}(:,3)', DefaultControlStrategy{1}(19,3)], '-+b', 'LineWidth', linewidth);
h23 = plot(x, [DefaultControlStrategy{2}(6,3), ControlStrategy{2}(:,3)', DefaultControlStrategy{2}(19,3)], '--dg', 'LineWidth', linewidth);
h33 = plot(x, [DefaultControlStrategy{3}(6,3), ControlStrategy{3}(:,3)', DefaultControlStrategy{3}(19,3)], '--sr','MarkerSize', markersize);
% h13 = plot(x, ControlStrategy{1}(:,3), '-ob');
% h23 = plot(x, ControlStrategy{2}(:,3), '--or');
% h33 = plot(x, ControlStrategy{3}(:,3), '--og');
% hopt = plot(x, ControlOpt(:,3), '-k');
ymin = 0.55;
ymax = 0.95;
plot(datenum(timevec(181))*ones(1,10), linspace(ymin,ymax,10),'--k');
plot(datenum(timevec(193))*ones(1,10), linspace(ymin,ymax,10),'--k');
ylabel(hs3,'LIGHT [-]')
set(hs3, 'Xlim', [ptimemin, ptimemax], 'Ylim', [ymin,ymax]);
xlabel('Time of day [hh:mm]')
datetick('x','HH:MM');
legend([h11, h21, h31], 'S1','S2', 'S3', 'location', 'northoutside', 'orientation', 'horizontal')

%% Plot Optimal control power output

figure; hold on; box on; grid on;
markersize = 7;
ymin = 1050;
ymax = 1550;
ylim([ymin, ymax]);
h1 = plot(x, [PowerGroundTruth{1}(6,1), BuildPowerAllStrat{1}', PowerGroundTruth{1}(19,1)]/1000, '--ob', 'MarkerSize', markersize);
h2 = plot(x1, PowerGroundTruth{1}/1000, '-b');
h3 = plot(x, [PowerGroundTruth{2}(6,1), BuildPowerAllStrat{2}', PowerGroundTruth{2}(19,1)]/1000, '--dg', 'MarkerSize', markersize);
h4 = plot(x1, PowerGroundTruth{2}/1000, '-g');
h5 = plot(x, [PowerGroundTruth{3}(6,1), BuildPowerAllStrat{3}', PowerGroundTruth{3}(19,1)]/1000, '--sr', 'MarkerSize', markersize);
h6 = plot(x1, PowerGroundTruth{3}/1000, '-r');
ptimevec2 = timevec(182:193+12);
x2 = ptimevec2;
plot(datenum(timevec(181))*ones(1,10), linspace(ymin,ymax,10),'--k', 'LineWidth', 1);
plot(datenum(timevec(193))*ones(1,10), linspace(ymin,ymax,10),'--k', 'LineWidth', 1);
% hopt = plot(x, PowerOpt/1000, '-k');
ylabel('Building Power [kW]')
xlabel('Time of day [hh:mm]')
legend([h1, h2, h3, h4, h5, h6], 'S1', 'S1-Cosim', 'S2', 'S2-Cosim', 'S3', 'S3-Cosim', 'Location', 'Best')


%% Plot zone temperatures from co-sim

% figure; hold on;
% 
% for pidx = 1:19;
%    
%     hp = plot(x1,INP{1}(176:199,15+pidx));
%     
% end
% ymin = 23.5;
% ymax = 28.5;
% ylim([ymin,ymax]);
%%

% figure; hold on;
% title('Control Inputs');
% 
% x = 1:length(DREventRange);
% [hx, hy1, hy2] = plotyy(x, [ControlStrategy{1}(:,1),ControlStrategy{1}(:,2),...
%                             ControlStrategy{2}(:,1),ControlStrategy{2}(:,2),...
%                             ControlStrategy{3}(:,1),ControlStrategy{3}(:,2),...
%                             ControlOpt(:,1), ControlOpt(:,2)],... 
%                         x, [ControlStrategy{1}(:,3),ControlStrategy{2}(:,3),...
%                             ControlStrategy{3}(:,3), ControlOpt(:,3)]);
% markersize = 10;
% set(hy1(1),'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', markersize, 'Color', 'r')
% set(hy1(2),'LineStyle', 'none', 'Marker', 'd', 'MarkerSize', markersize, 'Color', 'r')
% set(hy1(3),'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', markersize, 'Color', 'b')
% set(hy1(4),'LineStyle', 'none', 'Marker', 'd', 'MarkerSize', markersize, 'Color', 'b')
% set(hy1(5),'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', markersize, 'Color', 'g')
% set(hy1(6),'LineStyle', 'none', 'Marker', 'd', 'MarkerSize', markersize, 'Color', 'g')
% set(hy1(7),'LineStyle', '-', 'Color', 'k')
% set(hy1(8),'LineStyle', '-', 'Color', 'k')
% 
% set(hy2(1),'LineStyle', 'none', 'Marker', 's', 'MarkerSize', markersize, 'Color', 'r')
% set(hy2(2),'LineStyle', 'none', 'Marker', 's', 'MarkerSize', markersize, 'Color', 'b')
% set(hy2(3),'LineStyle', 'none', 'Marker', 's', 'MarkerSize', markersize, 'Color', 'g')
% set(hy2(4),'LineStyle', '-', 'Color', 'k')
% 
% ylabel(hx(1),'Cooling SP [deg C]/ Chiller Water SP [deg C]') % left y-axis
% ylabel(hx(2),'Lighting SP [deg C]') % right y-axis
% 
% set(hx(1),'YLim',[0 30])
% set(hx(2),'YLim',[0.1 1.2])
% set(hx,'XLim',[-2 13])
% 
% legend([hy1(1),hy1(3),hy1(5),...
%         hy1(2),hy1(4),hy1(6),...
%         hy2(1),hy2(2),hy2(3),...
%         hy2(4)],...
%         'S1-CHSP', 'S2-CHSP', 'S3-CHSP',...
%         'S1-CLSP', 'S2-CLSP', 'S3-CLSP',...
%         'S1-LTSP', 'S2-LTSP', 'S3-LTSP',...
%         'Optimal Strategies',...
%         'location', 'west')
%     
% 
%     