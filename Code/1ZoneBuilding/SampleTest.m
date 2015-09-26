load dry2
ze = dry2(1:500);
zr = dry2(501:1000);
m = arx(ze,[2 3 0]);

opt = arxOptions('InitialCondition','estimate');
y = sim(m,zr.InputData,opt);

y2 = SimulateARMAX(m, zr.InputData, zr.OutputData);
compare(zr,m);

% figure; hold on;
% plot(zr.OutputData, 'r')
% plot(y, 'b')
% 
% figure; hold on;
% plot(zr.OutputData, 'r')
% plot(y2, 'b')

%% Extract data from compare.m

h = figure(2);
axesObjs = get(h, 'Children');  %axes handles
dataObjs = get(axesObjs, 'Children'); %handles to low-level graphics objects in axes
linedataObjs = get(dataObjs, 'Children');
PredictedData = linedataObjs{1}.YData;
ActualData = linedataObjs{2}.YData;
figure(3)
hold on;
plot(y1, 'r')
plot(y2, 'b')