% Matlab script that demonstrates infrasound slowness inversion for source backazimuht and
% apparent horizontal velocity, including associated uncertainites. 
% Please, note that the script is provided as a "recipe" for the implementation of the array processing. 
% Users that intend to apply the same processing to their own data will need to adapt this script to their specific
% requirements. 
% 
% The script follows the workflow discussed in:
% De Angelis et al. (2020) ......
%
% Dependencies: GISMO toolbox for Matlab, not provided here but freely available at: https://geoscience-community-codes.github.io/GISMO/

% Author: Silvio De Angelis, University of Liverpool
% Version: 1.0
% Date: 2020/01/15

% Housekeeping
clear all;

%% Add functions and colormap folder to path
addpath ./functions;
addpath ./cmaps;

%% USER INPUTS
% Save output here
outdir = './output';
plotOutput = './plot/out.png';

% Flag for final plot. 1 if a figure is wanted, 0 if not. As default,
% figure is not saved
plotFlag = 0;

% Name of array
arr_name = 'ENCR';

% List of data files
filename1='./data/XZ.ENCR.01.HDF.D.2019.208';
filename2='./data/XZ.ENCR.02.HDF.D.2019.208';
filename3='./data/XZ.ENCR.03.HDF.D.2019.208';
filename4='./data/XZ.ENCR.04.HDF.D.2019.208';
filename5='./data/XZ.ENCR.05.HDF.D.2019.208';
filename6='./data/XZ.ENCR.06.HDF.D.2019.208';

% Output dir - where output of processing is saved in comma-separated .txt
% files
outDir = './output';

% Start and end date/time of period to analyse
snum = datenum(2019,07,27,15,0,0);
enum = datenum(2019,07,27,18,0,0);

% Sampling frequency of data
fs = 100;

% Analise data segments with this duration
duration = 600;

% Taper each data at each end by this factor
taper_val = 0.1; % 0.1 == 10% of trace, 5% at each end

% Bandpass filter cutoff
f1 = 1;
f2 = 10;

% Width (seconds) of sliding window for slowness inversion
window_length = 20;

% Overlap (seconds) of consecutive windows
overlap = 5;

% Array Coordinates and Calibration
chantags = ChannelTag({'XZ.ENCR.01.HDF' 'XZ.ENCR.02.HDF' 'XZ.ENCR.03.HDF' 'XZ.ENCR.04.HDF' 'XZ.ENCR.05.HDF' 'XZ.ENCR.06.HDF'});
cal = (6.10E-05);
stacoords = [37.742870 14.991700
    37.742430 14.991170
    37.743050 14.990980
    37.742100 14.991880
    37.741970 14.990890
    37.742400 14.990290];


%% Processing starts here
% Read datafiles
ww(1) = waveform(filename1,'seed');
ww(2) = waveform(filename2,'seed');
ww(3) = waveform(filename3,'seed');
ww(4) = waveform(filename4,'seed');
ww(5) = waveform(filename5,'seed');
ww(6) = waveform(filename6,'seed');

% Build vector of times for data download
tvec1 = snum:(duration/86400):enum;


% Process data and perform inversion
for ii = 1:length(tvec1)-1
    
    display(['Importing data between ', datestr(tvec1(ii)), ' and ', datestr(tvec1(ii+1))])
    
    % Open file to write output of inversion
    filename=([outDir, '/' arr_name '_' datestr(tvec1(ii),'YYYY-mm-dd-HH-MM-ss') '.txt']);
    fid=fopen (filename,'w+t');
    fprintf(fid,' TIMESTAMP,ARRAY,Azimuth,Velocity,MCCM,Vel_err,Az_err \n');
    
    % Extract data windows for processing
    w(1) = extract(ww(1), 'time', tvec1(ii), tvec1(ii+1));
    w(2) = extract(ww(2), 'time', tvec1(ii), tvec1(ii+1));
    w(3) = extract(ww(3), 'time', tvec1(ii), tvec1(ii+1));
    w(4) = extract(ww(4), 'time', tvec1(ii), tvec1(ii+1));
    w(5) = extract(ww(5), 'time', tvec1(ii), tvec1(ii+1));
    w(6) = extract(ww(6), 'time', tvec1(ii), tvec1(ii+1));
    
    % Make sure all channels are same lenght and there are no NaN
    w = fillgaps(w,0);
    w = fix_data_length(w, duration*fs);
    
    % Demean/detrend data
    w = detrend(demean(w));
    w = taper(w,taper_val);
    
    % Apply calibration to data (not really used now, but could be useful if data are plotted in the future)
    w = w*cal;
    
    % Apply bandpass filter
    f = filterobject('b', [1 10], 2);
    w = filtfilt(f,w);
    
    % Get the start and end times of sliding windows
    [start_num, end_num] = do_overlap(tvec1(ii), tvec1(ii+1), window_length, overlap, fs);
    
    % Extract data from waveform and process each overlapping window
    disp(['Performing slowness inversion ...'])
    
    for jj = 1:length(start_num)
        
        w2 = extract(w, 'TIME', start_num(jj), end_num(jj));
        w2 = fix_data_length(w2, window_length*fs);
        w2 = fillgaps(w2,0);
        x = get(w2, 'data');
        x = cell2mat(x);
        
        % Put data into structure as required by the inversion.m function
        for kk = 1:size(x,2)
            
            D(kk).data = x(:,kk);
            D(kk).stalat = stacoords(kk,1);
            D(kk).stalon = stacoords(kk,2);
            D(kk).fs = fs;
            
        end
        
        % Perform slowness inversion
        [v, srcaz, cmax, sig2th, sig2vl] = do_inversion(D);
        
        vel(jj) = v;
        az(jj) = srcaz;
        mcmm(jj) = mean(cmax);
        azerr(jj) = rad2deg(sqrt(sig2th));
        velerr(jj) = sqrt(sig2vl);
        tt(jj) = (start_num(jj)+end_num(jj))/2;
        
        % Write output to .txt file
        fprintf(fid,'%20s,% 4s,% 3.4f,% 3.4f,% 1.4f,% 3.4f,% 3.4f \n',datestr(start_num(jj),'YYYY-mm-dd HH:MM:ss'),arr_name,az(jj),vel(jj),mcmm(jj),velerr(jj), azerr(jj));
        
    end
end

% Housekeeping
clearvars -except outdir plotFlag plotOutput

%% Import and plot output if required by user
if plotFlag == 1
    
    [tvec, azi, velo, azi_err, velo_err, MCMM] =  import_output(outdir);
    
    % Load colormaps
    load('./cmaps/PRGn.mat')
    cmap2 = cmap;
    load('./cmaps/RdYlBu.mat')
    cmap1 = cmap;
    clear cmap;
    azAxLims = [0 120];
    velAxLims = [300 400];
    
    % Remove low-quality detections or non-detections (unreasonably large
    % uncertainties and low values of mcmm). The inversion processing saves 
    % all results for every data window analysed irrespective of data coherence
    % across the array.  
    
    % Only select results from analyses with MCMM > 0.5 (this should suffice to identify only true volcanic 
    % activity - or any other coherent signal across the array).
    
    [a,~] = find(MCMM > 0.5);
    azi = azi(a);
    velo = velo(a);
    azi_err = azi_err(a);
    velo_err = velo_err(a);
    tvec = tvec(a);
    MCMM = MCMM(a);
    
    % Only results from analyses with back-azimuth error < 2 degrees
    [a,~] = find(azi_err < 2);
    azi = azi(a);
    velo = velo(a);
    azi_err = azi_err(a);
    velo_err = velo_err(a);
    tvec = tvec(a);
    MCMM = MCMM(a);
    
    % Create figure
    figure1 = figure;
    set(figure1, 'Position', [190   370   940   425]);
    % Create axes
    axes1 = axes('Parent',figure1);
    box(axes1,'on');
    % Set the remaining axes properties
    set(axes1,'OuterPosition',[0 0.5 1 0.5]);
    % Plot apparent velocity with error
    scatter(tvec, velo, 40, velo_err, 'filled');
    ylabel('Apparent velocity [m/s]');
    xlabel('Time [hh:mm]');
    ylim(velAxLims);
    set(axes1, 'colormap', cmap2);
    c = colorbar;
    c.Label.String = '\sigma_v [m/s]';
    
    
    % Create axes
    axes2 = axes('Parent',figure1);
    box(axes2,'on');
    % Set the remaining axes properties
    set(axes2,'OuterPosition',[0 0 1 0.5]);
    % Plot azimuth to source with error
    
    scatter(tvec, azi, 40,azi_err, 'filled');
    hold on;
    plot(tvec, 69*ones(length(tvec),1), '--k', 'LineWidth', 2);
    text(tvec(end-10),80,'NSEC');
    ylabel('Backazimuth [deg from N]');
    xlabel('Time [hh:mm]');
    ylim(azAxLims)
    set(axes2, 'colormap', cmap1);
    c2 = colorbar;
    c2.Label.String = '\sigma_{az} [deg]';
    %Datetime on horizontal axis
    datetick2('x', 'HH:MM');
    
else
    
end
