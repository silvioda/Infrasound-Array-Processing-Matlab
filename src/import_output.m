function [tvec, azi, velo, azerr, velerr, MCMM] =  import_output(outdir)
%IMPORT_OUTPUT Import data from output text file of infrasound array inversion
%
%  [TVEC,, AZIMUTH, VELOCITY, MCCM, VEL_ERR, AZ_ERR] = IMPORT_OUTPUT(FILENAME) reads data from text files in directory OUTDIR and returns 
%  the data as column vectors.


out = dir([outdir, '/*.txt']);
N = size(out,1);

% Initialize output
tvec = [];
azi = [];
velo = [];
MCMM = [];
velerr = [];
azerr = [];

for ii = 1:N
    
    fpath = [out(ii).folder, '/', out(ii).name];
    disp(['Importing output file ', num2str(ii), ' of ', num2str(N)])
    [tt, ~, az, vel, mcmm, vel_err, az_err] = importfile(fpath);
    tvec = [tvec; datenum(tt)];
    azi = [azi; az];
    velo = [velo; vel];
    MCMM = [MCMM; mcmm];
    velerr = [velerr; vel_err];
    azerr = [azerr; az_err];

end


function [tt, array, az, vel, mcmm, vel_err, az_err] = importfile(filename, dataLines)
%IMPORTFILE Import data from a text file
%  [TIMESTAMP, ARRAY, AZIMUTH, VELOCITY, MCCM, VEL_ERR, AZ_ERR] =
%  IMPORTFILE(FILENAME) reads data from text file FILENAME for the
%  default selection.  Returns the data as column vectors.
%
%  [TIMESTAMP, ARRAY, AZIMUTH, VELOCITY, MCCM, VEL_ERR, AZ_ERR] =
%  IMPORTFILE(FILE, DATALINES) reads data for the specified row
%  interval(s) of text file FILENAME. Specify DATALINES as a positive
%  scalar integer or a N-by-2 array of positive scalar integers for
%  dis-contiguous row intervals.
%
%  Example:
%  [TIMESTAMP, ARRAY, Azimuth, Velocity, MCCM, Vel_err, Az_err] = importfile("/Users/volcanolab/Desktop/array_proc_demo/output/ENCR_2019-07-27-15-00-00.txt", [2, Inf]);


%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [2, Inf];
end

%% Setup the Import Options
opts = delimitedTextImportOptions("NumVariables", 7);

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["TIMESTAMP", "ARRAY", "Azimuth", "Velocity", "MCCM", "Vel_err", "Az_err"];
opts.VariableTypes = ["datetime", "categorical", "double", "double", "double", "double", "double"];
opts = setvaropts(opts, 1, "InputFormat", "yyyy-MM-dd HH:mm:ss");
opts = setvaropts(opts, 2, "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
tbl = readtable(filename, opts);

%% Convert to output type
tt = tbl.TIMESTAMP;
array = tbl.ARRAY;
az = tbl.Azimuth;
vel = tbl.Velocity;
mcmm = tbl.MCCM;
vel_err = tbl.Vel_err;
az_err = tbl.Az_err;