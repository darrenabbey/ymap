function [] = CNV_v6_6(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString,CNV_verString,rDNA_verString,displayBREAKS, referencechrom, drawFigures); %% rDNA_verString & referencechrom are not used.
addpath('../');

% hide figures during construction.
set(0,'DefaultFigureVisible','off');


%%==========================================================================================
% Load project figure version.
%-------------------------------------------------------------------------------------------
workingDir = [main_dir '/users/' user '/projects/' project '/'];
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;


%%==========================================================================================
% Check if figures are needed.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tNot drawing CNV plots during CNV_LOH_check.m analysis.\n');
if (drawFigures == true)
	fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
	if exist([main_dir '/users/' user '/projects/' project '/figure_options.txt'], 'file')
		figure_options = importdata([main_dir '/users/' user '/projects/' project '/figure_options.txt'],'\t',1);

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
else
	Make_figure_bias_end = false;
	Make_figure_bias_GC  = false;
	Make_figure_linear   = false;
	Make_figure_standard = false;
end;


%%==========================================================================================
% Some configuration variables.
%-------------------------------------------------------------------------------------------
Centromere_format_default   = 3;
Yscale_nearest_even_ploidy  = true;
HistPlot                    = true;
chromNum                      = true;
show_annotations            = true;
analyze_rDNA                = true;
Standard_display            = Make_figure_standard;
Linear_display              = Make_figure_linear;
Linear_displayBREAKS        = false;
Low_quality_ploidy_estimate = true;


%%==========================================================================================
% Load FASTA file name from 'reference.txt' file for project.
%-------------------------------------------------------------------------------------------
Reference    = [main_dir '/users/' genomeUser '/genomes/' genome '/reference.txt'];
FASTA_string = strtrim(fileread(Reference));
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%==========================================================================================
% Control variables.
%-------------------------------------------------------------------------------------------
projectDir = [main_dir '/users/' user '/projects/' project '/'];
genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];

fprintf(['\n$$ projectDir : ' projectDir '\n']);
fprintf([  '$$ genomeDir  : ' genomeDir  '\n']);
fprintf([  '$$ genome     : ' genome     '\n']);
fprintf([  '$$ project    : ' project    '\n']);

[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
Aneuploidy = [];  % later loaded from Load_dataset_information(projectDir) after ChARM algorithm is used.
num_chroms   = length(chrom_sizes);

for i = 1:num_chroms
	chrom_size(i)  = 0;
	cen_start(i) = 0;
	cen_end(i)   = 0;
end;
for i = 1:num_chroms
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


%%==========================================================================================
% Some basic setup.
%-------------------------------------------------------------------------------------------
% Sanitize user input of euploid state base for species.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
maxY             = ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/4;

fprintf(['\nGenerating CNV figure from ''' project ''' sequence data.\n']);


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
	chroms          = raw_data{1};
	fragment_starts = raw_data{2};
	fragment_ends   = raw_data{3};
	readAverages    = raw_data{4};
	CNVlines_analyzed  = length(chroms);

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
% Determine bases_per_bin sizes to be used as a fallback.
%-------------------------------------------------------------------------------------------
%% Separately calculate bases_per_bin for figure scaling purposes.
max_chrom_size = max(chrom_size);
cnv_res_file = [genomeDir 'resolution.CNV.txt'];
if (exist(cnv_res_file, 'file') == 0)
	bases_per_bin = round(max_chrom_size / 700);
else
	bases_per_bin = round(max_chrom_size / str2num(fileread(cnv_res_file)));
end;
snp_res_file = [genomeDir 'resolution.SNPs.txt'];
if (exist(snp_res_file, 'file') == 0)
	bases_per_bin_SNP = round(max_chrom_size / 700);
else
	bases_per_bin_SNP = round(max_chrom_size / str2num(fileread(snp_res_file)));
end;


%%==========================================================================================
% Initialize some data vectors for data.
%-------------------------------------------------------------------------------------------
num_chroms = length(chrom_in_use);
chrom_CNVdata = cell(1, num_chroms); % Pre-allocate the cell array
for chrom = 1:num_chroms
        if chrom_in_use(chrom) == 1
                % Safe check: use file tracking data if it exists, otherwise use math fallback.
                if preprocessed_CNVs
                        % Count how many fragment rows match this specific chromosome number.
                        num_bins = sum(chroms == chrom);
                else
                        % Fallback math definition when file is missing.
                        num_bins = ceil(chrom_size(chrom) / bases_per_bin);
                end;

                % Category tracked : average read counts per bin.
                chrom_CNVdata{chrom} = zeros(1, num_bins);
        end;
end;


%%==========================================================================================
% Reorganize raw data loaded earlier into actual bin counts used per chromosome.
%-------------------------------------------------------------------------------------------
mat_file_path = [projectDir 'CNV_' CNV_verString '.mat'];

if (exist(mat_file_path, 'file') == 0)
        fprintf('\nMAT file not found, regenerating.\n');

        % Populate cell array.
        % Check if we are using pre-defined bins from the file or math fallback
        if preprocessed_CNVs
                % --- FILE BIN STRATEGY ---
                % Since each row in the file represents a sequential bin for its chromosome,
                % we use a running index (1 to N) per chromosome to map perfectly.
                unique_chroms = unique(chroms);
                for c = unique_chroms'
                        idx = (chroms == c);
                        num_bins_for_c = sum(idx);
                        % Assign values sequentially matching exactly your zeros(1, num_bins) initialization
                        chrom_CNVdata{c}(1:num_bins_for_c) = readAverages(idx);
                end;
        else
                % --- FALLBACK MATH STRATEGY ---
                % Calculate spatial grid index positions relative to sequence coordinate spans
                positions = ceil(double(fragment_starts) / bases_per_bin);

                unique_chroms = unique(chroms);
                for c = unique_chroms'
                        idx = (chroms == c);
                        chrom_pos = positions(idx);
                        chrom_vals = readAverages(idx);

                        % Vectorized accumulation to handle multiple entries mapping to the same bin
                        for i = 1:length(chrom_pos)
                                p = chrom_pos(i);
                                if p > 0 && p <= length(chrom_CNVdata{c})
                                        chrom_CNVdata{c}(p) = chrom_vals(i);
                                end;
                        end;
                end;
        end;

        save(mat_file_path, 'chrom_CNVdata', 'chroms', 'fragment_starts', 'fragment_ends');

        %% change permissions of file.
        system(['chmod 774 ' mat_file_path]);
else
        fprintf('\nMAT file found, loading.\n');
        load(mat_file_path);
end;


%%==========================================================================================
% Log the first several values of a chromosome for testing.
%-------------------------------------------------------------------------------------------
target_chrom = 6;
fprintf('\n----------------------------------------------------------------------\n');
if target_chrom <= length(chrom_CNVdata) && ~isempty(chrom_CNVdata{target_chrom})
	current_chrom_data = chrom_CNVdata{target_chrom};
	valid_indices = find(current_chrom_data, 10);
	if ~isempty(valid_indices)
		fprintf('\tFirst %d values for Chromosome %d (right after loading preprocessed_CNVs.txt file)\n', length(valid_indices), target_chrom);

		for idx = valid_indices
			val = current_chrom_data(idx);
			fprintf('\t\tChr: %d | Position Index: %d | CNV Value: %.4f\n', target_chrom, idx, val);
		end
	else
		fprintf('\tChromosome %d exists but contains no data (all zeros).\n', target_chrom);
	end;
else
	fprintf('\tChromosome %d data was not found.\n', target_chrom);
end;
fprintf('\n----------------------------------------------------------------------\n');


%%==========================================================================================
% Load bias selections from 'dataBiases.txt' file.
%-------------------------------------------------------------------------------------------
datafile = [projectDir 'dataBiases.txt'];
if (exist(datafile,'file') == 0)
	performLengthbiasCorrection = false;
	performGCbiasCorrection     = true;
	performRepetbiasCorrection  = false;
	performEndbiasCorrection    = false;
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

	%%% Perform fragment length bias correction is meaningless for this data format, so ignore.

	%%% Perform %GC bias correction.
	if (strcmp(bias2,'True') == 1)
		performGCbiasCorrection    = true;
	else
		performGCbiasCorrection    = false;
	end;

	%%% Repetitiveness bias ended up being a meaningless concept.

	%%% Perform chromosome end bias correction.
	if (strcmp(bias4,'True') == 1)
		performEndbiasCorrection   = true;
		performGCbiasCorrection    = true; % needed since end bias use gc data
	else
		performEndbiasCorrection   = false;
	end;
end;


%%==========================================================================================
% Setup for LOWESS fitting and figure generation.
%-------------------------------------------------------------------------------------------
%% calculate CNV bin values.
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		CNVplot{chrom} = chrom_CNVdata{chrom};
	end;
end;

%% Gather CNV data for LOWESS fitting.
CNVdata_all = [];
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		CNVdata_all = [CNVdata_all     CNVplot{chrom}];
	end;
end;
medianRawY = median(CNVdata_all)


%% Gather median-normalized CNV data for LOWESS fitting.
CNVdata_all = [];
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		if (medianRawY ~= 0)
			CNVplot{chrom} = CNVplot{chrom}/medianRawY;
		end;
		CNVdata_all = [CNVdata_all CNVplot{chrom}];
	end;
end;

%% per chrom median values for LOWESS fitting.
medianCNV = [];
for chrom = 1:length(chrom_in_use)
        if (chrom_in_use(chrom) == 1)
		medianCNV(chrom) = median(CNVplot{chrom});
	else
		medianCNV(chrom) = 0;
        end;
end;


%%================================================================================================
% Load pre-processed standard-bin fragment GC-bias data for genome.
%-------------------------------------------------------------------------------------------------
if (performGCbiasCorrection)
        gc_file = [main_dir '/users/' genomeUser '/genomes/' genome '/' FastaName '.GC_ratios.standard_bins.txt'];
        fprintf('standard_bins_GC_ratios_file :\n\t%s\n', gc_file);

        standard_bins_GC_ratios_fid = fopen(gc_file, 'r');
        if standard_bins_GC_ratios_fid == -1, error('Cannot open GC ratios file: %s', gc_file); end
        fprintf('\tFile ID: %d\n', standard_bins_GC_ratios_fid);

        %% Initialize GC ratio cell array matching pre-allocated sizes
        num_chroms = length(chrom_in_use);
        chrom_GCratioData = cell(1, num_chroms);

        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        % Match the exact length used during your previous bin initialization
                        if preprocessed_CNVs
                                num_bins = sum(chroms == chrom);
                        else
                                num_bins = ceil(chrom_size(chrom) / bases_per_bin);
                        end;
                        chrom_GCratioData{chrom} = zeros(1, num_bins);
                end;
        end;

        %% Vectorized parsing: Read entire file at once skipping '#' comment lines
        raw_gc_data = textscan(standard_bins_GC_ratios_fid, '%d %d %d %f', 'CommentStyle', '#');
        fclose(standard_bins_GC_ratios_fid);

        gc_chroms      = raw_gc_data{1};
        gc_starts      = raw_gc_data{2};
        gc_ends        = raw_gc_data{3};
        gc_ratios      = raw_gc_data{4};

	%% Populate cell array cleanly
        if preprocessed_CNVs
                % --- FILE BIN STRATEGY ---
                % If tracking via preprocessed file, map fragment lines sequentially (1 to N) per chromosome
                unique_gc_chroms = unique(gc_chroms);
                for c = unique_gc_chroms'
                        if c <= num_chroms && chrom_in_use(c) == 1
                                idx = (gc_chroms == c);
                                num_bins_for_c = sum(idx);

                                % FIX: Extract the chromosome-specific subset first to avoid double-subscripting crash
                                current_chrom_ratios = gc_ratios(idx);

                                % Fill sequentially up to the length allocated
                                limit_bins = min(num_bins_for_c, length(chrom_GCratioData{c}));
                                chrom_GCratioData{c}(1:limit_bins) = current_chrom_ratios(1:limit_bins);
                        end;
                end;
        else
                % --- FALLBACK MATH STRATEGY ---
                % Calculate explicit index grid locations based on coordinates
                gc_positions = ceil(double(gc_starts) / bases_per_bin);

                unique_gc_chroms = unique(gc_chroms);
                for c = unique_gc_chroms'
                        if c <= num_chroms && chrom_in_use(c) == 1
                                idx = (gc_chroms == c);
                                chrom_pos = gc_positions(idx);
                                chrom_vals = gc_ratios(idx);

                                % Assign to positions with a safety boundary check
                                for i = 1:length(chrom_pos)
                                        p = chrom_pos(i);
                                        if p > 0 && p <= length(chrom_GCratioData{c})
                                                chrom_GCratioData{c}(p) = chrom_vals(i);
                                        end;
                                end;
                        end;
                end;
        end;
end;


%%================================================================================================
% Perform chromosome-end bias correction.
%-------------------------------------------------------------------------------------------------
if (performEndbiasCorrection)
        %% Calculate distance from CNV bin fragment center to nearest end of chromosome.
        num_chroms = length(chrom_in_use);
        chrom_EndDistanceData = cell(1, num_chroms);

        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        % Dynamic allocation based on file-defined bins or math fallback
                        if preprocessed_CNVs
                                num_bins = sum(chroms == chrom);
                        else
                                num_bins = ceil(chrom_size(chrom)/bases_per_bin);
                        end;

                        % Fully vectorized distance calculation (replacing the nested loop)
                        positions = 1:num_bins;
                        chrom_EndDistanceData{chrom} = min(positions, num_bins - positions);
                end;
        end;

        %% Extend EndDistance data for shorter chromosomes to length of the longest chromosome.
        chrom_EndDistanceData_extended = chrom_EndDistanceData;

        % Dynamically calculate largest bin dimension based on active structural lengths
        largest_chrom_bin_count = 0;
        for chrom = 1:length(chrom_in_use)
                if (chrom_in_use(chrom) == 1)
                        largest_chrom_bin_count = max(largest_chrom_bin_count, length(chrom_EndDistanceData{chrom}));
                end;
        end;

        for chrom = 1:length(chrom_in_use)
                if (chrom_in_use(chrom) == 1)
                        chrom_bin_count = length(chrom_EndDistanceData{chrom});
                        diff_bins       = largest_chrom_bin_count - chrom_bin_count;

                        if diff_bins > 0
                                % Vectorized append operation (replacing the iterative element loop)
                                chrom_EndDistanceData_extended{chrom}(chrom_bin_count + (1:diff_bins)) = (1:diff_bins) + chrom_bin_count;
                        end;
                end;
        end;

        %% Extend CNV data for shorter chromosomes to length of the longest chromosome.
        num_chroms = length(chrom_in_use);
        chrom_CNVdata_extended  = cell(1, num_chroms);
        chrom_CNVdata_extended_ = cell(1, num_chroms);

        % Determine the largest chromosome block length from the actual allocated data sizes
        largest_chrom_bin_count = 0;
        largest_chrom = 1;
        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        % Safeguard data source mapping variant names
                        current_len = length(CNVplot{chrom});

                        if current_len > largest_chrom_bin_count
                                largest_chrom_bin_count = current_len;
                                largest_chrom = chrom;
                        end;
                end;
        end;

        % Populate core values
        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        source_data = CNVplot{chrom};
                        chrom_CNVdata_extended{chrom}  = source_data;
                        chrom_CNVdata_extended_{chrom} = source_data / medianCNV(chrom);
                end;
        end;

        % Perform vectorized padding extensions.
        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        chrom_bin_count = length(chrom_CNVdata_extended{chrom});
                        fprintf('chrom_bin_count(%d) = %d\n', chrom, chrom_bin_count);

                        chrom_middle_bin = round(chrom_bin_count / 2);
                        fprintf('chrom_middle_bin   = %d\n', chrom_middle_bin);

                        diff_bins = largest_chrom_bin_count - chrom_bin_count;
                        if diff_bins > 0
                                % Vectorized block copy (replacing the performance-draining end+1 loop)
                                target_indices = chrom_bin_count + (1:diff_bins);
                                source_indices = chrom_bin_count + (1:diff_bins);

                                chrom_CNVdata_extended{chrom}(target_indices)  = chrom_CNVdata_extended{largest_chrom}(source_indices);
                                chrom_CNVdata_extended_{chrom}(target_indices) = chrom_CNVdata_extended_{largest_chrom}(source_indices);
                        end;
                end;
        end;

	%% Gather data for LOWESS fitting 3 : chrom end bias.
        num_chroms = length(chrom_in_use);

        % 1. Pre-calculate total total element footprint to avoid dynamic memory resizing
        total_elements = 0;
        total_extended_elements = 0;
        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        total_elements = total_elements + length(CNVplot{chrom});
                        total_extended_elements = total_extended_elements + length(chrom_CNVdata_extended{chrom});
                end;
        end;

        % 2. Pre-allocate flat arrays for speed
        CNVdata_all_n1                     = zeros(1, total_elements);
        GCratioData_all                    = zeros(1, total_elements);
        chrom_EndDistanceData_all          = zeros(1, total_elements);

        chrom_CNVdata_extended_all         = zeros(1, total_extended_elements);
        chrom_CNVdata_extended_all_        = zeros(1, total_extended_elements);
        chrom_EndDistanceData_extended_all = zeros(1, total_extended_elements);

        % 3. Populate pre-allocated matrices using running index markers
        idx_start = 1;
        idx_ext_start = 1;

        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        % Use (:)'' to force data into standard horizontal vector shape regardless of source orientation
                        current_cnv    = CNVplot{chrom}(:)';
                        current_gc     = chrom_GCratioData{chrom}(:)';
                        current_dist   = chrom_EndDistanceData{chrom}(:)';

                        current_ext    = chrom_CNVdata_extended{chrom}(:)';
                        current_ext_   = chrom_CNVdata_extended_{chrom}(:)';
                        current_ext_ds = chrom_EndDistanceData_extended{chrom}(:)';

                        % Calculate insertion spans
                        len = length(current_cnv);
                        len_ext = length(current_ext);

                        % Insert core values
                        CNVdata_all_n1(idx_start : idx_start + len - 1)            = current_cnv;
                        GCratioData_all(idx_start : idx_start + len - 1)           = current_gc;
                        chrom_EndDistanceData_all(idx_start : idx_start + len - 1) = current_dist;

                        % Insert investigational extended values
                        chrom_CNVdata_extended_all(idx_ext_start : idx_ext_start + len_ext - 1)         = current_ext;
                        chrom_CNVdata_extended_all_(idx_ext_start : idx_ext_start + len_ext - 1)        = current_ext_;
                        chrom_EndDistanceData_extended_all(idx_ext_start : idx_ext_start + len_ext - 1) = current_ext_ds;

                        % Shift index tracking pointers forward
                        idx_start = idx_start + len;
                        idx_ext_start = idx_ext_start + len_ext;
                end;
        end;

	% Clean up data by:
	%    deleting GC ratio data near zero.
	%    deleting CNV data beyond 6* the median value.  (rDNA, etc.)

	% Create a logical mask for the UNEXTENDED core datasets.
	invalid_mask = (GCratioData_all < 0.01) | (CNVdata_all_n1 > 6) | (CNVdata_all_n1 == 0);
	keep_mask = ~invalid_mask;

	% FIX; Create a separate logical mask for the EXTENDED arrays to prevent length mismatch crashes.
	% Since GC ratio data isn't extended, we check the extended CNV profiles directly
	invalid_mask_extended = (chrom_CNVdata_extended_all > 6) | (chrom_CNVdata_extended_all == 0);
	keep_mask_extended = ~invalid_mask_extended;

	% Extract the clean arrays using their respective matching length masks.
	CNVdata_clean                                        = CNVdata_all_n1(keep_mask);
	GCratioData_clean                                    = GCratioData_all(keep_mask);
	chrom_EndDistanceData_clean                          = chrom_EndDistanceData_all(keep_mask);

	% Clean the extended variables using the extended mask.
	chrom_CNVdata_extended_clean                         = chrom_CNVdata_extended_all(keep_mask_extended);
	chrom_CNVdata_extended_clean_                        = chrom_CNVdata_extended_all_(keep_mask_extended);
	chrom_EndDistanceData_extended_clean                 = chrom_EndDistanceData_extended_all(keep_mask_extended);

	%% Perform LOWESS fitting : end bias.
	rawData_X1     = chrom_EndDistanceData_extended_clean;
	rawData_Y1     = chrom_CNVdata_extended_clean;
	rawData_Y1_    = chrom_CNVdata_extended_clean_;

	% Perform correction only if the data has more than two values since otherwise interp1() will crash.
        if (size(rawData_X1,2) > 2 && size(rawData_Y1,2) > 2)
                fprintf('Lowess X:Y size : [%d,%d]:[%d,%d]\n', size(rawData_X1,1), size(rawData_X1,2), size(rawData_Y1,1), size(rawData_Y1,2));
                [fitX1, fitY1]  = optimize_mylowess(rawData_X1,rawData_Y1, 10,0);
                [fitX1_,fitY1_] = optimize_mylowess(rawData_X1,rawData_Y1_,10,0);
                fprintf('rawData_X1 size = %d\n', size(rawData_X1,2));
                fprintf('rawData_Y1 size = %d\n', size(rawData_Y1,2));
                fprintf('fitX1 size      = [%d,%d]\n', size(fitX1,1), size(fitX1,2));
                fprintf('fitY1 size      = [%d,%d]\n', size(fitY1,1), size(fitY1,2));

                %% Find minimum coordinate of fits, then apply that value to every location to the right in the fit (towards the chromosome center).
                % To raw data.
                [minFitY1, minFitY1key]   = min(fitY1);
                fprintf('minFitY1        = %f\n', minFitY1);
                fprintf('minFitY1key     = %d\n', minFitY1key);
                fitY1_raw                 = fitY1;
                fitY1(minFitY1key:end)    = minFitY1;

                % To investigational algorithm data.
                if (isnan(fitY1_(1)))
                        fitY1_            = fitY1;
                end
                [minFitY1_, minFitY1key_] = min(fitY1_);
                fprintf('minFitY1_       = %f\n', minFitY1_);
                fprintf('minFitY1key_    = %d\n', minFitY1key_);
                fitY1_raw_                = fitY1_;
                fitY1_(minFitY1key_:end)  = minFitY1_;

                % Correct data using normalization to LOWESS fitting
                Y_target = 1;
                for chrom = 1:length(chrom_in_use)
                        if (chrom_in_use(chrom) == 1)
                                % Safely target raw base matrix for unnormalized calculations
                                current_cnv_source = CNVplot{chrom}; % Pre-normalized mapping

                                % Track dynamic file bin length to ensure logs match memory allocations
                                if preprocessed_CNVs
                                        actual_bins = sum(chroms == chrom);
                                else
                                        actual_bins = ceil(chrom_size(chrom)/bases_per_bin);
                                end;

                                fprintf('chrom%d : %d ... %d \t; numbins = %d\n', ...
                                        chrom, length(chrom_GCratioData{chrom}), length(current_cnv_source), actual_bins);

                                rawData_chrom_X1{chrom}          = chrom_EndDistanceData{chrom};
                                rawData_chrom_Y1{chrom}          = current_cnv_source;
                                rawData_chrom_Y1_{chrom}         = current_cnv_source / medianCNV(chrom); % Kept intact for investigational algorithm

                                fitData_chrom_Y1{chrom}          = interp1(fitX1,  fitY1,  rawData_chrom_X1{chrom}, 'spline');
                                fitData_chrom_Y1_{chrom}         = interp1(fitX1_, fitY1_, rawData_chrom_X1{chrom}, 'spline');

                                % FIX: Swapped '*' for '.*' to ensure scalar normalization behaves predictably regardless of vector shape orientation
                                normalizedData_chrom_Y1{chrom}   = (rawData_chrom_Y1{chrom} ./ fitData_chrom_Y1{chrom}) .* Y_target;
                                if (medianCNV(chrom) > 0)
                                        normalizedData_chrom_Y1_{chrom}  = (rawData_chrom_Y1_{chrom} ./ fitData_chrom_Y1_{chrom}) .* Y_target * medianCNV(chrom);
                                else
                                        normalizedData_chrom_Y1_{chrom}  = (rawData_chrom_Y1_{chrom} ./ fitData_chrom_Y1_{chrom}) .* Y_target;
                                end;

                                % Setting all NaN values to zero
                                normalizedData_chrom_Y1{chrom}(isnan(normalizedData_chrom_Y1{chrom}))   = 0;
                                normalizedData_chrom_Y1_{chrom}(isnan(normalizedData_chrom_Y1_{chrom})) = 0;
                        end;
                end;
        else
                % Flatten matrices safely if insufficient fitting coordinates exist
                for chrom = 1:length(chrom_in_use)
                        if (chrom_in_use(chrom) == 1)
                                current_cnv_source              = CNVplot{chrom};
                                normalizedData_chrom_Y1{chrom}  = current_cnv_source;
                                normalizedData_chrom_Y1_{chrom} = CNVplot{chrom} / medianCNV(chrom);
                        end;
                end;
        end;
else
        % FALLBACK: If there is insufficient data to safely calculate
        % LOWESS fitting curves, pass the uncorrected data directly.
        for chrom = 1:length(chrom_in_use)
                if (chrom_in_use(chrom) == 1)
                        current_cnv_source              = CNVplot{chrom};
                        normalizedData_chrom_Y1{chrom}  = current_cnv_source;
                        normalizedData_chrom_Y1_{chrom} = current_cnv_source / medianCNV(chrom);
                end;
        end;
end;


%%================================================================================================
% Perform %GC bias correction.
%-------------------------------------------------------------------------------------------------
if (performGCbiasCorrection)
        % 1. Pre-calculate total element footprint to optimize memory allocation
        num_chroms = length(chrom_in_use);
        total_elements = 0;
        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        total_elements = total_elements + length(chrom_GCratioData{chrom});
                end;
        end;

        % 2. Pre-allocate arrays for optimal speed
        GCratioData_all = zeros(1, total_elements);
        CNVdata_all_n1  = zeros(1, total_elements);

        % 3. Populate flat matrices using running index markers
        idx_start = 1;
        for chrom = 1:num_chroms
                if (chrom_in_use(chrom) == 1)
                        current_gc  = chrom_GCratioData{chrom}(:)';
                        current_cnv = normalizedData_chrom_Y1{chrom}(:)';
                        len = length(current_gc);

                        GCratioData_all(idx_start : idx_start + len - 1) = current_gc;
                        CNVdata_all_n1(idx_start : idx_start + len - 1)  = current_cnv;

                        idx_start = idx_start + len;
                end;
        end;

        % 4. Unified atomic filtration mask (Fixes the array-shortening/index-shifting bug)
        invalid_mask = (GCratioData_all < 0.01) | (CNVdata_all_n1 > 6) | (CNVdata_all_n1 == 0);
        keep_mask = ~invalid_mask;

        CNVdata_clean     = CNVdata_all_n1(keep_mask);
        GCratioData_clean = GCratioData_all(keep_mask);

        % Perform LOWESS fitting : GC_bias.
        rawData_X2     = GCratioData_clean;
        rawData_Y2     = CNVdata_clean;

        % Perform correction only if the data has more than two values since otherwise interp1() will crash.
        if (size(rawData_X2,2) > 2 && size(rawData_Y2,2) > 2)
                fprintf('Lowess X:Y size : [%d,%d]:[%d,%d]\n', size(rawData_X2,1), size(rawData_X2,2), size(rawData_Y2,1), size(rawData_Y2,2));
                [fitX2, fitY2] = optimize_mylowess2(rawData_X2,rawData_Y2,10, 0);

                % Correct data using normalization to LOWESS fitting
                Y_target = 1;
                for chrom = 1:num_chroms
                        if (chrom_in_use(chrom) == 1)
                                if (size(chrom_GCratioData{chrom},2) > 2)
                                        % Synchronize file-defined bin tracking lengths for correct logging
                                        if preprocessed_CNVs
                                                actual_bins = sum(chroms == chrom);
                                        else
                                                actual_bins = ceil(chrom_size(chrom)/bases_per_bin);
                                        end;

                                        fprintf('chrom%d : %d ... %d \t; numbins = %d\n', ...
                                                chrom, length(chrom_GCratioData{chrom}), length(CNVplot{chrom}), actual_bins);

                                        rawData_chrom_X2{chrom}        = chrom_GCratioData{chrom};
                                        rawData_chrom_Y2{chrom}        = normalizedData_chrom_Y1{chrom};
                                        fitData_chrom_Y2{chrom}        = interp1(fitX2,fitY2,rawData_chrom_X2{chrom},'spline');

                                        % Filter by dividing out the fit curve.
                                        normalizedData_chrom_Y2{chrom} = rawData_chrom_Y2{chrom}./fitData_chrom_Y2{chrom};
                                else
                                        % There's not enough data on this chromosome to do GC bias correction.
                                        rawData_chrom_X2{chrom}        = chrom_GCratioData{chrom};
                                        rawData_chrom_Y2{chrom}        = normalizedData_chrom_Y1{chrom};
                                        normalizedData_chrom_Y2{chrom} = normalizedData_chrom_Y1{chrom};
                                end;
                        end;
                end;
        else
                for chrom = 1:num_chroms
                        if (chrom_in_use(chrom) == 1)
                                normalizedData_chrom_Y2{chrom} = normalizedData_chrom_Y1{chrom};
                        end;
                end;
                % disabling perform GC bias correction since data is invalid or empty and so the figure should not be created
                performGCbiasCorrection = false;
        end;
else
        for chrom = 1:length(chrom_in_use)
                if (chrom_in_use(chrom) == 1)
                        normalizedData_chrom_Y2{chrom} = normalizedData_chrom_Y1{chrom};
                end;
        end;
end;


%%================================================================================================
% Move LOWESS-normalizd CNV data into display pipeline.
%-------------------------------------------------------------------------------------------------
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		CNVplot{chrom} = normalizedData_chrom_Y2{chrom};
	end;
end;


%%================================================================================================
% Generate chromosome-end bias correction figure.
%-------------------------------------------------------------------------------------------------
if (Make_figure_bias_end)
	%% Generate figure showing subplots of LOWESS fittings.
	if (performEndbiasCorrection)
		bias_end_fig = figure();

		%%================================================================================
		% Original plots. (top subfigures)
		%---------------------------------------------------------------------------------
		%% Make genome median normalized data subplot.
		subplot(2,6,1:2);
		hold on;
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				plot(rawData_chrom_X1{chrom},rawData_chrom_Y1{chrom},'k.','markersize',1);        % raw data
			end;
		end;
		plot(fitX1,fitY1,     'Color', [1 0 0], 'LineWidth',4);       % Adjusted LOWESS fit curve.
		plot(fitX1,fitY1_raw, 'Color', [0 0 1], 'LineWidth',2);       % Raw LOWESS fit curve.
		hold off;
		xlabel('NearestEnd');
		ylabel('CNV data');
		xlim([0 largest_chrom_bin_count/2]);
		ylim([0 4]);
		axis square;
		title('Reads vs. NearestEnd');

		% Make y-value histogram
		subplot(2,6,3);
		data = [];
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				data = [data, rawData_chrom_Y1{chrom}];
			end;
		end;
		endBias_histogram(data,4);
		ylabel('CNV data');

		%% Make corrected data subplot.
		subplot(2,6,4:5);
		hold on;
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				plot(rawData_chrom_X1{chrom},normalizedData_chrom_Y1{chrom},'k.','markersize',1); % corrected data.
			end;
		end;
		plot([fitX1(1) fitX1(end)],[Y_target Y_target], 'Color', [1 0 0], 'LineWidth',4);          % normalization line.
		hold off;
		xlabel('NearestEnd');
		ylabel('corrected CNV data');
		xlim([0 largest_chrom_bin_count/2]);
		ylim([0 4]);
		axis square;
		title('NearestEnd Corrected (algorithm 1)');

		% Make y-value histogram
		subplot(2,6,6);
		data = [];
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				data = [data, normalizedData_chrom_Y1{chrom}];
			end;
		end;
		endBias_histogram(data,4);
		ylabel('corrected CNV data');


		%%================================================================================
		% Attempting to normalize by chromosome median CNV before fitting. (bottom subfigures)
		%---------------------------------------------------------------------------------

		%% Make chromosome median normalized data subplot.
		subplot(2,6,7:8);
		hold on;
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				plot(rawData_chrom_X1{chrom},rawData_chrom_Y1_{chrom},'k.','markersize',1);        % raw data
			end;
		end;
		plot(fitX1,fitY1_,     'Color', [1 0 0], 'LineWidth',4);	% Adjusted LOWESS fit curve.
		plot(fitX1,fitY1_raw_, 'Color', [0 0 1], 'LineWidth',2);        % Raw LOWESS fit curve.
		hold off;
		xlabel('NearestEnd');
		ylabel('CNV data');
		xlim([0 largest_chrom_bin_count/2]);
		ylim([0 4]);
		axis square;
		title('Median normalized Reads vs. NearestEnd');

		% Make y-value histogram
		subplot(2,6,9);
		data = [];
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				data = [data, rawData_chrom_Y1_{chrom}];
			end;
		end;
		endBias_histogram(data,4);
		ylabel('CNV data');

		%% Make corrected data subplot.
		subplot(2,6,10:11);
		hold on;
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				plot(rawData_chrom_X1{chrom},normalizedData_chrom_Y1_{chrom},'k.','markersize',1); % corrected data.
			end;
		end;
		plot([fitX1(1) fitX1(end)],[Y_target Y_target], 'Color', [1 0 0], 'LineWidth',2);          % normalization line.
		hold off;
		xlabel('NearestEnd');
		ylabel('corrected CNV data');
		xlim([0 largest_chrom_bin_count/2]);
		ylim([0 4]);
		axis square;
		title('NearestEnd Corrected\n(algorithm 2, in development)');

		% Make y-value histogram
		subplot(2,6,12);
		data = [];
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				data = [data, normalizedData_chrom_Y1{chrom}];
			end;
		end;
		endBias_histogram(data,4);
		ylabel('corrected CNV data');


		%%================================================================================
		% final stuff.
		%---------------------------------------------------------------------------------

		set(bias_end_fig,'PaperPosition',[0 0 6 3]*2);
		saveas(bias_end_fig, [projectDir 'fig.bias_chrom_end.' figVer 'eps'], 'epsc');
		saveas(bias_end_fig, [projectDir 'fig.bias_chrom_end.' figVer 'png'], 'png');
		delete(bias_end_fig);

		%% change permissions of figures.
		system(['chmod 774 ' projectDir 'fig.bias_chrom_end.' figVer 'eps']);
		system(['chmod 774 ' projectDir 'fig.bias_chrom_end.' figVer 'png']);
	end;
end;


%%================================================================================================
% Generate GC% bias correction figure.
%-------------------------------------------------------------------------------------------------
if (Make_figure_bias_GC)
	if (performGCbiasCorrection)
		bias_GC_fig = figure();

		%=================================================================================
		% First subfigure pair.
		%---------------------------------------------------------------------------------

		% Make raw GC% bias plot.
		subplot(2,6,1:2);
		hold on;
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				plot(rawData_chrom_X2{chrom},normalizedData_chrom_Y1{chrom},'k.','markersize',1);		% raw data
			end;
		end;
		plot(fitX2,fitY2,'r','LineWidth',2);						% LOWESS fit curve.
		hold off;
		xlabel('GC ratio');
		ylabel('CNV data');
		xlim([0.0 1.0]);
		ylim([0 4]);
		axis square;
		title('Reads vs. GC bias');

		% Make y-value histogram
		subplot(2,6,3);
		data = [];
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				data = [data, normalizedData_chrom_Y1{chrom}];
			end;
		end;
		endBias_histogram(data,4);
		ylabel('CNV data');
		title('CNV histogram');


		%=================================================================================
		% Second subfigure pair.
		%---------------------------------------------------------------------------------

		% Make corrected GC% bias plot.
		subplot(2,6,4:5);
		hold on;
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				plot(rawData_chrom_X2{chrom},normalizedData_chrom_Y2{chrom},'k.','markersize',1);	% corrected data.
			end;
		end;
		plot([fitX2(1) fitX2(end)],[Y_target Y_target],'r','LineWidth',2);			% normalization line.
		hold off;
		xlabel('GC ratio');
		ylabel('corrected CNV data');
		xlim([0.0 1.0]);
		ylim([0 4]);
		axis square;
		title('GC bias Corrected');

		% Make y-value histogram
		subplot(2,6,6);
		data = [];
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				data = [data, normalizedData_chrom_Y2{chrom}];
			end;
		end;
		endBias_histogram(data,4);
		ylabel('corrected CNV data');
		title('CNV histogram');

		% Save figure.
		set(bias_GC_fig,'PaperPosition',[0 0 6 3]*2);
		saveas(bias_GC_fig, [projectDir 'fig.bias_GC_content.' figVer 'eps'], 'epsc');
		saveas(bias_GC_fig, [projectDir 'fig.bias_GC_content.' figVer 'png'], 'png');
		delete(bias_GC_fig);

		%% change permissions of figures.
		system(['chmod 774 ' projectDir 'fig.bias_GC_content.' figVer 'eps']);
		system(['chmod 774 ' projectDir 'fig.bias_GC_content.' figVer 'png']);
	end;
end;


%%================================================================================================
% Save presented CNV data in a file format common across pipeline modules.
%-------------------------------------------------------------------------------------------------
fprintf('\nSaving "Common_CNV" data file.\n');
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		CNVplot2{chrom} = CNVplot{chrom};
	end;
end;
genome_CNV = genome;
save([projectDir 'Common_CNV.mat'], 'CNVplot2','genome_CNV','chrom_in_use');

%% change permissions of file.
system(['chmod 774 ' projectDir 'Common_CNV.mat']);

ploidy = str2num(ploidyEstimateString);
[chrom_breaks, chromCopyNum, ploidyAdjust, CNVfit_Rsquared] = FindChromSizes_4(workingDir, Aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use, false);

largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


%%================================================================================================
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------------
% load size definitions
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

if (Standard_display)
	Standard_fig = figure();
end;

if (Linear_display)
	Linear_fig           = figure();
	Linear_genome_size   = sum(chrom_size);
	Linear_TickSize      = -0.01;            % negative for outside, percentage of longest chrom figure.
	Linear_maxY          = 10;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;

%% Initialize copy numbers string.
stringchromCNVs = '';


%%================================================================================================
% Median normalize CNV data before figure generation.
%-------------------------------------------------------------------------------------------------
CNVdata_all = [];
fprintf('CNV normalization step\n');
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		CNVdata_all = [CNVdata_all CNVplot2{chrom}];
	end;
end;
medianCNV = median(CNVdata_all)
% avoid divding by zero
fprintf(['    medianCNV = ' num2str(medianCNV) '\n']);
if (medianCNV > 0)
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			CNVplot2{chrom} = CNVplot2{chrom}/medianCNV;
			fprintf(['    chrom' num2str(chrom) ' :: ' num2str(median(CNVplot2{chrom})) '\n']);
		end;
	end;
else
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			fprintf(['    chrom' num2str(chrom) ' :: ' num2str(median(CNVplot2{chrom})) '\n']);
		end;
	end;
end;

%% When analyzing a short FASTA representing a partial chromosome, this happens.
%        |    medianCNV = 0
%        |    chrom2 :: 0.99517
%        |    chrom3 :: 0
%        |    chrom4 :: 0
%        |    chrom5 :: 0
%        |    chrom6 :: 0
%        |    chrom7 :: 0
%        |    chrom8 :: 0
%        |    chrom9 :: 0


%%================================================================================================
% Make figures.
%-------------------------------------------------------------------------------------------------
first_chrom = true;

% Determine order to draw chromosome cartoons in.
chrom_order = [];
for test_chrom = 1:num_chroms
	chrom_pos   = find(chrom_figOrder==test_chrom);
	chrom_order = [chrom_order chrom_pos];
end;

% Draw chromosomes in order defined in figure_definitions.txt file.
for chrom_to_draw  = 1:length(chrom_order)
	chrom = chrom_order(chrom_to_draw);
	if (chrom_in_use(chrom) == 1)

		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chrom_figReversed(chrom) == 1)
			CNVplot2{chrom} = fliplr(CNVplot2{chrom});
		end;

		if (Standard_display)
			%% make standard chrom cartoons.
			figure(Standard_fig);
			left   = chrom_posX(chrom);
			bottom = chrom_posY(chrom);
			width  = chrom_width(chrom);
			height = chrom_height(chrom);
			fprintf(['chrom' num2str(chrom) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
			subplot('Position',[left bottom width height]);
			hold on;

			%% Hide axis lines.
			box off;

			%% standard : show centromere.
			Centromere_format = Centromere_format_default;
			x1       = cen_start(chrom)/bases_per_bin;
			x2       = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0;                                       % 0.5*(5000/bases_per_bin);
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
			%% standard : end show centromere.

			%% CNV plot section.
			fprintf(['standard-plot : chrom' num2str(chrom) ':' num2str(sum(chroms == chrom)) '\n']);
			draw_CNV_plot;

			%% draw lines across plots for easier interpretation of CNV regions.
			x2 = chrom_size(chrom)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % base ploidy line.
			%% end CNV plot section.

			%axes labels etc.
			hold off;

			% standard : limit x-axis to range of chromosome.
			xlim([0,chrom_size(chrom)/bases_per_bin]);

			% modify y axis limits to show annotation locations if any are provided.
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

			%% chromosome cartoon titles for standard figure.
			if (chrom_figReversed(chrom) == 0)
				text(-50000/5000/2*3, maxY/2, chrom_label{chrom}, 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size);
			else
				%% [chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)']
				text(-50000/5000/2*3, maxY/2, [chrom_label{chrom} char(10) '(reversed)'], 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize',round(stacked_chrom_font_size/2));
			end;

			set(gca,'FontSize',gca_stacked_font_size);
			if (chrom == find(chrom_posY == max(chrom_posY)))
				title([ project ' CNV map'],'Interpreter','none','FontSize',stacked_title_size);
			end;
			hold on;

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
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
				for segment = 2:length(chrom_breaks{chrom})-1
					bP = chrom_breaks{chrom}(segment)*chrom_length;
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
					if (annotation_chrom(i) == chrom)
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

			% make CNV histograms to the right of the main chrom cartoons.
			if (HistPlot)
				width     = 0.020;
				height    = chrom_height(chrom);
				bottom    = chrom_posY(chrom);
				histAll   = [];
				histAll2  = [];
				smoothed  = [];
				smoothed2 = [];
				fprintf(['chrom = ' num2str(chrom) '\n']);
				for segment = 1:length(chromCopyNum{chrom})
					subplot('Position',[(left+chrom_width(chrom)+0.005)+width*(segment-1) bottom-0.007 width height+0.007]);
					% The CNV-histogram values were normalized to a median value of 1.
					for i = round(1+length(CNVplot2{chrom})*chrom_breaks{chrom}(segment)):round(length(CNVplot2{chrom})*chrom_breaks{chrom}(segment+1))
						if (Low_quality_ploidy_estimate)
							histAll{segment}(i) = CNVplot2{chrom}(i)*ploidy*ploidyAdjust;
						else
							histAll{segment}(i) = CNVplot2{chrom}(i)*ploidy;
						end;
					end;
					% make a histogram of CNV data, then smooth it for display.
					histogram_end                                    = 15;   % end point in copy numbers for the histogram, this should be way outside the expected range.
					histAll{segment}(histAll{segment}<=0)            = [];   % clears any zero data. If ploidyAdjust is somehow zero, this causes on CNV histogram data to exist.

					% endpoints added to ensure histogram bounds.
					histAll{segment}(length(histAll{segment})+1)     = 0;
					histAll{segment}(length(histAll{segment})+1)     = histogram_end;

					% crop off any copy data outside the range.
					histAll{segment}(histAll{segment}<0)             = [];
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

					% ensure subplot axes are consistent with main chrom plots.
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
			% standard : end of CNV histograms at right.

			% places chrom copy number to the right of the main chrom cartoons.
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
				if (length(chromCopyNum{chrom}) == 1)
					chrom_string = num2str(chromCopyNum{chrom}(1));
				else
					chrom_string = num2str(chromCopyNum{chrom}(1));
					for i = 2:length(chromCopyNum{chrom})
						chrom_string = [chrom_string ',' num2str(chromCopyNum{chrom}(i))];
					end;
				end;
				text(0.1,0.5, chrom_string,'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',stacked_copy_font_size);

				stringchromCNVs = [stringchromCNVs ';' chrom_string];
			end;
		end;

		%% Linear figure draw section
		if (Linear_display)
			figure(Linear_fig);
			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
			hold on;

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
			%% linear : end show centromere/outline.

			%% CNV plot section.
			fprintf(['linear-plot : chrom' num2str(chrom) ':' num2str(sum(chroms == chrom)) '\n']);
			draw_CNV_plot;

			% draw lines across plots for easier interpretation of CNV regions.
			x2 = chrom_size(chrom)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			%% end CNV plot section.

			%% show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS) && (show_annotations)
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
                                for segment = 2:length(chrom_breaks{chrom})-1
                                        bP = chrom_breaks{chrom}(segment)*chrom_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;

			%% show annotation locations (linear)
			if (show_annotations) && (length(annotations) > 0)
				hold on;
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chrom(i) == chrom)
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
			if (rotate == 0 && chrom_size(chrom) ~= 0 )
				if (chrom_figReversed(chrom) == 0)
					title(chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
					title([chrom_label{chrom} char(10) '(reversed)'],'Interpreter','tex','FontSize',round(linear_chrom_font_size/2),'Rotation',rotate);
				end;
			else
				if (chrom_figReversed(chrom) == 0)
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,[chrom_label{chrom} char(10) '(reversed)'],'Interpreter','tex','FontSize',round(linear_chrom_font_size/2),'Rotation',rotate);
				end;
			end;
		end;
		first_chrom = false;
	end;
end;


%%================================================================================================
% Save figures.
%-------------------------------------------------------------------------------------------------
if (Standard_display)
	% Save primary genome figure.
	set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(Standard_fig, [projectDir 'fig.CNV-map.1.' figVer 'eps'], 'epsc');
	saveas(Standard_fig, [projectDir 'fig.CNV-map.1.' figVer 'png'], 'png');
	delete(Standard_fig);

	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.CNV-map.1.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.CNV-map.1.' figVer 'png']);
end;

if (Linear_display)
	% Save horizontal aligned genome figure.
	set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig,   [projectDir 'fig.CNV-map.2.' figVer 'eps'], 'epsc');
	saveas(Linear_fig,   [projectDir 'fig.CNV-map.2.' figVer 'png'], 'png');
	delete(Linear_fig);

	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.CNV-map.2.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.CNV-map.2.' figVer 'png']);
end;

% Output chromosome copy number estimates.
textFileName = [projectDir 'txt.CNV-map.3.txt'];
fprintf(['Text output of CNVs : "' textFileName '"\n']);
textFileID = fopen(textFileName,'w');
fprintf(textFileID,stringchromCNVs);
fclose(textFileID);

%% change permissions of figures.
system(['chmod 774 ' projectDir 'txt.CNV-map.3.txt']);

end
