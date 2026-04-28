function [x_peak,actual_cutoffs,mostLikelyGaussians, Rsquared] = FindGaussianCutoffs_3(workingDir,descriptionString, chromosome,segment,copyNum, smoothed_Histogram, makeFitFigures);
graphics_toolkit gnuplot;

%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
% hide figures during construction.
set(0,'DefaultFigureVisible','off');

versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;

%%% Define allelic ratio peak locations.
monosomy_peaks  = [0, 1]*199+1;
disomy_peaks    = [0, 1/2, 1]*199+1;
trisomy_peaks   = [0, 1/3, 2/3, 1]*199+1;
tetrasomy_peaks = [0, 1/4, 2/4, 3/4, 1]*199+1;
pentasomy_peaks = [0, 1/5, 2/5, 3/5, 4/5, 1]*199+1;
hexasomy_peaks  = [0, 1/6, 2/6, 3/6, 4/6, 5/6, 1]*199+1;
heptasomy_peaks = [0, 1/7, 2/7, 3/7, 4/7, 5/7, 6/7, 1]*199+1;
octasomy_peaks  = [0, 1/8, 2/8, 3/8, 4/8, 5/8, 6/8, 7/8, 1]*199+1;
nonasomy_peaks  = [0, 1/9, 2/9, 3/9, 4/9, 5/9, 6/9, 7/9, 8/9, 1]*199+1;

%% Calculation of Gaussians against per chromosome data.
% Fits Gaussians to real data per chromomsome, then determines equal probability cutoffs between them.
sigma = 5;
%% FindGaussianCutoffs Finds cutoffs as intersections of Gaussians, fit to the data at each peak location.
ErrorType      = 'cubic';
% Define range of fit curves.
range = 1:200;

if (copyNum == 0)
	G                   = [];
	list                = [];
	x_peak              = [];
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	Rsquared = 0.0;
elseif (copyNum == 1)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, Rsquared] = ...
		fit_Gaussian_model_monosomy_2(workingDir,descriptionString, smoothed_Histogram,monosomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:2; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 2)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b ,G{2}.c, G{3}.a, G{3}.b, G{3}.c, Rsquared] = ...
		fit_Gaussian_model_disomy_2(workingDir,descriptionString, smoothed_Histogram,disomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:3; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 3)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, Rsquared] = ...
		fit_Gaussian_model_trisomy_2(workingDir,descriptionString, smoothed_Histogram,trisomy_peaks,sigma,ErrorType, makeFitFigures);
	list                = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:4; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 4)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, G{5}.a, G{5}.b, G{5}.c, Rsquared] = ...
		fit_Gaussian_model_tetrasomy_2(workingDir,descriptionString, smoothed_Histogram,tetrasomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:5; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 5)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, G{5}.a, G{5}.b, G{5}.c, G{6}.a, G{6}.b, G{6}.c, Rsquared] = ...
		fit_Gaussian_model_pentasomy_2(workingDir,descriptionString, smoothed_Histogram,pentasomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:6; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 6)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, G{5}.a, G{5}.b, G{5}.c, G{6}.a, G{6}.b, G{6}.c, G{7}.a, G{7}.b, G{7}.c, Rsquared] = ...
		fit_Gaussian_model_hexasomy_2(workingDir,descriptionString, smoothed_Histogram,hexasomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:7; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 7)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, G{5}.a, G{5}.b, G{5}.c, G{6}.a, G{6}.b, G{6}.c, G{7}.a, G{7}.b, G{7}.c, G{8}.a, G{8}.b, G{8}.c, Rsquared] = ...
		fit_Gaussian_model_heptasomy_2(workingDir,descriptionString, smoothed_Histogram,heptasomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:8; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
elseif (copyNum == 8)
	G                  = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, G{5}.a, G{5}.b, G{5}.c, G{6}.a, G{6}.b, G{6}.c, G{7}.a, G{7}.b, G{7}.c, G{8}.a, G{8}.b, G{8}.c, G{9}.a, G{9}.b, G{9}.c, Rsquared] = ...
		fit_Gaussian_model_octasomy_2(workingDir,descriptionString, smoothed_Histogram,octasomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:9; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
else % if (copyNum == 9+)
	G                   = [];
	[G{1}.a, G{1}.b, G{1}.c, G{2}.a, G{2}.b, G{2}.c, G{3}.a, G{3}.b, G{3}.c, G{4}.a, G{4}.b, G{4}.c, G{5}.a, G{5}.b, G{5}.c, G{6}.a, G{6}.b, G{6}.c, G{7}.a, G{7}.b, G{7}.c, G{8}.a, G{8}.b, G{8}.c, G{9}.a, G{9}.b, G{9}.c, G{10}.a, G{10}.b, G{10}.c, Rsquared] = ...
		fit_Gaussian_model_nonasomy_2(workingDir,descriptionString, smoothed_Histogram,nonasomy_peaks,sigma,ErrorType, makeFitFigures);
	[list]              = FindHighestGaussian_2(G);
	actual_cutoffs      = [];
	mostLikelyGaussians = [];
	x_peak              = [];
	for i = 1:9; x_peak(i) = G{i}.b; end;

	for i = 1:199
		if (list(i) ~= list(i+1))   % we've found a boundary.
			actual_cutoffs = [actual_cutoffs (i+0.5)];
			mostLikelyGaussians = [mostLikelyGaussians list(i)];
		end;
	end;
	mostLikelyGaussians = [mostLikelyGaussians list(200)];
end;

end
