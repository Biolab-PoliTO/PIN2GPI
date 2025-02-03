function [output] = HFPS_extraction(PI)
% function [output] = HFPS_extraction(PI)
%
% 'HFPS_extraction' function detects gait phases from clustering of pressure
% insoles 16 channels according to three anatomic contact points on the foot. 
%
% INPUT: PI        --> INDIP acquired structure data containing
%                       - LeftFoot: Left PI signal
%                       - RightFoot: Right PI signal
% OUTPUT: output   --> structure containing:
%                       - LeftFoot: Left basographic signal
%                       - RightFoot: Right basographic signal

% ------------------------
% Author(s): N. Leo (nicolas.leo@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
% 
%            M. Ghislieri (marco.ghislieri@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
%
%            V. Agostini (valentina.agostini@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
%
% Last Updated: 03/02/2024
% ------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% a. Three clusters selection
% ----------------------------------------------------------------------
% ----------------------------------------------------------------------

% PI channels organization into three clusters according to 
% three different anatomic contact points on the foot 
% --------------------------------------------------------
% Default cluster names
cluster_name = {'heel', 'head5', 'head1'};
% Default channel assignments
cluster_channels = {
    '12,13,14,15,16',  ...% Heel
    '5,9,10,11',       ...% 5th Metatarsal Head
    '1,2,3,4,6,7,8'    ...% 1st Metatarsal Head
};
% Convert default channel strings to numeric arrays
channels.heel = str2double('12,13,14,15,16');    % Heel cluster
channels.head5 = str2double('5,9,10,11');   % 5th Metatarsal Head
channels.head1 = str2double('1,2,3,4,6,7,8');   % 1st Metatarsal Head

% Plot default configuration
% --------------------------
% Coordinates of foot sensing resistors
x = [1, 1, 2, 3, 4, 1, 2, 3, 4, 4, 4, 4, 3, 4, 2, 3];
y = [13, 11.5, 11.5, 11.5, 10.5, 10, 10, 10, 9, 7.5, 6, 3.5, 2, 2, 0.5, 0.5];

% Display the current configuration on a plot
figure; hold on;
scatter(x, y, 100, 'k', 'filled'); % General foot points
scatter(x(channels.heel), y(channels.heel), 300, hex2rgb('#0072bd'), 'filled', 'DisplayName', 'Heel');
scatter(x(channels.head5), y(channels.head5), 300, hex2rgb('#77ac30'), 'filled', 'DisplayName', '5th Metatarsal Head');
scatter(x(channels.head1), y(channels.head1), 300, hex2rgb('#a2142f'), 'filled', 'DisplayName', '1st Metatarsal Head');
for i = 1:length(x)
    text(x(i)-0.2, y(i), num2str(i), 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'w');
end
xlim([-6 10]), ylim([-1 16])
legend({'','Heel', '5th Metatarsal Head', '1st Metatarsal Head'}, 'Location', 'Best');
title('Current PI Cluster Configuration'); axis off; grid off; 
hold off;
disp('Please refer to the figure to see the current cluster configuration.');

% Prompt the user to input the channel distribution for each cluster
for i = 1:length(cluster_name)
    prompt = sprintf('Enter channels for %s (default: %s): ', cluster_name{i}, cluster_channels{i});
    user_input = input(prompt, 's');
    if ~isempty(user_input)
        cluster_channels{i} = user_input;
    end
end

% Prompt the user to input the sampling frequency
user_fs = input('Enter the sampling frequency (default: 100 Hz): ');
if ~isempty(user_fs)
    fs = user_fs;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% b. Pre-processing and Activation Windows detection for each cluster 
% between the max and min peaks
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Minimum Peak Height: the minimum height that a peak must have to be 
% considered and allows you to ignore peaks with very low amplitude values ​​
% that could be caused by noise fluctuations.
minPeakHeight = 0.01;

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

end
