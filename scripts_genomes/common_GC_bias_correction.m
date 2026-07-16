function [output] = common_GC_bias_correction(input)
%% Corrects GC bias per standard display bin in Common_CNV files for analysis pipeline.

num_chroms = length(input);

%% figure out how much data was provided.
dataLength = 0;
for chrom = 1:num_chroms
	dataLength = dataLength + length(input{chrom});
end;

%% Load GC_ratio data...
X_data   = zeros(1,dataLength);

%% gather CNV data from input...
Y_data   = zeros(1,dataLength);
current  = 0;
for chrom = 1:num_chroms;
	for bin = 1:length(input{chrom})
		current = current + 1;
		Y_data(current) = input{chrom,2}(bin);
	end;
end;

fprintf('\tPreparing for LOWESS fitting : GC_ratio vs CNV data.\n');

%% Perform LOWESS fitting.
fprintf('\tLOWESS fitting to reference data.\n');
[newX2, newY2] = optimize_mylowess(X_data,Y_data,10, 0);
fprintf('\tLOWESS fitting to reference data complete.\n');

Y_target          = 1;
for chrom = 1:num_chroms
	Y_fitCurve    = interp1(newX2,newY2,input{chrom,2},'spline');
	output{chrom,1} = 1;
	output{chrom,2} = input{chrom,2}./Y_fitCurve*Y_target;
end;
