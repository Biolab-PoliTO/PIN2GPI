%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    PI2GPI: from the Pressure Insoles to the Gait Phases Identification  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Author(s): N. Leo (nicolas.leo@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
% 
%            M. Ghislieri (marco.ghislieri@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
%
%            V. Agostini (valentina.agostini@polito.it)
%            BIOLAB, Politecnico di Torino, Turin, Italy
% Last Updated: 03/02/2024
% ------------------------

% Add functions folder to Matlab path
currentfolder = pwd;
addpath(currentfolder);

% Load data file ('PI.mat'), a structure containing normalized pressure 
% insoles data in the range [0 1], organized in two fields:
% - LeftFoot: N-by-M matrix, where N = time-samples and M = channels number;
% - RighFoot: N-by-M matrix, where N = time-samples and M = channels number;
% --------------------------------------------------------------
[filename,path] = uigetfile('*.mat','Select File to open');
cd(path)
load(filename)
cd(currentfolder)

% Basographic Signal Extraction:
% ------------------------
[baso] = HFPS_extraction(PI);