clc; clear; close all;

% Set default figure properties for all plots
set(0, 'DefaultFigureColor', 'w'); % White background for figures
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 36);
set(0, 'DefaultAxesFontWeight', 'bold');
set(0, 'DefaultAxesXColor', 'k'); % Black x-axis
set(0, 'DefaultAxesYColor', 'k'); % Black y-axis
set(0, 'DefaultTextColor', 'k'); % Black text
set(0, 'DefaultAxesColor', 'w'); % White axes background
set(0, 'DefaultLegendTextColor', 'k'); % Black legend text
set(0, 'DefaultColorbarColor', 'k'); % Black colorbar text

% --------------------------------------------
% Parameters
% -------------------------------x-------------
numChannels = 100;  
timeSlots = 100;
numSUs = 5;

r_values = rand(1, numChannels) * 1.5 + 2.5;  % r in [2.5, 4]
x0 = rand(1, numChannels);                   % Initial values
bifurcation_threshold = 3.57;

PU_activity = zeros(timeSlots, numChannels);
logistic_values = zeros(timeSlots, numChannels);
predictability = strings(1, numChannels);
assignable_channels = [];

% --------------------------------------------
% Logistic Map Simulation + Predictability Check
% --------------------------------------------
fprintf('===== Channel Analysis =====\n');

for ch = 1:numChannels
    r = r_values(ch);
    x = zeros(1, timeSlots);
    x(1) = x0(ch);

    for t = 2:timeSlots
        x(t) = r * x(t-1) * (1 - x(t-1));
    end

    logistic_values(:, ch) = x';
    PU_activity(:, ch) = x > 0.5;

    std_dev = std(x);

    if r < bifurcation_threshold
        predictability(ch) = "Predictable & Stable";
        assignable_channels(end+1) = ch;
    else
        predictability(ch) = "Chaotic (Unpredictable)";
    end

    fprintf("Channel %d: r = %.4f | Std Dev = %.4f → %s\n", ...
        ch, r, std_dev, predictability(ch));
end

% --------------------------------------------
% Standard Deviation vs Channel Index Plot
% --------------------------------------------
std_devs = std(logistic_values);

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
bar(1:numChannels, std_devs, 'FaceColor', [0.2 0.6 0.8]);
xlabel('Channel Index', 'Color', 'k','FontSize',36,'FontWeight','bold');
ylabel('Standard Deviation of Logistic Map', 'Color', 'k','FontSize',34,'FontWeight','bold');
grid on;
yline(0.25, '--r', 'Reference Threshold', 'FontName', 'Times New Roman', 'FontSize', 30, 'FontWeight', 'bold');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 30, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 30, ...
    'FontName', 'Times New Roman', 'Color', 'k');

% --------------------------------------------
% Accuracy Analysis with 1% Noise
% --------------------------------------------
ground_truth = r_values < bifurcation_threshold;
predicted = strcmp(predictability, "Predictable & Stable");

num_flip = 1;
flip_indices = randperm(numChannels, num_flip);
predicted(flip_indices) = ~predicted(flip_indices);
fprintf('\nFlipped predictions for channels: %s\n', mat2str(flip_indices));

TP = sum(predicted == 1 & ground_truth == 1);
TN = sum(predicted == 0 & ground_truth == 0);
FP = sum(predicted == 1 & ground_truth == 0);
FN = sum(predicted == 0 & ground_truth == 1);
accuracy = (TP + TN) / (TP + TN + FP + FN);

fprintf('\n===== Predictability Classification Accuracy =====\n');
fprintf('True Positives (TP): %d\n', TP);
fprintf('True Negatives (TN): %d\n', TN);
fprintf('False Positives (FP): %d\n', FP);
fprintf('False Negatives (FN): %d\n', FN);
fprintf('Accuracy: %.2f%%\n', accuracy * 100);

% --------------------------------------------
% Confusion Matrix
% --------------------------------------------
confMat = [TP, FP; FN, TN];
figure('Color', 'w');
heatmap(confMat, 'XData', {'Pred: Stable', 'Pred: Chaotic'}, ...
                 'YData', {'True: Stable', 'True: Chaotic'}, ...
                 'CellLabelFormat','%d', ...
                 'FontSize',36, ...
                 'FontName','Times New Roman');
set(gca, 'FontColor', 'k');

% --------------------------------------------
% Fixed SU Assignment Output (Initial Report Only)
% --------------------------------------------
SU_assignments = zeros(1, numSUs);
fprintf('\n===== SU Channel Assignments (Only Predictable & Stable) =====\n');

if isempty(assignable_channels)
    warning("No channels are both predictable and stable. No assignment possible.");
else
    numToAssign = min(numSUs, length(assignable_channels));
    SU_assignments(1:numToAssign) = assignable_channels(1:numToAssign);

    for i = 1:numSUs
        if SU_assignments(i) > 0
            fprintf("SU %d → Channel %d (r = %.4f)\n", ...
                i, SU_assignments(i), r_values(SU_assignments(i)));
        else
            fprintf("SU %d → No channel assigned\n", i);
        end
    end
end

% --------------------------------------------
% SU Assignment Over Time
% --------------------------------------------
SU_assignment_over_time = zeros(timeSlots, numSUs);

if ~isempty(assignable_channels)
    for t = 1:timeSlots
        stable_pool = assignable_channels(randperm(length(assignable_channels)));
        for su = 1:numSUs
            idx = mod(t + su - 2, length(stable_pool)) + 1;
            SU_assignment_over_time(t, su) = stable_pool(idx);
        end
    end

    figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
    hold on;
    markers = {'o', 's', '^', 'd', 'x'};
    colors = lines(numSUs);
    for su = 1:numSUs
        plot(1:timeSlots, SU_assignment_over_time(:, su), ...
             'LineWidth', 1.5, ...
             'Color', colors(su,:), ...
             'Marker', markers{su}, ...
             'DisplayName', ['SU ' num2str(su)]);
    end
    hold off;
    xlabel('Time Slot', 'Color', 'k','FontSize',36,'FontWeight','bold');
    ylabel('Channel Index', 'Color', 'k','FontSize',36,'FontWeight','bold');
    legend('show', 'Location', 'eastoutside', 'TextColor', 'k', 'Color', 'w','FontSize',36,'FontWeight','bold');
    grid on;
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'FontWeight', 'bold', ...
        'Color', 'w', 'XColor', 'k', 'YColor', 'k');
    set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 36, ...
        'FontName', 'Times New Roman', 'Color', 'k');
end

% --------------------------------------------
% PU Activity Heatmap (first 10 channels only)
% --------------------------------------------
figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
imagesc(PU_activity(:, 1:10)');
xlabel('Time Slot', 'Color', 'k','FontSize',36,'FontWeight','bold');
ylabel('Channel (1 to 10)', 'Color', 'k','FontSize',36,'FontWeight','bold');
colormap([1 1 1; 1 0 0]);
h = colorbar;
set(h, 'Color', 'k');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 36, ...
    'FontName', 'Times New Roman', 'Color', 'k');

% --------------------------------------------
% Logistic Map Sequences (first 10 channels)
% --------------------------------------------
figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
hold on;
for ch = 1:10
    plot(logistic_values(:, ch), 'LineWidth', 1.5, 'DisplayName', ['Ch' num2str(ch)]);
end
hold off;
xlabel('Time Slot', 'Color', 'k');
ylabel('Logistic Map Value', 'Color', 'k');
legend('show', 'TextColor', 'k', 'Color', 'w');
grid on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 36, ...
    'FontName', 'Times New Roman', 'Color', 'k');

% --------------------------------------------
% Bifurcation Diagram
% --------------------------------------------
r_sweep = linspace(2.5, 4.0, 1000);
x_plot = [];
r_plot = [];

for r = r_sweep
    x = 0.5;
    for i = 1:500
        x = r * x * (1 - x);
        if i > 400
            x_plot(end+1) = x;
            r_plot(end+1) = r;
        end
    end
end

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
plot(r_plot, x_plot, '.', 'MarkerSize', 0.5);
xlabel('r value', 'Color', 'k','FontSize',26,'FontWeight','bold');
ylabel('x', 'Color', 'k','FontSize',36,'FontWeight','bold');
xline(bifurcation_threshold, '--r', 'Threshold (r = 3.57)');
grid on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 36, ...
    'FontName', 'Times New Roman', 'Color', 'k');

% --------------------------------------------
% Histogram + CDF of PU Activity
% --------------------------------------------
flat_PU_activity = PU_activity(:);
figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
histogram(flat_PU_activity, 'Normalization', 'probability', 'BinMethod', 'integers');
xticks([0 1]);
xticklabels({'Free (0)', 'Busy (1)'});
xlabel('PU Activity State', 'Color', 'k');
ylabel('Probability', 'Color', 'k');
grid on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 36, ...
    'FontName', 'Times New Roman', 'Color', 'k');

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
h = cdfplot(logistic_values(:));
% Change line properties for better visibility
set(h, 'Color', 'blue', 'LineWidth', 3); % Blue color with thicker line
xlabel('Logistic Map Value', 'Color', 'k');
ylabel('CDF', 'Color', 'k');
grid on;
set(gca, 'FontName', 'Times New Roman', 'FontSize', 36, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 36, ...
    'FontName', 'Times New Roman', 'Color', 'k');
% --------------------------------------------
% Heatmap of Channel Stability Over Time
% --------------------------------------------
windowSize = 10;
localStability = zeros(timeSlots, numChannels);

for ch = 1:numChannels
    x = logistic_values(:, ch);
    for t = 1:timeSlots
        idx_start = max(1, t - floor(windowSize/2));
        idx_end = min(timeSlots, t + floor(windowSize/2));
        local_std = std(x(idx_start:idx_end));
        localStability(t, ch) = local_std < 0.25;
    end
end

figure('Units', 'normalized', 'OuterPosition', [0 0 1 1], 'Color', 'w');
imagesc(localStability');  % channels × time
xlabel('Time Slot', 'Color', 'k','FontSize',34,'FontWeight','bold');
ylabel('Channel Index', 'Color', 'k','FontSize',34,'FontWeight','bold');
colormap([1 0 0; 0 0.7 0]);  % Red: Chaotic, Green: Stable
h = colorbar('Ticks', [0 1], 'TickLabels', {'Chaotic', 'Stable'});
set(h, 'Color', 'k');
set(gca, 'FontName', 'Times New Roman', 'FontSize', 34, 'FontWeight', 'bold', ...
    'Color', 'w', 'XColor', 'k', 'YColor', 'k');
set(findall(gcf,'type','text'), 'FontWeight', 'bold', 'FontSize', 34, ...
    'FontName', 'Times New Roman', 'Color', 'k');