function [] = allelic_ratios_WGseq(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

% hide figures during construction.
set(0,'DefaultFigureVisible','off');


%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
workingDir = [main_dir '/users/' user '/projects/' project '/'];
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;


fprintf(['main_dir             = "' main_dir             '"\n']);
fprintf(['user                 = "' user                 '"\n']);
fprintf(['genomeUser           = "' genomeUser           '"\n']);
fprintf(['project              = "' project              '"\n']);
fprintf(['parent               = "' parent               '"\n']);
fprintf(['hapmap               = "' hapmap               '"\n']);
fprintf(['genome               = "' genome               '"\n']);
fprintf(['ploidyEstimateString = "' ploidyEstimateString '"\n']);
fprintf(['ploidyBaseString     = "' ploidyBaseString     '"\n']);

fprintf('\n\n\t*===============================================================*\n');
fprintf(    '\t| Fireplot generation in script "allelic_ratios_WGseq.m".       |\n');
fprintf(    '\t*---------------------------------------------------------------*\n');
tic;
fprintf('\t|\tGenerating FirePlot of SNP allelic ratio data across genome.\n');
%% ========================================================================
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin              : Controls bin sizes for SNP/CNV fractions of plot.
%    chrom_max_width              : max width of chroms as fraction of figure width.
ploidyBase                  = 0.5;
Centromere_format_default   = 3;
chrom_max_width             = 0.8;
colorBars                   = true;
blendColorBars              = false;
show_annotations            = true;
Yscale_nearest_even_ploidy  = true;
Linear_displayBREAKS        = false;

projectDir = [main_dir '/users/' user '/projects/' project '/'];
genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir '/users/' user '/projects/' project '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir '/users/' user '/projects/' project '/figure_options.txt'],'\t',1);

	option         = figure_options{9,1};
	if strcmp(option,'False')
		Make_figure = false;
	else
		Make_figure = true;
	end
else
	Make_figure = true;
end;

if (Make_figure == true)
	fprintf('\t|\tDetermine if hapmap is in use.\n');
	%
	% For right now, ('parent' == 'hapmap') always because of earlier mixed use of variables.
	% Determine if 'hapmap' is in use by checking user and system hapmap directories.
	%
	% Possible error case where 'parent' and 'hapmap' have same name string.
	% Will be resolved with later disambiguation of parent/hapmap variable.
	%
	if (exist([main_dir '/users/default/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir = [main_dir '/users/default/hapmaps/' hapmap '/'];   % system hapmap.
		useHapmap = true;
	elseif (exist([main_dir '/users/' user '/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir = [main_dir '/users/' user '/hapmaps/' hapmap '/'];  % user hapmap.
		useHapmap = true;
	else
		useHapmap = false;
	end;

	fprintf('\t|\tDetermine if parent project is in use.\n');
	%
	% The 'parent' will == the 'project' when no 'parent' is selected in setup.
	%
	if (strcmp(project,parent) == 0)
		useParent = true;
		if (exist([main_dir '/users/default/projects/' parent '/'], 'dir') == 7)
			parentDir = [main_dir '/users/default/projects/' parent '/'];   % system parent.
		else
			parentDir = [main_dir '/users/' user '/projects/' parent '/'];  % user parent.
		end;
	else
		useParent = false;
		parentDir = projectDir;
	end;

	fprintf('\t|\tLoading dataset information.\n');
	[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
	[Aneuploidy]                                                          = Load_dataset_information(projectDir);

	num_chroms = length(chrom_sizes);
	for chromID = 1:length(chrom_sizes)
		chrom_size( chromID) = 0;
		cen_start(chromID) = 0;
		cen_end(  chromID) = 0;
	end;
	for chromID = 1:length(chrom_sizes)
		chrom_size(chrom_sizes(   chromID).chrom) = chrom_sizes(  chromID).size;
		cen_start(centromeres(chromID).chrom) = centromeres(chromID).start;
		cen_end(centromeres(  chromID).chrom) = centromeres(chromID).end;
	end
	if (length(annotations) > 0)
		fprintf(['\nAnnotations for ' genome '.\n']);
		for annoteID = 1:length(annotations)
			annotation_chrom(      annoteID) = annotations(annoteID).chrom;
			annotation_type{     annoteID} = annotations(annoteID).type;
			annotation_start(    annoteID) = annotations(annoteID).start;
			annotation_end(      annoteID) = annotations(annoteID).end;
			annotation_fillcolor{annoteID} = annotations(annoteID).fillcolor;
			annotation_edgecolor{annoteID} = annotations(annoteID).edgecolor;
			annotation_size(     annoteID) = annotations(annoteID).size;
			fprintf(['\t[' num2str(annotations(annoteID).chrom) ':' annotations(annoteID).type ':' num2str(annotations(annoteID).start) ':' ...
			               num2str(annotations(annoteID).end) ':' annotations(annoteID).fillcolor ':' annotations(annoteID).edgecolor ':' num2str(annotations(annoteID).size) ']\n']);
		end;
	end;
	for figureDetailID = 1:length(figure_details)
		if (figure_details(figureDetailID).chrom == 0)
			if (strcmp(figure_details(figureDetailID).label,'Key') == 1)
				key_posX   = figure_details(figureDetailID).posX;
				key_posY   = figure_details(figureDetailID).posY;
				key_width  = figure_details(figureDetailID).width;
				key_height = figure_details(figureDetailID).height;
			end;
		else
			chrom_id         (figure_details(figureDetailID).chrom) = figure_details(figureDetailID).chrom;
			chrom_label      {figure_details(figureDetailID).chrom} = figure_details(figureDetailID).label;
			chrom_name       {figure_details(figureDetailID).chrom} = figure_details(figureDetailID).name;
			chrom_posX       (figure_details(figureDetailID).chrom) = figure_details(figureDetailID).posX;
			chrom_posY       (figure_details(figureDetailID).chrom) = figure_details(figureDetailID).posY;
			chrom_width      (figure_details(figureDetailID).chrom) = figure_details(figureDetailID).width;
			chrom_height     (figure_details(figureDetailID).chrom) = figure_details(figureDetailID).height;
			chrom_in_use     (figure_details(figureDetailID).chrom) = str2num(figure_details(figureDetailID).usechrom);
			chrom_figOrder   (figure_details(figureDetailID).chrom) = str2num(figure_details(figureDetailID).figOrder);
			chrom_figReversed(figure_details(figureDetailID).chrom) = str2num(figure_details(figureDetailID).figReversed);
		end;
	end;

	%% This block is normally calculated in FindChromSizes_2 in CNV analysis.
	for usedchrom = 1:length(chrom_in_use)
		if (chrom_in_use(usedchrom) == 1)
			% determine where the endpoints of ploidy segments are.
			chrom_breaks{usedchrom}(1) = 0.0;
			break_count = 1;
			if (length(Aneuploidy) > 0)
				for i = 1:length(Aneuploidy)
					if (Aneuploidy(i).chrom == usedchrom)
						break_count = break_count+1;
						chrom_broken = true;
						chrom_breaks{usedchrom}(break_count) = Aneuploidy(i).break;
					end;
				end;
			end;
			chrom_breaks{usedchrom}(length(chrom_breaks{usedchrom})+1) = 1;
		end;
	end;


	%%================================================================================================
	% Load FASTA file name from 'reference.txt' file for project.
	%-------------------------------------------------------------------------------------------------
	fprintf('\t|\tLoad FASTA file name for project.\n');
	userReference    = [main_dir '/users/' user '/genomes/' genome '/reference.txt'];
	defaultReference = [main_dir '/users/default/genomes/' genome '/reference.txt'];
	if (exist(userReference,'file') == 0)
		FASTA_string = strtrim(fileread(defaultReference));
	else
		FASTA_string = strtrim(fileread(userReference));
	end;
	[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


	%%================================================================================================
	% Preallocate data vectors the length of each chromosome.
	%-------------------------------------------------------------------------------------------------
	fprintf('\t|\tPreallocating data vectors the length of each chromosome.\n');
	chrom_SNP_data_positions = cell(length(chrom_size),1);
	chrom_SNP_data_ratios    = cell(length(chrom_size),1);
	chrom_count              = cell(length(chrom_size),1);
	for chromID = 1:length(chrom_size)
		if (chrom_in_use(chromID) == 1)
			chrom_SNP_data_positions{chromID} = zeros(chrom_size(chromID),1);
			chrom_SNP_data_ratios{   chromID} = zeros(chrom_size(chromID),1);
			chrom_count{             chromID} = zeros(chrom_size(chromID),1);
			chrom_lines_analyzed(    chromID) = 0;
		end;
	end;


	%%================================================================================================
	% Process project 1 dataset.
	%-------------------------------------------------------------------------------------------------
	if (useHapmap)
		% Load only putative SNP data corresponding to hapmap loci.
		fprintf('\t|\tLoad SNP information from "trimmed_SNPs_v5.txt" file for project.\n');
		fprintf('\t|\t\t');
		datafile   = [projectDir '/SNPdata_child.txt'];
	else
		% Load all putative SNP data.
		fprintf('\t|\tLoad SNP information from "putative_SNPs_v4.txt" file for project.\n');
		fprintf('\t|\t\t');
		datafile   = [projectDir '/putative_SNPs_v4.txt'];
	end;
	data       = fopen(datafile,'r');
	count      = 0;
	old_chrom  = 0;
	gap_string = '';
	% Reading the line before checking for end of file to avoid reading empty file.
	dataLine = fgetl(data);

	% Loop while dataLine contains active string characters.
	while ischar(dataLine)
		% Strip leading whitespace and skip empty lines or lines starting with #.
		cleanLine = strtrim(dataLine);
                if (length(cleanLine) > 0 && cleanLine(1) ~= '#')
			% Process the loaded line into data channels.
			lineVariables = textscan(cleanLine, '%s %d %s %d %d %d %d');
			SNP_chrom_name = lineVariables{1}{1};
			SNP_coordinate = lineVariables{2};
			SNP_reference  = lineVariables{3}{1};
			SNP_countA     = lineVariables{4};
			SNP_countT     = lineVariables{5};
			SNP_countG     = lineVariables{6};
			SNP_countC     = lineVariables{7};

			% Convert Octave logical mask array into a single integer scalar index.
			chrom_num = find(strcmp(SNP_chrom_name, chrom_name));

			% Run only if an actual matching chromosome index was resolved.
			if (~isempty(chrom_num) && chrom_num > 0)
				count = count+1;
				if (~isequal(old_chrom,chrom_num))
					fprintf(['\n\t|\t' SNP_chrom_name '\n\t|\t' gap_string]);
				end;
				if (mod(count,300) == 0)
					fprintf('.');
					gap_string = [gap_string ' '];
				end;
				if (count == 24000)
					fprintf('\n\t|\t');
					count = 0;
					gap_string = '';
				end;
				count_vector     = [SNP_countA SNP_countT SNP_countG SNP_countC];
				count_sum        = sum(count_vector);
				if (count_sum > 1)
					% Increment tracking scalar index.
					chrom_lines_analyzed(chrom_num) = chrom_lines_analyzed(chrom_num)+1;
					current_idx = chrom_lines_analyzed(chrom_num);

					% Expand cell vectors if file rows outgrow preallocated chromosome bounds.
					current_allocated_length = length(chrom_SNP_data_positions{chrom_num});
					if (current_idx > current_allocated_length)
						% Pad 5,000 extra rows vertically to minimize memory reallocation overhead
						expansion_padding = current_idx + 5000;
						chrom_SNP_data_positions{chrom_num}(end+1:expansion_padding, 1) = 0;
						chrom_SNP_data_ratios{chrom_num}(end+1:expansion_padding, 1)    = 0;
						chrom_count{chrom_num}(end+1:expansion_padding, 1)              = 0;
					end;

					% Assign values to clear, distinct scalar array cell bounds.
					chrom_SNP_data_positions{chrom_num}(current_idx) = SNP_coordinate;
					chrom_SNP_data_ratios{chrom_num}(current_idx)    = max(count_vector) / count_sum;
					chrom_count{chrom_num}(current_idx)              = count_sum;
				end;
				old_chrom        = chrom_num;
			end;
		end;
		% read next line
		dataLine = fgetl(data);
	endwhile;
	fclose(data);

	%%================================================================================================
	% Clean up data vectors.
	%-------------------------------------------------------------------------------------------------
	fprintf('\n\t|\tClean up data vectors.\n');
	for chromID = 1:length(chrom_in_use)
		if (chrom_in_use(chromID) == 0)
			% Clear unused chromosomes using a flat syntax pattern.
			chrom_SNP_data_positions{chromID} = [];
			chrom_SNP_data_ratios{chromID}    = [];
			chrom_count{chromID}              = [];
		else
			% Truncate preallocated arrays to exact count of parsed lines.
			valid_count = chrom_lines_analyzed(chromID);
			if (valid_count > 0)
				% Use (:) to guarantee vectors stay in an explicit vertical layout (N x 1).
				chrom_SNP_data_positions{chromID} = chrom_SNP_data_positions{chromID}(1:valid_count, 1);
				chrom_SNP_data_ratios{chromID}    = chrom_SNP_data_ratios{chromID}(1:valid_count, 1);
				chrom_count{chromID}              = chrom_count{chromID}(1:valid_count, 1);

				% Force the logical filter mask into a strict column layout.
				keep_mask = (chrom_count{chromID}(:) > 20);

				% Apply the unified column filter safely across all channels.
				chrom_SNP_data_positions{chromID} = chrom_SNP_data_positions{chromID}(keep_mask, 1);
				chrom_SNP_data_ratios{chromID}    = chrom_SNP_data_ratios{chromID}(keep_mask, 1);
				chrom_count{chromID}              = chrom_count{chromID}(keep_mask, 1);
			else
				% Handle edge cases where zero data lines were found for an active chromosome
				chrom_SNP_data_positions{chromID} = [];
				chrom_SNP_data_ratios{chromID}    = [];
				chrom_count{chromID}              = [];
			end;
		end;
	end;


	%%================================================================================================
	% Save processed SNP/LOH data file.
	%-------------------------------------------------------------------------------------------------
	%    chrom_SNP_data_ratios    : allelic ratios of SNP data.
	%    chrom_SNP_data_positions : coordinates of SNP data.
	%    chrom_count              : number of chromosomes in dataset.
	%
	fprintf('\t|\tSave processed SNP/LOH data to file "SNP_v4.all1.mat" for project.\n');
	save([projectDir 'SNP_' SNP_verString '.all1.mat'],'chrom_SNP_data_ratios','chrom_SNP_data_positions','chrom_count');
	%% change permissions of file.
	system(['chmod 774 ' projectDir 'SNP_' SNP_verString '.all1.mat']);


	%%================================================================================================
	% Setup basic figure parameters.
	%-------------------------------------------------------------------------------------------------
	fprintf('\t|\tDefine basic figure parameters, not specific to genome.\n');
	% basic plot parameters not defined per genome.
	TickSize         = 0; % -0.005;  %negative for outside, percentage of longest chrom figure.
	maxYbins         = 50;   % number of Y-bins in 2D smoothed histogram.
	maxY             = ploidyBase*2;
	cen_tel_Xindent  = 5;
	cen_tel_Yindent  = maxY/4;
	largestchrom       = find(chrom_width == max(chrom_width));
	largestchrom       = largestchrom(1);

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
	% Setup for linear-view figure generation.
	%-------------------------------------------------------------------------------------------------
	% load size definitions
	[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
		,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
		stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
		gca_stacked_font_size,stacked_copy_font_size,max_chromom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);
	fprintf('\t|\tInitialize linear figure.\n');
	Linear_fig              = figure(2);
	Linear_genome_size      = sum(chrom_size);
	Linear_TickSize         = -0.01;  % negative for outside, percentage of longest chrom figure.
	maxYbins                = 50;     % number of Y-bins in 2D smoothed histogram.
	maxY                    = ploidyBase*2;
	Linear_left             = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
	axisLabelPosition_vert  = 0.01125;


	%%================================================================================================
	% Make figures
	%-------------------------------------------------------------------------------------------------
	first_chrom = true;

	%% Determine statistics of data density across entire genome.
	fprintf('\t|\tDetermine statistics of data density for chromosomes.\n');
	all_data        = [];
	chrom_mean        = zeros(1,num_chroms);
	chrom_mean_scaler = zeros(1,num_chroms);

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
			chrom_length        = ceil(chrom_size(chrom)/bases_per_bin);
			dataX               = ceil(chrom_SNP_data_positions{chrom}/bases_per_bin)';
			dataY1              = chrom_SNP_data_ratios{chrom};
			dataY2              = (dataY1*maxYbins)';
			dataX_CNVcorrection = ones(1,chrom_length);
			if (length(dataX) > 0)
				% 2D smoothed hisogram with correction term.
				[imageX{chrom},imageY{chrom},imageC{chrom}, imageD{chrom}] = smoothhist2D_4_Xcorrected([dataX dataX 0 chrom_length], [dataY2 (maxYbins-dataY2) 0 0], 0.5,[chrom_length maxYbins],[chrom_length maxYbins], dataX_CNVcorrection, 1,1);
				all_data = [all_data imageD{chrom}];
			end;
			if (length(dataX) > 0)
			    chrom_mean(chrom) = mean(imageD{chrom}(:));
			else
			    chrom_mean(chrom) = 0;
			end;
			fprintf(['\t|\t\tchrom' num2str(chrom) ' smoothhist2D average value = ' num2str(chrom_mean) '\n']);
		end;
	end;
	max_mean = max(chrom_mean);
	for chrom = 1:length(chrom_in_use)
		if ((chrom_in_use(chrom) == 1) && (chrom_mean(chrom) != 0))
			chrom_mean_scaler(chrom) = max_mean/chrom_mean(chrom);
		else
			chrom_mean_scaler(chrom) = 0;
		end;
	end;
	if (isempty(all_data(:)) == true)
		median_val = 0;
		mean_val   = 0;
		mode_val   = 0;
		min_val    = 0;
		max_val    = 0;
	else
		median_val = median(all_data(:));
		mean_val   = mean(all_data(:));
		mode_val   = mode(all_data(:));
		min_val    = min(all_data(:));
		max_val    = max(all_data(:));
	end;


	%% Generate chromosome figures.
	fprintf('\t|\tGenerate final chromosome figures.\n');
	for chrom_to_draw  = 1:length(chrom_order)
		chrom = chrom_order(chrom_to_draw);
		if (chrom_in_use(chrom) == 1)
		%% Linear figure draw section
			figure(Linear_fig);
			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			hold on;
			Linear_left = Linear_left + Linear_width + Linear_chrom_gap;

			% linear : show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS == true) && (show_annotations == true)
				fprintf('\t|\t\t\tShow ChARM breakpoints on linear figure.\n');
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
				for segment = 2:length(chrom_breaks{chrom})-1
					bP = chrom_breaks{chrom}(segment)*chrom_length;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;

			%% linear : show allelic ratio data as 2D-smoothed scatter-plot.
			fprintf('\t|\t\t\tDraw 2D smoothed histogram of allelic ratio data in linear figure.\n');
			chrom_length                   = ceil(chrom_size(chrom)/bases_per_bin);
			dataX                        = ceil(chrom_SNP_data_positions{chrom}/bases_per_bin)';
			dataY1                       = chrom_SNP_data_ratios{chrom};
			dataY2                       = (dataY1*maxYbins)';
			dataX_CNVcorrection          = ones(1,chrom_length);;
			if (length(dataX) > 0)
				% 2D smoothed hisogram with correction term.
				fprintf(['\t|\t\tGenerating chrom' num2str(chrom) ' final smoothed 2D histogram.\n']);
				[imageX{chrom},imageY{chrom},imageC{chrom}, discard] = smoothhist2D_4_Xcorrected([dataX dataX 0 chrom_length], [dataY2 (maxYbins-dataY2) 0 0], 0.5,[chrom_length maxYbins],[chrom_length maxYbins], dataX_CNVcorrection, mean_val, chrom_mean_scaler(chrom));

				fprintf('\t|\t\t\tDe-emphasizing near-homozygous data.\n');
				% Image correction method to de-emphasize the near homozygous data points.
				%    The square factor correction was determined empirically, from the relative amounts of data near homozygous and heterozygous.
				%    Improvements in sequencing technology that reduce sequencing error and reduce near-homozygous data will require adjusting this.
				imageC_correction          = imageC{chrom}*0;
				for y = 1:maxYbins
					imageC_correction(y,:) = 1-abs(y-maxYbins/2)/(maxYbins/2);
				end;
				imageC{chrom} = imageC{chrom}.*(1+imageC_correction.^2*16);

				% reverse order of 2D histogram if chromosome is indicated as reversed in figure_definitions.txt file.
				if (chrom_figReversed(chrom) == 1)
					imageX{chrom}   = fliplr(imageX{chrom});
				end;

				fprintf('\t|\t\t\tDrawing 2D histogram to figure.\n');
				x_axis_spatial_bounds = [1, chrom_length]; 
				y_axis_spatial_bounds = [0, maxY];
				image(x_axis_spatial_bounds, y_axis_spatial_bounds, imageC{chrom});
			end;
			%% linear : end show allelic ratio data.

			%% linear : show centromere.
			Centromere_format = Centromere_format_default;
			fprintf('\t|\t\t\tDraw centromere in linear figure.\n');
			x1 = cen_start(chrom)/bases_per_bin;
			x2 = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0;
			rightEnd = chrom_size(chrom)/bases_per_bin;
			if (Centromere_format == 0)
				source('cartoon_linear_0.m');
			elseif (Centromere_format == 1)
				source('cartoon_linear_1.m');
			elseif (Centromere_format == 2) % sausage!
				source('cartoon_linear_2.m');
			elseif (Centromere_format == 3) % improved sausage! (standard plot)
				source('cartoon_linear_3.m');
			end;
			% linear : end show centromere.

			% linear : show annotation locations.
			if (show_annotations) && (length(annotations) > 0)
				fprintf('\t|\t\t\tShow annotation locations in linear figure.\n');
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
			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'TickLength',[(Linear_TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',[]);
			if (first_chrom == true)
				% This section sets the Y-axis labelling.
				text(axisLabelPosition_horiz, maxY/4*0, '0'  ,'HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*1, '1/4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*2, '1/2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*3, '3/4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*4, '1'  ,'HorizontalAlignment','right','Fontsize',linear_axis_font_size);
			end;
			set(gca,'FontSize',linear_gca_font_size);
			% linear : end final reformatting.

			% Adding title is done in the end since if placed upper.
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
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,[chrom_label{chrom} char(10) '(reversed)'],'Interpreter','tex','FontSize',round(linear_chrom_font_size/2),'Rotation',rotate);
				end;
			end;
			hold off;
		end;
		first_chrom = false;
	end;

	set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	fprintf('\t|\tSaving linear figure in EPS format.\n');
	saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.b2.' figVer 'eps'], 'epsc');
	fprintf('\t|\tSaving linear figure in PNG format.\n');
	saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.b2.' figVer 'png'], 'png');

	%% change permissions of figures.
	system(['chmod 774 ' projectDir 'fig.allelic_ratio-map.b2.' figVer 'eps']);
	system(['chmod 774 ' projectDir 'fig.allelic_ratio-map.b2.' figVer 'png']);
	delete(Linear_fig);
else
	fprintf('\t|\t No figure generated.\n');
end;

time_end = toc;
fprintf('\t|\t%d min, %f sec.\n',floor(time_end/60),rem(time_end,60));
fprintf('\t*---------------------------------------------------------------*\n');
fprintf('\t| Fireplot generation in "allelic_ratios_WGseq.m" completed.    |\n');
fprintf('\t*===============================================================*\n');
end
