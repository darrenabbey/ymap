function [] = CNV_v6_6(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString, ...
                       CNV_verString,rDNA_verString,displayBREAKS, referenceCHR);
addpath('../');

% hide figures during construction.
set(0,'DefaultFigureVisible','off');


%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
workingDir = [main_dir 'users/' user '/projects/' project '/'];
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir 'users/' user '/projects/' project '/figure_options.txt'], 'file')
	%%
	%% readtable is not implemented in Octave.
	%%
	%figure_options = readtable([main_dir 'users/' user '/projects/' project '/figure_options.txt']);

	figure_options = importdata([main_dir 'users/' user '/projects/' project '/figure_options.txt'],'\t',1);

	option         = figure_options{2,1};
	if strcmp(option,'False')
		Make_figure_bias_GC = false;
	else
		Make_figure_bias_GC = true;
	end;

	option         = figure_options{3,1};
	if strcmp(option,'False')
		Make_figure_bias_end = false;
	else
		Make_figure_bias_end = true;
	end;

	option         = figure_options{4,1};
	if strcmp(option,'False')
		Make_figure_linear = false;
	else
		Make_figure_linear = true;
	end;

	option         = figure_options{5,1};
	if strcmp(option,'False')
		Make_figure_standard = false;
	else
		Make_figure_standard = true;
	end;
else
	Make_figure_bias_end = true;
	Make_figure_bias_GC  = true;
	Make_figure_linear   = true;
	Make_figure_standard = true;
end;

%% ========================================================================

Centromere_format_default   = 1;
Yscale_nearest_even_ploidy  = true;
HistPlot                    = true;
ChrNum                      = true;
show_annotations            = true;
analyze_rDNA                = true;
Standard_display            = Make_figure_standard;
Linear_display              = Make_figure_linear;
Linear_displayBREAKS        = false;
Low_quality_ploidy_estimate = true;


%%=========================================================================
% Load FASTA file name from 'reference.txt' file for project.
%--------------------------------------------------------------------------
Reference    = [main_dir 'users/' genomeUser '/genomes/' genome '/reference.txt'];
FASTA_string = strtrim(fileread(Reference));
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%=========================================================================
% Control variables.
%--------------------------------------------------------------------------
projectDir = [main_dir 'users/' user '/projects/' project '/'];
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];

fprintf(['\n$$ projectDir : ' projectDir '\n']);
fprintf([  '$$ genomeDir  : ' genomeDir  '\n']);
fprintf([  '$$ genome     : ' genome     '\n']);
fprintf([  '$$ project    : ' project    '\n']);

[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
Aneuploidy = [];

num_chrs  = length(chr_sizes);

for i = 1:num_chrs
	chr_size(i)  = 0;
	cen_start(i) = 0;
	cen_end(i)   = 0;
end;
for i = 1:num_chrs
    chr_size(chr_sizes(i).chr)    = chr_sizes(i).size;
    cen_start(centromeres(i).chr) = centromeres(i).start;
    cen_end(centromeres(i).chr)   = centromeres(i).end;
end;
if (length(annotations) > 0)
    fprintf(['\nAnnotations for ' genome '.\n']);
    for i = 1:length(annotations)
        annotation_chr(i)       = annotations(i).chr;
        annotation_type{i}      = annotations(i).type;
        annotation_start(i)     = annotations(i).start;
        annotation_end(i)       = annotations(i).end;
        annotation_fillcolor{i} = annotations(i).fillcolor;
        annotation_edgecolor{i} = annotations(i).edgecolor;
        annotation_size(i)      = annotations(i).size;
        fprintf(['\t[' num2str(annotations(i).chr) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' ...
            annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
    end;
end;
for i = 1:length(figure_details)
	if (figure_details(i).chr == 0)
		if (strcmp(figure_details(i).label,'Key') == 1)
			key_posX   = figure_details(i).posX;
			key_posY   = figure_details(i).posY;
			key_width  = figure_details(i).width;
			key_height = figure_details(i).height;
		end;
	else
		chr_id         (figure_details(i).chr) = figure_details(i).chr;
		chr_label      {figure_details(i).chr} = figure_details(i).label;
		chr_name       {figure_details(i).chr} = figure_details(i).name;
		chr_posX       (figure_details(i).chr) = figure_details(i).posX;
		chr_posY       (figure_details(i).chr) = figure_details(i).posY;
		chr_width      (figure_details(i).chr) = figure_details(i).width;
		chr_height     (figure_details(i).chr) = figure_details(i).height;
		chr_in_use     (figure_details(i).chr) = str2num(figure_details(i).useChr);
		chr_figOrder   (figure_details(i).chr) = str2num(figure_details(i).figOrder);
		chr_figReversed(figure_details(i).chr) = str2num(figure_details(i).figReversed);
	end;
end;


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

% Sanitize user input of euploid state base for species.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chr figure.
bases_per_bin    = max(chr_size)/700;
maxY             = ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/5;
cen_tel_Yindent2 = maxY/2;

fprintf(['\nGenerating CNV figure from ''' project ''' sequence data.\n']);

% Initializes vectors used to hold copy number data.
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		% 1 category tracked : average read counts per bin.
		chr_CNVdata{chr}= zeros(1,ceil(chr_size(chr)/bases_per_bin));
	end;
end;


%%================================================================================================
% Load CGH data from 'preprocessed_CNVs.txt' file.
%-------------------------------------------------------------------------------------------------
if (exist([projectDir 'CNV_' CNV_verString '.mat'],'file') == 0)
	fprintf('\nMAT file not found, regenerating.\n');
	datafile = [projectDir 'preprocessed_CNVs.txt'];
	data     = fopen(datafile, 'r');
	lines_analyzed = 0;
	while not (feof(data))
		dataLine = fgetl(data);
		if (length(dataLine) > 0)
			if (dataLine(1) ~= '#')
				lines_analyzed             = lines_analyzed+1;
				chr                        = str2num(sscanf(dataLine, '%s',1));
				fragment_start             = sscanf(dataLine, '%s',2);  for i = 1:size(sscanf(dataLine,'%s',1),2);      fragment_start(1) = []; end;    fragment_start = str2num(fragment_start);
				fragment_end               = sscanf(dataLine, '%s',3);  for i = 1:size(sscanf(dataLine,'%s',2),2);      fragment_end(1)   = []; end;    fragment_end   = str2num(fragment_end);
				readAverage                = sscanf(dataLine, '%s',4);  for i = 1:size(sscanf(dataLine,'%s',3),2);      readAverage(1)    = []; end;    readAverage    = str2num(readAverage);
				position                   = ceil(fragment_start/bases_per_bin);

				% defining position with fragment_end results in much fuzzier data.
				chr_CNVdata{chr}(position) = readAverage;
			end;
		end;
	end;
	fclose(data);

	save([projectDir 'CNV_' CNV_verString '.mat'],'chr_CNVdata');

	%% change permissions of file.
	system(['chmod 664 ' projectDir 'CNV_' CNV_verString '.mat']);
else
	fprintf('\nMAT file found, loading.\n');
	load([projectDir 'CNV_' CNV_verString '.mat']);
end;


%% ====================================================================
% Load bias selections from 'dataBiases.txt' file.
%----------------------------------------------------------------------
datafile = [projectDir 'dataBiases.txt'];
if (exist(datafile,'file') == 0)
	performGCbiasCorrection    = true;
	performRepetbiasCorrection = false;
	performEndbiasCorrection   = true;
else
	biases_fid = fopen(datafile, 'r');
	bias1      = fgetl(biases_fid);	% performLengthbiasCorrection
	bias2      = fgetl(biases_fid);	% performGCbiasCorrection
	bias3      = fgetl(biases_fid);	% performRepetbiasCorrection
	bias4      = fgetl(biases_fid);	% performEndbiasCorrection
	fclose(biases_fid);

	fprintf('%%%% Load data bias correction selections:\n');
	fprintf(['%%%%   bias1 = ' bias1 '\n']);
	fprintf(['%%%%   bias2 = ' bias2 '\n']);
	fprintf(['%%%%   bias3 = ' bias3 '\n']);
	fprintf(['%%%%   bias4 = ' bias4 '\n']);
	fprintf('%%%%\n');

	% performLengthbiasCorrection is meaningless for this data format.

	if (strcmp(bias2,'True') == 1)
		performGCbiasCorrection    = true;
	else
		performGCbiasCorrection    = false;
	end;

	% Repetitiveness bias correction is turned off, as endedup not being more useful than %GC correction.
	if (strcmp(bias3,'True') == 1)
		performRepetbiasCorrection = false;
		performGCbiasCorrection    = true; % needed since repet bias use gc data
	else
		performRepetbiasCorrection = false;
	end;

	if (strcmp(bias4,'True') == 1)
		performEndbiasCorrection   = true;
		performGCbiasCorrection    = true; % needed since end bias use gc data
	else
		performEndbiasCorrection   = false;
	end;
end;

% performGCbiasCorrection
% performRepetbiasCorrection
% performEndbiasCorrection


%% -----------------------------------------------------------------------------------------
% Setup for LOWESS fitting and figure generation.
%-------------------------------------------------------------------------------------------
% calculate CGH bin values.
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		CNVplot{chr} = chr_CNVdata{chr};
	end;
end;

% Gather CGH data for LOWESS fitting.
CGHdata_all = [];
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		CGHdata_all = [CGHdata_all     CNVplot{chr}];
	end;
end;
medianRawY = median(CGHdata_all)

% Gather median-normalized CGH data for LOWESS fitting.
CGHdata_all = [];
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		if (medianRawY ~= 0)
			CNVplot{chr} = CNVplot{chr}/medianRawY;
		end;
		CGHdata_all = [CGHdata_all CNVplot{chr}];
	end;
end;


%% ====================================================================
% Apply GC bias correction to CGH data.
%   Average read counts vs. GCbias per standard bin.
%----------------------------------------------------------------------


%%================================================================================================
% Load pre-processed standard-bin fragment GC-bias data for genome.
%-------------------------------------------------------------------------------------------------
if (performGCbiasCorrection)
	fprintf(['standard_bins_GC_ratios_file :\n\t' main_dir 'users/' genomeUser '/genomes/' genome '/' FastaName '.GC_ratios.standard_bins.txt\n']);
	standard_bins_GC_ratios_fid = fopen([main_dir 'users/' genomeUser '/genomes/' genome '/' FastaName '.GC_ratios.standard_bins.txt'], 'r');
	fprintf(['\t' num2str(standard_bins_GC_ratios_fid) '\n']);
	lines_analyzed = 0;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			chr_GCratioData{chr} = zeros(1,ceil(chr_size(chr)/bases_per_bin));
		end;
	end;
	while not (feof(standard_bins_GC_ratios_fid))
		dataLine = fgetl(standard_bins_GC_ratios_fid);
		if (length(dataLine) > 0)
			if (dataLine(1) ~= '#')
				lines_analyzed = lines_analyzed+1;
				chr            = str2num(sscanf(dataLine, '%s',1));
				fragment_start = sscanf(dataLine, '%s',2);  for i = 1:size(sscanf(dataLine,'%s',1),2);      fragment_start(1) = []; end;    fragment_start = str2num(fragment_start);
				fragment_end   = sscanf(dataLine, '%s',3);  for i = 1:size(sscanf(dataLine,'%s',2),2);      fragment_end(1) = [];   end;    fragment_end   = str2num(fragment_end);
				GCratio        = sscanf(dataLine, '%s',4);  for i = 1:size(sscanf(dataLine,'%s',3),2);      GCratio(1) = [];        end;    GCratio        = str2num(GCratio);
				position       = ceil(fragment_start/bases_per_bin);
				chr_GCratioData{chr}(position) = GCratio;
			end;
		end;
	end;
	fclose(standard_bins_GC_ratios_fid);
end;


%%================================================================================================
% Load pre-processed standard bin repetitiveness data for genome.
%-------------------------------------------------------------------------------------------------
if (performRepetbiasCorrection)
	fprintf(['standard_bins_repetitiveness_file :\n\t' main_dir 'users/' genomeUser '/genomes/' genome '/' FastaName '.repetitiveness.standard_bins.txt\n']);
	standard_bins_repetitiveness_fid = fopen([main_dir 'users/' genomeUser '/genomes/' genome '/' FastaName '.repetitiveness.standard_bins.txt'], 'r');
	fprintf(['\t' num2str(standard_bins_repetitiveness_fid) '\n']);
	lines_analyzed = 0;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			chr_repetitivenessData{chr} = zeros(1,ceil(chr_size(chr)/bases_per_bin));
		end;
	end;
	while not (feof(standard_bins_repetitiveness_fid))
		dataLine = fgetl(standard_bins_repetitiveness_fid);
		if (length(dataLine) > 0)
			if (dataLine(1) ~= '#')
				% The number of valid lines found so far...  the number of usable standard fragments with data so far.
				chr            = str2num(sscanf(dataLine, '%s',1));
				fragment_start = sscanf(dataLine, '%s',2);  for i = 1:size(sscanf(dataLine,'%s',1),2);      fragment_start(1) = []; end;    fragment_start = str2num(fragment_start);
				fragment_end   = sscanf(dataLine, '%s',3);  for i = 1:size(sscanf(dataLine,'%s',2),2);      fragment_end(1)   = []; end;    fragment_end   = str2num(fragment_end);
				repetitiveness = sscanf(dataLine, '%s',4);  for i = 1:size(sscanf(dataLine,'%s',3),2);      repetitiveness(1) = []; end;    repetitiveness = str2num(repetitiveness);
				position       = ceil(fragment_start/bases_per_bin);
				chr_repetitivenessData{chr}(position) = repetitiveness;
			end;
		end;
	end;
	fclose(standard_bins_repetitiveness_fid);
end;


%%================================================================================================
% Calculate distance from fragment center to nearest end of chromosome.
%-------------------------------------------------------------------------------------------------
if (performEndbiasCorrection)
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			chr_EndDistanceData{chr} = zeros(1,ceil(chr_size(chr)/bases_per_bin));
		end;
	end;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			for position = 1:ceil(chr_size(chr)/bases_per_bin)
				frag_size                          = ceil(chr_size(chr)/bases_per_bin);
				frag_center                        = position;
				frag_nearestChrEnd                 = min(frag_center, frag_size - frag_center);
				chr_EndDistanceData{chr}(position) = frag_nearestChrEnd;
			end;
		end;
	end;

	% Extend EndDistance data for shorter chromosomes to length of the midpoint of the longest chromosome.
	chr_EndDistanceData_extended = chr_EndDistanceData;
	largest_chr_bin_count        = ceil(max(chr_size)/bases_per_bin);
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			chr_bin_count = ceil(chr_size(chr)/bases_per_bin);
			for pos = 1:(largest_chr_bin_count - chr_bin_count)
				bin_center                               = pos + chr_bin_count/2;
				chr_EndDistanceData_extended{chr}(end+1) = min(bin_center, largest_chr_bin_count - bin_center);
			end;
		end;
	end;
end;


%%================================================================================================
% Perform bias corrections.
%-------------------------------------------------------------------------------------------------
if (performEndbiasCorrection)
	% Extend CGH data for shorter chromosomes to length of the midpoint of the longest chromosome.
	chr_CGHdata_extended  = [];
	%largest_chr_bin_count = ceil(max(chr_size)/bases_per_bin);
	[largest_chr_size,largest_chr] = max(chr_size);
	largest_chr_bin_count = ceil(largest_chr_size/bases_per_bin);

	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			chr_CGHdata_extended{chr} = CNVplot{chr};
		end;
	end;

	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			chr_bin_count     = ceil(chr_size(chr)/bases_per_bin);
			fprintf(['chr_bin_count(' num2str(chr) ') = ' num2str(chr_bin_count) '\n']);
			chr_middle_bin    = round(chr_bin_count/2);
			fprintf(['chr_middle_bin   = ' num2str(chr_middle_bin) '\n']);
			median_range = min(20, chr_bin_count/4); % Bin length could be less than 40, so taking a range of 20 crashes the analysis.

			%center_median_CGH = mean(chr_CGHdata_extended{chr}((chr_middle_bin-median_range):(chr_middle_bin+median_range)));

			for pos = 1:(largest_chr_bin_count - chr_bin_count)
				%% Results in chr end correction not being done well for center of large chromosomes.
				%chr_CGHdata_extended{chr}(end+1) = center_median_CGH;

				%% Results in chr end correction being done effectively for all areas.
				chr_CGHdata_extended{chr}(end+1) = chr_CGHdata_extended{largest_chr}(pos+chr_bin_count);
			end;
		end;
	end;

	% Gather data for LOWESS fitting 3 : Chr end bias.
	CGHdata_all_n1                   = [];
	GCratioData_all                  = [];
	chr_EndDistanceData_all          = [];
	chr_CGHdata_extended_all         = [];
	chr_EndDistanceData_extended_all = [];
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			CGHdata_all_n1                   = [CGHdata_all_n1                   CNVplot{chr}                     ];
			GCratioData_all                  = [GCratioData_all                  chr_GCratioData{chr}             ];
			chr_EndDistanceData_all          = [chr_EndDistanceData_all          chr_EndDistanceData{chr}         ];

			chr_CGHdata_extended_all         = [chr_CGHdata_extended_all         chr_CGHdata_extended{chr}        ];
			chr_EndDistanceData_extended_all = [chr_EndDistanceData_extended_all chr_EndDistanceData_extended{chr}];
		end;
	end;

	% Clean up data by:
	%    deleting GC ratio data near zero.
	%    deleting CGH data beyond 3* the median value.  (rDNA, etc.)
	CGHdata_clean                                        = CGHdata_all_n1;
	GCratioData_clean                                    = GCratioData_all;
	chr_EndDistanceData_clean                            = chr_EndDistanceData_all;
	chr_CGHdata_extended_clean                           = chr_CGHdata_extended_all;
	chr_EndDistanceData_extended_clean                   = chr_EndDistanceData_extended_all;

	chr_EndDistanceData_clean(         GCratioData_clean <  0.01) = [];
	CGHdata_clean(                     GCratioData_clean <  0.01) = [];
	chr_CGHdata_extended_clean(        GCratioData_clean <  0.01) = [];
	chr_EndDistanceData_extended_clean(GCratioData_clean <  0.01) = [];
	GCratioData_clean(                 GCratioData_clean <  0.01) = [];

	chr_EndDistanceData_clean(         CGHdata_clean     >  6   ) = [];
	GCratioData_clean(                 CGHdata_clean     >  6   ) = [];
	chr_CGHdata_extended_clean(        CGHdata_clean     >  6   ) = [];
	chr_EndDistanceData_extended_clean(CGHdata_clean     >  6   ) = [];
	CGHdata_clean(                     CGHdata_clean     >  6   ) = [];

	chr_EndDistanceData_clean(         CGHdata_clean     == 0   ) = [];
	GCratioData_clean(                 CGHdata_clean     == 0   ) = [];
	chr_CGHdata_extended_clean(        CGHdata_clean     == 0   ) = [];
	chr_EndDistanceData_extended_clean(CGHdata_clean     == 0   ) = [];
	CGHdata_clean(                     CGHdata_clean     == 0   ) = [];

	% Perform LOWESS fitting : end bias.
	rawData_X1     = chr_EndDistanceData_extended_clean;
	rawData_Y1     = chr_CGHdata_extended_clean;
	% perform correction only if the data it not empty
	if (~isempty(rawData_X1) && ~isempty(rawData_Y1))
		fprintf(['Lowess X:Y size : [' num2str(size(rawData_X1,1)) ',' num2str(size(rawData_X1,2)) ']:[' num2str(size(rawData_Y1,1)) ',' num2str(size(rawData_Y1,2)) ']\n']);
		[fitX1, fitY1] = optimize_mylowess(rawData_X1,rawData_Y1,10, 0);

		% Correct data using normalization to LOWESS fitting
		Y_target = 1;
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				fprintf(['chr' num2str(chr) ' : ' num2str(length(chr_GCratioData{chr})) ' ... ' num2str(length(CNVplot{chr})) '\t; numbins = ' num2str(ceil(chr_size(chr)/bases_per_bin)) '\n']);
				rawData_chr_X1{chr}        = chr_EndDistanceData{chr};
				rawData_chr_Y1{chr}        = CNVplot{chr};
				fitData_chr_Y1{chr}        = interp1(fitX1,fitY1,rawData_chr_X1{chr},'spline');
				normalizedData_chr_Y1{chr} = rawData_chr_Y1{chr}./fitData_chr_Y1{chr}*Y_target;
				% setting all NaN values to zero (since dividing by zero
				% can occur in empty dataset)
				normalizedData_chr_Y1{chr}(isnan(normalizedData_chr_Y1{chr}))=0;
			end;
		end;
	else
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				normalizedData_chr_Y1{chr} = CNVplot{chr};
			end;
		end;
	end;
else
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			normalizedData_chr_Y1{chr} = CNVplot{chr};
		end;
	end;
	% disabling perform End bias correction since data is invalid or empty and so the figure should not be created
	performEndbiasCorrection = 0;
end;


if (performGCbiasCorrection)
	% Gather data for LOWESS fitting 1 : GC bias.
	GCratioData_all        = [];
	CGHdata_all_n1         = [];
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			GCratioData_all        = [GCratioData_all        chr_GCratioData{chr}];
			CGHdata_all_n1         = [CGHdata_all_n1         normalizedData_chr_Y1{chr}  ];
		end;
	end;
	% Clean up data by:
	%    deleting GC ratio data near zero.
	%    deleting CGH data beyond 3* the median value.  (rDNA, etc.)
	CGHdata_clean                                       = CGHdata_all_n1;
	GCratioData_clean                                   = GCratioData_all;
	CGHdata_clean(           GCratioData_clean <  0.01) = [];
	GCratioData_clean(       GCratioData_clean <  0.01) = [];
	GCratioData_clean(       CGHdata_clean     >  6   ) = [];
	CGHdata_clean(           CGHdata_clean     >  6   ) = [];
	GCratioData_clean(       CGHdata_clean     == 0   ) = [];
	CGHdata_clean(           CGHdata_clean     == 0   ) = [];
	% Perform LOWESS fitting : GC_bias.
	rawData_X2     = GCratioData_clean;
	rawData_Y2     = CGHdata_clean;
	% perform correction only if the data has more then one value since
	% otherwise inner functions of matlab will cause crash
	if (size(rawData_X2,2) > 1 && size(rawData_Y2,2) > 1)
	fprintf(['Lowess X:Y size : [' num2str(size(rawData_X2,1)) ',' num2str(size(rawData_X2,2)) ']:[' num2str(size(rawData_Y2,1)) ',' num2str(size(rawData_Y2,2)) ']\n']);
	[fitX2, fitY2] = optimize_mylowess(rawData_X2,rawData_Y2,10, 0);
	% Correct data using normalization to LOWESS fitting
	Y_target = 1;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			fprintf(['chr' num2str(chr) ' : ' num2str(length(chr_GCratioData{chr})) ' ... ' num2str(length(CNVplot{chr})) '\t; numbins = ' num2str(ceil(chr_size(chr)/bases_per_bin)) '\n']);
			rawData_chr_X2{chr}        = chr_GCratioData{chr};
			rawData_chr_Y2{chr}        = normalizedData_chr_Y1{chr}; % CNVplot{chr};
			fitData_chr_Y2{chr}        = interp1(fitX2,fitY2,rawData_chr_X2{chr},'spline');

			% Filter by dividing out the fit curve.
			normalizedData_chr_Y2{chr} = rawData_chr_Y2{chr}./fitData_chr_Y2{chr};

			% Filter by subtracting out the fit curve : no strong rationale for this.
			%normalizedData_chr_Y2{chr} = rawData_chr_Y2{chr}-fitData_chr_Y2{chr} + 1;

			%Filter by average of above two methods.
			%try1                       = rawData_chr_Y2{chr}./fitData_chr_Y2{chr};
			%try2                       = rawData_chr_Y2{chr}-fitData_chr_Y2{chr} + 1;
			%normalizedData_chr_Y2{chr} = (try1+try2)/2;

			end;
		end;
	else
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				normalizedData_chr_Y2{chr} = normalizedData_chr_Y1{chr};
			end;
		end;
		% disabling perform GC bias correction since data is invalid or empty and so the figure should not be created
		performGCbiasCorrection = 0; 
	end;
else
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			normalizedData_chr_Y2{chr} = normalizedData_chr_Y1{chr};
		end;
	end;
end;


% Gather data for LOWESS fitting 2 : Repetitiveness bias.
if (performRepetbiasCorrection)
	CGHdata_all_n2         = [];
	repetitivenessData_all = [];
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			CGHdata_all_n2         = [CGHdata_all_n2         normalizedData_chr_Y2{chr} ];
			repetitivenessData_all = [repetitivenessData_all chr_repetitivenessData{chr}];
		end;
	end;
	% Clean up data by:
	%    deleting GC ratio data near zero.
	%    deleting CGH data beyond 3* the median value.  (rDNA, etc.)
	CGHdata_clean                                       = CGHdata_all_n2;
	GCratioData_clean                                   = GCratioData_all;
	repetitivenessData_clean                            = repetitivenessData_all;
	repetitivenessData_clean(GCratioData_clean <  0.01) = [];
	CGHdata_clean(           GCratioData_clean <  0.01) = [];
	GCratioData_clean(       GCratioData_clean <  0.01) = [];
	repetitivenessData_clean(CGHdata_clean     >  6   ) = [];
	GCratioData_clean(       CGHdata_clean     >  6   ) = [];
	CGHdata_clean(           CGHdata_clean     >  6   ) = [];
	repetitivenessData_clean(CGHdata_clean     == 0   ) = [];
	GCratioData_clean(       CGHdata_clean     == 0   ) = [];
	CGHdata_clean(           CGHdata_clean     == 0   ) = [];
	% Perform LOWESS fitting : Repetitiveness bias.
	rawData_X3     = repetitivenessData_clean;
	rawData_Y3     = CGHdata_clean;
	% perform correction only if the data has more then one value since
	% otherwise inner functions of matlab will cause crash
	if (size(rawData_X3,2) > 1 && size(rawData_Y3,2) > 1)
		fprintf(['Lowess X:Y size : [' num2str(size(rawData_X3,1)) ',' num2str(size(rawData_X3,2)) ']:[' num2str(size(rawData_Y3,1)) ',' num2str(size(rawData_Y3,2)) ']\n']);
		[fitX3, fitY3] = optimize_mylowess(rawData_X3,rawData_Y3,10, 0);
		% Correct data using normalization to LOWESS fitting
		Y_target = 1;
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				fprintf(['chr' num2str(chr) ' : ' num2str(length(chr_GCratioData{chr})) ' ... ' num2str(length(CNVplot{chr})) '\t; numbins = ' num2str(ceil(chr_size(chr)/bases_per_bin)) '\n']);
				rawData_chr_X3{chr}        = chr_repetitivenessData{chr};
				rawData_chr_Y3{chr}        = normalizedData_chr_Y2{chr}; % CNVplot{chr};
				fitData_chr_Y3{chr}        = interp1(fitX3,fitY3,rawData_chr_X3{chr},'spline');
				normalizedData_chr_Y3{chr} = rawData_chr_Y3{chr}./fitData_chr_Y3{chr}*Y_target;
			end;
		end;
	else
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				normalizedData_chr_Y3{chr} = normalizedData_chr_Y2{chr};
			end;
		end;
		% disabling perform Repet bias correction since data is invalid or empty and so the figure should not be created
		performRepetbiasCorrection = 0;
	end;
else
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			normalizedData_chr_Y3{chr} = normalizedData_chr_Y2{chr};
		end;
	end;
end;


% Move LOWESS-normalizd CGH data into display pipeline.
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		CNVplot{chr} = normalizedData_chr_Y3{chr};
	end;
end;


if (Make_figure_bias_end)
	%% Generate figure showing subplots of LOWESS fittings.
	if (performEndbiasCorrection)
		bias_end_fig = figure();
		subplot(1,2,1);
		hold on;
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				plot(rawData_chr_X1{chr},rawData_chr_Y1{chr},'k.','markersize',1);        % raw data
			end;
		end;
		plot(fitX1,fitY1,'r','LineWidth',2);                        % LOWESS fit curve.
		hold off;

		xlabel('NearestEnd');
		ylabel('CGH data');
		xlim([0 200]);
		ylim([0 4]);
		axis square;
		title('Reads vs. NearestEnd');
		subplot(1,2,2);
		hold on;
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				plot(rawData_chr_X1{chr},normalizedData_chr_Y1{chr},'k.','markersize',1); % corrected data.
			end;
		end;
		plot([fitX1(1) fitX1(end)],[Y_target Y_target],'r','LineWidth',2);          % normalization line.
		hold off;
		xlabel('NearestEnd');
		ylabel('corrected CGH data');
		xlim([0 200]);
		ylim([0 4]);
		axis square;
		title('NearestEnd Corrected');

		set(bias_end_fig,'PaperPosition',[0 0 6 3]*2);
		saveas(bias_end_fig, [projectDir 'fig.bias_chr_end.' figVer 'eps'], 'epsc');
		saveas(bias_end_fig, [projectDir 'fig.bias_chr_end.' figVer 'png'], 'png');
		delete(bias_end_fig);

		%% change permissions of figures.
		system(['chmod 664 ' projectDir 'fig.bias_chr_end.' figVer 'eps']);
		system(['chmod 664 ' projectDir 'fig.bias_chr_end.' figVer 'png']);
	end;
end;
if (Make_figure_bias_GC)
	if (performGCbiasCorrection)
		bias_GC_fig = figure();
		subplot(1,2,1);
		hold on;
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				plot(rawData_chr_X2{chr},rawData_chr_Y2{chr},'k.','markersize',1);		% raw data
			end;
		end;
		plot(fitX2,fitY2,'r','LineWidth',2);						% LOWESS fit curve.
		hold off;
		xlabel('GC ratio');
		ylabel('CGH data');
		xlim([0.0 1.0]);
		ylim([0 4]);
		axis square;
		title('Reads vs. GC bias');
		subplot(1,2,2);
		hold on;
		for chr = 1:num_chrs
			if (chr_in_use(chr) == 1)
				plot(rawData_chr_X2{chr},normalizedData_chr_Y2{chr},'k.','markersize',1);	% corrected data.
			end;
		end;
		plot([fitX2(1) fitX2(end)],[Y_target Y_target],'r','LineWidth',2);			% normalization line.
		hold off;
		xlabel('GC ratio');
		ylabel('corrected CGH data');
		xlim([0.0 1.0]);
		ylim([0 4]);
		axis square;
		title('GC bias Corrected');

		set(bias_GC_fig,'PaperPosition',[0 0 6 3]*2);
		saveas(bias_GC_fig, [projectDir 'fig.bias_GC_content.' figVer 'eps'], 'epsc');
		saveas(bias_GC_fig, [projectDir 'fig.bias_GC_content.' figVer 'png'], 'png');
		delete(bias_GC_fig);

		%% change permissions of figures.
		system(['chmod 664 ' projectDir 'fig.bias_GC_content.' figVer 'eps']);
		system(['chmod 664 ' projectDir 'fig.bias_GC_content.' figVer 'png']);
	end;
end;
if (performRepetbiasCorrection)
	bias_repet_fig = figure();
	subplot(1,2,1);
 	hold on;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			plot(rawData_chr_X3{chr},rawData_chr_Y3{chr},'k.','markersize',1);        % raw data
		end;
	end;
	plot(fitX3,fitY3,'r','LineWidth',2);                        % LOWESS fit curve.
	hold off;
	xlabel('Repetitiveness');
	ylabel('CGH data');
	xlim([0 5*10^5]);
	ylim([0 4]);
	axis square;
	title('Reads vs. Repetitiveness');
	subplot(1,2,2);
	hold on;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			plot(rawData_chr_X3{chr},normalizedData_chr_Y3{chr},'k.','markersize',1); % corrected data.
		end;
	end;
	plot([fitX3(1) fitX3(end)],[Y_target Y_target],'r','LineWidth',2);          % normalization line.
	hold off;
	xlabel('Repetitiveness');
	ylabel('corrected CGH data');
	xlim([0 5*10^5]);
	ylim([0 4]);
	axis square;
	title('Repetitiveness Corrected');

	set(bias_repet_fig,'PaperPosition',[0 0 6 3]*2);
	saveas(bias_repet_fig, [projectDir 'fig.bias_repetitiveness.' figVer 'eps'], 'epsc');
	saveas(bias_repet_fig, [projectDir 'fig.bias_repetitiveness.' figVer 'png'], 'png');
	delete(bias_repet_fig);

	%% change permissions of figures.
	system(['chmod 664 ' projectDir 'fig.bias_repetitiveness.' figVer 'eps']);
	system(['chmod 664 ' projectDir 'fig.bias_repetitiveness.' figVer 'png']);
end;


%% ====================================================================
% Save presented CNV data in a file format common across pipeline modules.
%----------------------------------------------------------------------
fprintf('\nSaving "Common_CNV" data file.\n');
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		CNVplot2{chr} = CNVplot{chr};
	end;
end;
genome_CNV = genome;
save([projectDir 'Common_CNV.mat'], 'CNVplot2','genome_CNV');

%% change permissions of file.
system(['chmod 664 ' projectDir 'Common_CNV.mat']);

ploidy = str2num(ploidyEstimateString);
[chr_breaks, chrCopyNum, ploidyAdjust] = FindChrSizes_4(Aneuploidy,CNVplot2,ploidy,num_chrs,chr_in_use);

largestChr = find(chr_width == max(chr_width));
largestChr = largestChr(1);


%% -----------------------------------------------------------------------------------------
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------
% load size definitions
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chr_gap,Linear_Chr_max_width,Linear_height...
    ,Linear_base,rotate,linear_chr_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chr_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chr_in_use,num_chrs,chr_label,chr_size);

if (Standard_display)
	Standard_fig = figure();
end;

if (Linear_display)
	Linear_fig           = figure();
	Linear_genome_size   = sum(chr_size);
	Linear_TickSize      = -0.01;            % negative for outside, percentage of longest chr figure.
	Linear_maxY          = 10;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;

%% Initialize copy numbers string.
stringChrCNVs = '';


%% -----------------------------------------------------------------------------------------
% Median normalize CNV data before figure generation.
%-------------------------------------------------------------------------------------------
CNVdata_all = [];
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		CNVdata_all = [CNVdata_all   CNVplot2{chr}];
	end;
end;
medianCNV = median(CNVdata_all)
% avoid divding by zero
if (medianCNV > 0)
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			CNVplot2{chr} = CNVplot2{chr}/medianCNV;
		end;
	end;
end;


%% -----------------------------------------------------------------------------------------
% Make figures
%-------------------------------------------------------------------------------------------
first_chr = true;

% Determine order to draw chromosome cartoons in.
chr_order = [];
for test_chr = 1:num_chrs
	chr_pos = find(chr_figOrder==test_chr);
	chr_order = [chr_order chr_pos];
end;

% Draw chromosomes in order defined in figure_definitions.txt file.
for chr_to_draw  = 1:length(chr_order)
	chr = chr_order(chr_to_draw);
	if (chr_in_use(chr) == 1)

		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chr_figReversed(chr) == 1)
			CNVplot2{chr} = fliplr(CNVplot2{chr});
		end;

		if (Standard_display)
			%% make standard chr cartoons.
			figure(Standard_fig);
			left   = chr_posX(chr);
			bottom = chr_posY(chr);
			width  = chr_width(chr);
			height = chr_height(chr);
			fprintf(['chr' num2str(chr) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
			subplot('Position',[left bottom width height]);
			hold on;

			%% Hide axis lines.
			box off;


			%% standard : show centromere.
			if (chr_size(chr) < 100000)
				Centromere_format = 0;
			else
				Centromere_format = 2;  % Centromere_format_default;
			end;
			x1       = cen_start(chr)/bases_per_bin;
			x2       = cen_end(chr)/bases_per_bin;
			leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
			rightEnd = chr_size(chr)/bases_per_bin;         % chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
			if (Centromere_format == 0)
				source('cartoon_stacked_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_stacked_1.m');
			elseif (Centromere_format == 2) % sausage! (standard plot)
				source('cartoon_stacked_2.m');
			end;
			%% standard : end show centromere.

			%% cgh plot section.
			c_ = [0 0 0];
			fprintf(['chr' num2str(chr) ':' num2str(length(CNVplot2{chr})) '\n']);
			for chr_bin = 1:length(CNVplot2{chr});   % ceil(chr_size(chr)/bases_per_bin)
				x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
				CNVhistValue = CNVplot2{chr}(chr_bin);

				% The CNV-histogram values were normalized to a median value of 1.
				% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the
				% median line.
				startY = maxY/2;
				if (Low_quality_ploidy_estimate)
					endY = min(maxY,CNVhistValue*ploidy*ploidyAdjust);
				else
					endY = min(maxY,CNVhistValue*ploidy);
				end;
				y_ = [startY endY endY startY];

				% makes a blackbar for each bin.
				f = fill(x_,y_,c_);
				set(f,'linestyle','none');
			end;

			%% draw lines across plots for easier interpretation of CNV regions.
			x2 = chr_size(chr)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % base ploidy line.
			%% end cgh plot section.

			%axes labels etc.
			hold off;

			% standard : limit x-axis to range of chromosome.
			xlim([0,chr_size(chr)/bases_per_bin]);

			% modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;

			%set(gca,'TickLength',[(TickSize*chr_size(largestChr)/chr_size(chr)) 0]); %ensures same tick size on all subfigs.
			set(gca,'TickLength',[TickSize 0]);

			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

			%% chromosome cartoon titles for standard figure.
			if (chr_figReversed(chr) == 0)
				text(-50000/5000/2*3, maxY/2, chr_label{chr}, 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chr_font_size);
			else
				text(-50000/5000/2*3, maxY/2, [chr_label{chr} '\fontsize{' int2str(round(stacked_chr_font_size/2)) '}' char(10) '(reversed)'], 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize',stacked_chr_font_size);
			end;

			%% This section sets the Y-axis labelling.
			switch ploidyBase
				case 1
					text(axisLabelPosition_vert, maxY/2,   '1','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,     '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 2
					text(axisLabelPosition_vert, maxY/4,   '1','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,   '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3, '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,     '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 3
					text(axisLabelPosition_vert, maxY/2,   '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,     '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 4
					text(axisLabelPosition_vert, maxY/4,   '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,   '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3, '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,     '8','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 5
					text(axisLabelPosition_vert, maxY/2,   '5','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,    '10','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 6
					text(axisLabelPosition_vert, maxY/4,   '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,   '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3, '9','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,    '12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 7
					text(axisLabelPosition_vert, maxY/2,   '7','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,    '14','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 8
					text(axisLabelPosition_vert, maxY/4,   '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,   '8','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,'12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,    '16','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
			end;
			%% end axes labels etc.

			%% standard : show segmental anueploidy breakpoints.
			if (displayBREAKS) && (show_annotations)
				chr_length = ceil(chr_size(chr)/bases_per_bin);
				for segment = 2:length(chr_breaks{chr})-1
					bP = chr_breaks{chr}(segment)*chr_length;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;
			%% standard : end of : show segmental aneuploidy breakpoints.

			% show annotation locations (standard)
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chr(i) == chr)
						annotationLoc   = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						if (strcmp(annotation_type{i},'dot') == 1)
							plot(annotationLoc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
							                                      'MarkerFaceColor',annotation_fillcolor{i}, ...
							                                      'MarkerSize',     annotation_size(i));
						elseif (strcmp(annotation_type{i},'block') == 1)
							fill([annotationStart annotationStart annotationEnd annotationEnd], ...
							     [-maxY/10*(1.5+0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5+0.75)], ...
							     annotation_fillcolor{i},'EdgeColor',annotation_edgecolor{i});
						end;
					end;
				end;
				hold off;
			end;
			% end show annotation locations (standard)

			% make CGH histograms to the right of the main chr cartoons.
			if (HistPlot)
				width     = 0.020;
				height    = chr_height(chr);
				bottom    = chr_posY(chr);
				histAll   = [];
				histAll2  = [];
				smoothed  = [];
				smoothed2 = [];
				fprintf(['chr = ' num2str(chr) '\n']);
				for segment = 1:length(chrCopyNum{chr})
					subplot('Position',[(left+chr_width(chr)+0.005)+width*(segment-1) bottom-0.007 width height+0.007]);

					% The CNV-histogram values were normalized to a median value of 1.
					for i = round(1+length(CNVplot2{chr})*chr_breaks{chr}(segment)):round(length(CNVplot2{chr})*chr_breaks{chr}(segment+1))
						if (Low_quality_ploidy_estimate)
							histAll{segment}(i) = CNVplot2{chr}(i)*ploidy*ploidyAdjust;
						else
							histAll{segment}(i) = CNVplot2{chr}(i)*ploidy;
						end;
					end;

					% make a histogram of CGH data, then smooth it for display.
					histogram_end                                    = 15;             % end point in copy numbers for the histogram, this should be way outside the expected range.
					histAll{segment}(histAll{segment}<=0)            = [];
					histAll{segment}(length(histAll{segment})+1)     = 0;              % endpoints added to ensure histogram bounds.
					histAll{segment}(length(histAll{segment})+1)     = histogram_end;
					histAll{segment}(histAll{segment}<0)             = [];             % crop off any copy data outside the range.
					histAll{segment}(histAll{segment}>histogram_end) = [];
					smoothed{segment}                                = smooth_gaussian(hist(histAll{segment},histogram_end*20),2,10);

					% make a smoothed version of just the endpoints used to ensure histogram bounds.
					histAll2{segment}(1)                             = 0;
					histAll2{segment}(2)                             = histogram_end;
					smoothed2{segment}                               = smooth_gaussian(hist(histAll2{segment},histogram_end*20),2,10);

					% subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints.
					smoothed{segment}                                = (smoothed{segment}-smoothed2{segment});
					smoothed{segment}                                = smoothed{segment}/max(smoothed{segment});

					% draw lines to mark whole copy number changes.
					plot([0;300], [0;       0      ],'color',[0.00 0.00 0.00]);
					hold on;
					for i = 1:15
						plot([0;300],[20*i;  20*i],'color',[0.75 0.75 0.75]);
					end;

					% draw histogram.
					area(smoothed{segment},1:300,'FaceColor',[0 0 0]);

					% Draw red ticks between histplot segments
					if (displayBREAKS) && (show_annotations)
						if (segment > 1)
							plot([0 0], [-maxY*20/10*1.5 0],  'Color',[1 0 0],'LineWidth',2);
						end;
					end;

					% ensure subplot axes are consistent with main chr plots.
					hold off;
					axis off;
					set(gca,'YTick',[]);
					set(gca,'XTick',[]);
					xlim([0,1]);
					if (show_annotations)
						ylim([-maxY*20/10*1.5,maxY*20]);
					else
						ylim([0,maxY*20]);
					end;
				end;
			end;
			% standard : end of CGH histograms at right.

			% places chr copy number to the right of the main chr cartoons.
			if (ChrNum)
				% subplot to show chr copy number value.
				width  = 0.020;
				height = chr_height(chr);
				bottom = chr_posY(chr);
				if (HistPlot)
					subplot('Position',[(left + chr_width(chr) + 0.005 + width*(length(chrCopyNum{chr})-1) + width+0.001) bottom width height]);
				else
					subplot('Position',[(left + chr_width(chr) + 0.005) bottom width height]);
				end;
				axis off square;
				set(gca,'YTick',[]);
				set(gca,'XTick',[]);
				if (length(chrCopyNum{chr}) == 1)
					chr_string = num2str(chrCopyNum{chr}(1));
				else
					chr_string = num2str(chrCopyNum{chr}(1));
					for i = 2:length(chrCopyNum{chr})
						chr_string = [chr_string ',' num2str(chrCopyNum{chr}(i))];
					end;
				end;
				text(0.1,0.5, chr_string,'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',stacked_copy_font_size);

				stringChrCNVs = [stringChrCNVs ';' chr_string];
			end;
		end;

		%% Linear figure draw section
		if (Linear_display)
			figure(Linear_fig);
			Linear_width = Linear_Chr_max_width*chr_size(chr)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			Linear_left = Linear_left + Linear_width + Linear_chr_gap;
			hold on;

			%% linear : show centromere/outline.
			if (chr_size(chr) < 100000)
				Centromere_format = 0;
			else
				Centromere_format = 2;  %Centromere_format_default;
			end;
			x1       = cen_start(chr)/bases_per_bin;
			x2       = cen_end(chr)/bases_per_bin;
			leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
			rightEnd = chr_size(chr)/bases_per_bin;         % chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
			if (Centromere_format == 0)
				source('cartoon_linear_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_linear_1.m');
			elseif (Centromere_format == 2) % sausage! (linear plot)
				source('cartoon_linear_2.m');
			end;
			%% linear : end show centromere/outline.

			%% cgh plot section.
			c_ = [0 0 0];
			fprintf(['chr' num2str(chr) ':' num2str(length(CNVplot2{chr})) '\n']);
			for i = 1:length(CNVplot2{chr});
				x_ = [i i i-1 i-1];
				CNVhistValue = CNVplot2{chr}(i);

				% The CNV-histogram values were normalized to a median value of 1.
				% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
				startY = maxY/2;
				if (Low_quality_ploidy_estimate)
					endY = CNVhistValue*ploidy*ploidyAdjust;
				else
					endY = CNVhistValue*ploidy;
				end;
				y_ = [startY endY endY startY];

				% makes a blackbar for each bin.
				f = fill(x_,y_,c_);
				set(f,'linestyle','none');
			end;

			x2 = chr_size(chr)/bases_per_bin;

			% draw lines across plots for easier interpretation of CNV regions.
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			%% end cgh plot section.

			%% show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS) && (show_annotations)
				chr_length = ceil(chr_size(chr)/bases_per_bin);
                                for segment = 2:length(chr_breaks{chr})-1
                                        bP = chr_breaks{chr}(segment)*chr_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;

			%% show annotation locations (linear)
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chr(i) == chr)
						annotationLoc   = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						if (strcmp(annotation_type{i},'dot') == 1)
							plot(annotationLoc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
							                                      'MarkerFaceColor',annotation_fillcolor{i}, ...
							                                      'MarkerSize',     annotation_size(i));
						elseif (strcmp(annotation_type{i},'block') == 1)
							fill([annotationStart annotationStart annotationEnd annotationEnd], ...
							     [-maxY/10*(1.5+0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5+0.75)], ...
							     annotation_fillcolor{i},'EdgeColor',annotation_edgecolor{i});
						end;
					end;
				end;
				hold off;
			end;
			%% end show annotation locations (linear)

			%% Final formatting stuff.
			xlim([0,chr_size(chr)/bases_per_bin]);

			% modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			%set(gca,'TickLength',[(Linear_TickSize*chr_size(largestChr)/chr_size(chr)) 0]); %ensures same tick size on all subfigs.
			set(gca,'TickLength',[Linear_TickSize 0]);

			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',[]);
			if (first_chr)
				% This section sets the Y-axis labelling.
				switch ploidyBase
				case 1
					text(axisLabelPosition_horiz, maxY/2,      '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,        '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 2
					text(axisLabelPosition_horiz, maxY/4,      '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/2,      '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/4*3,    '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,        '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 3
					text(axisLabelPosition_horiz, maxY/2,      '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,        '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 4
					text(axisLabelPosition_horiz, maxY/4,      '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/2,      '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/4*3,    '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,        '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 5
					text(axisLabelPosition_horiz, maxY/2,      '5','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,       '10','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 6
					text(axisLabelPosition_horiz, maxY/4,      '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/2,      '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/4*3,    '9','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,       '12','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 7
					text(axisLabelPosition_horiz, maxY/2,      '7','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,       '14','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				case 8
					text(axisLabelPosition_horiz, maxY/4,      '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/2,      '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY/4*3,   '12','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					text(axisLabelPosition_horiz, maxY,       '16','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				end;
			end;
			set(gca,'FontSize',linear_gca_font_size);
			%% end final reformatting.

			% Adding chromosome titles above the middle of the chromosome cartoons.
			% note: adding title is done in the end since if placed earlier in the code somehow the plot function changes the title position.
			if (rotate == 0 && chr_size(chr) ~= 0 )
				if (chr_figReversed(chr) == 0)
					title(chr_label{chr},'Interpreter','none','FontSize',linear_chr_font_size,'Rotation',rotate);
				else
					title([chr_label{chr} '\fontsize{' int2str(round(linear_chr_font_size/2)) '}' char(10) '(reversed)'],'Interpreter','tex','FontSize',linear_chr_font_size,'Rotation',rotate);
				end;
			else
				if (chr_figReversed(chr) == 0)
					text((chr_size(chr)/bases_per_bin)/2,maxY+0.25,chr_label{chr},'Interpreter','none','FontSize',linear_chr_font_size,'Rotation',rotate);
				else
					text((chr_size(chr)/bases_per_bin)/2,maxY+0.25,[chr_label{chr} '\fontsize{' int2str(round(linear_chr_font_size/2)) '}' char(10) '(reversed)'],'Interpreter','tex','FontSize',linear_chr_font_size,'Rotation',rotate);
				end;
			end;
		end;

		if (Standard_display)
			% shift back to main figure generation.
			figure(Standard_fig);
			hold on;

			set(gca,'FontSize',gca_stacked_font_size);
			if (chr == find(chr_posY == max(chr_posY)))
				title([ project ' CNV map'],'Interpreter','none','FontSize',stacked_title_size);
			end;
		end;

		first_chr = false;
	end;
end;

if (Standard_display)
	% Save primary genome figure.
	set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(Standard_fig, [projectDir 'fig.CNV-map.1.' figVer 'eps'], 'epsc');
	saveas(Standard_fig, [projectDir 'fig.CNV-map.1.' figVer 'png'], 'png');
	delete(Standard_fig);

	%% change permissions of figures.
	system(['chmod 664 ' projectDir 'fig.CNV-map.1.' figVer 'eps']);
	system(['chmod 664 ' projectDir 'fig.CNV-map.1.' figVer 'png']);
end;

if (Linear_display)
	% Save horizontal aligned genome figure.
	set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig,   [projectDir 'fig.CNV-map.2.' figVer 'eps'], 'epsc');
	saveas(Linear_fig,   [projectDir 'fig.CNV-map.2.' figVer 'png'], 'png');
	delete(Linear_fig);

	%% change permissions of figures.
	system(['chmod 664 ' projectDir 'fig.CNV-map.2.' figVer 'eps']);
	system(['chmod 664 ' projectDir 'fig.CNV-map.2.' figVer 'png']);
end;

% Output chromosome copy number estimates.
textFileName = [projectDir 'txt.CNV-map.3.txt'];
fprintf(['Text output of CNVs : "' textFileName '"\n']);
textFileID = fopen(textFileName,'w');
fprintf(textFileID,stringChrCNVs);
fclose(textFileID);

%% change permissions of figures.
system(['chmod 664 ' projectDir 'txt.CNV-map.3.txt']);

end
