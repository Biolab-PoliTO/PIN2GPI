function [output] = HFPS_extraction(data)
% function [output, PI] = HFPS_extraction(data)
%
% 'HFPS_extraction' function detects gait phases from clustering of pressure
% insoles 16 channels according to three anatomic regions on the foot. 
%
% INPUT: data        --> INDIP acquired matrix data
%
%
% OUTPUT: output     --> structure containing:
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
% Last Updated: 17/1/2024
% ------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% a. Three clusters selection
% ----------------------------------------------------------------------
% ----------------------------------------------------------------------

% Organize the sixteen channels of PIs into three clusters according to 
% three different anatomic points on the foot: 
% Heel: channels '12,13,14,15,16'
% 5th metatarsal head: channels '5,9,10,11'
% 1st metatrsal head: channels '1,2,3,4,6,7,8'
% -------------------------------------------
% If your data contains a different number of channels (16) or follows a 
% different channels distribution, you should modify the cluster 
% organization below to match your specific dataset.
cluster_channels = {'12,13,14,15,16','5,9,10,11','1,2,3,4,6,7,8'};
cluster_name = {'heel','head5', 'head1'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% b. Pre-processing and Activation Windows detection for each cluster 
% between max and min peaks
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Define parameters of 'findpeaks' function:
% -------------------------------------------
% Minimum prominence value: the height difference between the peak and the 
% lowest point between the peak and its surrounding neighbors. It helps 
% filter out peaks that are significant compared to the overall signal, 
% eliminating small peaks due to noise
minProminence = 0.15; 
% Minimum Peak Height: the minimum height that a peak must have to be 
% considered and allows you to ignore peaks with very low amplitude values ​​
% that could be caused by noise fluctuations.
minPeakHeight = 0.06;
% Minimum Peak Distance: the minimum distance between two consecutive peaks
% for them to be considered separate, preventing detection of peaks that 
% are too close together that might represent local fluctuations rather 
% than distinct events.
minPeakDistance = 20; 

side_PI = fieldnames(data); % Sides: LeftFoot and RightFoot

for s = 1:length(side_PI)
    for clus = 1:length(cluster_channels) % Cluster selection

        PI_signals = data.(side_PI{s});
        num_samples = size(PI_signals, 1); % Samples number
    
        % Signal pre-processing
        % ---------------------
        signals = PI_signals(:, [str2num(cluster_channels{1, clus})]); % Its channels selection
        signal_sum.(cluster_name{clus}) = sum(signals, 2); % Signals sum 
        signal_sum.(cluster_name{clus}) = smooth(sum(signals, 2),11); % Smoothing 
        deriv_signal = [0; diff(signal_sum.(cluster_name{clus}))]; % Derivatative signal
        smooth_signal.(cluster_name{clus}) = smooth(deriv_signal); % Additional smoothing
    
        % Find maximum peaks
        % ------------------
        [~, maxLocs.(cluster_name{clus})] = findpeaks(smooth_signal.(cluster_name{clus}), ...
            'MinPeakProminence', minProminence,'MinPeakHeight', minPeakHeight, ...
            'MinPeakDistance', minPeakDistance);
    
        % Find minimum peaks on inverted signal
        % -------------------------------------
        [minPeaks.(cluster_name{clus}), minLocs.(cluster_name{clus})] = findpeaks(-smooth_signal.(cluster_name{clus}), ...
            'MinPeakProminence', minProminence, 'MinPeakHeight', minPeakHeight, ...
            'MinPeakDistance', minPeakDistance);
        minPeaks.(cluster_name{clus}) = -minPeaks.(cluster_name{clus});
    
        % Array inizialization of activation windows
        % ------------------------------------------
        activation.(cluster_name{clus}) = zeros(1, num_samples);
    
        % Activation window definition
        % ----------------------------
       for i = 1:length(maxLocs.(cluster_name{clus}))
         start_idx = maxLocs.(cluster_name{clus})(i); % Maximum
         subsequent_min_idxs = find((minLocs.(cluster_name{clus}) > start_idx), 1, 'first'); % nearest following minimum
   
           % If a minimum exists, define activation between max and min 
           % ----------------------------------------------------------
           if ~isempty(subsequent_min_idxs)
               end_idx = minLocs.(cluster_name{clus})(subsequent_min_idxs);
   
               % In cases where two consecutive minima occurred within a 500 ms
               % interval, the second minimum was selected as the deactivation point 
               % --------------------------------------------------------------------
               % Control if there is a double minimum after current maximum
               second_min_idxs = find((minLocs.(cluster_name{clus}) > end_idx), 1, 'first');
   
               if ~isempty(second_min_idxs)
                   % Control if there are maximum among current max and 2nd min
                   second_min = minLocs.(cluster_name{clus})(second_min_idxs);
   
                   % Add a condition for maximum distance between first and second minimum (50 samples)
                   if second_min - end_idx <= 50  % (samples)
                       if isempty(find((maxLocs.(cluster_name{clus}) > end_idx) & (maxLocs.(cluster_name{clus}) < second_min), 1, 'first'))
                           end_idx = second_min; % Update disactivation index
                       end
                   end
               end
   
               % Define activation among max and min (or 2nd min)
               activation.(cluster_name{clus})(start_idx:end_idx) = 1; % Activation cluster
           end
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
        
    Time = [(find(diff(phase_string) ~= 0)), num_samples]; % End of each gait phase (expressed in samples)
    Dur = [Time(1), diff(Time)]; % Duration of each gait phase (expressed in samples)
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % d. Post-processing
    % ------------------
    % ------------------

    % Anti-bouncing Filter is applied to remove short and spurious phases 
    % (≤ 50 ms) that are surrounded by the same phase both before and after
    % ---------------------------------------------------------------------
    i = 2; % Starting by 2nd phase
    while i <= length(Dur) - 1
        if Dur(i) <= 5 % (5 samples/100 Hz = 50 ms)
            % Verify if the phase before and after is the same
            if phase_num(Time(i-1)) == phase_num(Time(i+1))
                % Update phase_num
                phase_num(Time(i-1)+1:Time(i)) = phase_num(Time(i-1));
                phase_string(Time(i-1)+1:Time(i)) = phase_string(Time(i-1));

            end
        end
        i = i + 1;
    end   
    output.phase.(side_PI{s}) = phase_string;
    output.levels.(side_PI{s}) = phase_num;
end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% e. Save results
% ---------------
% ---------------

% The user is prompted to choose the output format ('csv' or 'txt') and the
% signal representation, either in 4 numeric levels ('levels') or phase labels ('phase')
% -------------------------------------------------------------------------
valid_formats = {'txt', 'csv'};
file_format = "";

% Prompt the user to choose the output format
% -------------------------------------------
while ~ismember(file_format, valid_formats)
    file_format = input('Choose the output format ("txt" or "csv"): ', 's');
    if ~ismember(file_format, valid_formats)
        disp('Invalid format. Please choose "txt" or "csv".');
    end
end

% Ask the user if he prefers the signal in 4 numeric levels or phase labels
% ---------------------------------------------------------------------
signal_type = input('Choose the signal type ("levels" for numeric or "phase" for phase labels): ', 's');

% Select the appropriate data based on user input
% -----------------------------------------------
if strcmp(signal_type, 'levels')
    Left = output.levels.LeftFoot(:);  % Column for levels data
    Right = output.levels.RightFoot(:);  % Column for levels data
elseif strcmp(signal_type, 'phase')
    Left = output.phase.LeftFoot(:);  % Column for phase data
    Right = output.phase.RightFoot(:);  % Column for phase data
else
    error('Invalid option. Please choose "levels" or "phase".');
end

results = table(Left, Right);  % Create a table with two columns

% Save the file based on the chosen format
% ----------------------------------------
if strcmp(file_format, 'txt')
    % Save in TXT format (with tab separation)
    writetable(results, 'baso_result.txt', 'Delimiter', '\t');
elseif strcmp(file_format, 'csv')
    % Save in CSV format (with comma separation)
    writetable(results, 'baso_result.csv');
end
end
