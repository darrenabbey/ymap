function [] = LOH_hapmap_v4(main_dir,user,genomeUser,project,parent_or_hapmap,genome,ploidyEstimateString,ploidyBaseString, SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

workingDir = [main_dir '/users/' user '/projects/' project '/'];
fprintf('\n\n\t*===============================================================*\n');
fprintf(    '\t| Generate SNP/LOH only plot in script "LOH_hapmap_v4.m".       |\n');
fprintf(    '\t*---------------------------------------------------------------*\n');
tic;

% hide figures during construction.
set(0,'DefaultFigureVisible','off');


%%================================================================================================
% Load project figure version.
%-------------------------------------------------------------------------------------------------
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;


%%================================================================================================
% Check if figures are needed.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir '/users/' user '/projects/' project '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir '/users/' user '/projects/' project '/figure_options.txt'],'\t',1);

        option         = figure_options{7,1};
        if strcmp(option,'False')
                Make_figure_linear = false;
        else
                Make_figure_linear = true;
        end;

        option         = figure_options{8,1};
        if strcmp(option,'False')
                Make_figure_standard = false;
        else
                Make_figure_standard = true;
        end;
else
        Make_figure_linear   = true;
        Make_figure_standard = true;
end;


%%================================================================================================
% Configuration variables.
%-------------------------------------------------------------------------------------------------
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin                Controls bin sizes for CNV fraction of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CNV data by ploidy.
%    chrom_max_width              : max width of chroms as fraction of figure width.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tSetup for processing.\n');
Centromere_format_default      = 3;
chrom_max_width                  = 0.8;
colorBars                      = true;
blendColorBars                 = false;
show_annotations               = true;
Yscale_nearest_even_ploidy     = true;
Standard_display               = Make_figure_standard;
Linear_display                 = Make_figure_linear;
Linear_displayBREAKS           = false;
AnglePlot                      = true;   % Show histogram of alleleic fraction at the left end of standard figure chromosomes.
FillColors                     = true;   %     Fill histogram using colors.
show_uncalibrated              = false;  %     Fill with single color instead of ratio call colors.


%%================================================================================================
% Load FASTA file name from 'reference.txt' file for project.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tLoad FASTA file name for the genome in use.\n');
userReference                  = [main_dir '/users/' user '/genomes/' genome '/reference.txt'];
defaultReference               = [main_dir '/users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string               = strtrim(fileread(defaultReference));
else
	FASTA_string               = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%================================================================================================
% Control variables for Candida albicans SC5314.
%-------------------------------------------------------------------------------------------------
projectDir = [main_dir '/users/' user '/projects/' project '/'];
genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];


%%================================================================================================
% Control logic about hapmap use or not.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tDetermine if hapmap is in use.\n');
if (exist([main_dir '/users/default/hapmaps/' parent_or_hapmap '/'], 'dir') == 7)
	useHapmap  = true;
	hapmapDir  = [main_dir '/users/default/hapmaps/' parent_or_hapmap '/'];   % system hapmap.
	hapmap     = parent_or_hapmap;
	hapmapUser = 'default';
elseif (exist([main_dir '/users/' user '/hapmaps/' parent_or_hapmap '/'], 'dir') == 7)
	useHapmap  = true;
	hapmapDir  = [main_dir '/users/' user '/hapmaps/' parent_or_hapmap '/'];  % user hapmap.
	hapmap     = parent_or_hapmap;
	hapmapUser = user;
else
	useHapmap  = false;
	hapmapDir  = '';
	hapmap     = '';
	hapmapUser = '';
end;


%%================================================================================================
% Control logic about parent project use or not.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tDetermine if parent project is in use.\n');
% The 'parent' will == the 'project' when no 'parent' is selected in setup.
if (strcmp(project,parent_or_hapmap) == 0)   % different
	useParent  = true;
	if (exist([main_dir '/users/default/projects/' parent_or_hapmap '/'], 'dir') == 7)
		parentDir  = [main_dir '/users/default/projects/' parent_or_hapmap '/'];   % system parent.
		parentUser = 'default';
	else
		parentDir  = [main_dir '/users/' user '/projects/' parent_or_hapmap '/'];  % user parent.
		parentUser = user;
	end;
	parent     = parent_or_hapmap;
else
	useParent  = false;
	parentDir  = projectDir;
	parent     = project;
	parentUser = user;
end;


%%================================================================================================
% Load configuration details.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tLoad details of genome in use.\n');
[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[Aneuploidy]                                                          = Load_dataset_information(projectDir);
num_chroms                          = length(chrom_sizes);
for i = 1:length(chrom_sizes)
	chrom_size(i)                   = 0;
	cen_start(i)                  = 0;
	cen_end(i)                    = 0;
end;
for i = 1:length(chrom_sizes)
	chrom_size(chrom_sizes(i).chrom)    = chrom_sizes(i).size;
	cen_start(centromeres(i).chrom) = centromeres(i).start;
	cen_end(centromeres(i).chrom)   = centromeres(i).end;
end;
if (length(annotations) > 0)
	fprintf(['\nAnnotations for ' genome '.\n']);
	for i = 1:length(annotations)
		annotation_chrom(i)       = annotations(i).chrom;
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


%%================================================================================================
% Some figure setup.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tProcess input ploidy.\n');
% Process input ploidy.
ploidy = str2num(ploidyEstimateString);
% Sanitize user input of euploid state.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);


%% ===============================================================================================
% Define colors for figure generation.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tLoad color definitions.\n');
source('../phased_and_unphased_color_definitions.m');


%%==========================================================================================
% Load SNP data from 'preprocessed_SNPs.txt' file.
%-------------------------------------------------------------------------------------------
snp_data_file = fullfile(projectDir, 'preprocessed_SNPs.txt');
if exist(snp_data_file, 'file')
	% Example data file line.
	% # chr_num	bp_start	bp_end	phasedData	unphasedData	phasedCoordinate	unphasedCoordinate	phasedAllele	unphasedAllele
	%   1		1		1941	()		()		()			()			()		()
	%   1		1942		3267	()		()		()			()			()		()

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


%%==========================================================================================
% Determine bases_per_bin sizes to be used as a fallback.
%-------------------------------------------------------------------------------------------
%% Load CNV and SNP figure resolutions.
if (exist([genomeDir 'resolution.CNV.txt'],'file') == 0)
	bases_per_bin           = max(chrom_size)/700;
else
	bases_per_bin           = max(chrom_size)/str2num(fileread([genomeDir 'resolution.CNV.txt']));
end;
if (exist([genomeDir 'resolution.SNPs.txt'],'file') == 0)
	bases_per_bin_SNP       = max(chrom_size)/700;
else
	bases_per_bin_SNP       = max(chrom_size)/str2num(fileread([genomeDir 'resolution.SNPs.txt']));
end;


%%================================================================================================
% Setup for SNP/LOH data calculations.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tInitialize data vectors for tracking SNP data presentation.\n');
% Initializes vectors used to hold allelic ratios for each chromosome segment.
for chrom = 1:length(chrom_sizes)
	if chrom_in_use(chrom) == 1
		% Safe check: use file tracking data if it exists, otherwise use math fallback.
		if preprocessed_SNPs
			num_bins = sum(chroms == chrom);
		else
			num_bins = ceil(chrom_size(chrom)/bases_per_bin_SNP);
		end;

		fprintf('\t|\t    num_bins for chromosome %d data file = %d\n', chrom, num_bins);

		% Setup to track SNP data.
		for j = 1:6
			chrom_SNPdata{chrom,j} = cell(1,num_bins);
		end;

		% Setup to track RGB values used to present SNP/LOH data for each chromosome bin.
		for j = 1:3
			% Track the RGB value sum per standard bin, then divide by the count to reach the average color per standard genome bin.
			chrom_SNPdata_colorsC{chrom,j}           = zeros(num_bins,1);
		end;

		% Track the number of SNP colors per standard bin.
		chrom_SNPdata_countC{chrom} = zeros(num_bins,1);
	end;
end;


%%================================================================================================
% Load 'Common_CNV.mat' file containing CNV estimates per standard genome bin.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tLoading "Common_CNV" data file, to be used in copy number estimation.\n');
load([projectDir 'Common_CNV.mat']);   % 'CNVplot2', 'genome_CNV'
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


%%================================================================================================
% Load SNP/LOH data.
%.................................................................................................
% if (useHapmap)
%       chrom_SNPdata{chrom,1}{idx} = phased SNP ratio data.
%       chrom_SNPdata{chrom,2}{idx} = unphased SNP ratio data.
%       chrom_SNPdata{chrom,3}{idx} = phased SNP position data.
%       chrom_SNPdata{chrom,4}{idx} = unphased SNP position data.
%       chrom_SNPdata{chrom,5}{idx} = flipper value for phased SNP.
%       chrom_SNPdata{chrom,6}{idx} = flipper value for unphased SNP.
% elseif (useParent)
%       chrom_SNPdata{chrom,1}{idx} = parent SNP ratio data.
%       chrom_SNPdata{chrom,2}{idx} = child SNP ratio data.
%       chrom_SNPdata{chrom,3}{idx} = parent SNP position data.
%       chrom_SNPdata{chrom,4}{idx} = child SNP position data.
% else
%       chrom_SNPdata{chrom,2}{idx} = child SNP ratio data.
%       chrom_SNPdata{chrom,4}{idx} = child SNP position data.
% end;
%-------------------------------------------------------------------------------------------------
%	if (useHapmap)
%		phased_ratio_data_string    = '(1.0)';
%		unphased_ratio_data_string  = '()';
%		phased_coordinates_string   = '(19846)';
%		unphased_coordinates_string = '()';
%		phased_alleles_string       = '(G:G/C)';
%		unphased_alleles_string     = '()';
%	elseif (useParent)
%		% coordinates that are heterozygous (0.25 .. 0.75) in the parent.
%		phased_ratio_data_string    = '()';
%		unphased_ratio_data_string  = '(1.0,1.0)';
%		phased_coordinates_string   = '()';
%		unphased_coordinates_string = '(19846,20572)';
%		phased_alleles_string       = '()';
%		unphased_alleles_string     = '(Z:G/C,Z:A/C)';
%	else
%		% coordinate sthat are heterozygous (0.25 .. 0.75) in the experimental dataset.
%		phased_ratio_data_string    = '()';
%		unphased_ratio_data_string  = '(0.529411764706,0.538461538462)';
%		phased_coordinates_string   = '()';
%		unphased_coordinates_string = '(19846,20572)';
%		phased_alleles_string       = '()';
%		unphased_alleles_string     = '(Z:G/C,Z:A/C)';
%	end;
%-------------------------------------------------------------------------------------------------
fprintf(['\n### Load SNP/LOH data.\n']);
mat_file_path = [projectDir 'SNP_' SNP_verString '.mat'];
if (exist(mat_file_path, 'file') == 0)
	fprintf('\t|\tMAT file not found, regenerating from memory structures.\n');
	count      = 0;
	old_chrom  = 0;
	gap_string = '';

	% Loop directly over the list of all SNP bins previously loaded.
	for line_idx = 1:SNPlines_analyzed
		chrom          = chroms(line_idx);
		% Check if this chromosome is actively displayed.
		if chrom_in_use(chrom) == 1
			fragment_start = fragment_starts(line_idx);
			idx            = per_chrom_SNPindex(line_idx);


			%%========================================================================
			% Log progress loading data per chromosome.
			%-------------------------------------------------------------------------
			if (old_chrom ~= chrom)
				% Instantly generate spaces with repmat instead of dynamic concatenation
				gap_string = repmat(' ', 1, floor(count / 10));
				fprintf('\n\t|\t%s\n\t|\t%s', chrom_name{chrom}, gap_string);
				old_chrom = chrom;
			end;
			count = count + 1;
			if (mod(count, 10) == 0)
				fprintf('.');
				if (count >= 800) % Combined loop check to save CPU cycles
					fprintf('\n\t|\t');
					count = 0;
				end;
			end;


			%%========================================================================
			% Parse Phased Ratio Data Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
			%-------------------------------------------------------------------------
			p_ratio_str = phased_ratio_data_string{line_idx};
			if length(p_ratio_str) > 2
				p_ratio_str(1)   = []; % Remove opening '('
				p_ratio_str(end) = []; % Remove closing ')'
				phased_ratio_data = str2num(p_ratio_str); % Automatically parses commas to numbers
			else
				phased_ratio_data = [];
			end;


			%%========================================================================
			% Parse Phased Coordinates Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
			%-------------------------------------------------------------------------
			p_coord_str = phased_coordinates_string{line_idx};
			if length(p_coord_str) > 2
				p_coord_str(1)   = [];
				p_coord_str(end) = [];
				phased_coordinates = str2num(p_coord_str);
			else
				phased_coordinates = [];
			end;


			%%========================================================================
			% Parse Unphased Ratio Data Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
			%-------------------------------------------------------------------------
			up_ratio_str = unphased_ratio_data_string{line_idx};
			if length(up_ratio_str) > 2
				up_ratio_str(1)   = [];
				up_ratio_str(end) = [];
				unphased_ratio_data = str2num(up_ratio_str);
			else
				unphased_ratio_data = [];
			end;


			%%========================================================================
			% Parse Unphased Coordinate Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
			%-------------------------------------------------------------------------
			up_coords_str = unphased_coordinates_string{line_idx};
			if length(up_coords_str) > 2
				up_coords_str(1)   = [];
				up_coords_str(end) = [];
				unphased_coordinates = str2num(up_coords_str);
			else
				unphased_coordinates  = [];
			end;


			%%========================================================================
			% Parse Phased Alleles; '(A:A/T,C:G/C)' -> {'A:A/T', 'C:G/C'}
			%-------------------------------------------------------------------------
			p_alleles_str = phased_alleles_string{line_idx};
			if length(p_alleles_str) > 2
				p_alleles_str(1)   = [];
				p_alleles_str(end) = [];
				commaCount         = length(find(p_alleles_str==','));
				if (commaCount == 0)
					phased_alleles = {p_alleles_str};
				else
					phased_alleles = strsplit(p_alleles_str,',');
				end;
			else
				phased_alleles = [];
			end;


			%%========================================================================
			% Parse Unphased Alleles; '(A:A/T,C:G/C)' -> {'A:A/T', 'C:G/C'}
			%-------------------------------------------------------------------------
			up_alleles_str = unphased_alleles_string{line_idx};
			if length(up_alleles_str) > 2
				up_alleles_str(1)   = [];
				up_alleles_str(end) = [];
				commaCount          = length(find(up_alleles_str==','));
				if (commaCount == 0)
					unphased_alleles = {up_alleles_str};
				else
					unphased_alleles = strsplit(up_alleles_str,',');
				end;
			else
				unphased_alleles = [];
			end;


			% Add phased and unphased data to storage arrays.
			chrom_SNPdata{chrom,1}{idx} = phased_ratio_data;
			chrom_SNPdata{chrom,2}{idx} = unphased_ratio_data;

			% Add phased and unphased data coordinates to storage arrays.
			chrom_SNPdata{chrom,3}{idx} = phased_coordinates;
			chrom_SNPdata{chrom,4}{idx} = unphased_coordinates;

			% Add phased and unphased data allele strings to storage arrays.
			chrom_SNPdata{chrom,5}{idx} = phased_alleles;
			chrom_SNPdata{chrom,6}{idx} = unphased_alleles;
		end;
	end;

	save([projectDir 'SNP_' SNP_verString '.mat'],'chrom_SNPdata');

	%% change permissions of file.
	system(['chmod 774 ' projectDir 'SNP_' SNP_verString '.mat']);
else
	fprintf('\t|\t\tMAT file found, loading.\n');
	load([projectDir 'SNP_' SNP_verString '.mat']);
end;


%%================================================================================================
% Process SNP/hapmap data to determine colors to be presented for each SNP locus.
%-------------------------------------------------------------------------------------------------
%    Calculate allelic fraction cutoffs for each segment and populate data structure containing
%    SNP phasing information.
%        chrom_SNPdata{chrom,1}{idx} = phased SNP ratio data.
%        chrom_SNPdata{chrom,2}{idx} = unphased SNP ratio data.
%        chrom_SNPdata{chrom,3}{idx} = phased SNP position data.
%        chrom_SNPdata{chrom,4}{idx} = unphased SNP position data.
%        chrom_SNPdata{chrom,5}{idx} = phased SNP allele strings.   (baseCall : alleleA/alleleB)
%        chrom_SNPdata{chrom,6}{idx} = unphased SNP allele strings.
%-------------------------------------------------------------------------------------------------
fprintf('\n\n### Calculate allelic ratio cutoffs using Gaussian fitting.\n');
temp_holding = chrom_SNPdata;
makeFitFigures = false;
calculate_allelic_ratio_cutoffs;
chrom_SNPdata = temp_holding;


%%================================================================================================
% Define new colors for SNPs, using Gaussian fitting crossover points as ratio cutoffs.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tDetermine display color for each SNP.\n');
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		SNPbin_mask = (chroms = chrom);
		num_bins = sum(SNPbin_mask);
		SNPbin_indices = find(SNPbin_mask);

		for line_idx = SNPbin_indices(:)'
			idx = per_chrom_SNPindex(line_idx);


			%%========================================================================
			% Determining colors for each SNP coordinate from calculated cutoffs.
			%-------------------------------------------------------------------------

			%fprintf(['\t|\t\ttest1 = ' num2str(chrom) '\n']);
			%fprintf(['\t|\t\ttest2 = ' num2str(idx) '\n']);
			%fprintf(['\t|\t\ttest3 = type:' typeinfo(chrom_SNPdata{chrom,1}{idx}) '\n']);
			%fprintf(['\t|\t\ttest3 = ' num2str(sizeof(chrom_SNPdata{chrom,1}{idx})) '\n']);
			%fprintf(['\t|\t\ttest3 = type:' typeinfo(chrom_SNPdata{chrom,2}{idx}) '\n']);
			%fprintf(['\t|\t\ttest3 = ' num2str(sizeof(chrom_SNPdata{chrom,2}{idx})) '\n']);
			%fprintf(['\t|\t\ttest3 = type:' typeinfo(chrom_SNPdata{chrom,3}{idx}) '\n']);
			%fprintf(['\t|\t\ttest3 = ' num2str(sizeof(chrom_SNPdata{chrom,3}{idx})) '\n']);
			%fprintf(['\t|\t\ttest3 = type:' typeinfo(chrom_SNPdata{chrom,4}{idx}) '\n']);
			%fprintf(['\t|\t\ttest3 = ' num2str(sizeof(chrom_SNPdata{chrom,4}{idx})) '\n']);
			%fprintf(['\t|\t\ttest3 = type:' typeinfo(chrom_SNPdata{chrom,5}{idx}) '\n']);
			%fprintf(['\t|\t\ttest3 = ' num2str(sizeof(chrom_SNPdata{chrom,5}{idx})) '\n']);
			%fprintf(['\t|\t\ttest4 = type:' typeinfo(chrom_SNPdata{chrom,6}{idx}) '\n']);
			%fprintf(['\t|\t\ttest4 = ' num2str(sizeof(chrom_SNPdata{chrom,6}{idx})) '\n']);


			% Concatenate phased (row 1/3) and unphased (row 2/4) vectors cleanly
			allelic_ratios = [chrom_SNPdata{chrom,1}{idx} chrom_SNPdata{chrom,2}{idx}];
			coordinates    = [chrom_SNPdata{chrom,3}{idx} chrom_SNPdata{chrom,4}{idx}];

			if isempty(chrom_SNPdata{chrom,5}{idx})
				phased_alleles = '';
			else
				phased_alleles = chrom_SNPdata{chrom,5}{idx};
			end;
			if isempty(chrom_SNPdata{chrom,6}{idx})
				unphased_alleles = '';
			else
				unphased_alleles = chrom_SNPdata{chrom,6}{idx};
			end;

			% Combine allele character cells horizontally
			if iscell(phased_alleles) && iscell(unphased_alleles)
				allele_strings = [phased_alleles, unphased_alleles];
			elseif iscell(phased_alleles)
				allele_strings = phased_alleles;
			else
				allele_strings = unphased_alleles;
			end;


			if (length(allelic_ratios) > 0)
				for SNP = 1:length(allelic_ratios)
					% Load phased/unphased SNP data checking matrix forms safely.
					if iscell(allelic_ratios)
						if isscalar(allelic_ratios{SNP})
							allelic_ratio = allelic_ratios{SNP};
						else
							allelic_ratio = allelic_ratios(SNP);
						end;
					else
						allelic_ratio = allelic_ratios(SNP);
					end;

					if iscell(coordinates)
						if isscalar(coordinates{SNP})
							coordinate = coordinates{SNP};
						else
							coordinate = coordinates(SNP);
						end;
					else
						coordinate = coordinates(SNP);
					end;

					if iscell(allele_strings)
						if length(allelic_ratios) > 1 && SNP <= length(allele_strings)
							allele_string = allele_strings{SNP};
						else
							allele_string = allele_strings{1};
						end;
					else
						allele_string = allele_strings;
					end;

					% Unpack the base-call and homologous descriptors.
					baseCall = allele_string(1);
					homologA = allele_string(3);
					homologB = allele_string(5);


					%%========================================================
					% Identify the physical segment containing the SNP
					%---------------------------------------------------------
					segmentID = 1; % Default to the first segment.
					num_segments = length(chromCopyNum{chrom});

					% Build true absolute boundary points in physical base pairs.
					% chrom_breaks starts with 0 and ends with 1; with one more element than num_segements.
					seg_boundaries = [double(chrom_breaks{chrom}) * chrom_size(chrom)];
					for segment = 1:num_segments
						segment_start = seg_boundaries(segment);
						segment_end   = seg_boundaries(segment+1);

						if (coordinate > segment_start) && (coordinate <= segment_end)
							segmentID = segment;
							break; % Break early once the matching physical block is isolated.
						end;
					end;


					%%========================================================
					% Load cutoffs between Gaussian fits performed earlier.
					%---------------------------------------------------------
					segment_copyNum     = round(chromCopyNum{chrom}(segmentID));
					actual_cutoffs      = chromSegment_actual_cutoffs{chrom}{segmentID};
					mostLikelyGaussians = chromSegment_mostLikelyGaussians{chrom}{segmentID};

					% Calculate allelic ratio on range of [1..200].
					SNPratio_int        = (allelic_ratio)*199+1;

					% Identify the allelic ratio region containing the SNP.
					cutoffs             = [1 actual_cutoffs 200];
					ratioRegionID       = 0;
					for GaussianRegionID = 1:length(mostLikelyGaussians)
						cutoff_start = cutoffs(GaussianRegionID  );
						cutoff_end   = cutoffs(GaussianRegionID+1);
						if (GaussianRegionID == 1)
							if (SNPratio_int >= cutoff_start) && (SNPratio_int <= cutoff_end)
								ratioRegionID	= mostLikelyGaussians(GaussianRegionID);
							end;
						else
							if (SNPratio_int > cutoff_start) && (SNPratio_int <= cutoff_end)
								ratioRegionID	= mostLikelyGaussians(GaussianRegionID);
							end;
						end;
					end;


					%%========================================================
					% Collect data in categories depending on CNV estimate for region.
					%---------------------------------------------------------
					if (segment_copyNum <= 0);
						colorList = colorNoData;
					elseif (segment_copyNum == 1)
						% allelic fraction cutoffs: [0.50000] => [A B]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 2);            colorList = colorB;
							else                                colorList = colorA;
							end;
						else
							if (useParent)                      colorList = unphased_color_1of1;
							else                                colorList = colorNoData;
							end;
						end;
					elseif (segment_copyNum == 2)
						% allelic fraction cutoffs: [0.25000 0.75000] => [AA AB BB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 3);            colorList = colorBB;
							elseif (ratioRegionID == 2);        colorList = colorAB;
							else                                colorList = colorAA;
							end;
						else
							if (ratioRegionID == 3);            colorList = unphased_color_2of2;
							elseif (ratioRegionID == 2);        colorList = unphased_color_1of2;
							else                                colorList = unphased_color_2of2;
							end;
						end;
					elseif (segment_copyNum == 3)
						% allelic fraction cutoffs: [0.16667 0.50000 0.83333] => [AAA AAB ABB BBB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 4);            colorList = colorBBB;
							elseif (ratioRegionID == 3);        colorList = colorABB;
							elseif (ratioRegionID == 2);        colorList = colorAAB;
							else                                colorList = colorAAA;
							end;
						else
							if (ratioRegionID == 4);            colorList = unphased_color_3of3;
							elseif (ratioRegionID == 3);        colorList = unphased_color_2of3;
							elseif (ratioRegionID == 2);        colorList = unphased_color_2of3;
							else                                colorList = unphased_color_3of3;
							end;
						end;
					elseif (segment_copyNum == 4)
						% allelic fraction cutoffs: [0.12500 0.37500 0.62500 0.87500] => [AAAA AAAB AABB ABBB BBBB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 5);            colorList = colorBBBB;
							elseif (ratioRegionID == 4);        colorList = colorABBB;
							elseif (ratioRegionID == 3);        colorList = colorAABB;
							elseif (ratioRegionID == 2);        colorList = colorAAAB;
							else                                colorList = colorAAAA;
							end;
						else
							if (ratioRegionID == 5);            colorList = unphased_color_4of4;
							elseif (ratioRegionID == 4);        colorList = unphased_color_3of4;
							elseif (ratioRegionID == 3);        colorList = unphased_color_2of4;
							elseif (ratioRegionID == 2);        colorList = unphased_color_3of4;
							else                                colorList = unphased_color_4of4;
							end;
						end;
					elseif (segment_copyNum == 5)
						% allelic fraction cutoffs: [0.10000 0.30000 0.50000 0.70000 0.90000] => [AAAAA AAAAB AAABB AABBB ABBBB BBBBB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 6);            colorList = colorBBBBB;
							elseif (ratioRegionID == 5);        colorList = colorABBBB;
							elseif (ratioRegionID == 4);        colorList = colorAABBB;
							elseif (ratioRegionID == 3);        colorList = colorAAABB;
							elseif (ratioRegionID == 2);        colorList = colorAAAAB;
							else                                colorList = colorAAAAA;
							end;
						else
							if (ratioRegionID == 6);            colorList = unphased_color_5of5;
							elseif (ratioRegionID == 5);        colorList = unphased_color_4of5;
							elseif (ratioRegionID == 4);        colorList = unphased_color_3of5;
							elseif (ratioRegionID == 3);        colorList = unphased_color_3of5;
							elseif (ratioRegionID == 2);        colorList = unphased_color_4of5;
							else                                colorList = unphased_color_5of5;
							end;
						end;
					elseif (segment_copyNum == 6)
						% allelic fraction cutoffs: [0.08333 0.25000 0.41667 0.58333 0.75000 0.91667] => [AAAAAA AAAAAB AAAABB AAABBB AABBBB ABBBBB BBBBBB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 7);            colorList = colorBBBBBB;
							elseif (ratioRegionID == 6);        colorList = colorABBBBB;
							elseif (ratioRegionID == 5);        colorList = colorAABBBB;
							elseif (ratioRegionID == 4);        colorList = colorAAABBB;
							elseif (ratioRegionID == 3);        colorList = colorAAAABB;
							elseif (ratioRegionID == 2);        colorList = colorAAAAAB;
							else                                colorList = colorAAAAAA;
							end;
						else
							if (ratioRegionID == 7);            colorList = unphased_color_6of6;
							elseif (ratioRegionID == 6);        colorList = unphased_color_5of6;
							elseif (ratioRegionID == 5);        colorList = unphased_color_4of6;
							elseif (ratioRegionID == 4);        colorList = unphased_color_3of6;
							elseif (ratioRegionID == 3);        colorList = unphased_color_4of6;
							elseif (ratioRegionID == 2);        colorList = unphased_color_5of6;
							else                                colorList = unphased_color_6of6;
							end;
						end;
					elseif (segment_copyNum == 7)
						% allelic fraction cutoffs: [0.07143 0.21429 0.35714 0.50000 0.64286 0.78571 0.92857] => [AAAAAAA AAAAAAB AAAAABB AAAABBB AAABBBB AABBBBB ABBBBBB BBBBBBB]
						if ((baseCall == homologA) || (baseCall == homologB))
						if (ratioRegionID == 8);            colorList = colorBBBBBBB;
							elseif (ratioRegionID == 7);        colorList = colorABBBBBB;
							elseif (ratioRegionID == 6);        colorList = colorAABBBBB;
							elseif (ratioRegionID == 5);        colorList = colorAAABBBB;
							elseif (ratioRegionID == 4);        colorList = colorAAAABBB;
							elseif (ratioRegionID == 3);        colorList = colorAAAAABB;
							elseif (ratioRegionID == 2);        colorList = colorAAAAAAB;
							else                                colorList = colorAAAAAAA;
							end;
						else
							if (ratioRegionID == 8);            colorList = unphased_color_7of7;
							elseif (ratioRegionID == 7);        colorList = unphased_color_6of7;
							elseif (ratioRegionID == 6);        colorList = unphased_color_5of7;
							elseif (ratioRegionID == 5);        colorList = unphased_color_4of7;
							elseif (ratioRegionID == 3);        colorList = unphased_color_4of7;
							elseif (ratioRegionID == 3);        colorList = unphased_color_5of7;
							elseif (ratioRegionID == 2);        colorList = unphased_color_6of7;
							else                                colorList = unphased_color_7of7;
							end;
						end;
					elseif (segment_copyNum == 8)
						% allelic fraction cutoffs: [0.06250 0.18750 0.31250 0.43750 0.56250 0.68750 0.81250 0.93750] => [AAAAAAAA AAAAAAAB AAAAAABB AAAAABBB AAAABBBB AAABBBBB AABBBBBB ABBBBBBB BBBBBBBB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 9);            colorList = colorBBBBBBBB;
							elseif (ratioRegionID == 8);        colorList = colorABBBBBBB;
							elseif (ratioRegionID == 7);        colorList = colorAABBBBBB;
							elseif (ratioRegionID == 6);        colorList = colorAAABBBBB;
							elseif (ratioRegionID == 5);        colorList = colorAAAABBBB;
							elseif (ratioRegionID == 4);        colorList = colorAAAAABBB;
							elseif (ratioRegionID == 3);        colorList = colorAAAAAABB;
							elseif (ratioRegionID == 2);        colorList = colorAAAAAAAB;
							else                                colorList = colorAAAAAAAA;
							end;
						else
							if (ratioRegionID == 9);            colorList = unphased_color_8of8;
							elseif (ratioRegionID == 8);        colorList = unphased_color_7of8;
							elseif (ratioRegionID == 7);        colorList = unphased_color_6of8;
							elseif (ratioRegionID == 6);        colorList = unphased_color_5of8;
							elseif (ratioRegionID == 5);        colorList = unphased_color_4of8;
							elseif (ratioRegionID == 4);        colorList = unphased_color_5of8;
							elseif (ratioRegionID == 3);        colorList = unphased_color_6of8;
							elseif (ratioRegionID == 2);        colorList = unphased_color_7of8;
							else                                colorList = unphased_color_8of8;
							end;
						end;
					elseif (segment_copyNum >= 9)
						% allelic fraction cutoffs: [0.05556 0.16667 0.27778 0.38889 0.50000 0.61111 0.72222 0.83333 0.94444] => [AAAAAAAAA AAAAAAAAB AAAAAAABB AAAAAABBB AAAAABBBB AAAABBBBB AAABBBBBB AABBBBBBB
						%                                                                                                         ABBBBBBBB BBBBBBBBB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 10);           colorList = colorBBBBBBBBB;
							elseif (ratioRegionID == 9);        colorList = colorABBBBBBBB;
							elseif (ratioRegionID == 8);        colorList = colorAABBBBBBB;
							elseif (ratioRegionID == 7);        colorList = colorAAABBBBBB;
							elseif (ratioRegionID == 6);        colorList = colorAAAABBBBB;
							elseif (ratioRegionID == 5);        colorList = colorAAAAABBBB;
							elseif (ratioRegionID == 4);        colorList = colorAAAAAABBB;
							elseif (ratioRegionID == 3);        colorList = colorAAAAAAABB;
							elseif (ratioRegionID == 2);        colorList = colorAAAAAAAAB;
							else                                colorList = colorAAAAAAAAA;
							end;
						else
							if (ratioRegionID == 10);           colorList = unphased_color_9of9;
							elseif (ratioRegionID == 9);        colorList = unphased_color_8of9;
							elseif (ratioRegionID == 8);        colorList = unphased_color_7of9;
							elseif (ratioRegionID == 7);        colorList = unphased_color_6of9;
							elseif (ratioRegionID == 6);        colorList = unphased_color_5of9;
							elseif (ratioRegionID == 5);        colorList = unphased_color_5of9;
							elseif (ratioRegionID == 4);        colorList = unphased_color_6of9;
							elseif (ratioRegionID == 3);        colorList = unphased_color_7of9;
							elseif (ratioRegionID == 2);        colorList = unphased_color_8of9;
							else                                colorList = unphased_color_9of9;
							end;
						end;
					end;
					chrom_SNPdata_colorsC{chrom,1}(idx) = chrom_SNPdata_colorsC{chrom,1}(idx) + colorList(1);
					chrom_SNPdata_colorsC{chrom,2}(idx) = chrom_SNPdata_colorsC{chrom,2}(idx) + colorList(2);
					chrom_SNPdata_colorsC{chrom,3}(idx) = chrom_SNPdata_colorsC{chrom,3}(idx) + colorList(3);
					chrom_SNPdata_countC{ chrom  }(idx) = chrom_SNPdata_countC{ chrom  }(idx) + 1;

					% Troubleshooting output.
					% fprintf(['chrom = ' num2str(chrom) '; seg = ' num2str(segment) '; bin = ' num2str(idx) '; ratioRegionID = ' num2str(ratioRegionID) '\n']);
				end;
			end;
		end;

		%%================================================================================
		% Average colors of SNPs found in bin.
		%---------------------------------------------------------------------------------
		fprintf('\t|\tDetermine average color for SNPs in chromosome bin.\n');

		% DYNAMIC FIX; Determine true allocation count to prevent out-of-bounds crashes.
		% num_allocated_bins = length(chrom_SNPdata_countC{chrom});
		num_allocated_bins = length(chrom_SNPdata{chrom});

		fprintf('\t|\t    length of chrom_SNPdata_countC for chromosome %d data file = %d\n', chrom, length(chrom_SNPdata_countC{chrom}) );
		fprintf('\t|\t    length of chrom_SNPdata        for chromosome %d data file = %d\n', chrom, length(chrom_SNPdata{chrom})        );

                for line_idx = SNPbin_indices(:)'
                        idx = per_chrom_SNPindex(line_idx);

			allelic_ratios = [chrom_SNPdata{chrom,1}{idx} chrom_SNPdata{chrom,2}{idx}];
			if (length(allelic_ratios) > 0)
				if (chrom_SNPdata_countC{chrom}(idx) > 0)
					chrom_SNPdata_colorsC{chrom,1}(idx) = chrom_SNPdata_colorsC{chrom,1}(idx)/chrom_SNPdata_countC{chrom}(idx);
					chrom_SNPdata_colorsC{chrom,2}(idx) = chrom_SNPdata_colorsC{chrom,2}(idx)/chrom_SNPdata_countC{chrom}(idx);
					chrom_SNPdata_colorsC{chrom,3}(idx) = chrom_SNPdata_colorsC{chrom,3}(idx)/chrom_SNPdata_countC{chrom}(idx);
				else
					chrom_SNPdata_colorsC{chrom,1}(idx) = 1.0;
					chrom_SNPdata_colorsC{chrom,2}(idx) = 1.0;
					chrom_SNPdata_colorsC{chrom,3}(idx) = 1.0;
				end;
			else
				chrom_SNPdata_colorsC{chrom,1}(idx)         = 1.0;
				chrom_SNPdata_colorsC{chrom,2}(idx)         = 1.0;
				chrom_SNPdata_colorsC{chrom,3}(idx)         = 1.0;
			end;
		end;
	end;
end;


%%================================================================================================
% Setup for main figure generation.
%-------------------------------------------------------------------------------------------------
% threshold for full color saturation in SNP/LOH figure.
% synced to bases_per_bin as below, or defaulted to 50.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tCalculate color intensity for each chromosome bin.\n');
largestchrom          = find(chrom_width == max(chrom_width));
largestchrom          = largestchrom(1);

%Threshold set for good figures with Candida albicans. Other species with less SNPs may not be ideal.
%full_data_threshold = 45;	%floor(bases_per_bin_SNP/100);	% C. albicans, highly heterozygous.
%full_data_threshold = 4;	%floor(bases_per_bin_SNP/1000);	% C. parapsilosis, far less heterozygous.

if (exist([genomeDir 'threshold.SNPs.txt'],'file') == 0)
	% default if no threshold.SNPs.txt file is found; works well for Candida albicans or genomes with large numbers of SNPs.
	full_data_threshold = 45;
else
	full_data_threshold = str2num(fileread([genomeDir 'threshold.SNPs.txt']));
end;

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

			phased_plot{ chrom}(idx)                               = length(chrom_SNPdata{chrom,1}{idx});             % phased data.
			phased_plot2{chrom}(idx)                               = phased_plot{chrom}(idx)/full_data_threshold;   %
			phased_plot2{chrom}(phased_plot2{chrom} > 1)                     = 1;                                                   %

			unphased_plot{ chrom}(idx)                             = length(chrom_SNPdata{chrom,2}{idx});             % unphased data.
			unphased_plot2{chrom}(idx)                             = unphased_plot{chrom}(idx)/full_data_threshold; %
			unphased_plot2{chrom}(unphased_plot2{chrom} > 1)                 = 1;                                                   %
		end;
	end;
end;
fprintf('\n');

%%================================================================================================
% Make figure showing histogram of SNPs_count across genome; dragon4
%-------------------------------------------------------------------------------------------------
fprintf('Make histogram of SNP count per bin across genome.\n');

% Vectorized collection: faster and cleaner than element-by-element growth
active_chroms = find(chrom_in_use == 1);
SNP_cells = cell(1, length(active_chroms));
for idx = 1:length(active_chroms)
	chrom = active_chroms(idx);
	num_allocated_bins = length(chrom_SNPdata{chrom, 1});
	SNP_cells{idx} = SNPs_count{chrom}(1:num_allocated_bins);
end;
SNP_count_all = [SNP_cells{:}];

if isempty(SNP_count_all)
	fprintf('\tWarning: No SNP bins found; skipping SNP histogram.\n');
else
	% Ensure NBINS is at least 1 even if max_SNP_count is 0
	max_SNP_count = max(SNP_count_all);
	num_hist_bins = max(1, round(max_SNP_count));

	SNP_histogram_fig = figure(3);
	hist(SNP_count_all, num_hist_bins, 'facecolor', 'g');

	saveas(SNP_histogram_fig, fullfile(projectDir, ['fig.SNP-histogram.' figVer 'eps']), 'epsc');
	saveas(SNP_histogram_fig, fullfile(projectDir, ['fig.SNP-histogram.' figVer 'png']), 'png');
	delete(SNP_histogram_fig);
end;
fprintf('\n');

%	fprintf('Make histogram of SNP count per bin across genome.\n');
%	SNP_count_all = [];
%	count = 1;
%	for chrom = 1:length(chrom_in_use)
%		if (chrom_in_use(chrom) == 1)
%			SNPbin_mask = (chroms = chrom);
%	                num_bins = sum(SNPbin_mask);
%	                SNPbin_indices = find(SNPbin_mask);
%
%	                for line_idx = SNPbin_indices(:)'
%	                        idx = per_chrom_SNPindex(line_idx);
%
%				SNP_count_all(count) = SNPs_count{chrom}(idx);
%				count = count+1;
%			end;
%		end;
%	end;
%	max_SNP_count = max(SNP_count_all);
%	SNP_histogram_fig = figure(3);
%	figure(SNP_histogram_fig);
%	hist(SNP_count_all, max_SNP_count, "facecolor", "g");
%	saveas(SNP_histogram_fig,[projectDir 'fig.SNP-histogram.' figVer 'eps'], 'epsc');
%	saveas(SNP_histogram_fig,[projectDir 'fig.SNP-histogram.' figVer 'png'], 'png');
%	delete(SNP_histogram_fig);
%	fprintf('\n');


%%================================================================================================
% Load size definitions
%-------------------------------------------------------------------------------------------------
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);


%%================================================================================================
% Setup for main-view figure generation.
%-------------------------------------------------------------------------------------------------
if (Standard_display == true)
	fprintf('\t|\tIntitial setup of main figure.\n');
	fig = figure(1);
end;

% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
maxY             = ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/4;


%%================================================================================================
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------------
if (Linear_display == true)
	fprintf('\t|\tInitial setup of linear figure.\n');
	Linear_fig = figure(2);
	Linear_genome_size   = sum(chrom_size);
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
	maxY                 = ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


%%================================================================================================
% Make figures.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tDraw figures.\n');
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
		if (Standard_display == true)
			figure(fig);
			% make standard chrom cartoons.
			left          = chrom_posX(chrom);
			bottom        = chrom_posY(chrom);
			width         = chrom_width(chrom);
			height        = chrom_height(chrom);
			subPlotHandle = subplot('Position',[left bottom width height]);
			fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
			hold on;
		end;

		c_prev = colorInit;
		c_post = colorInit;
		c_     = c_prev;
		infill = zeros(1,length(phased_plot2{chrom}));
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


		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chrom_figReversed(chrom) == 1)
			colors        = flipud(colors);
		end;

		if (Standard_display == true)
			%% standard : draw colorbars.
			draw_colorbars_plot;
			% standard : axes labels etc.
			hold off;
			xlim([0,chrom_size(chrom)/bases_per_bin]);

			%% standard : modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});
			if (chrom_figReversed(chrom) == 0)
				text(-50000/5000/2*3, maxY/2,chrom_label{chrom}, 'rotation', 90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size);
			else
				%% [chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)']
				text(-50000/5000/2*3, maxY/2,[chrom_label{chrom} char(10) '(reversed)'], 'rotation', 90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', round(stacked_chrom_font_size/2));
			end;

			set(gca,'FontSize',gca_stacked_font_size);
			if (chrom == find(chrom_posY == max(chrom_posY)))
				if (length(hapmap) == 0)
					title([ project ' vs. SNP/LOH map'],'Interpreter','none','FontSize',stacked_title_size);
				else
					title([ project ' vs. ' hapmap ' SNP/LOH map'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;
			hold on;
			% standard : end axes labels etc.

			% standard : show segmental anueploidy breakpoints.
	                if (displayBREAKS == true) && (show_annotations == true)
				num_allocated_bins = length(chrom_SNPdata{chrom,1});
	                        for segment = 2:length(chrom_breaks{chrom})-1
	                                bP = chrom_breaks{chrom}(segment)*num_allocated_bins;
	                                plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
	                        end;
	                end;

			%% standard : show centromere/outlines.
			Centromere_format = Centromere_format_default;
			x1 = cen_start(chrom)/bases_per_bin;
			x2 = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0;					% 0.5*5000/bases_per_bin;
			rightEnd = chrom_size(chrom)/bases_per_bin;		% (chrom_size(chrom) - 0.5*5000)/bases_per_bin;
			if (Centromere_format == 0)
				source('cartoon_stacked_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_stacked_1.m');
			elseif (Centromere_format == 2) % sausage!
				source('cartoon_stacked_2.m');
			elseif (Centromere_format == 3) % improved sausage! (standard plot)
				source('cartoon_stacked_3.m');
			end;
			%standard : end show centromere.

			%show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for annoteID = 1:length(annotation_location)
					if (annotation_chrom(annoteID) == chrom)
						annotationloc   = annotation_location(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(   annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(     annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						if (strcmp(annotation_type{annoteID},'dot') == 1)
							plot(annotationloc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{annoteID}, ...
							     'MarkerFaceColor',annotation_fillcolor{annoteID}, ...
							     'MarkerSize',     annotation_size(annoteID));
						elseif (strcmp(annotation_type{annoteID},'block') == 1)
							fill([annotationStart annotationStart annotationEnd annotationEnd], ...
							     [-maxY/10*(1.5+0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5+0.75)], ...
							     annotation_fillcolor{annoteID},'EdgeColor',annotation_edgecolor{annoteID});
						end;
					end;
				end;
				hold off;
			end;
			%end show annotation locations.


			%% =======================================================================
			% Draw angleplots to left of main chromosome cartoons.
			%-------------------------------------------------------------------------
			apply_phasing = true;
			angle_plot_subfigures;
		end;


%%%%%%%%%%%%%%%% Linear figure draw section


		%% Linear figure draw section
		if (Linear_display == true)
			figure(Linear_fig);
			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
			hold on;

			%% linear : draw colorbars.
			draw_colorbars_plot;
			% linear : end draw colorbars.

			%% linear : show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS == true) && (show_annotations == true)
				num_allocated_bins = length(chrom_SNPdata{chrom,1});
				for segment = 2:length(chrom_breaks{chrom})-1
					bP = chrom_breaks{chrom}(segment)*num_allocated_bins;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;

			%% linear : show centromere/outlines.
			Centromere_format = Centromere_format_default;
			x1 = cen_start(chrom)/bases_per_bin;
			x2 = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0;					% 0.5*5000/bases_per_bin;
			rightEnd = chrom_size(chrom)/bases_per_bin;		% (chrom_size(chrom) - 0.5*5000)/bases_per_bin;
			if (Centromere_format == 0)
				source('cartoon_linear_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_linear_1.m');
			elseif (Centromere_format == 2) % sausage!
				source('cartoon_linear_2.m');
			elseif (Centromere_format == 3) % improved sausage! (standard plot)
				source('cartoon_linear_3.m');
			end;
			% linear : end show centromere/outlines.

			%% linear : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for annoteID = 1:length(annotation_location)
					if (annotation_chrom(annoteID) == chrom)
						annotationloc   = annotation_location(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(   annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(     annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						if (strcmp(annotation_type{annoteID},'dot') == 1)
							plot(annotationloc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{annoteID}, ...
							     'MarkerFaceColor',annotation_fillcolor{annoteID}, ...
							     'MarkerSize',     annotation_size(annoteID));
						elseif (strcmp(annotation_type{annoteID},'block') == 1)
							fill([annotationStart annotationStart annotationEnd annotationEnd], ...
							     [-maxY/10*(1.5+0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5-0.75) -maxY/10*(1.5+0.75)], ...
							     annotation_fillcolor{annoteID},'EdgeColor',annotation_edgecolor{annoteID});
						end;
					end;
				end;
				hold off;
			end;
			% linear : end show annotation locations.

			%% linear : Final formatting stuff.
			xlim([0,chrom_size(chrom)/bases_per_bin]);
			% modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			set(gca,'TickLength',[(Linear_TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
			set(gca,'YTick',[]);
        		set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',[]);
			set(gca,'FontSize',linear_gca_font_size);
			% end final reformatting.

			% adding title in the middle of the cartoon
			% note: adding title is done in the end since if placed upper
			% in the code somehow the plot function changes the title position
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
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,[chrom_label{chrom} char(10) '(reversed)'],'interpreter', 'tex' ,'fontsize', round(linear_chrom_font_size/2), 'rotation', rotate);
				end;
			end;
		end;

		if (Standard_display == true)
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
if (Standard_display == true)
	%% Save figures.
	set(fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(fig,        [projectDir 'fig.SNP-map.1.' figVer 'eps'], 'epsc');
	saveas(fig,        [projectDir 'fig.SNP-map.1.' figVer 'png'], 'png');
	delete(fig);

	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.SNP-map.1.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.SNP-map.1.' figVer 'png']);
end;

if (Linear_display == true)
	set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig, [projectDir 'fig.SNP-map.2.' figVer 'eps'], 'epsc');
	saveas(Linear_fig, [projectDir 'fig.SNP-map.2.' figVer 'png'], 'png');
	delete(Linear_fig);

	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.SNP-map.2.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.SNP-map.2.' figVer 'png']);
end;

end
