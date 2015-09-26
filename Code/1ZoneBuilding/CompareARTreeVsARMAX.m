%% Comparison between ARTree and ARMAX
load ARTree_60mins
load ARMAX_60mins

% Prediction
figure; hold on;
ylabel('Zone Air Temperature [deg C]');
idAR = 2;
title(['Timestep: ' num2str(TimeStep) ' mins, Order of AR: ' num2str(OrderOfAR(idAR)) ' steps = '  num2str(OrderOfAR(idAR)*TimeStep) ' mins']);
h1 = plot(1:length(ActualOutput), ActualOutput, 'k');
h2 = plot(1:length(ActualOutput), rtreeOutput{idAR}, 'r');
h3 = plot(1:length(ActualOutput), brtreeOutput{idAR}, 'b');
h4 = plot(1:length(ActualOutput), ARMAXOutput{idAR}.OutputData, '--g');
legend([h1, h2, h3, h4], 'GroundTruth', ['SingleTree ' num2str(rtreeNRMSE(idAR),2)],['BoostedTree' num2str(brtreeNRMSE(idAR),2)],['ARMAX ' num2str(ARMAXNRMSE(idAR),2)])


% NRMSE
figure; hold on;
title(['Timestep: ' num2str(TimeStep) ' mins']);
ylabel('NRMSE');
xlabel('Order of regression [time steps]');
h2 = plot(OrderOfAR, rtreeNRMSE, 'r');
h3 = plot(OrderOfAR, brtreeNRMSE, 'b');
h4 = plot(OrderOfAR, ARMAXNRMSE, '--g');
legend([h2, h3, h4], 'SingleTree', 'BoostedTree', 'ARMAX')