%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  PI-GaPhI: Gait Cycle Phases Identification from Pressure Insoles (INDIP)  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Author(s): N. Leo (nicolas.leo@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
%
% Last Updated: 28/08/2024
% ------------------------

% Add functions folder to Matlab path
currentfolder = pwd;
addpath(currentfolder); 

% Load and convert INDIP text file (".txt") into a MATLAB matrix:
% --------------------------------------------------------------
[filename,path] = uigetfile('*.txt','Select File to open');
cd(path)
[XX, infoStr] = openINDIP(filename, 'r');

% Detection Gait Cycle Phases:
% ------------------------
[output, PI] = HFPTSdetect(XX);

%%%%%%%%%%%%%%%%%%%%%%%% Visualize the results %%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define parameters:
% -----------------
fs = 100;                                 % Sampling frequency (Hz)
num_samples = size(PI.norm_signals, 1);   % Samples number
time = 0:1/fs:num_samples/fs-1/fs;        % Time vector (s)
num_channels = size(PI.norm_signals, 2);  % Insole channels number

% Representation of basographic signals and normalized signals of PI
% ------
figure;

% First subplot: Basographic Signal
subplot(2, 1, 1), hold on,
stairs(time, PI.baso,'Color','k', 'LineWidth', 2);
yticks([0 1 2 3 4 5]), yticklabels({'','H', 'F', 'P', 'T', 'S'});
xlabel('Time (s)'), ylim([0 6])
title('Basographic Signal'), hold off;

% Second subplot: Pressure Insoles Channels Signals (Volt)
subplot(2, 1, 2);
hold on
pressure_handles = gobjects(1, 4);

% Different colors for each channles according to the belonging cluster 
channel_colors = {'[1, 0.5, 0]', 'r', 'r', 'r', 'g', 'r', 'r', 'r', ...
                   'g', 'g', 'g', 'b', 'b', 'b', 'b', 'b'};

for i = 1:size(PI.norm_signals,2)
    p = plot(time,PI.norm_signals(:, i), 'Color', channel_colors{i});    
    if isequal(channel_colors{i}, 'b')
        pressure_handles(1) = p; % Cluster 1
    elseif isequal(channel_colors{i}, 'g')
        pressure_handles(2) = p; % Cluster 2
    elseif isequal(channel_colors{i}, 'r')
        pressure_handles(3) = p; % Cluster 3
    elseif isequal(channel_colors{i}, '[1, 0.5, 0]')
        pressure_handles(4) = p; % Cluster 4
    end
end

start_phase = find(diff(PI.baso) ~= 0); % Samples of start phase
marker_handle = plot(time(start_phase+1), 0.01*ones(1,length(start_phase)), 'k*', 'MarkerSize', 6);
xlabel('Time (s)')
legend([marker_handle, pressure_handles(1), pressure_handles(2), pressure_handles(3), pressure_handles(4)], ...
       'Start phase', 'CH 12-13-14-15-16','CH 5-9-10-11', 'CH 2-3-4-6-7-8', 'CH 1', 'Location', 'best'),
title('Normalized Pressure'), ylim([-0.1 1]), hold off
linkaxes(findall(gcf, 'Type', 'axes'), 'x');
