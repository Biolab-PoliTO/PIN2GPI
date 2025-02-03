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
load([path filename])
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ' - Loading *.mat file...Ok']);

%% Spatial clusters definition
% ----------------------------
% Pressure insole channels are divided into three distinct clusters based on 
% anatomical contact points of the foot: heel, fifth metatarsal head (head5),
% and first metatarsal head (head1).

% IMPORTANT: The number and composition of the spatial clusters should be 
% adjusted to best fit the specific requirements of your study.
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ...
    ' - Set spatial clusters...']);
cluster_name = {'heel', 'head5', 'head1'}; % Set clusters' names
cluster_channels = {          % Assignment of channels to each cluster
    [12, 13, 14, 15, 16], ... % Cluster 1: heel
    [5, 9, 10, 11], ...       % Cluster 2: 5th Metatarsal Head
    [1, 2, 3, 4, 6, 7, 8]};   % Cluster 3: 1st Metatarsal Head

% Set foot sensing resistors' coordinates
x = [1, 1, 2, 3, 4, 1, 2, 3, 4, 4, 4, 4, 3, 4, 2, 3];
y = [13, 11.5, 11.5, 11.5, 10.5, 10, 10, 10, 9, 7.5, 6, 3.5, 2, 2, 0.5, 0.5];

% Plot current cluster configuration
% ----------------------------------
figure; hold on;
scatter(x, y, 100, 'k', 'filled');
scatter(x(cluster_channels{1}), y(cluster_channels{1}), 300, ...
    hex2rgb('#0072bd'), 'filled', 'DisplayName', 'Heel'); % Cluster 1
scatter(x(cluster_channels{2}), y(cluster_channels{2}), 300, ...
    hex2rgb('#77ac30'), 'filled', 'DisplayName', '5th Metatarsal Head'); % Cluster 2
scatter(x(cluster_channels{3}), y(cluster_channels{3}), 300, ...
    hex2rgb('#a2142f'), 'filled', 'DisplayName', '1st Metatarsal Head'); % Cluster 3

for i = 1:length(x)
    text(x(i)-0.2, y(i), num2str(i), 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'w');
end
xlim([-6 10]), ylim([-1 16])
legend({'','Heel', '5th Metatarsal Head', '1st Metatarsal Head'}, ...
    'Location', 'Best');
title('Current PI Cluster Configuration'); axis off; grid off; 
hold off;
disp([char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')) ...
    ' - Set spatial clusters...Ok']);

%% b. Pre-processing and Activation Windows detection for each cluster 
% between the max and min peaks
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Minimum Peak Height: the minimum height that a peak must have to be 
% considered and allows you to ignore peaks with very low amplitude values ​​
% that could be caused by noise fluctuations.
minPeakHeight = 0.01;
fs = 100;
sides = fieldnames(PI); % sides: LeftFoot and RightFoot

for s = 1:length(sides)
    for clus = 1:length(cluster_channels) % Cluster selection

        PI_signals = PI.(sides{s});
        num_samples = size(PI_signals, 1); % Samples number
    
        % Signal pre-processing
        % ---------------------
        signals = PI_signals(:, channels.(cluster_name{clus})); % Its channels selection
        signal_sum = sum(signals, 2)/length(channels.(cluster_name{clus})); % Sum signals/n_signals 
        signal_sum = smooth(signal_sum,11); % Smoothing 
        deriv_signal = [0; diff(signal_sum)]; % Derivatative signal
        smooth_signal = smooth(deriv_signal); % Additional smoothing
    
        % Find maximum peaks
        % ------------------
        [maxPeaks.(cluster_name{clus}), maxLocs.(cluster_name{clus})] = findpeaks(smooth_signal,"MinPeakHeight",minPeakHeight);
    
        % Find minimum peaks on inverted signal
        % -------------------------------------
        [minPeaks.(cluster_name{clus}), minLocs.(cluster_name{clus})] = findpeaks(-smooth_signal,"MinPeakHeight",minPeakHeight);
        minPeaks.(cluster_name{clus}) = -minPeaks.(cluster_name{clus});
        % Array inizialization of activation windows
        % ------------------------------------------
        activation.(cluster_name{clus}) = zeros(1, num_samples);
    
        % Activation window definition
        % ----------------------------
        for i = 1:length(maxLocs.(cluster_name{clus}))-1
            current_max_pos = maxLocs.(cluster_name{clus})(i); % Current maximum
            subsequent_max_pos = maxLocs.(cluster_name{clus})(i+1); % Consecutive maximum
     
            % Find all the minima between two consecutive maxima 
            valid_min_idxs = find((minLocs.(cluster_name{clus}) > current_max_pos) & ...
                (minLocs.(cluster_name{clus}) < subsequent_max_pos )); 
            
            if ~isempty(valid_min_idxs)
                % Select the minimum with higher absolute amplitude as
                % disactivation time
                [~, max_amplitude_idx] = max(abs(minPeaks.(cluster_name{clus})(valid_min_idxs))); % Max value
                min_idx = valid_min_idxs(max_amplitude_idx);
                subsequent_min_pos = minLocs.(cluster_name{clus})(min_idx); 
            else
                % Select the maximum with higher absolute amplitude as
                % activation time
                if maxPeaks.(cluster_name{clus})(i) < maxPeaks.(cluster_name{clus})(i+1)
                    current_max_pos = subsequent_max_pos; 
                end 
                % Select the subsequent minimum as disactivation time
               subsequent_min_idxs = find((minLocs.(cluster_name{clus}) > current_max_pos), 1, 'first'); 
               subsequent_min_pos = minLocs.(cluster_name{clus})(subsequent_min_idxs);
            end
 
             % Define activation among max and min-1
             activation.(cluster_name{clus})(current_max_pos:subsequent_min_pos-1) = 1; % Activation cluster       
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% d. Save results
% ---------------
% ---------------

% Create a output table with Left and Right basographic signal
% -----------------------------------------------
results = table(output.LeftFoot(:), output.RightFoot(:), ...
    'VariableNames', {'Left', 'Right'});

% Save the file based on the chosen format
% ----------------------------------------
writetable(results, 'baso_result.csv');