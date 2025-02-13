%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    PI2GPI: from the Pressure Insoles to the Gait Phases Identification  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MATLAB code to offline extract gait cycle sub-phases (heel contact, flat-
% foot contact, push-off, and swing phases) from plantar pressure insoles.
%
% Author(s): Nicolas LEO (nicolas.leo@polito.it)
%            PolitoBIOMed Lab and BIOLAB, Politecnico di Torino, Turin, Italy
% 
%            Marco GHISLIERI (marco.ghislieri@polito.it)
%            PolitoBIOMed Lab and BIOLAB, Politecnico di Torino, Turin, Italy
%
%            Valentina AGOSTINI (valentina.agostini@polito.it)
%            PolitoBIOMed Lab and BIOLAB, Politecnico di Torino, Turin, Italy
%
% File: Pi2GPI.m
% Date: 07-02-2025 (Plot and comments)
%       06-02-2025 (Data export)
%       05-02-2025 (Code fixing and optimization)
%       03-02-2025 (Documentations)
% -------------------------------------------------------------------------

% Clear all previous initialized variables and close all figures
% --------------------------------------------------------------
clearvars
close all
clc
tic

% Set code logging
% ----------------
logFileName = 'command_window_log.txt';
diary(logFileName);

% Set working path
% ----------------
currentfolder = pwd;
addpath(currentfolder);

%% Load the *.mat file containing normalized pressure insole data
% ---------------------------------------------------------------
% Please ENSURE that the pressure insole data are already amplitude-normalized
% and structured as follows:
% Single structure containing two double matrices: 'LeftFoot' (N-by-M matrix)
% and 'RightFoot' (N-by-M matrix), where N = time-samples and M = channels
% number.
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Loading *.mat file...']);
[filename, path] = uigetfile('*.mat',['Select *.mat file containing pressure' ...
    'insole data to open...']);
load([path filename]);
clear filename path
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Loading *.mat file...Ok']);

%% Spatial clusters definition
% ----------------------------
% Pressure insole channels are divided into three distinct clusters based on 
% anatomical contact points of the foot: heel, fifth metatarsal head (head5),
% and first metatarsal head (head1).

sides = fieldnames(data); % sides: LeftFoot and RightFoot

for s = 1:length(sides) % Loop over sides
    % IMPORTANT: The number and composition of the spatial clusters should be 
    % adjusted to best fit the specific requirements of your study.
    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
        char(sides(s)) ' - Set spatial clusters...']);
    cluster_name = {'heel', 'head5', 'head1'}; % Set clusters' names
    cluster_channels = {          % Assignment of channels to each cluster
        [12, 13, 14, 15, 16], ... % Cluster 1: heel
        [5, 9, 10, 11], ...       % Cluster 2: 5th Metatarsal Head
        [1, 2, 3, 4, 6, 7, 8]};   % Cluster 3: 1st Metatarsal Head
    
    % Set foot sensing resistors' coordinates
    x = [1, 1, 2, 3, 4, 1, 2, 3, 4, 4, 4, 4, 3, 4, 2, 3];
    y = [13, 11.5, 11.5, 11.5, 10.5, 10, 10, 10, 9, 7.5, 6, 3.5, 2, 2, 0.5, 0.5];
    
    % Plot cluster configuration
    % --------------------------
    figure; hold on;
    scatter(x, y, 100, 'k', 'filled');
    
    colors = {[0, 114, 189] / 255,  [119, 172, 48] / 255, [162, 20, 47] / 255};
    labels = {'Heel', '5th Metatarsal head', '1st Metatarsal head'};
    
    for i = 1:3 % Loop over clusters
        scatter(x(cluster_channels{i}), y(cluster_channels{i}), 300, colors{i}, ...
            'filled', 'DisplayName', labels{i});
    end
    
    offset = 0.2 * strcmp(sides{s}, 'LeftFoot') - 0.2 * strcmp(sides{s}, 'RightFoot');
    text(x + offset, y, cellstr(num2str((1:length(x))')), 'FontSize', 10, ...
        'FontWeight', 'bold', 'Color', 'w');
    if strcmp(sides{s}, 'LeftFoot')
        set(gca, 'XDir', 'reverse');
    end
    
    xlim([-6 10]); ylim([-1 16]);
    legend([{''}, labels(:)'], 'Location', 'Best');
    title(sprintf('%s current cluster configuration', sides{s})); axis off; grid off;
    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Set spatial clusters...Ok']);
    hold off;
    
    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
        char(sides(s)) ' - Set spatial clusters...Ok']);
   
    %% Pre-processing and detection of activation windows for each cluster
    % --------------------------------------------------------------------
    % Setting parameters
    % ------------------
    minPeakHeight = 0.01; % The lowest amplitude a signal must reach to be 
                          % considered as 'active', filtering out low-amplitude 
                          % fluctuations likely caused by noise.

    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
        char(sides(s)) ' - Pre-processing and detection of activation windows...']);

    for clus = 1:length(cluster_channels) % Loop over clusters
        num_samples = size(data.(sides{s}), 1); % Number of time-instants
    
        % Pre-processing: combine, normalize, and smooth signals
        % ------------------------------------------------------
        clus_signals_sum.(cluster_name{clus}) = mean(data.(sides{s})(:, ...
            cluster_channels{clus}), 2); % Combine and normalize signals
        clus_signals_der.(cluster_name{clus}) = smooth([0; diff(smooth(clus_signals_sum.(cluster_name{clus})...
            , 11))]); % Smooth and compute first derivative

        % Detection of maximum and minimum peaks
        % --------------------------------------
        [maxPeaks.(cluster_name{clus}), maxLocs.(cluster_name{clus})] = ...
            findpeaks(clus_signals_der.(cluster_name{clus}), "MinPeakHeight", minPeakHeight);
        [minPeaks.(cluster_name{clus}), minLocs.(cluster_name{clus})] = ...
            findpeaks(-clus_signals_der.(cluster_name{clus}), "MinPeakHeight", minPeakHeight);
        minPeaks.(cluster_name{clus}) = -minPeaks.(cluster_name{clus}); % Invert minima

        % Activation Window (AW) detection
        % ---------------------------
        % For each cluster, AW is the time between the i-th maximum and the 
        % lowest preceding minimum before the next maximum. If two maxima occur
        % consecutively, the higher one marks activation onset, and the next 
        % minimum marks activation offset.
        
        activation.(cluster_name{clus}) = zeros(1, num_samples);

        for i = 1:length(maxLocs.(cluster_name{clus}))-1 % Loop over maximum peaks
            current_max_pos = maxLocs.(cluster_name{clus})(i); % Current maximum peak
            subsequent_max_pos = maxLocs.(cluster_name{clus})(i+1); % Next maximum peak
     
            % Find all the minimum peaks between two consecutive maximum peaks
            valid_min_idxs = find((minLocs.(cluster_name{clus}) > current_max_pos) & ...
                (minLocs.(cluster_name{clus}) < subsequent_max_pos));

            if ~isempty(valid_min_idxs)
                % Select minimum with highest amplitude
                [~, min_idx] = max(abs(minPeaks.(cluster_name{clus})(valid_min_idxs)));
                subsequent_min_pos = minLocs.(cluster_name{clus})(valid_min_idxs(min_idx));
            else
                % Select higher amplitude max if no valid minima
                if maxPeaks.(cluster_name{clus})(i) < maxPeaks.(cluster_name{clus})(i+1)
                    current_max_pos = subsequent_max_pos;
                end
                % Find subsequent minimum
                subsequent_min_pos = minLocs.(cluster_name{clus})(find(minLocs.(cluster_name{clus}) ...
                    > current_max_pos, 1, 'first'));
            end
             % Define activation windows for each cluster
             activation.(cluster_name{clus})(current_max_pos:subsequent_min_pos-1) = 1;     
        end
    end
    
    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
        char(sides(s)) ' - Pre-processing and detection of activation windows...Ok']);

    %% Gait cycle sub-phases identification
    % -------------------------------------
    % The gait cycle subphases are determined based on the activation status 
    % of each cluster, following these rules:
    % Phase H (Heel Contact): Only the heel cluster is active;
    % Phase F (Flat-Foot Contact): The heel cluster remains active, with at 
    %                              least one cluster under the forefoot also active;
    % Phase P (Push-Off): The heel cluster becomes inactive, while at least 
    %                     one forefoot cluster remains active;
    % Phase S (Swing): All clusters are inactive. 
    
    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
        char(sides(s)) ' - Gait cycle subphase identification...']);
    
     % Identify gait subphase according to activation rules
    % ----------------------------------------------------
    output.(sides{s}) = ones(1, num_samples) * 4; % Default phase is swing (output = 4)
    output.(sides{s})(activation.heel & ~(activation.head1 | activation.head5)) = 1; % Heel phase (output = 1)
    output.(sides{s})(activation.heel & (activation.head1 | activation.head5)) = 2; % Flat-foot phase (output = 2)
    output.(sides{s})(~activation.heel & (activation.head1 | activation.head5)) = 3; % Push-off phase (output = 3)

    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
        char(sides(s)) ' - Gait cycle subphase identification...Ok']);

    % Represent gait subphases
    % ------------------------
    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
    char(sides(s))    ' - Results visualization...']);
    
    figure('Name', sprintf('%s Results Plot', sides{s}), 'NumberTitle', 'off', ...
        'units', 'normalized', 'outerposition', [0 0 1 1]);
    subplot(2,3,1), hold on;
    scatter(x, y, 100, 'k', 'filled');
    
    for i = 1:3 % Loop over clusters
        scatter(x(cluster_channels{i}), y(cluster_channels{i}), 300, colors{i}, ...
            'filled', 'DisplayName', labels{i});
    end

    offset = 0.2 * strcmp(sides{s}, 'LeftFoot') - 0.2 * strcmp(sides{s}, 'RightFoot');
    text(x + offset, y, cellstr(num2str((1:length(x))')), 'FontSize', 10, ...
        'FontWeight', 'bold', 'Color', 'w');
    if strcmp(sides{s}, 'LeftFoot')
        set(gca, 'XDir', 'reverse');
    end
    
    xlim([-6 10]); ylim([-1 16]);
    legend([{''}, labels(:)'], 'Location', 'Best'); hold off;
    title(sprintf('%s current cluster configuration', sides{s})); grid off;
    set(gca, 'XTick', [], 'YTick', []);
    
    subplot(2,3,[2 3]), hold on;
    for clus = 1:length(cluster_channels) % Loop over clusters
         plot(data.(sides{s})(:, cluster_channels{clus}),  'Color', colors{clus})
    end
    title('Pressure insole signals')
    ylabel('Amplitude (a.u.)'),
    ylim([-0.1 1.1]), yticks([0 1]), set(gca, 'XTickLabel', []);
   
    subplot(2,3,[5 6])
    stairs(output.(sides{s}),'Color','k', 'LineWidth', 2),
    yticks([0 1 2 3 4 5]), yticklabels({'','H', 'F', 'P', 'S', ''});
    xlabel('Time (sample)'), ylim([0 5]);
    title(sprintf('%s Gait Subphases', sides{s}))
    hold off, box off, 
    
    axesHandles = findall(gcf, 'Type', 'axes');
    axesToLink = [axesHandles(2), axesHandles(1)]; 
    linkaxes(axesToLink, 'x');
    xlim([-0.1 num_samples]);

    disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - ' ...
    char(sides(s)) ' - Results visualization...Ok']);
end


%% Export data
% ------------
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ...
    ' - Saving results to *.csv file...']);

% Create the table with left and right signals
results = table((1:num_samples)', output.LeftFoot(:), output.RightFoot(:), ...
    'VariableNames', {'Sample','Left', 'Right'});

% Save the *.csv file
writetable(results, 'PI2GPI_result.csv');

disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ...
    ' - Saving results to *.csv file...Ok']);

elapsedTime = toc;
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Execution time: ' num2str(elapsedTime, '%.2f') ' seconds']);
diary off;
