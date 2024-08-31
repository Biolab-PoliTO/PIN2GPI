function [XX, infoStr] = openINDIP(filename, flagPI, dataLines)
% File: openINDIP.m
% Author: S.Bertuletti (University of Sassari - sbertuletti@uniss.it)
% Version: 10
% Date: July-2023
% Details: Function that imports an INDIP text file (".txt") into a MATLAB
% matrix

%% Input:
% - filename = name of the INDIP txt file
% - flagPI = char variable ('L' or 'l' if left pressure insole is connected to the INDIP unit, 'R' or 'r' if right pressure insole is connected to the INDIP unit, any other character)
% - dataLines (optional) = line from which the function start reading the file
%% Output:
% - XX = imported and reorganized data (time in ms | acc in m/s^2 | gyro in rad/s | magn in mGauss | DS in mm | PI in V | Baro in Pa | Temp in °C)
% - infoStr = information about the recording
%% Example:
% - [data, info] = openINDIP('INDIP#000_01-01-1970_000000','L');
%% Additional info
% Jul-22 --> Pressure insoles side (left <-> right) bug fixed (with respect to openINDIP)
%
% Nov-22 --> Acquisitions @200Hz: pressure insoles data --> NaN values for those sensing elements that have
% not been selected, in the firmware, for the acquisition (with respect to openINDIP)
% and the rest filetered. Magnetometer data --> resampled due to the its maximum sampling frequency (i.e. 100Hz)
%
% Feb-23 --> Changed PI @200Hz management according to INDIP GUI - USB
% (v1.3) --> "-1" for not acquired PI channels
%
% Jul-23 --> Modified Distance sensors output (-1 -> NaN); 
% Added Baro, and Temp fields
% Jul-24 --> Modify pressure insole channels-pin correspondence


%% Input handling
% If dataLines is not specified, define defaults
if nargin < 3
    dataLines = [21, Inf];
else
    dataLines = [21+dataLines-1, Inf];
end

%% Info managing
opts = delimitedTextImportOptions("NumVariables", 2);
% Specify range and delimiter
opts.DataLines = [2, 17];
opts.Delimiter = ": ";
% Specify column names and types
opts.VariableNames = ["GeneralInformation", "VarName2"];
opts.VariableTypes = ["string", "string"];
opts = setvaropts(opts, [1, 2], "WhitespaceRule", "preserve");
opts = setvaropts(opts, [1, 2], "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Import the data
t_info = readtable(filename, opts);

%% Convert to output type
t_info = table2cell(t_info);

%% Clear temporary variables
clear opts
t_info(7,:)=[];
t_info(3,:)=[];
t_info(1,:)=[];

%%
fldsName=matlab.lang.makeValidName({'UI_version','Device_ID','Hardware_Version','Firmware_Version','Mode','Sampling_Frequency','Axl_FS','Gyro_FS','Magn_FS','DS1_FS','DS1_Offset','DS2_FS','DS2_Offset'})';
data=t_info(:,2);
infoStr=cell2struct(data,fldsName);

%% Data managing
% Setup the Import Options
opts = delimitedTextImportOptions("NumVariables", 30);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Timestamp", "AccX", "AccY", "AccZ", "GyroX", "GyroY", "GyroZ", "MagnX", "MagnY", "MagnZ", "Distance1", "Distance2", "P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11", "P12", "P13", "P14", "P15", "Baro", "Temp"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
XX = readtable(filename, opts);

%% Convert to output type
XX = table2array(XX);
XX(:,2:4)=XX(:,2:4)/1000*9.81;
XX(:,5:7)=deg2rad(XX(:,5:7));

% Re-organize Distance Sensors data
% -1 -> data not available
tempDistance=XX(:,11);
tempDistance(tempDistance==-1)=nan;
XX(:,11)=tempDistance;
tempDistance=XX(:,12);
tempDistance(tempDistance==-1)=nan;
XX(:,12)=tempDistance;

% Re-organize Pressure Insole data
t_PI=XX(:,13:28);

% Set NaN those sensing elements that have not been selected for the
% recording @200Hz
[rows, columns]=size(t_PI);
for i=1:columns
    if isequal(t_PI(:,i),-ones(rows,1))
        t_PI(:,i)=NaN(rows,1);
    end
end
t_PI=t_PI-2.8;
t_PI=-t_PI/2.8;

% Filter PI signals to remove spikes only for PI @ 200Hz
% Re-sample magnetometer data (maximum sampling frequency 100Hz)
if strcmp(infoStr.Sampling_Frequency,"200Hz")
    t_PI=medfilt1(t_PI,3);

    % Find, replace with NaN, and then linear interpolate repeated
    % magnetometer values
    index = find(diff(XX(:,8)), 1 );
    for i=1:length(XX)
        if mod(i,index+1)~=0
            XX(i,8:10)=nan;
        end
    end
    XX(:,8:10)=fillmissing(XX(:,8:10),'linear');
end

% Sort sensing elements as described in the INDIP documentation
if strcmp(flagPI,'L') || strcmp(flagPI,'l')
    XX(:,13:28)=[t_PI(:,9) t_PI(:,10) t_PI(:,13) t_PI(:,16) t_PI(:,14) t_PI(:,11) t_PI(:,12) t_PI(:,15) t_PI(:,3) t_PI(:,2) t_PI(:,1) t_PI(:,5) t_PI(:,4) t_PI(:,7) t_PI(:,6) t_PI(:,8)];
elseif strcmp(flagPI,'R') || strcmp(flagPI,'r') % Update after SpotCheck of the new presuure insole (Nicolas Leo)
    XX(:,13:28)=[t_PI(:,9) t_PI(:,10) t_PI(:,16) t_PI(:,5) t_PI(:,7) t_PI(:,11) t_PI(:,12) t_PI(:,14)  t_PI(:,4) t_PI(:,8) t_PI(:,6) t_PI(:,1) t_PI(:,13) t_PI(:,3) t_PI(:,15) t_PI(:,2)];
% elseif strcmp(flagPI,'R') || strcmp(flagPI,'r')
%    XX(:,13:28)=[t_PI(:,4) t_PI(:,8) t_PI(:,5) t_PI(:,2) t_PI(:,3) t_PI(:,6) t_PI(:,7) t_PI(:,1)  t_PI(:,14) t_PI(:,16) t_PI(:,15) t_PI(:,13) t_PI(:,9) t_PI(:,12) t_PI(:,11) t_PI(:,10)];
else % PI not used
    XX(:,13:28)=NaN(length(XX),16);
end

%% Set NaN those sensors that have not been selected for the acquisition (infoStr.Mode)
% Distance Sensors
if ~contains(infoStr.Mode,"Distance Sensors")
    [rows, ~]=size(XX);
    XX(:,11:12)=NaN(rows,2);
end
% Pressure Insole
if ~contains(infoStr.Mode,"Pressure Insole")
    [rows, ~]=size(XX);
    XX(:,13:28)=NaN(rows,16);
end
% Baro + Temp
if ~contains(infoStr.Mode,"Baro + Temp")
    [rows, ~]=size(XX);
    XX(:,29:30)=NaN(rows,2);
end
end