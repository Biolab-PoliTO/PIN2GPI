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
% Date: 03-02-2024 (Documentations)
% -------------------------------------------------------------------------

% Clear all previous initialized variables and close all figures
% --------------------------------------------------------------
clearvars
close all
clc

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

% IMPORTANT: The number and composition of the spatial clusters should be 
% adjusted to best fit the specific requirements of your study.
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Set spatial clusters...']);
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

colors = {hex2rgb('#0072bd'), hex2rgb('#77ac30'), hex2rgb('#a2142f')};
labels = {'Heel', '5th Metatarsal Head', '1st Metatarsal Head'};

for i = 1:3 % Loop over clusters
    scatter(x(cluster_channels{i}), y(cluster_channels{i}), 300, colors{i}, ...
        'filled', 'DisplayName', labels{i});
end

text(x-0.2, y, cellstr(num2str((1:length(x))')), 'FontSize', 10, 'FontWeight', ...
    'bold', 'Color', 'w');

xlim([-6 10]); ylim([-1 16]);
legend([{''}, labels(:)'], 'Location', 'Best');
title('Current PI Cluster Configuration'); axis off; grid off;
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Set spatial clusters...Ok']);
hold off;

clear colors labels x y

%% Pre-processing and detection of activation windows for each cluster
% --------------------------------------------------------------------
% Setting parameters
% ------------------
minPeakHeight = 0.01; % The lowest amplitude a signal must reach to be 
                      % considered as 'active', filtering out low-amplitude 
                      % fluctuations likely caused by noise.
sides = fieldnames(data); % sides: LeftFoot and RightFoot

for s = 1:length(sides) % Loop over sides
    for clus = 1:length(cluster_channels) % Loop over clusters
        num_samples = size(data.(sides{s}), 1); % Number of time-instants
    
        % % Signal pre-processing: Combine, normalize, and smooth signals
        % ---------------------------------------------------------------
        clus_signals_sum = mean(sum(data.(sides{s})(:, cluster_channels{clus}), 2), 2); % Combine and normalize signals
        clus_signals_der = smooth([0; diff(smooth(clus_signals_sum, 11))]); % Smooth and compute first derivative

        % Detection of maximum and minimum peaks
        % --------------------------------------
        [maxPeaks.(cluster_name{clus}), maxLocs.(cluster_name{clus})] = ...
            findpeaks(clus_signals_der, "MinPeakHeight", minPeakHeight);
        [minPeaks.(cluster_name{clus}), minLocs.(cluster_name{clus})] = ...
            findpeaks(-clus_signals_der, "MinPeakHeight", minPeakHeight);
        minPeaks.(cluster_name{clus}) = -minPeaks.(cluster_name{clus}); % Invert minima

        % Activation window detection
        % ---------------------------
        % BRIEFLY DESCRIBE THE FUNCTIONING OF THE ALGORITHM!
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
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % c. Gait Phases Identification (GPI) (Heel contact - Flat foot contact - 
    % Push off - Swing)
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------

    % Define the correspondence between the combination of 'active' or 'not 
    % active' clusters and specific gait phases
    % (H): only the heel cluster is active
    % (F): the heel cluster is active, and at least one cluster under the 
    %      forefoot is also active
    % (P): the heel cluster is inactive, while at least one forefoot cluster 
    %      remains active
    % (S): all clusters are inactive 
    
    % Variables Inizialization
    % ------------------------
    phase_string = repmat(' ', 1, num_samples);
    phase_num = zeros(1, num_samples);
    
    % Select phase for each temporal instant
    % ------------------------
    for t = 1:num_samples
        if activation.heel(t) && ~activation.head1(t) && ~activation.head5(t)
            phase_string(t) = 'H'; % Heel contact
            phase_num(t) = 1;
        elseif activation.heel(t) && (activation.head1(t) || activation.head5(t))
            phase_string(t) = 'F'; % Flat foot
            phase_num(t) = 2;
        elseif ~activation.heel(t) && (activation.head1(t) || activation.head5(t))
            phase_string(t) = 'P'; % Push off
            phase_num(t) = 3;
        else
            phase_string(t) = 'S'; % Swing
            phase_num(t) = 4;
        end
    end
    output.(sides{s}) = phase_string;
end

%% Export data
% ------------
% Create the table with left and right signals
results = table(output.LeftFoot(:), output.RightFoot(:), ...
    'VariableNames', {'Left', 'Right'});

% Save the *.csv file
writetable(results, 'PI2GPI_result.csv');