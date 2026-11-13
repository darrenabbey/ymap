function [] = CNV_SNP_hapmap_v4(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString, SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

workingDir      = [main_dir '/users/' user '/projects/' project '/'];
fprintf('\n\n\t*===============================================================*\n');
fprintf(    '\t| Generate CNV/SNP/LOH plot in script "CNV_SNP_hapmap_v4.m".    |\n');
fprintf(    '\t*---------------------------------------------------------------*\n');
tic;

% hide figures during construction.
set(groot,'DefaultFigureVisible','off');


%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir '/users/' user '/projects/' project '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir '/users/' user '/projects/' project '/figure_options.txt'],'\t',1);

	option         = figure_options{10,1};
	if strcmp(option,'False')
		Make_figure_linear = false;
	else
		Make_figure_linear = true;
	end;

	option         = figure_options{11,1};
	if strcmp(option,'False')
		Make_figure_standard = false;
	else
		Make_figure_standard = true;
	end;
else
	Make_figure_linear   = true;
	Make_figure_standard = true;
end;


%% ========================================================================
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin              : Controls bin sizes for CNV fractions of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CNV data by ploidy.
%    chrom_max_width              : max width of chroms as fraction of figure width.
Centromere_format_default   = 3;
chrom_max_width             = 0.8;
colorBars                   = true;
blendColorBars              = false;
show_annotations            = true;
Yscale_nearest_even_ploidy  = true;
AnglePlot                   = true;   % Show histogram of alleleic fraction at the left end of standard figure chromosomes.
FillColors                  = true;   %     Fill histogram using colors.
show_uncalibrated           = false;  %     Fill with single color instead of ratio call colors.
HistPlot                    = true;   % Show histogram of CNV at the right end of standard figure chromosomes.
chromNum                    = true;   % Show numerical etimates of copy number to the right of standard figure chromosomes.
Standard_display            = Make_figure_standard;
Linear_display              = Make_figure_linear;   % Figure version with chromosomes laid out horizontally.
Linear_displayBREAKS        = false;
Low_quality_ploidy_estimate = true    % Estimate error in overall ploidy estimate, assuming most common value is actually euploid.


%% =========================================================================================
% Load FASTA file name from 'reference.txt' file for project.
%-------------------------------------------------------------------------------------------
userReference    = [main_dir '/users/' user '/genomes/' genome '/reference.txt'];
defaultReference = [main_dir '/users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string = strtrim(fileread(defaultReference));
else
	FASTA_string = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%% =========================================================================================
% Control variables.
%-------------------------------------------------------------------------------------------
projectDir = [main_dir '/users/' user '/projects/' project '/'];
genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];
if (strcmp(hapmap,'') == 1)
	useHapmap = false;
else
	useHapmap = true;
	if (exist([main_dir '/users/default/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir  = [main_dir '/users/default/hapmaps/' hapmap '/'];   % system hapmap.
		hapmapUser = 'default';
	elseif (exist([main_dir '/users/' user '/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir  = [main_dir '/users/' user '/hapmaps/' hapmap '/'];  % user hapmap.
		hapmapUser = user;
	else
		useHapmap = false;
	end;
	parent = '';
end;
if (useHapmap == false)
	parentFile = [main_dir '/users/' user '/projects/' project '/parent.txt'];
	parent     = strtrim(fileread(parentFile));
	if (strcmp(project,parent) == 1)
		useParent = false;
	else
		useParent = true;
		if (exist([main_dir '/users/default/projects/' parent '/'], 'dir') == 7)
			parentDir  = [main_dir '/users/default/projects/' parent '/'];   % system parent.
			parentUser = 'default';
		else
			parentDir  = [main_dir '/users/' user '/projects/' parent '/'];  % user parent.
			parentUser = user;
		end;
	end;
end;
fprintf(['hapmap  = "' hapmap  '"\n']);
fprintf(['genome  = "' genome  '"\n']);
fprintf(['project = "' project '"\n']);
fprintf(['parent  = "' parent  '"\n']);


[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[Aneuploidy] = Load_dataset_information(projectDir);

num_chroms = length(chrom_sizes);
for i = 1:num_chroms
	chrom_size(i)  = 0;
	cen_start(i) = 0;
	cen_end(i)   = 0;
end;
for i = 1:length(chrom_sizes)
	chrom_size(chrom_sizes(i).chrom) = chrom_sizes(i).size;
	cen_start(centromeres(i).chrom)  = centromeres(i).start;
	cen_end(centromeres(i).chrom)    = centromeres(i).end;
end;
if (length(annotations) > 0)
	fprintf(['\nAnnotations for ' genome '.\n']);
	for i = 1:length(annotations)
		annotation_chrom(i)     = annotations(i).chrom;
		annotation_type{i}      = annotations(i).type;
		annotation_start(i)     = annotations(i).start;
		annotation_end(i)       = annotations(i).end;
		annotation_fillcolor{i} = annotations(i).fillcolor;
		annotation_edgecolor{i} = annotations(i).edgecolor;
		annotation_size(i)      = annotations(i).size;
		fprintf(['\t[' num2str(annotations(i).chrom) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
	end;
end;
for i = 1:length(figure_details)
        if (figure_details(i).chrom == 0)
                if (strcmp(figure_details(i).label,'Key') == 1)
                        key_posX   = figure_details(i).posX;
                        key_posY   = figure_details(i).posY;
                        key_width  = figure_details(i).width;
                        key_height = figure_details(i).height;
                end;
        else
                chrom_id         (figure_details(i).chrom) = figure_details(i).chrom;
                chrom_label      {figure_details(i).chrom} = figure_details(i).label;
                chrom_name       {figure_details(i).chrom} = figure_details(i).name;
                chrom_posX       (figure_details(i).chrom) = figure_details(i).posX;
                chrom_posY       (figure_details(i).chrom) = figure_details(i).posY;
                chrom_width      (figure_details(i).chrom) = figure_details(i).width;
                chrom_height     (figure_details(i).chrom) = figure_details(i).height;
                chrom_in_use     (figure_details(i).chrom) = str2num(figure_details(i).usechrom);
                chrom_figOrder   (figure_details(i).chrom) = str2num(figure_details(i).figOrder);
                chrom_figReversed(figure_details(i).chrom) = str2num(figure_details(i).figReversed);
        end;
end;

%% This block is normally calculated in FindChromSizes during CNV analysis.
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		% determine where the endpoints of ploidy segments are.
		chrom_breaks{chrom}(1) = 0.0;
		break_count = 1;
		if (length(Aneuploidy) > 0)
			for i = 1:length(Aneuploidy)
				if (Aneuploidy(i).chrom == chrom)
					break_count = break_count+1;
					chrom_broken = true;
					chrom_breaks{chrom}(break_count) = Aneuploidy(i).break;
				end;
			end;
		end;
		chrom_breaks{chrom}(length(chrom_breaks{chrom})+1) = 1;
	end;
end;


%% =========================================================================================
%% =========================================================================================
%% =========================================================================================


% Process input ploidy.
ploidy = str2num(ploidyEstimateString);

% Sanitize user input of euploid state.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

% basic plot parameters not defined per genome.
TickSize                = -0.005;  %negative for outside, percentage of longest chrom figure.
maxY                    = ploidyBase*2;
cen_tel_Xindent         = 5;
cen_tel_Yindent         = maxY/4;


%% =========================================================================================
% Define colors for figure generation.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tDefine colors used in figure generation.\n');
source('../phased_and_unphased_color_definitions.m');


%%==========================================================================================
% Determine bases_per_bin sizes to be used as a fallback.
%-------------------------------------------------------------------------------------------
max_chr_sz = max(chrom_size); % Cache the max size math calculation to save CPU cycles.

%% Load CNV figure resolution.
res_cnv_file = fullfile(genomeDir, 'resolution.CNV.txt');
if exist(res_cnv_file, 'file')
	% OPTIMIZATION: sscanf is faster than str2num and immune to trailing newlines/spaces
	res_val = sscanf(fileread(res_cnv_file), '%f');
	bases_per_bin = max_chr_sz / res_val(1);
else
	bases_per_bin = max_chr_sz / 700;
end;

%% Load SNP figure resolution.
res_snp_file = fullfile(genomeDir, 'resolution.SNPs.txt');
if exist(res_snp_file, 'file')
	res_val_snp = sscanf(fileread(res_snp_file), '%f');
	bases_per_bin_SNP = max_chr_sz / res_val_snp(1);
else
	bases_per_bin_SNP = max_chr_sz / 700;
end;


%%==========================================================================================
% Load CNV data from 'preprocessed_CNVs.txt' file.
%-------------------------------------------------------------------------------------------
cnv_data_file = fullfile(projectDir, 'preprocessed_CNVs.txt');
if exist(cnv_data_file, 'file')
	% Open file and parse text, automatically ignoring lines starting with '#'
	fid = fopen(cnv_data_file, 'r');
	raw_data = textscan(fid, '%d %d %d %f', 'CommentStyle', '#');
	fclose(fid);

	% The first column contains the chromosome numbers (chrNum)
	chroms            = raw_data{1};
	fragment_starts   = raw_data{2};
	fragment_ends     = raw_data{3};
	readAverages      = raw_data{4};
	CNVlines_analyzed = length(chroms);

	% Compute the 1-based index within each chromosome for every data row
	per_chrom_CNVindex = zeros(CNVlines_analyzed, 1);
	for c = unique(chroms(:))'
		mask = (chroms == c);
		per_chrom_CNVindex(mask) = 1:sum(mask);
	end;

	preprocessed_CNVs = true;
else
	preprocessed_CNVs = false;
end;


%%==========================================================================================
% Load SNP data from 'preprocessed_SNPs.txt' file.
%-------------------------------------------------------------------------------------------
snp_data_file = fullfile(projectDir, 'preprocessed_SNPs.txt');
if exist(snp_data_file, 'file')
	% Example data file line.
	% # chr_num     bp_start        bp_end  phasedData      unphasedData    phasedCoordinate        unphasedCoordinate      phasedAllele    unphasedAllele
	%   1           1               1941    ()              ()              ()                      ()                      ()              ()
	%   1           1942            3267    ()              ()              ()                      ()                      ()              ()

	% Open file and parse text, automatically ignoring lines starting with '#'
	fid = fopen(snp_data_file, 'r');
	raw_data = textscan(fid, '%f %f %f %s %s %s %s %s %s', 'CommentStyle', '#');
	fclose(fid);

	% The first column contains the chromosome numbers (chrNum)
	chroms                      = raw_data{1};
	fragment_starts             = raw_data{2};
	fragment_ends               = raw_data{3};
	phased_ratio_data_string    = raw_data{4};
	unphased_ratio_data_string  = raw_data{5};
	phased_coordinates_string   = raw_data{6};
	unphased_coordinates_string = raw_data{7};
	phased_alleles_string       = raw_data{8};
	unphased_alleles_string     = raw_data{9};
	SNPlines_analyzed           = length(chroms);

	% Compute the 1-based index within each chromosome for every data row
	per_chrom_SNPindex = zeros(SNPlines_analyzed, 1);
	for c = unique(chroms(:))'
		mask = (chroms == c);
		per_chrom_SNPindex(mask) = 1:sum(mask);
	end;

	preprocessed_SNPs = true;
else
	preprocessed_SNPs = false;
end;


%%================================================================================================
% Setup for SNP/LOH data calculations.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tInitialize data vectors for tracking SNP data presentation.\n');

% Pre-allocate the top-level cell arrays to hold data for all chromosomes
chrom_SNPdata         = cell(length(chrom_sizes), 6);
chrom_SNPdata_colorsC = cell(length(chrom_sizes), 3);
chrom_SNPdata_countC  = cell(length(chrom_sizes), 1);

for chrom = 1:length(chrom_sizes)
	if chrom_in_use(chrom) == 1
		% Safe check; use file defined bin data if it exists, otherwise use math fallback.
		if preprocessed_SNPs
			num_bins = sum(chroms == chrom);
		else
			num_bins = ceil(chrom_size(chrom)/bases_per_bin_SNP);
		end;

		fprintf('\t|\t    num_bins for chromosome %d data file = %d\n', chrom, num_bins);

		% Assign cell arrays to columns 1 to 6 instantly using standard cell assignment.
		chrom_SNPdata(chrom, 1:6) = {cell(1, num_bins)};

		% Assign a num_bins x 1 column vector of zeros to columns 1 to 3 instantly.
		chrom_SNPdata_colorsC(chrom, 1:3) = {zeros(num_bins, 1)};

		% Track the number of SNP colors per standard bin.
		chrom_SNPdata_countC{chrom} = zeros(num_bins, 1);
	end;
end;


%%==========================================================================================
% Load corrected CNV data.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tLoad CNV data.\n');
load([projectDir 'Common_CNV.mat']);       % 'CNVplot2','genome_CNV'
[chrom_breaks, chromCopyNum, ploidyAdjust, chromCopyRsquared] = FindChromSizes_4(workingDir, Aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use, false);

for chrom = 1:length(chrom_breaks)
	for segment = 1:length(chromCopyNum{chrom})
		fprintf(['*** chrom_breaks{' num2str(chrom) '}(' num2str(segment) ')  = ' num2str(chrom_breaks{chrom}(segment)) '\n']);
	end;
end;
fprintf(['\n']);
for chrom = 1:length(chromCopyNum)
	for segment = 1:length(chromCopyNum{chrom})
		fprintf(['*** chromCopyNum{' num2str(chrom) '}(' num2str(segment) ')  = ' num2str(chromCopyNum{chrom}(segment)) '\n']);
	end;
end;

largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


%%================================================================================================
% Setup for CNV data calculations.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tInitialize data vectors for tracking CNV data presentation.\n');

for chrom = 1:length(chrom_sizes)
	if chrom_in_use(chrom) == 1
		num_bins = length(CNVplot2{chrom});
		fprintf('\t|\t    num_bins for chromosome %d data file = %d\n', chrom, num_bins);
	end;
end;


%% =========================================================================================
% Generate CNV track files.
%-------------------------------------------------------------------------------------------
source('../createCnvTrack.m');
source('../createCnvTrack_reduced.m');


%% =========================================================================================
% Save workspace variables for use in 'CNV_SNP_hapmap_v4_RedGreen.m' and 'CNV_SNP_hapmap_v4_highTop.m' scripts.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tSave workspace variables for later use in RedGreen alternate plot.\n');
save([projectDir 'CNV_SNP_hapmap_v4.workspace_variables.mat']);

%% change permissions of file.
system(['chmod 774 ' projectDir 'CNV_SNP_hapmap_v4.workspace_variables.mat']);


%% =========================================================================================
% Load SNP/LOH data.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tLoad SNP data.\n');
load([projectDir 'SNP_' SNP_verString '.mat']);
%    'chrom_SNPdata{chrom,i}(idx)'
%        i = 1 : phased ratio data.
%        i = 2 : unphased ratio data.
%        i = 3 : phased coordinate data.
%        i = 4 : unphased coordinate data.
%        i = 5 : phased allele string.
%        i = 6 : unphased allele string.


%%================================================================================================
% Process SNP/hapmap data to determine colors to be presented for each SNP locus.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tDetermine colors per SNP using hapmap.\n');
%% =========================================================================================
% Calculate allelic fraction cutoffs for each segment and populate data structure containing
% SNP phasing information.
%       chrom_SNPdata{chrom,1}{idx} = phased SNP ratio data.
%       chrom_SNPdata{chrom,2}{idx} = unphased SNP ratio data.
%       chrom_SNPdata{chrom,3}{idx} = phased SNP position data.
%       chrom_SNPdata{chrom,4}{idx} = unphased SNP position data.
%       chrom_SNPdata{chrom,5}{idx} = phased SNP allele strings.   (baseCall:alleleA/alleleB)
%       chrom_SNPdata{chrom,6}{idx} = unphased SNP allele strings.
%-------------------------------------------------------------------------------------------
fprintf('\n\n### Calculate allelic ratio cutoffs using Gaussian fitting.\n');
temp_holding = chrom_SNPdata;
makeFitFigures = false;
calculate_allelic_ratio_cutoffs;
chrom_SNPdata = temp_holding;


%% =========================================================================================
% Define new colors for SNPs, using Gaussian fitting crossover points as ratio cutoffs.
% Generate allele ratio track file.
%-------------------------------------------------------------------------------------------
source('../createAlleleRatiosTrack.m');


%% =========================================================================================
% Setup for main figure generation.
%-------------------------------------------------------------------------------------------
% load size definitions
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

fprintf('\t|\tCount SNPs per chromosome bin.\n');
% threshold for full color saturation in SNP/LOH figure.
% synced to bases_per_bin as below, or defaulted to 50.

%DRAGON Threshold set for good figures with Candida albicans. Other species with less SNPs may not be ideal.
%full_data_threshold = 45;	%floor(bases_per_bin_SNP/100);	% C. albicans, highly heterozygous.
%full_data_threshold = 4;	%floor(bases_per_bin_SNP/1000);	% C. parapsilosis, far less heterozygous.

if (exist([genomeDir 'threshold.SNPs.txt'],'file') == 0)
	% default if no threshold.SNPs.txt file is found; works well for Candida albicans or genomes with large numbers of SNPs.
	full_data_threshold = 45;
else
	full_data_threshold = str2num(fileread([genomeDir 'threshold.SNPs.txt']));
end;


fig = figure(1);

for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		SNPbin_mask = (chroms = chrom);
		num_bins = sum(SNPbin_mask);
		SNPbin_indices = find(SNPbin_mask);

		for line_idx = SNPbin_indices(:)'
			idx = per_chrom_SNPindex(line_idx);

			% the number of heterozygous data points in this bin.
			SNPs_count{chrom}(idx)                                 = length(chrom_SNPdata{chrom,1}{idx}) + length(chrom_SNPdata{chrom,2}{idx});

			% divide by the threshold for full color saturation in SNP/LOH figure.
			SNPs_to_fullData_ratio{chrom}(idx)                     = SNPs_count{chrom}(idx)/full_data_threshold;

			% any bins with more data than the threshold for full color saturation are limited to full saturation.
			SNPs_to_fullData_ratio{chrom}(SNPs_to_fullData_ratio{chrom} > 1) = 1;

			phased_plot{chrom}(idx)                                = length(chrom_SNPdata{chrom,1}{idx});             % phased data.
			phased_plot2{chrom}(idx)                               = phased_plot{chrom}(idx)/full_data_threshold;   %
			phased_plot2{chrom}(phased_plot2{chrom} > 1)                     = 1;                                                   %

			unphased_plot{chrom}(idx)                              = length(chrom_SNPdata{chrom,2}{idx});             % unphased data.
			unphased_plot2{chrom}(idx)                             = unphased_plot{chrom}(idx)/full_data_threshold; %
			unphased_plot2{chrom}(unphased_plot2{chrom} > 1)                 = 1;                                                   %
		end;
	end;
end;


fprintf('\n');
largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


%% =========================================================================================
% Setup for figure generation.
%-------------------------------------------------------------------------------------------
if (Standard_display)
	fprintf('\t|\tSetup for main figure generation.\n');
	fig = figure(1);
end;


%% =========================================================================================
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------
if (Linear_display)
	fprintf('\t|\tSetup for linear figure generation.\n');
	Linear_fig           = figure(2);
	Linear_genome_size   = sum(chrom_size);
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
	maxY                 = ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


%% =========================================================================================
% Make figures
%-------------------------------------------------------------------------------------------
first_chrom = true;

% Determine order to draw chromosome cartoons in.
chrom_order = [];
for test_chrom = 1:num_chroms
	chrom_pos = find(chrom_figOrder==test_chrom);
	chrom_order = [chrom_order chrom_pos];
end;

% Draw chromosomes in order defined in figure_definitions.txt file.
for chrom_to_draw  = 1:length(chrom_order)
	chrom = chrom_order(chrom_to_draw);
	if (chrom_in_use(chrom) == 1)
		c_prev = colorInit;
		c_post = colorInit;
		c_     = c_prev;
		infill = zeros(1,length(unphased_plot2{chrom}));
		colors = [];


		%%================================================================================
		%% determine color of each bin (Vectorized).
		%---------------------------------------------------------------------------------
		num_allocated_bins = length(chrom_SNPdata{chrom,1});

		% Extract and cap the data ratios for all bins at 1 (Force 862 x 1 column).
		ratios = min(1, SNPs_to_fullData_ratio{chrom}(1:num_allocated_bins));
		ratios = reshape(ratios, [], 1);

		% Extract the RGB mix components as strict column vectors (862 x 3 matrix).
		c1 = reshape(chrom_SNPdata_colorsC{chrom,1}(1:num_allocated_bins), [], 1);
		c2 = reshape(chrom_SNPdata_colorsC{chrom,2}(1:num_allocated_bins), [], 1);
		c3 = reshape(chrom_SNPdata_colorsC{chrom,3}(1:num_allocated_bins), [], 1);
		colorMix = [c1, c2, c3];

		% Calculate the weighted color blend for all bins at once.
		colorNoData = reshape(colorNoData, 1, 3); % Force 1 x 3 row vector
		colors = colorMix .* ratios + colorNoData .* (1 - ratios);

		% Find where there is no data and force them to colorNoData.
		noDataMask = (ratios == 0);
		if any(noDataMask)
			colors(noDataMask, :) = repmat(colorNoData, sum(noDataMask), 1);
		end;

		% Print the console progress dots all at once (preserving 100-dot wrapping).
		num_no_data = sum(noDataMask);
		if num_no_data > 0
			dots = repmat('.', 1, num_no_data);
			fprintf('%s\n', regexprep(dots, '(.{100})', '$1\n'));
		end;
		%% end determine color of each bin.


		% reverse order of color and CNV bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chrom_figReversed(chrom) == 1)
			colors        = flipud(colors);
			CNVplot2{chrom} = fliplr(CNVplot2{chrom});
		end;


%%%%%%%%%%%%%%%%==================================================================================
%%%%%%%%%%%%%%%% Standard figure draw section
%%%%%%%%%%%%%%%%----------------------------------------------------------------------------------
		if (Standard_display)
			figure(fig);

			% make standard chrom cartoons.
			left          = chrom_posX(chrom);
			bottom        = chrom_posY(chrom);
			width         = chrom_width(chrom);
			height        = chrom_height(chrom);
			subPlotHandle = subplot('Position',[left bottom width height]);
			fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
			hold on;


			%% standard : draw colorbars.
			draw_colorbars_plot;
			%% standard : end draw colorbars.


			%% standard : show centromere outlines/outline.
			Centromere_format = Centromere_format_default;
			x1       = cen_start(chrom)/bases_per_bin;
			x2       = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
			rightEnd = chrom_size(chrom)/bases_per_bin;         % chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
			if (Centromere_format == 0)
				source('cartoon_stacked_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_stacked_1.m');
			elseif (Centromere_format == 2) % sausage!
				source('cartoon_stacked_2.m');
			elseif (Centromere_format == 3) % improved sausage! (standard plot)
				source('cartoon_stacked_3.m');
			end;
			%% standard : end show centromere/outline.


			%% standard : CNV plot section.
			draw_CNV_plot;
			%% standard : end CNV plot section.


			% standard : draw lines across plots for easier interpretation of CNV regions.
			x2 = chrom_size(chrom)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			% standard : end CNV plot section.

			% standard : axes labels etc.
			hold off;
			xlim([0,chrom_size(chrom)/bases_per_bin]);

			% standard : modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			%set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
			set(gca,'TickLength',[TickSize 0]);

			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});
			if (chrom_figReversed(chrom) == 0)
				text(-50000/5000/2*3, maxY/2,chrom_label{chrom}, 'rotation', 90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size);
			else
				%% [chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)']
				text(-50000/5000/2*3, maxY/2,[chrom_label{chrom} char(10) '(reversed)'], 'rotation', 90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size/2);
			end;
			switch ploidyBase
				case 1
					text(axisLabelPosition_vert, maxY/2,     '1','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '2','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 2
					text(axisLabelPosition_vert, maxY/4,     '1','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '2','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '3','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '4','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 3
					text(axisLabelPosition_vert, maxY/2,     '3','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '6','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 4
					text(axisLabelPosition_vert, maxY/4,     '2','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '4','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '6','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '8','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 5
					text(axisLabelPosition_vert, maxY/2,     '5','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '10','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 6
					text(axisLabelPosition_vert, maxY/4,     '3','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '6','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '9','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '12','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 7
					text(axisLabelPosition_vert, maxY/2,     '7','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '14','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
				case 8
					text(axisLabelPosition_vert, maxY/4,     '4','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '8','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,  '12','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '16','horizontalalignment', 'right', 'fontsize', stacked_axis_font_size);
			end;
			set(gca,'FontSize',gca_stacked_font_size);
			if (chrom == find(chrom_posY == max(chrom_posY)))
				if (useHapmap == false)
					if (project == parent)
						title([ project ' CNV & SNP/LOH'],'Interpreter','none','FontSize',stacked_title_size);
					else
						title([ project ' CNV & SNP/LOH vs. ' parent],'Interpreter','none','FontSize',stacked_title_size);
					end;
				else
					title([ project ' CNV & SNP/LOH vs. ' hapmap],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;
			hold on;
			% standard : end axes labels etc.

			if (displayBREAKS) && (show_annotations)
				num_allocated_bins = length(chrom_SNPdata{chrom,1});
				for segment = 2:length(chrom_breaks{chrom})-1
					bP = chrom_breaks{chrom}(segment)*num_allocated_bins;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;

			%% standard : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chrom(i) == chrom)
					annotationloc = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						if (strcmp(annotation_type{i},'dot') == 1)
							plot(annotationloc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
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
			% standard : end show annotation locations.


			%% =======================================================================
			% Draw histplots to right of main chromosome cartoons.
			%-------------------------------------------------------------------------
			hist_plot_subfigures;

			% standard : places chrom copy number to the right of the main chrom cartoons.
			if (chromNum)
				% subplot to show chrom copy number value.
				width  = 0.020;
				height = chrom_height(chrom);
				bottom = chrom_posY(chrom);
				if (HistPlot)
					subplot('Position',[(left + chrom_width(chrom) + 0.005 + width*(length(chromCopyNum{chrom})-1) + width+0.001) bottom width height]);
				else
					subplot('Position',[(left + chrom_width(chrom) + 0.005) bottom width height]);
				end;
				axis off square;
				set(gca,'YTick',[]);
				set(gca,'XTick',[]);
				if (length(chromCopyNum{chrom}) > 0)
					if (length(chromCopyNum{chrom}) == 1)
						chrom_string = num2str(chromCopyNum{chrom}(1));
					else
						chrom_string = num2str(chromCopyNum{chrom}(1));
						for i = 2:length(chromCopyNum{chrom})
							chrom_string = [chrom_string ',' num2str(chromCopyNum{chrom}(i))];
						end;
					end;
					text(0.1,0.5, chrom_string,'horizontalalignment', 'left', 'verticalalignment', 'middle', 'fontsize', stacked_copy_font_size);
				end;
			end;
			% standard : end of chrom copy number at right of the main chrom cartons.


			%% =======================================================================
			% Draw angleplots to left of main chromosome cartoons.
			%-------------------------------------------------------------------------
			apply_phasing = true;
			angle_plot_subfigures;
		end;


%%%%%%%%%%%%%%%%==================================================================================
%%%%%%%%%%%%%%%% Linear figure draw section
%%%%%%%%%%%%%%%%----------------------------------------------------------------------------------
		%% Linear figure draw section
		if (Linear_display)
			figure(Linear_fig);

			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;

			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
			hold on;


			%% linear : draw colorbars.
			draw_colorbars_plot;
			%% linear : end draw colorbars.


			%% linear : show centromere/outline.
			Centromere_format = Centromere_format_default;
			x1       = cen_start(chrom)/bases_per_bin;
			x2       = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
			rightEnd = chrom_size(chrom)/bases_per_bin;         % chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
			if (Centromere_format == 0)
				source('cartoon_linear_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_linear_1.m');
			elseif (Centromere_format == 2) % sausage!
				source('cartoon_linear_2.m');
			elseif (Centromere_format == 3) % improved sausage! (standard plot)
				source('cartoon_linear_3.m');
			end;
			% linear : end show centromere/outline.


			%% linear : CNV plot section.
			draw_CNV_plot
			%% linear : end CNV plot section.


			%% linear : draw lines across plots for easier interpretation of CNV regions.
			x2 = chrom_size(chrom)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			% linear : end CNV plot section.

			%% linear : show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS == true) && (show_annotations == true)
				num_allocated_bins = length(chrom_SNPdata{chrom,1});
				for segment = 2:length(chrom_breaks{chrom})-1
					bP = chrom_breaks{chrom}(segment)*num_allocated_bins;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;
			% linear : end segmental aneuploidy breakpoint section.

			% linear : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chrom(i) == chrom)
						annotationloc = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(i)/bases_per_bin-0.5*(5000/bases_per_bin);
						if (strcmp(annotation_type{i},'dot') == 1)
							plot(annotationloc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
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
			% linear : end show annotation locations.

			% linear : Final formatting stuff.
			xlim([0,chrom_size(chrom)/bases_per_bin]);
			% modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			%set(gca,'TickLength',[(Linear_TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
			set(gca,'TickLength',[Linear_TickSize 0]);

			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',[]);
			if (first_chrom)
				% This section sets the Y-axis labelling.
				switch ploidyBase
					case 1
						text(axisLabelPosition_horiz, maxY/2,     '1','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '2','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 2
						text(axisLabelPosition_horiz, maxY/4,     '1','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '2','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '3','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '4','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 3
						text(axisLabelPosition_horiz, maxY/2,     '3','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '6','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 4
						text(axisLabelPosition_horiz, maxY/4,     '2','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '4','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '6','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '8','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 5
						text(axisLabelPosition_horiz, maxY/2,     '5','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '10','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 6
						text(axisLabelPosition_vert, maxY/4,      '3','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_vert, maxY/2,      '6','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_vert, maxY/4*3,    '9','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_vert, maxY,       '12','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 7
						text(axisLabelPosition_horiz, maxY/2,     '7','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '14','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
					case 8
						text(axisLabelPosition_horiz, maxY/4,     '4','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '8','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,  '12','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '16','horizontalalignment', 'right', 'fontsize', linear_axis_font_size);
				end;
			end;
			set(gca,'FontSize',linear_gca_font_size);
			%end final reformatting.

			% adding title in the middle of the cartoon
			% note: adding title is done in the end since if placed upper
			% in the code somehow the plot function changes the title position
			% location
			if (rotate == 0 && chrom_size(chrom) ~= 0 )
				if (chrom_figReversed(chrom) == 0)
					title(chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
					title([chrom_label{chrom} char(10) '(reversed)'],'Interpreter','tex','FontSize',round(linear_chrom_font_size/2),'Rotation',rotate);
				end;
			else
				if (chrom_figReversed(chrom) == 0)
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,chrom_label{chrom},'interpreter', 'none', 'fontsize', linear_chrom_font_size, 'rotation', rotate);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,[chrom_label{chrom} char(10) '(reversed)'], 'interpreter', 'tex', 'fontsize', round(linear_chrom_font_size/2), 'rotation', rotate);
				end;
			end;
		end;

		if (Standard_display)
			% shift back to main figure generation.
			figure(fig);

			hold on;
		end;

		first_chrom = false;
	end;
end;


%%================================================================================================
% Save figures.
%-------------------------------------------------------------------------------------------------
if (Standard_display)
	fprintf('\n###\n### Saving main figure.\n###\n');
	set(   fig,        'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(fig,        [projectDir 'fig.CNV-SNP-map.1.' figVer 'eps'], 'epsc');
	saveas(fig,        [projectDir 'fig.CNV-SNP-map.1.' figVer 'png'], 'png' );
	delete(fig);
	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.1.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.1.' figVer 'png']);
end;
if (Linear_display)
	fprintf('\n###\n### Saving linear figure.\n###\n');
	set(   Linear_fig, 'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.2.' figVer 'eps'], 'epsc');
	saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.2.' figVer 'png'], 'png' );
	delete(Linear_fig);

	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.2.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.2.' figVer 'png']);
end;


end
