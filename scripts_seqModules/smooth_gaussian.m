function s = smooth_gaussian(data,sigma,size)

%%%    data  : input vector with raw data.
%%%    sigma : standard deviation of the gaussian distribution used in the smoothing.
%%%    size  : size of vector over which smoothing function is applied.   (2-3 sigmas is usually good.)

% Force data to be a row vector for safe concatenation
is_col_vector = false;
if size(data, 1) > 1
	data = data';
	is_col_vector = true;
end;

%%% Gaussian smoothing.
halfsize = round(size/2);
a        = 1/(sqrt(2*pi)*sigma);
b        = 1/(2*sigma^2);
w        = a*exp(-b*(-halfsize:1:halfsize).^2);
w        = w/sum(w);   % normalize the filter to a total of 1.

%%% Extends endpoint data to larger than smoothing width.
data_L_val = data(1);
data_R_val = data(end);
pad_len    = size * 4;
data_L = ones(1, pad_len)*data_L_val;
data_R = ones(1, pad_len)*data_R_val;
extended_data = [data_L data data_R];

%%% filters data and shifts smoothing left to align with data.
filtered = circshift(filter(w,1,extended_data),[1 -halfsize]);

% Trims off the padded data used to ensure median filter works.
start_idx = pad_len + 1;
end_idx   = length(filtered) - pad_len;
s = filtered(start_idx:end_idx);

% Restore to a column vector if the input was originally a column vector
if is_col_vector
	s = s';
end
