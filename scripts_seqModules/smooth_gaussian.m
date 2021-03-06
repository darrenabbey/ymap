function s = smooth_gaussian(data,sigma,size)

%    data  : input vector with raw data.
%    sigma : standard deviation of the gaussian distribution used in the smoothing.
%    size  : size of vector over which smoothing function is applied.   (2-3 sigmas is usually good.)

% Gaussian smoothing.
halfsize = round(size/2);
a        = 1/(sqrt(2*pi)*sigma);
b        = 1/(2*sigma^2);
w        = a*exp(-b*(-halfsize:1:halfsize).^2);
w        = w/sum(w);   % normalize the filter to a total of 1.

% Extends endpoint data to larger than smoothing width.
data_L_val = data(1);
data_R_val = data(end);
data_L = ones(1,size*4)*data_L_val;
data_R = ones(1,size*4)*data_R_val;
data = [data_L data data_R];

% filters data and shifts smoothing left to align with data.
filtered = circshift(filter(w,1,data),[1 -halfsize]);

% crops away the extended endpoint data from the raw and smoothed data.
filtered(1:size*4) = [];
filtered((end-size*4+1):end) = [];
data(1:size*4) = [];
data((end-size*4+1):end) = [];
s = filtered;
