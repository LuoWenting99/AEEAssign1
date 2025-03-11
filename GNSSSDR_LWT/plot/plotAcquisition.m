function plotAcquisition(Acquired, filename)
% Plot Capture Results Bar Chart
% Acquired - Capture result structure
% filename - Data file name

% Generate all PRN numbers (1-32)
allPRN = 1:32;
SNR_values = zeros(1, 32) * NaN; % Initialize as NaN

% Fill in the captured satellite SNR values
for i = 1:length(Acquired.sv)
    prn = Acquired.sv(i);
    SNR_values(prn) = Acquired.SNR(i);
end

% Create a bar chart
figure('Name', 'Acquisition Results', 'NumberTitle', 'off');
bar(allPRN, SNR_values, 'FaceColor', [0.2 0.6 0.8]);
xlabel('PRN Number');
ylabel('SNR (dB)');
title(['Acquired Signals - ', filename]);
grid on;

% Set axis range
xlim([0 33]);
ylim([0 max(SNR_values) + 5]);

% Label satellites that were not captured
hold on;
plot(allPRN(isnan(SNR_values)), zeros(1, sum(isnan(SNR_values))), 'kx', 'MarkerSize', 8);
legend('Detected', 'Not Detected', 'Location', 'northeast');
hold off;
end
