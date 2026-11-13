function [chrom_breaks, chromCopyNum] = CNV_LOH_check(main_dir,user,genomeUser,project,parent_or_hapmap,genome,ploidyEstimateString,ploidyBaseString, SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

workingDir = [main_dir '/users/' user '/projects/' project '/'];
fprintf('\n\n### *===============================================================*\n');
fprintf(    '### | Comparing CNV and SNP/LOH fits in script "CNV_LOH_check.m".       |\n');
fprintf(    '### *---------------------------------------------------------------*\n');
tic;

% hide figures during construction.
set(0,'DefaultFigureVisible','off');


%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;

fprintf('\n### Check figure_options.txt to see if this figure is needed.\n');
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


%% ========================================================================
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin                Controls bin sizes for CNV fraction of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CNV data by ploidy.
%    chrom_max_width              : max width of chroms as fraction of figure width.
fprintf('\n### Setup for processing.\n');
Centromere_format_default      = 2;
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



%%=========================================================================
% Load FASTA file name from 'reference.txt' file for project.
%--------------------------------------------------------------------------
fprintf('\n### Load FASTA file name for the genome in use.\n');
userReference                  = [main_dir '/users/' user '/genomes/' genome '/reference.txt'];
defaultReference               = [main_dir '/users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string               = strtrim(fileread(defaultReference));
else
	FASTA_string               = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%=========================================================================
% Control variables.
%--------------------------------------------------------------------------
projectDir = [main_dir '/users/' user '/projects/' project '/'];
genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];


fprintf('\n### Determine if hapmap is in use.\n');
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


fprintf('\n### Determine if parent project is in use.\n');
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


fprintf('\n### Load details of genome in use.\n');
[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[segmental_aneuploidy]                                                = Load_dataset_information(projectDir);
num_chroms = length(chrom_sizes); % includes chroms not displayed.
for chrom = 1:num_chroms
	chrom_size(chrom)                   = 0;
	cen_start(chrom)                  = 0;
	cen_end(chrom)                    = 0;
end;
for chrom = 1:num_chroms
	chrom_size(chrom_sizes(chrom).chrom)    = chrom_sizes(chrom).size;
	cen_start(centromeres(chrom).chrom) = centromeres(chrom).start;
	cen_end(centromeres(chrom).chrom)   = centromeres(chrom).end;
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
		if (length(segmental_aneuploidy) > 0)	% Percentages across chromosome where CNV/ChARM breakpoint exists.
			for i = 1:length(segmental_aneuploidy)
				if (segmental_aneuploidy(i).chrom == chrom)
					break_count = break_count+1;
					chrom_broken = true;
					chrom_breaks{chrom}(break_count) = segmental_aneuploidy(i).position/chrom_sizes(chrom).size;
				end;
			end;
		end;
		chrom_breaks{chrom}(length(chrom_breaks{chrom})+1) = 1;
	end;
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
		per_chrom_SNPindex(mask) = (1:sum(mask))';
	end;

	preprocessed_SNPs = true;
else
	preprocessed_SNPs = false;
end;


%%========================================================================
% DIAGNOSTIC; Verify raw_data parsed from preprocessed_SNPs.txt
%-------------------------------------------------------------------------
fprintf('\n[CNV_LOH_check.m : DEBUG-1] preprocessed_SNPs = %d | SNPlines_analyzed = %d\n', ...
        preprocessed_SNPs, SNPlines_analyzed);

for d_chr = unique(chroms(:))'
        chr_rows  = find(chroms == d_chr);
        first_row = chr_rows(1);
        last_row  = chr_rows(end);

        fprintf('[DEBUG-TEXTSCAN] chr_num = %d | row count = %d | rows %d..%d\n', ...
                d_chr, length(chr_rows), first_row, last_row);

        % Print the first 10 rows for this chromosome to check column alignment & per-chrom index
        max_rows = min(10, length(chr_rows));
        for local_idx = 1:max_rows
                r = chr_rows(local_idx);

                p_preview = phased_ratio_data_string{r};
                if length(p_preview) > 35
                        p_preview = [p_preview(1:35) '...'];
                end;
                c_preview = phased_coordinates_string{r};
                if length(c_preview) > 35
                        c_preview = [c_preview(1:35) '...'];
                end;

                fprintf('\tGlobalRow %4d | LocalBin %3d | per_chrom_SNPindex=%3d | bp=%d..%d | phasedData=%s | phasedCoords=%s\n', ...
                        r, local_idx, per_chrom_SNPindex(r), fragment_starts(r), fragment_ends(r), p_preview, c_preview);
        end;
end;
fprintf('[CNV_LOH_check.m : DEBUG-1] ====================================================\n\n');



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


%% =========================================================================================
% Some setup variables.
%-------------------------------------------------------------------------------------------
fprintf('\n### Process input ploidy.\n');
% Process input ploidy.
ploidy = str2num(ploidyEstimateString);
% Sanitize user input of euploid state.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);


%% =========================================================================================
% Define colors for figure generation.
%-------------------------------------------------------------------------------------------
fprintf('\n### Load color definitions.\n');
source('../phased_and_unphased_color_definitions.m');


%%================================================================================================
% Setup for SNP/LOH data calculations.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tInitialize data vectors for tracking SNP data presentation.\n');
% Initializes vectors used to hold allelic ratios for each chromosome segment.
% 	Build data structure for SNP information:  chrom_SNPdata{chrom,j}{idx} = [];
%		1 : phased SNP ratio data.
%		2 : unphased SNP ratio data.
%		3 : phased SNP position data.
%		4 : unphased SNP position data.
%		5 : phased SNP allele strings.   (baseCall:alleleA/alleleB)
%		6 : unphased SNP allele strings.
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
% Load CNV estimates per standard bin..
%-------------------------------------------------------------------------------------------------
fprintf('\n### Loading "Common_CNV" data file, to be used in copy number estimation.\n');
load([projectDir 'Common_CNV.mat']);   % 'CNVplot2', 'genome_CNV'
[chrom_breaks, chromCopyNum, ploidyAdjust, chromCopyRsquared] = FindChromSizes_4(workingDir, segmental_aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use, false);
CNVfit_Rsquared = chromCopyRsquared;


fprintf('\n\n### Check for inconsistent CNV segment breakpoints using CNV and SNP-ratio data.\n');
%% Keep iterating to look for bad segments until there have been no changes.
chromCopyNum_changed = true;
chromFitValues       = chromCopyNum; % use to hold best fit R^2 values for later processing.
countIters         = 0;
while (chromCopyNum_changed == true)
	fprintf('======== Loop started ========\n');
	countIters += 1;
	chromCopyNum_changed = false;

	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			%% Clean up chrom_breaks vectors by filtering out non-unique values.
			%chrom_breaks_     = chrom_breaks{chrom}
			%chrom_breaks{chrom} = unique(chrom_breaks{chrom});

			fprintf(['\t chrom_breaks{' num2str(chrom) '} = ']);
			for i = 1:length(chrom_breaks{chrom})
				fprintf(['chrom_breaks{' num2str(chrom) '}(' num2str(i) ') = ' num2str(chrom_breaks{chrom}(i)) '\n']);
			end;
			fprintf('\n');
		end;
	end;
	fprintf(['\n']);

	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			fprintf(['\t chromCopyNum{' num2str(chrom) '} = ']);
			for i = 1:length(chromCopyNum{chrom})
				fprintf(['chromCopyNum{' num2str(chrom) '}(' num2str(i) ') = ' num2str(chromCopyNum{chrom}(i)) '\n']);
			end;
			fprintf('\n');
		end;
	end;


	%%========================================================================================
	% Load SNP/LOH data.
	%.........................................................................................
	fprintf(['\n### Load SNP/LOH data.\n']);
	mat_file_path = [projectDir 'SNP_' SNP_verString '.mat'];
	if (exist(mat_file_path, 'file') == 0)
	        fprintf('\t|\tMAT file not found, regenerating from memory structures.\n');
	        count      = 0;
	        old_chrom  = 0;
	        gap_string = '';

		% Reset chrom_SNPdata cleanly so every chromosome has independent bin storage
		chrom_SNPdata = cell(length(chrom_in_use), 6);
		for c_init = 1:length(chrom_in_use)
		        if chrom_in_use(c_init) == 1
		                n_bins_init = sum(chroms == c_init);
		                for col_init = 1:6
		                        chrom_SNPdata{c_init, col_init} = cell(1, n_bins_init);
		                end;
		        end;
		end;

	        % Loop directly over the list of all SNP bins previously loaded.
	        for line_idx = 1:SNPlines_analyzed
	                chrom = chroms(line_idx);
	                % Check if this chromosome is actively displayed.
	                if chrom_in_use(chrom) == 1
	                        fragment_start = fragment_starts(line_idx);
	                        idx            = per_chrom_SNPindex(line_idx);


				%%================================================================
				% Log progress loading data per chromosome.
				%-----------------------------------------------------------------
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


				%%================================================================
				% Parse Phased Ratio Data Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
				%-----------------------------------------------------------------
				p_ratio_str = phased_ratio_data_string{line_idx};
				if length(p_ratio_str) > 2
					p_ratio_str(1)   = []; % Remove opening '('
					p_ratio_str(end) = []; % Remove closing ')'
					phased_ratio_data = str2num(p_ratio_str); % Automatically parses commas to numbers
				else
					phased_ratio_data = [];
				end;


				%%================================================================
				% Parse Phased Coordinates Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
				%-----------------------------------------------------------------
				p_coord_str = phased_coordinates_string{line_idx};
				if length(p_coord_str) > 2
					p_coord_str(1)   = [];
					p_coord_str(end) = [];
					phased_coordinates = str2num(p_coord_str);
				else
					phased_coordinates = [];
				end;


				%%================================================================
				% Parse Unphased Ratio Data Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
				%-----------------------------------------------------------------
				up_ratio_str = unphased_ratio_data_string{line_idx};
				if length(up_ratio_str) > 2
					up_ratio_str(1)   = [];
					up_ratio_str(end) = [];
					unphased_ratio_data = str2num(up_ratio_str);
				else
					unphased_ratio_data = [];
				end;


				%%================================================================
				% Parse Unphased Coordinate Strings; '(val1,val2,...,valN)' -> [val1,val2,...,valN]
				%-----------------------------------------------------------------
				up_coords_str = unphased_coordinates_string{line_idx};
				if length(up_coords_str) > 2
					up_coords_str(1)   = [];
					up_coords_str(end) = [];
					unphased_coordinates = str2num(up_coords_str);
				else
					unphased_coordinates  = [];
				end;


				%%================================================================
				% Parse Phased Alleles; '(A:A/T,C:G/C)' -> {'A:A/T', 'C:G/C'}
				%-----------------------------------------------------------------
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


				%%================================================================
				% Parse Unphased Alleles; '(A:A/T,C:G/C)' -> {'A:A/T', 'C:G/C'}
				%-----------------------------------------------------------------
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


				% add phased and unphased data to storage arrays.
				chrom_SNPdata{chrom,1}{idx} = phased_ratio_data;
				chrom_SNPdata{chrom,2}{idx} = unphased_ratio_data;

				% add phased and unphased data coordinates to storage arrays.
				chrom_SNPdata{chrom,3}{idx} = phased_coordinates;
				chrom_SNPdata{chrom,4}{idx} = unphased_coordinates;

				% add phased and unphased data allele strings to storage arrays.
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

%%========================================================================
% DIAGNOSTIC: Log first 10 SNP bins for each active chromosome.
%-------------------------------------------------------------------------
fprintf('\n[CNV_LOH_check.m : DEBUG-2] === Logging First 10 SNP Bins Per Chromosome ===\n');
for d_chrom = 1:length(chrom_in_use)
        if (chrom_in_use(d_chrom) == 1)
                fprintf('[DEBUG] Chromosome %d (%s) - total allocated bins: %d\n', ...
                        d_chrom, chrom_name{d_chrom}, length(chrom_SNPdata{d_chrom, 1}));

                max_check = min(10, length(chrom_SNPdata{d_chrom, 1}));
                for d_bin = 1:max_check
                        p_ratios = chrom_SNPdata{d_chrom, 1}{d_bin};
                        u_ratios = chrom_SNPdata{d_chrom, 2}{d_bin};
                        p_coords = chrom_SNPdata{d_chrom, 3}{d_bin};

                        % Format coordinates & ratios safely whether empty or non-empty
                        if isempty(p_coords)
                                coord_str = 'none';
                        else
                                coord_str = num2str(p_coords(1:min(3, end)));
                        end;

                        if isempty(p_ratios)
                                ratio_str = 'none';
                        else
                                ratio_str = num2str(p_ratios(1:min(3, end)), '%.3f ');
                        end;

                        % Also log averaged RGB colors if chrom_SNPdata_colorsC is already populated
                        if exist('chrom_SNPdata_colorsC', 'var') && length(chrom_SNPdata_colorsC{d_chrom, 1}) >= d_bin
                                rgb_str = sprintf('[%.2f, %.2f, %.2f]', ...
                                        chrom_SNPdata_colorsC{d_chrom, 1}(d_bin), ...
                                        chrom_SNPdata_colorsC{d_chrom, 2}(d_bin), ...
                                        chrom_SNPdata_colorsC{d_chrom, 3}(d_bin));
                        else
                                rgb_str = 'N/A';
                        end;

                        fprintf('\tBin %2d | phasedCount=%2d | unphasedCount=%2d | firstCoords=[%s] | firstRatios=[%s] | RGB=%s\n', ...
                                d_bin, length(p_ratios), length(u_ratios), coord_str, ratio_str, rgb_str);
                end;
        end;
end;
fprintf('[CNV_LOH_check.m : DEBUG-2] ====================================================\n\n');

	%%========================================================================================
	fprintf('\n\n### Calculate allelic ratio cutoffs using Gaussian fitting.\n');
	temp_holding    = chrom_SNPdata;
	makeFitFigures  = false;
	calculate_allelic_ratio_cutoffs;
	chrom_SNPdata     = temp_holding;
	SNPfit_Rsquared = chromSegment_Rsquared;


	%%========================================================================================
	% Make figure of R^2 values for CNV vs SNP ratio fittings.
	%-----------------------------------------------------------------------------------------
	fprintf('### Draw initial R^2 comparison figure.\n');

	%%% Collapse Rsquared structures into vectors for logging output.
	%%%	CNVfit_Rsquared
	%%%	SNPfit_Rsquared
	CNVfit_Rsquared_vector = [];
	SNPfit_Rsquared_vector = [];
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			for segment = 1:(length(chromCopyNum{chrom}))
				CNVfit_Rsquared_vector = [CNVfit_Rsquared_vector; CNVfit_Rsquared{chrom}(segment)];
				SNPfit_Rsquared_vector = [SNPfit_Rsquared_vector; SNPfit_Rsquared{chrom}(segment)];
			end;
		end;
	end;
	SNPfit_Rsquared_vector = cell2mat(SNPfit_Rsquared_vector);
	CNVfit_Rsquared_vector
	SNPfit_Rsquared_vector


	%%% Produce figure illustrating Rsquared values from CNV vs SNP ratio fittings.
	Rsquared_fig = figure();
	plot(CNVfit_Rsquared_vector, SNPfit_Rsquared_vector, 'color', 'blue', '.', 'markersize',3);
	line([0,0] ,[-1,1], 'linestyle', '-', 'color', 'black');
	line([-1,1],[0,0], 'linestyle', '-', 'color', 'black');
	xlim([-1.1,1.1]);
	ylim([-1.1,1.1]);
	title('R^2 values of CNV fits vs SNP fits.');
	xlabel('CNV R^2 values.');
	ylabel('SNP ratio R^2 values.');

	%%% Save figure.
	saveas(Rsquared_fig, [projectDir 'fig.Rsquared.' figVer num2str(countIters) '.png'], 'png');
	delete(Rsquared_fig);

	%%% change permissions of figure.
	system(['chmod 774 ' projectDir 'fig.Rsquared.' figVer num2str(countIters) '.png']);



	%%========================================================================================
	% Check for better CNV/SNP-ratio fittings with different copy number estimates for bad
	% initial fittings.
	%-----------------------------------------------------------------------------------------
	%	CNVplot / CNVplot2 contains the full CNV data across chromosome regions, at the resolution limit for YMAP.
	%	chrom_breaks{chrom}(segment) contains CNV start and end coordinates for each chromosome segment.
	%	chromCopyNum{chrom}(segment) contains CNV estimates for each chromosome segment.
	%-----------------------------------------------------------------------------------------
	chrom_breaks_new     = chrom_breaks;
	chromCopyNum_new     = chromCopyNum;
	chromCopyNum_new2    = chromCopyNum;
	fprintf(['\n### Looking at chrom segment Rsquared values to assess quality of CNV estimates.\n']);
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			for segment = 1:(length(chromCopyNum{chrom}))
				%%%
				%%% Calculate initial Rsquared distance from ideal (1,1).
				%%%
				CNVfit_testRsquared = CNVfit_Rsquared{chrom}(segment);
				SNPfit_testRsquared = cell2mat(SNPfit_Rsquared{chrom}(segment));
				Rsquared_distance   = sqrt((1-CNVfit_testRsquared)^2 + (1-SNPfit_testRsquared)^2);

				if (Rsquared_distance > 0.5)
					fprintf(['\nchrom ' num2str(chrom) '.' num2str(segment) ' initial CNV/SNP fit failure.\n']);
					%%%
					%%% If initial Rsquared_distance from ideal (1,1) is bad, lets figure out what the CNV estimate should be for this segment.
					%%%
					Rsquared_CNVtest_vector = [];
					Rsquared_SNPtest_vector = [];
					for copyNum = 1:9
						%fprintf(['    copyNum    = ' num2str(copyNum) '\n']);
						%fprintf(['\tchrom_breaks = ']);
						%fprintf(['\n']);
						%fprintf(['\tploidy     = ' num2str(ploidy) '\n']);
						%fprintf(['\tchrom        = ' num2str(chrom) '\n']);
						%fprintf(['\tsegment    = ' num2str(segment) '\n']);

						Rsquared_CNV            = testPloidyEstimate_CNV(workingDir, CNVplot2, chrom_breaks, ploidy, chrom, segment, copyNum, makeFitFigures);
						Rsquared_CNVtest_vector = [Rsquared_CNVtest_vector Rsquared_CNV];
						testPloidyEstimate_SNP;
						Rsquared_SNP            = Rsquared;
						if isnan(Rsquared_SNP)
							Rsquared_SNP = -1;
						end;
						Rsquared_SNPtest_vector = [Rsquared_SNPtest_vector Rsquared_SNP];
					end;

					%% Logging output of CNV test values.
					%fprintf('\tmax(Rsquared_CNVtest_vector) = ');
					%for i = 1:length(Rsquared_CNVtest_vector)
					%	if (max(Rsquared_CNVtest_vector) == Rsquared_CNVtest_vector(i))
					%		fprintf('[');
					%	end;
					%	fprintf([num2str(Rsquared_CNVtest_vector(i))]);
					%	if (max(Rsquared_CNVtest_vector) == Rsquared_CNVtest_vector(i))
					%		fprintf(']');
					%	end;
					%	fprintf(' ');
					%end;
					%fprintf('\n');

					%% Logging output of SNP test values..
					%fprintf('\tmax(Rsquared_SNPtest_vector) = ');
					%for i = 1:length(Rsquared_SNPtest_vector)
					%	if (max(Rsquared_SNPtest_vector) == Rsquared_SNPtest_vector(i))
					%		fprintf('[');
					%	end;
					%	fprintf([num2str(Rsquared_SNPtest_vector(i))]);
					%	if (max(Rsquared_SNPtest_vector) == Rsquared_SNPtest_vector(i))
					%		fprintf(']');
					%	end;
					%	fprintf(' ');
					%end;
					%fprintf('\n');

					Rsquared_distance_vector = sqrt((1-Rsquared_CNVtest_vector).^2 + (1-Rsquared_SNPtest_vector).^2);

					%% Logging output of combined CNV/SNP test values..
					%fprintf('\tmin(Rsquared_distance_vector) = ');
					%for i = 1:length(Rsquared_distance_vector)
					%	if (min(Rsquared_distance_vector) == Rsquared_distance_vector(i))
					%		fprintf('[');
					%	end;
					%	fprintf([num2str(Rsquared_distance_vector(i))]);
					%	if (min(Rsquared_distance_vector) == Rsquared_distance_vector(i))
					%		fprintf(']');
					%	end;
					%	fprintf(' ');
					%end;
					%fprintf('\n')

					%%% Find best fit CNV estimate by looking at (the more reliable?) SNP ratios.
					Rsquared_CNVtest_vector_min  = min(Rsquared_CNVtest_vector);
					Rsquared_SNPtest_vector_min  = min(Rsquared_SNPtest_vector);
					Rsquared_distance_vector_min = min(Rsquared_distance_vector);

					for i = length(Rsquared_SNPtest_vector):1
							% Find best fit.
						if (Rsquared_SNPtest_vector_min == Rsquared_SNPtest_vector(i))
							chromFitValues{chrom}(segment)   = Rsquared_distance_vector_min;
							chromCopyNum_new{chrom}(segment) = i;
						end;
					end;
				else
					fprintf(['\nchrom ' num2str(chrom) '.' num2str(segment) ' initial CNV/SNP fit success.\n']);
					chromFitValues{chrom}(segment)   = Rsquared_distance;
					fprintf(['\tRsquared_distance = ' num2str(Rsquared_distance) '\n']);
					chromCopyNum_new{chrom}(segment) = round(chromCopyNum_new{chrom}(segment));
				end;
				fprintf(['\tchrom' num2str(chrom) '.' num2str(segment) ': ' num2str(chromCopyNum_new{chrom}(segment)) '\n']);

				%%% If CNV estimate changed, update boolean and log it.
				if (round(chromCopyNum_new{chrom}(segment)) != round(chromCopyNum{chrom}(segment)))
					chromCopyNum_changed = true;
					fprintf('chromCopyNum_changed = true\n');
					fprintf(['\tchromCopyNum_new{' num2str(chrom) '}(' num2str(segment) ') = ' num2str(chromCopyNum_new{chrom}(segment)) '\n']);
					fprintf(['\tchromCopyNum{' num2str(chrom) '}(' num2str(segment) ') = ' num2str(chromCopyNum{chrom}(segment)) '\n']);
				end;
			end;
		end;
	end;
	chromCopyNum = chromCopyNum_new;
	if (chromCopyNum_changed == true)
		fprintf('\n-------- Loop reset in block 1: testing for better CNV fits with different CNV estimates --------\n\n');
	end;


	%%========================================================================================
	% Re-review to deal with poor best-fits (likely due to limited data on a segment).
	%-----------------------------------------------------------------------------------------
	fprintf(['\n### Dealing with bad best-fit segments.\n']);
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			%%========================================================================
			% Only meaningful to examine this if there is more than one segment on this chromosome.
			%-------------------------------------------------------------------------
			if (length(chromCopyNum{chrom}) > 1)
				for segment = (length(chromCopyNum{chrom})):1
					%%========================================================
					% Calculate initial Rsquared distance from ideal (1,1).
					%---------------------------------------------------------
					CNVfit_testRsquared = CNVfit_Rsquared{chrom}(segment);
					SNPfit_testRsquared = cell2mat(SNPfit_Rsquared{chrom}(segment));
					Rsquared_distance   = sqrt((1-CNVfit_testRsquared)^2 + (1-SNPfit_testRsquared)^2);

					if (Rsquared_distance > 0.5)
						if (chromFitValues{chrom}(segment) > 1)
							% Bad fit, need to fix by using best neighboring fit.
							if (segment == 1)
								prevFitVal  = chromFitValues{chrom}(segment);
								prevCopyNum = chromCopyNum{chrom}(segment);
							else
								prevFitVal  = chromFitValues{chrom}(segment-1);
								prevCopyNum = chromCopyNum{chrom}(segment-1);
							end;

							if (segment == length(chromCopyNum{chrom}))
								nextFitVal  = chromFitValues{chrom}(segment);
								nextCopyNum = chromCopyNum{chrom}(segment);
							else
								nextFitVal  = chromFitValues{chrom}(segment+1);
								nextCopyNum = chromCopyNum{chrom}(segment+1);
							end;

							if (prevFitVal < nextFitVal)
								chromFitValues{chrom}(segment)   = prevFitVal;
								chromCopyNum_new{chrom}(segment) = prevCopyNum;
							else
								chromFitValues{chrom}(segment)   = nextFitVal;
								chromCopyNum_new{chrom}(segment) = nextCopyNum;
							end;
						end;
					end;
				end;

				%%================================================================
				% Repeat in reverse order to ensure best fits are used for all segments.
				%-----------------------------------------------------------------
				for segment = 1:(length(chromCopyNum{chrom}))
					%%%
					%%% Calculate initial Rsquared distance from ideal (1,1).
					%%%
					CNVfit_testRsquared = CNVfit_Rsquared{chrom}(segment);
					SNPfit_testRsquared = cell2mat(SNPfit_Rsquared{chrom}(segment));
					Rsquared_distance   = sqrt((1-CNVfit_testRsquared)^2 + (1-SNPfit_testRsquared)^2);

					if (Rsquared_distance > 0.5)
						if (chromFitValues{chrom}(segment) > 1)
							% Bad fit, need to fix by using best neighboring fit.
							if (segment == 1)
								prevFitVal  = chromFitValues{chrom}(segment);
								prevCopyNum = chromCopyNum{chrom}(segment);
							else
								prevFitVal  = chromFitValues{chrom}(segment-1);
								prevCopyNum = chromCopyNum{chrom}(segment-1);
							end;

							if (segment == length(chromCopyNum{chrom}))
								nextFitVal  = chromFitValues{chrom}(segment);
								nextCopyNum = chromCopyNum{chrom}(segment);
							else
								nextFitVal  = chromFitValues{chrom}(segment+1);
								nextCopyNum = chromCopyNum{chrom}(segment+1);
							end;

							if (prevFitVal < nextFitVal)
								chromFitValues{chrom}(segment)      = prevFitVal;
								chromCopyNum_new2{chrom}(segment)   = prevCopyNum;
							else
								chromFitValues{chrom}(segment)      = nextFitVal;
								chromCopyNum_new2{chrom}(segment)   = nextCopyNum;
							end;
						end;
					end;
				end;

				%% Check to see if any changes make sense.
				for segment = 1:(length(chromCopyNum{chrom}))
					fprintf(['\tchrom' num2str(chrom) '.' num2str(segment) ': ' num2str(chromCopyNum{chrom}(segment)) ' => ' num2str(chromCopyNum_new2{chrom}(segment)) '\n']);

					%%% If CNV estimate changed, update boolean.
					if ((chromCopyNum_new{chrom}(segment) != chromCopyNum{chrom}(segment)) || (chromCopyNum_new2{chrom}(segment) != chromCopyNum{chrom}(segment)))
						chromCopyNum_changed = true;
					end;
				end;
			end;
		end;
	end;
	chromCopyNum = chromCopyNum_new2;
	if (chromCopyNum_changed == true)
		fprintf('\n-------- Loop reset in block 2: testing for poor R^2 values --------\n\n');
	end;


	%%========================================================================================
	% Merge any adjacent segments that now have the same best estimate of copy number.
	%-----------------------------------------------------------------------------------------
	fprintf(['\n### Merging adjacent segments.\n']);
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			if (length(chromCopyNum{chrom}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.
				% Add break representing left end of chromosome.
				breakCount_new         = 1;
				chrom_breaks_new{chrom}    = [];
				chromCopyNum_new{chrom}    = [];
				chrom_breaks_new{chrom}(1) = 0.0;

				chromCopyNum_new{chrom}(1) = chromCopyNum{chrom}(1);
				for segment = 1:(length(chromCopyNum{chrom})-1)
					if (round(chromCopyNum{chrom}(segment)) == round(chromCopyNum{chrom}(segment+1)))
						% two adjacent segments have identical copyNum and should be fused into one; don't add boundry to new list.
					else
						% two adjacent segments have different copyNum; add boundry to new list.
						breakCount_new                      = breakCount_new + 1;
						chrom_breaks_new{chrom}(breakCount_new) = chrom_breaks{chrom}(segment+1);
						chromCopyNum_new{chrom}(breakCount_new) = chromCopyNum{chrom}(segment+1);
					end;
				end;

				% add break representing right end of chromosome.
				breakCount_new = breakCount_new+1;
				chrom_breaks_new{chrom}(breakCount_new) = 1.0;

				% copy new lists to old.
				chrom_breaks{chrom} = chrom_breaks_new{chrom};
				chromCopyNum{chrom} = [];
				chromCopyNum{chrom} = chromCopyNum_new{chrom};
			end;
		end;
	end;


	%%========================================================================================
	%% Convert chrom segment breakpoints to ChARM output file, replacing original for later use.
	%%----------------------------------------------------------------------------------------
	dataFile = [projectDir 'Common_ChARM.mat'];
	fprintf(['\n### Updating saved common_ChARM file for "' project '" : ' dataFile '$$$$\n']);
	i = 0;
	segmental_aneuploidy = [];
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			fprintf(['\t chrom_breaks{' num2str(chrom) '} = ']);
			for i = 1:length(chrom_breaks{chrom})
				fprintf([num2str(chrom_breaks{chrom}(i)) ' ']);
			end;
			fprintf('\n');
			for edge = 1:length(chrom_breaks{chrom})
				if (chrom_breaks{chrom}(edge) == 0) || (chrom_breaks{chrom}(edge) == 1)
					% nothing is added to file for start and end coordinates; these edges are later assumed.
				else
					i = i+1;
					segmental_aneuploidy(i).chrom      = chrom;							% chromosome being examined.
					segmental_aneuploidy(i).position = round( chrom_breaks{chrom}(edge)*chrom_sizes(chrom).size );	% chrom bin at start of CNV change.
					segmental_aneuploidy(i).break    = chrom_breaks{chrom}(edge);				% percent along chromosome of edge.
				end;
			end;
		end;
	end;
	save(dataFile, 'segmental_aneuploidy');


	%%========================================================================================
	% Redo CNV_v6_6.m to update calculation of CNV estimates per standard genome bin
	%-----------------------------------------------------------------------------------------
	if (countIters == 5)
		chromCopyNum_changed = false;
	end;
	if chromCopyNum_changed
		CNV_v6_6(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString,CNV_verString,'not-used',displayBREAKS,'not-used',false);
	end;
end;


%%================================================================================================
% Redraw CNV figures after analysis completes.
%-------------------------------------------------------------------------------------------------
CNV_v6_6(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString,CNV_verString,'not-used',displayBREAKS,'not-used',true);


%%================================================================================================
% Logging stuff.
%-------------------------------------------------------------------------------------------------
fprintf('\n');
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		fprintf(['\t chromCopyNum{' num2str(chrom) '} = ']);
		for i = 1:length(chromCopyNum{chrom})
			fprintf([num2str(chromCopyNum{chrom}(i)) ' ']);
		end;
		fprintf('\n');
	end;
end;


%%================================================================================================
% end stuff
%-------------------------------------------------------------------------------------------------
fprintf('\n### End of CNV_LOH_check.m processing.\n');

end


