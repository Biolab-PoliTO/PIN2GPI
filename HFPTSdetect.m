function [output, PI] = HFPTSdetect(XX)
% function [output, PI] = HFPTSdetect(XX)
%
% 'GCPhasesDetect' function detects gait cycle phases from clustering of 
% pressure insoles channels according to anatomic regions of foot. 
%
% INPUT: XX          --> INDIP acquired matrix
%
% OUTPUT: output     --> structure containing segmentation results:
%                       - phasefin: End of each gait cycle phase expressed in samples
%                       - phase: Duration of each  gait cycle phase expressed in samples
%                       - class: Classification of each gait cycle phase
%         PI         --> structure containing signals:
%                       - norm_signals: PI signals (normalized)
%                       - baso: basographic signal

% ------------------------
% Author(s): N. Leo (nicolas.leo@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
%
% Last Updated: 28/08/2024
% ------------------------

% Select PI and define parameters:
% -----------------
PI_signals = XX(:,13:28);                       % Selection of filtered pressure
num_samples = size(PI_signals, 1);              % Samples number
num_channels = size(PI_signals, 2);             % Insole channels number

% 1. Individuate Activation Windows (AW) of each PI channel 
% -------------------------------------------------------------
% -------------------------------------------------------------

% Phase 1: AW control based on amplitude of signal
% ------------------------------------------------
% Define AW according to the noise amplitude of PI signals
% ---------------------------------------------------------------
noise_threshold = 0.1; 
activations = PI_signals > noise_threshold;
activations_plus = activations; 

% Phase 2: AW control based on Neighborhood
% -------------------------------------------------
% In order to prevent possible activation spikes due to acquisition error, 
% a channel is considered "active" if almost three channels of its 
% neighborhood are 'active'.
% ---------------------------------------------------------------
% Neighborhood definition
neighborhood = {
    [2, 3, 4, 6, 7], ...             % Channel 1
    [1, 3, 4, 6, 7], ...             % Channel 2
    [1, 2, 4, 5, 6, 7, 8], ...       % Channel 3
    [1, 2, 3, 5, 6, 7, 8, 9], ...    % Channel 4
    [1, 2, 3, 4, 6, 7, 8, 9], ...    % Channel 5
    [1, 2, 3, 4, 7, 8], ...          % Channel 6
    [1, 2, 3, 4, 5, 6, 8, 9], ...    % Channel 7
    [3, 4, 5, 6, 7, 9, 10], ...      % Channel 8
    [4, 5, 7, 8, 10, 11], ...        % Channel 9
    [5, 8, 9, 11, 12], ...           % Channel 10
    [9, 10, 12, 13, 14, 15, 16], ... % Channel 11
    [10, 11, 13, 14, 15, 16], ...    % Channel 12
    [11, 12, 14, 15, 16], ...        % Channel 13
    [11, 12, 13, 15, 16], ...        % Channel 14
    [11, 12, 13, 14, 16], ...        % Channel 15
    [11, 12, 13, 14, 15] ...         % Channel 16
};

for t = 1:num_samples
    for channel_idx = 1:num_channels
        % Find the neighborhood of the current channel 
        neighbors = neighborhood{channel_idx};
        % Control if almost three neighbors are 'active'
        if sum(activations_plus(t, neighbors)) < 3
            activations(t, channel_idx) = 0;
        end
    end
end


% 2. Individuate AW of each PI cluster 
% -------------------------------------
% -------------------------------------

% Define four clusters according to four different anatomic points of foot
% --------------------------------------------------------------------
cluster1 = [12, 13, 14, 15, 16];            % Heel
cluster2 = [11, 10, 9, 5];                  % 5th metatarsal head
cluster3 = [2, 3, 4, 6, 7, 8];              % 1st metatarsal head
cluster4 = 1;                               % Thumb

% Variables inizialization
cluster1_active = false(num_samples, 1);
cluster2_active = false(num_samples, 1);
cluster3_active = false(num_samples, 1);
cluster4_active = false(num_samples, 1);
phase_num = zeros(1, num_samples); 
phase_string = strings(1, num_samples); 

% Function to find the temporal instants of each cluster. 
% A cluster is considered 'active' when almost one of its channels is active
is_cluster_active = @(cluster, t, n) sum(activations(t, cluster)) >= n;

% Iteration on all temporal instants
for t = 1:num_samples
    cluster1_active(t) = is_cluster_active(cluster1, t, 1);
    cluster2_active(t) = is_cluster_active(cluster2, t, 1);
    cluster3_active(t) = is_cluster_active(cluster3, t, 1);
    cluster4_active(t) = is_cluster_active(cluster4, t, 1);
end


% 3. Identification of GC phases
% ------------------------------
% ------------------------------

% Define the correspondence between the combination of 'active' or 'not 
% active' clusters and a specific gait phase
% 'H': cluster1 'active', cluster2, cluster3 and cluster4 'not active'
% 'F': cluster1 'active' and almost one among cluster2, cluster3 or cluster4 'active'
% 'P': cluster1 'not active' and almost one among cluster2, cluster3 o cluster4 'active'
% 'T': only cluster4 'active'
% 'S': no cluster 'active'
for t = 1:num_samples
    if cluster1_active(t) && ~cluster2_active(t) && ~cluster3_active(t) && ~cluster4_active(t)
        phase_string(t) = 'H'; % Heel contact
        phase_num(t) = 1;
    elseif cluster1_active(t) && (cluster2_active(t) || cluster3_active(t) || cluster4_active(t))
        phase_string(t) = 'F'; % Flat foot
        phase_num(t) = 2;
    elseif ~cluster1_active(t) && (cluster2_active(t) || cluster3_active(t) || cluster4_active(t))
        phase_string(t) = 'P'; % Push off
        phase_num(t) = 3;
    elseif ~cluster1_active(t) && ~cluster2_active(t) && ~cluster3_active(t) && cluster4_active(t)
        phase_string(t) = 'T'; % Thumb
        phase_num(t) = 4;
    else
        phase_string(t) = 'S'; % Swing
        phase_num(t) = 5;
    end
end


%%%%%%%%%%%%%%%%%%%% 
% 4. GC Segmentation 
% ------------------------------
% ------------------------------

Time = [(find(diff(phase_num) ~= 0)), num_samples]; % End of each gait subphase (expressed in samples)
Dur = [Time(1), diff(Time)]; % Duration of each gait subphase (expressed in samples)

charVector = {'H', 'F', 'P', 'S'}; % Gait subphase's labels
uniqueValues = unique(phase_num(1,Time));
indexMapping = containers.Map(uniqueValues, 1:length(uniqueValues)); % Map gait subphases and foot-floor contact sequences
String = cellfun(@(x) charVector{indexMapping(x)}, num2cell(phase_num(1,Time))); % Sequence of gait subphases after mapping

Pos = [0 diff(double(String))<0];   % find the falling fronts ("candidates" of starting GC)
rejPos = find(Pos == 1);
Pos(rejPos(find(diff(rejPos)==1)+1))=0; % If there are two consecutive transitions, only the first one is considered as a valid cycle start
Pos=[1, find(Pos==1)];

for l = 1:length(Pos)-1
    Class{1,l} = String(Pos(l):Pos(l+1)-1);
end

% Define phasefin, phase, class, and dur cells
for m = 1:length(Pos)-1 % Remove the first and last gait cycles
    for n = 1:length(Class{1,m})
        phasefin{n,m} = Time(1,Pos(1,m)+(n-1)); % Contains the ends in samples of each gait phase
        phase{n,m} = Dur(1,Pos(1,m)+(n-1)); % Contains the durations in samples of each gait phase
        class{n,m} = Class{1,m}(n); % Contains the classifications of each gait phase
    end
    dur(1,m) = sum([phase{:,m}]); % Contains the durations in samples of each gait cycle
end

% Save results
output.phasefin = phasefin;   % End of each gait cycle phase expressed in samples
output.phase = phase;         % Duration of each  gait cycle phase expressed in samples
output.class = class;         % Classification of each gait cycle phase
PI.norm_signals = PI_signals; % Normalized signals of PI
PI.baso = phase_num;          % Basographic signals and normalized signals of PI

end

