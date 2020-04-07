function [v, srcaz, cmax, sig2th, sig2vl, sig2dt] = do_inversion(D)
%INVERSION Invert array infrasound data for backazimuth to the source and apparent horizontal velocity across the array
%
%   [V, SRCAZ, CMAX, SIG2TH, SIG2VL, SIG2TAU, SIG2DT] = inversion(D) Perform array slowness inversion for infrasound 
%   data from N channels stored in Matlab structure D of size 1XN and fields: 
%                                
%     D(i).data = Infrasound data (i-th channel)
%     D(i).stalat = Microphone latitude (i-th channel)
%     D(i).stalon = Microphone longitude (i-th channel)
%     D(i).fs = Data sampling frequency (i-th channel)
%
%   The function returns:
%
%     v = Apparent horizontal velocity across the array for each processing data window 
%     srcaz = Direction of Arrival (DOA) for each processing data window
%     cmax = Max multistation cross-correlation coefficient  
%     sig2th = variance of DOA for each processing data window 
%     sig2vl = Variance of v for each processing data window  
%     sig2dt = Variance of time delay measurements for each processing data window

% Author: Silvio De Angelis, University of Liverpool
% Version: 1.0 
% Date: 2020/01/15 

% Number of channels
L = length(D);

% Sampling frequency (must be the same for all channels)
fs = D(1).fs;

% Inter-station distances and azimuths across the array
d = [];
az = [];
for ii = 1:L
    for jj = ii+1:L
        [alen, azi] = distance(D(ii).stalat,D(ii).stalon,D(jj).stalat,D(jj).stalon);
        dist = deg2km(alen);
        d = [d dist];
        az = [az azi];
    end
end

% Convert distance in meters
d = d*1000;

% Time lags and max cross-correlation coefficients between all station pairs in the array
lags = [];
cmax = [];
for ii = 1:L-1
    for jj = ii+1:L
        [cc, ll] = xcorr(D(ii).data,D(jj).data, 'coeff');
        [a,b] = max(cc);
        cmax = [cmax, a];
        lags = [lags, ll(b)];
    end
end

% Convert time lags in seconds
dt =lags/fs;

% Generalized inverse of slowness matrix
Dm = transpose([d.*cos(az.*(pi/180)); d.*sin(az.*(pi/180))]);
Gmi = inv(transpose(Dm)*Dm);

% Solve for slowness using least squares
sv = Gmi*transpose(Dm)*transpose(dt);

% Obtain velocity from slowness
v = 1/sqrt((sv(1)^2)+(sv(2)^2));

% Cosine and Sine for backazimuth
caz = v*sv(1);
saz = v*sv(2);

% 180 degree resolved backazimuth to source
srcaz = atan2(saz,caz)*(180/pi);
if srcaz < 0
    
    srcaz = srcaz+360;

end

% Estimate of data covariance from Szuberla and Olson (2004), their equation 5
sig2dt = (dt*(eye(length(Dm))-Dm*Gmi*transpose(Dm))*transpose(dt))/(length(Dm)-2);

% Model covariance in terms of slowness assuming independent, Gaussian noise
sig2sx = sig2dt*Gmi(1,1);
sig2sy = sig2dt*Gmi(2,2);
covsxsy = sig2dt*Gmi(1,2);

% Variance of trace velocity and azimuth these are obtained by propagation of errors and differentiation
sig2vl = sig2sx*(sv(1)^2)*(v^6) + sig2sy*(sv(2)^2)*(v^6) + 2*covsxsy*sv(1)*sv(2)*(v^6);
sig2th = sig2sx*(sv(2)^2)*(v^4) + sig2sy*(sv(1)^2)*(v^4) - 2*covsxsy*sv(1)*sv(2)*(v^4);

