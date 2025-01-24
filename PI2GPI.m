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
% Last Updated: 24/01/2024
% ------------------------

% Add functions folder to Matlab path
currentfolder = pwd;
addpath(currentfolder);

% Load and convert INDIP text file (".txt") into a MATLAB matrix:
% --------------------------------------------------------------
[filename,path] = uigetfile('*.mat','Select File to open');
cd(path)
load(filename)
cd(currentfolder)

% Basographic Signal Extraction:
% ------------------------
[baso] = HFPS_extraction_old(PI);