NRMSE = zeros(11,2);
AR = 0:2:20;
for iii = 1:length(AR)
    OrderOfAR = AR(iii);
    ART_BuildPower;
    NRMSE(iii,:) = [rtreeNRMSE, brtreeNRMSE];
    iii
end

figure; hold on;
h1 = plot(NRMSE(:,1), 'r');
h2 = plot(NRMSE(:,2), 'b');
legend([h1, h2], 'Single Tree', 'Boosted Tree', 'Location', 'Best');