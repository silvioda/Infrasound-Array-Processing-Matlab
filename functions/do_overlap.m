function [start_num, end_num] = do_overlap(snum, enum, win_sec, overlap_sec, fs)
% MAKE_OVERLAP Calculate start and end times of sliding window along a data vector including overlap.

% Author: Silvio De Angelis, University of Liverpool
% Version: 1.0 
% Date: 2020/01/15 


% Nunmber of data segments
nx = (enum-snum)*86400*fs;
nsegments = fix((nx-(overlap_sec*fs))/((win_sec*fs)-(overlap_sec*fs)));

% Initialize output
start_num = zeros(1, nsegments);
end_num = zeros(1, nsegments);

% Calculate start and end times of each window
for jj = 1:nsegments
    start_num(jj) = snum + ((jj-1)*((win_sec-overlap_sec)/86400));
    end_num(jj) = start_num(jj) + win_sec/86400;
end



