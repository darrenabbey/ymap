function [chr_breaks, chrCopyNum] = CNV_LOH_check(main_dir,user,genomeUser,project,parent_or_hapmap,genome,ploidyEstimateString,ploidyBaseString, SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

workingDir = [main_dir '/users/' user '/projects/' project '/'];
fprintf('\n\n### *===============================================================*\n');
fprintf(    '### | Generate SNP/LOH only plot in script "LOH_hapmap_v4.m".       |\n');
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
	%%figure_options = readtable([main_dir '/users/' user '/projects/' project '/figure_options.txt']);
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
%    Chr_max_width              : max width of chrs as fraction of figure width.
fprintf('\n### Setup for processing.\n');
Centromere_format_default      = 2;
Chr_max_width                  = 0.8;
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
[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[segmental_aneuploidy]                                                = Load_dataset_information(projectDir);
num_chrs = length(chr_sizes);
for chr = 1:num_chrs
	chr_size(chr)                   = 0;
	cen_start(chr)                  = 0;
	cen_end(chr)                    = 0;
end;
for chr = 1:num_chrs
	chr_size(chr_sizes(chr).chr)    = chr_sizes(chr).size;
	cen_start(centromeres(chr).chr) = centromeres(chr).start;
	cen_end(centromeres(chr).chr)   = centromeres(chr).end;
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
		fprintf(['\t[' num2str(annotations(i).chr) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
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


%% This block is normally calculated in FindChrSizes during CNV analysis.
for usedChr = 1:num_chrs
	if (chr_in_use(usedChr) == 1)
		% determine where the endpoints of ploidy segments are.
		chr_breaks{usedChr}(1) = 0.0;
		break_count = 1;
		if (length(segmental_aneuploidy) > 0)	% Percentages across chromosome where CNV/ChARM breakpoint exists.
			for i = 1:length(segmental_aneuploidy)
				if (segmental_aneuploidy(i).chr == usedChr)
					break_count = break_count+1;
					chr_broken = true;
					chr_breaks{usedChr}(break_count) = segmental_aneuploidy(i).break;
				end;
			end;
		end;
		chr_breaks{usedChr}(length(chr_breaks{usedChr})+1) = 1;
	end;
end;

%% Load CNV and SNP figure resolutions.
if (exist([genomeDir 'resolution.CNV.txt'],'file') == 0)
	bases_per_bin		= max(chr_size)/700;
else
	bases_per_bin		= max(chr_size)/str2num(fileread([genomeDir 'resolution.CNV.txt']));
end;
if (exist([genomeDir 'resolution.SNPs.txt'],'file') == 0)
	bases_per_bin_SNP	= max(chr_size)/700;
else
	bases_per_bin_SNP	= max(chr_size)/str2num(fileread([genomeDir 'resolution.SNPs.txt']));
end;


%% =========================================================================================
%% =========================================================================================
%% =========================================================================================
%% -----------------------------------------------------------------------------------------
%% =========================================================================================
%% =========================================================================================
%% =========================================================================================

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
phased_and_unphased_color_definitions;


%%================================================================================================
% Setup for SNP/LOH data calculations.
%-------------------------------------------------------------------------------------------------
fprintf('\n### Initialize data vectors for tracking data presentation.\n');
% Initializes vectors used to hold allelic ratios for each chromosome segment.
for chr = 1:num_chrs
	% Build data structure for SNP information:  chr_SNPdata{chr,j}{chr_bin_SNP} = [];
	%       1 : phased SNP ratio data.
	%       2 : unphased SNP ratio data.
	%       3 : phased SNP position data.
	%       4 : unphased SNP position data.
	%       5 : phased SNP allele strings.   (baseCall:alleleA/alleleB)
	%       6 : unphased SNP allele strings.
	chr_length = ceil(chr_size(chr)/bases_per_bin_SNP);
	for j = 1:6
		chr_SNPdata{chr,j} = cell(1,chr_length);
	end;
	% Setup to track RGB values used to present SNP/LOH data for each chromosome bin.
	for j = 1:3
		% Track the RGB value sum per standard bin, then divide by the count to reach the average color per standard genome bin.
		chr_SNPdata_colorsC{chr,j}           = zeros(chr_length,1);
		chr_SNPdata_colorsP{chr,j}           = zeros(chr_length,1);
	end;
	% Track the number of SNP colors per standard bin.
	chr_SNPdata_countC{chr} = zeros(chr_length,1);
	chr_SNPdata_countP{chr} = zeros(chr_length,1);
end;


%%================================================================================================
% Load CNV estimates per standard bin..
%-------------------------------------------------------------------------------------------------
fprintf('\n### Loading "Common_CNV" data file, to be used in copy number estimation.\n');
load([projectDir 'Common_CNV.mat']);   % 'CNVplot2', 'genome_CNV'
[chr_breaks, chrCopyNum, ploidyAdjust, chrCopyRsquared] = FindChrSizes_4(workingDir, segmental_aneuploidy,CNVplot2,ploidy,num_chrs,chr_in_use, false);
CNVfit_Rsquared = chrCopyRsquared;

fprintf('\n\n### Check for inconsistent CNV segment breakpoints using CNV and SNP-ratio data.\n');
%% Keep iterating to look for bad segments until there have been no changes.
chrCopyNum_changed = true;
chrFitValues       = chrCopyNum; % use to hold best fit R^2 values for later processing.
countIters         = 0;
while (chrCopyNum_changed == true)
	countIters += 1;
	chrCopyNum_changed = false;

	if (countIters == 1)
		%%================================================================================================
		% Load CNV estimates per standard bin..
		%-------------------------------------------------------------------------------------------------
		fprintf('\n### Loading "Common_CNV" data file, to be used in copy number estimation.\n');
		load([projectDir 'Common_CNV.mat']);   % 'CNVplot2', 'genome_CNV'
		[chr_breaks, chrCopyNum, ploidyAdjust, chrCopyRsquared] = FindChrSizes_4(workingDir, segmental_aneuploidy,CNVplot2,ploidy,num_chrs,chr_in_use, false);
		CNVfit_Rsquared = chrCopyRsquared;
	endif;

	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			%% Clean up chr_breaks vectors by filtering out non-unique values.
			%chr_breaks_     = chr_breaks{chr}
			%chr_breaks{chr} = unique(chr_breaks{chr});

			fprintf(['\t chr_breaks{' num2str(chr) '} = ']);
			for i = 1:length(chr_breaks{chr})
				fprintf(['chr_breaks{' num2str(chr) '}(' num2str(i) ') = ' num2str(chr_breaks{chr}(i)) '\n']);
			end;
			fprintf('\n');
		end;
	end;
	fprintf(['\n']);

	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			fprintf(['\t chrCopyNum{' num2str(chr) '} = ']);
			for i = 1:length(chrCopyNum{chr})
				fprintf(['chrCopyNum{' num2str(chr) '}(' num2str(i) ') = ' num2str(chrCopyNum{chr}(i)) '\n']);
			end;
			fprintf('\n');
		end;
	end;


	%%================================================================================================
	% Load SNP/LOH data.
	%.................................................................................................
	fprintf(['\n### Load SNP/LOH data.\n']);
	if (exist([projectDir 'SNP_' SNP_verString '.mat'],'file') == 0)
		fprintf(['\t|\t\tMAT file "SNP_' SNP_verString '.mat" not found, regenerating.']);
		datafile       = [projectDir 'preprocessed_SNPs.txt'];
		data           = fopen(datafile, 'r');
		count          = 0;
		old_chr        = 0;
		gap_string     = '';
		while not (feof(data))
			dataLine = fgetl(data);
			if (length(dataLine) > 0)
				if (dataLine(1) ~= '#')
					% process the loaded line into data channels.
					lineVariables               = textscan(dataLine, '%f %f %f %s %s %s %s %s %s');
					chr_num                     = lineVariables{1};
					fragment_start              = lineVariables{2};
					fragment_end                = lineVariables{3};
					phased_ratio_data_string    = lineVariables{4}{1};
					unphased_ratio_data_string  = lineVariables{5}{1};
					phased_coordinates_string   = lineVariables{6}{1};
					unphased_coordinates_string = lineVariables{7}{1};
					phased_alleles_string       = lineVariables{8}{1};
					unphased_alleles_string     = lineVariables{9}{1};

					if (chr_in_use(chr_num) == 1)
						% format = simple, one number per column.
						chr_length                  = ceil(chr_size(chr_num)/bases_per_bin_SNP);
						chr_bin_SNP                 = ceil(fragment_start/bases_per_bin_SNP);

						% Log file output to indicate progression of this section of code.
						count = count+1;
						if (old_chr ~= chr_num)
							fprintf(['\n\t|\t\t' chr_name{chr_num} '\n\t|\t' gap_string]);
						end;
						if (mod(count,10) == 0)
							fprintf('.');
							gap_string = [gap_string ' '];
						end;
						if (count == 800)
							fprintf('\n\t|\t\t');
							count = 0;
							gap_string = '';
						end;
						old_chr = chr_num;

						% format = '(number1,number2,...,numberN)'
						phased_ratio_data_string(1)              = [];
						phased_ratio_data_string(end)            = [];
						if (length(phased_ratio_data_string)    == 0)
							phased_ratio_data                = [];
						else
							commaCount                       = length(find(phased_ratio_data_string==','));
							if (commaCount == 0)
								phased_ratio_data        = str2num(phased_ratio_data_string);
							else
								phased_ratio_data        = strsplit(phased_ratio_data_string,',');   % function converts number lists from strings to numbers.
							end;
						end;

						% format = '(number1,number2,...,numberN)'
						phased_coordinates_string(1)             = [];
						phased_coordinates_string(end)           = [];
						if (length(phased_coordinates_string)   == 0)
							phased_coordinates               = [];
						else
							commaCount                       = length(find(phased_coordinates_string==','));
							if (commaCount == 0)
								phased_coordinates       = str2num(phased_coordinates_string);
							else
								phased_coordinates       = strsplit(phased_coordinates_string,',');   % function converts number lists from strings to numbers.
							end;
						end;

						% format = '(number1,number2,...,numberN)'
						unphased_ratio_data_string(1)            = [];
						unphased_ratio_data_string(end)          = [];
						if (length(unphased_ratio_data_string)  == 0)
							unphased_ratio_data              = [];
						else
							commaCount                       = length(find(unphased_ratio_data_string==','));
							if (commaCount == 0)
								unphased_ratio_data      = str2num(unphased_ratio_data_string);
							else
								unphased_ratio_data      = strsplit(unphased_ratio_data_string,',');  % function converts number lists from strings to numbers.
							end;
						end;

						% format = '(number1,number2,...,numberN)'
						unphased_coordinates_string(1)           = [];
						unphased_coordinates_string(end)         = [];
						if (length(unphased_coordinates_string) == 0)
							unphased_coordinates             = [];
						else
							commaCount                       = length(find(unphased_coordinates_string==','));
							if (commaCount == 0)
								unphased_coordinates     = str2num(unphased_coordinates_string);
							else
								unphased_coordinates     = strsplit(unphased_coordinates_string,',');   % function converts number lists from strings to numbers.
							end;
						end;

						% format = '(A:A/T,C:G/C,...,T:A/T)'
						phased_alleles_string(1)                 = [];
						phased_alleles_string(end)               = [];
						if (length(phased_alleles_string)       == 0)
							phased_alleles                   = [];
						else
							commaCount                       = length(find(phased_alleles_string==','));
							if (commaCount == 0)
								phased_alleles           = phased_alleles_string;
							else
								phased_alleles           = strsplit(phased_alleles_string,',');   % function converts number lists from strings to numbers.
							end;
						end;

						% format = '(A:A/T,C:G/C,...,T:A/T)'
						unphased_alleles_string(1)               = [];
						unphased_alleles_string(end)             = [];
						if (length(unphased_alleles_string)     == 0)
							unphased_alleles                 = [];
						else
							commaCount                       = length(find(unphased_alleles_string==','));
							if (commaCount == 0)
								unphased_alleles         = unphased_alleles_string;
							else
								unphased_alleles         = strsplit(unphased_alleles_string,',');   % function converts number lists from strings to numbers.
							end;
						end;

						% add phased and unphased data to storage arrays.
						chr_SNPdata{chr_num,1}{chr_bin_SNP}          = phased_ratio_data;
						chr_SNPdata{chr_num,2}{chr_bin_SNP}          = unphased_ratio_data;

						% add phased and unphased data coordinates to storage arrays.
						chr_SNPdata{chr_num,3}{chr_bin_SNP}          = phased_coordinates;
						chr_SNPdata{chr_num,4}{chr_bin_SNP}          = unphased_coordinates;

						% add phased and unphased data allele strings to storage arrays.
						chr_SNPdata{chr_num,5}{chr_bin_SNP}          = phased_alleles;
						chr_SNPdata{chr_num,6}{chr_bin_SNP}          = unphased_alleles;
					end;
				end;
			end;
		endwhile;
		fclose(data);

		save([projectDir 'SNP_' SNP_verString '.mat'],'chr_SNPdata');

		%% change permissions of file.
		system(['chmod 774 ' projectDir 'SNP_' SNP_verString '.mat']);
	else
		fprintf('\t|\t\tMAT file found, loading.\n');
		load([projectDir 'SNP_' SNP_verString '.mat']);
	end;

	%%================================================================================================
	fprintf('\n\n### Calculate allelic ratio cutoffs using Gaussian fitting.\n');
	temp_holding    = chr_SNPdata;
	makeFitFigures  = false;
	calculate_allelic_ratio_cutoffs;
	chr_SNPdata     = temp_holding;
	SNPfit_Rsquared = chrSegment_Rsquared;


	%%================================================================================================
	%% Make figure of R^2 values for CNV vs SNP ratio fittings.
	%%------------------------------------------------------------------------------------------------
	fprintf('### Draw initial R^2 comparison figure.\n');

	%%% Collapse Rsquared structures into vectors for logging output.
	%%%	CNVfit_Rsquared
	%%%	SNPfit_Rsquared
	CNVfit_Rsquared_vector = [];
	SNPfit_Rsquared_vector = [];
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			for segment = 1:(length(chrCopyNum{chr}))
				CNVfit_Rsquared_vector = [CNVfit_Rsquared_vector; CNVfit_Rsquared{chr}(segment)];
				SNPfit_Rsquared_vector = [SNPfit_Rsquared_vector; SNPfit_Rsquared{chr}(segment)];
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


	%%================================================================================================
	%% Check for better CNV/SNP-ratio fittings with different copy number estimates for bad initial fittings.
	%%------------------------------------------------------------------------------------------------
	%%	CNVplot / CNVplot2 contains the full CNV data across chromosome regions, at the resolution limit for YMAP.
	%%	chr_breaks{chr}(segment) contains CNV start and end coordinates for each chromosome segment.
	%%	chrCopyNum{chr}(segment) contains CNV estimates for each chromosome segment.
	chr_breaks_new     = chr_breaks;
	chrCopyNum_new     = chrCopyNum;
	fprintf(['\n### Looking at chr segment Rsquared values to assess quality of CNV estimates.\n']);
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			for segment = 1:(length(chrCopyNum{chr}))
				%%%
				%%% Calculate initial Rsquared distance from ideal (1,1).
				%%%
				CNVfit_testRsquared = CNVfit_Rsquared{chr}(segment);
				SNPfit_testRsquared = cell2mat(SNPfit_Rsquared{chr}(segment));
				Rsquared_distance   = sqrt((1-CNVfit_testRsquared)^2 + (1-SNPfit_testRsquared)^2);

				if (Rsquared_distance > 0.5)
					fprintf(['\nchr ' num2str(chr) '.' num2str(segment) ' initial CNV/SNP fit failure.\n']);
					%%%
					%%% If initial Rsquared_distance from ideal (1,1) is bad, lets figure out what the CNV estimate should be for this segment.
					%%%
					Rsquared_CNVtest_vector = [];
					Rsquared_SNPtest_vector = [];
					for copyNum = 1:9
						fprintf(['    copyNum    = ' num2str(copyNum) '\n']);
						fprintf(['\tworkingDir = ' num2str(workingDir) '\n']);
						fprintf(['\tchr_breaks = ']); 
						temp = chr_breaks
						fprintf(['\n']);
						fprintf(['\tploidy     = ' num2str(ploidy) '\n']);
						fprintf(['\tchr        = ' num2str(chr) '\n']);
						fprintf(['\tsegment    = ' num2str(segment) '\n']);
						Rsquared_CNV            = testPloidyEstimate_CNV(workingDir, CNVplot2, chr_breaks, ploidy, chr, segment, copyNum, makeFitFigures);
						Rsquared_CNVtest_vector = [Rsquared_CNVtest_vector Rsquared_CNV];

						testPloidyEstimate_SNP;
						Rsquared_SNP            = Rsquared;
						if isnan(Rsquared_SNP)
							Rsquared_SNP = -1;
						endif;
						Rsquared_SNPtest_vector = [Rsquared_SNPtest_vector Rsquared_SNP];
					endfor;

					%% Logging output of CNV test values.
					fprintf('\tmax(Rsquared_CNVtest_vector) = ');
					for i = 1:length(Rsquared_CNVtest_vector)
						if (max(Rsquared_CNVtest_vector) == Rsquared_CNVtest_vector(i))
							fprintf('[');
						endif;
						fprintf([num2str(Rsquared_CNVtest_vector(i))]);
						if (max(Rsquared_CNVtest_vector) == Rsquared_CNVtest_vector(i))
							fprintf(']');
						endif;
						fprintf(' ');
					endfor;
					fprintf('\n');

					%% Logging output of SNP test values..
					fprintf('\tmax(Rsquared_SNPtest_vector) = ');
					for i = 1:length(Rsquared_SNPtest_vector)
						if (max(Rsquared_SNPtest_vector) == Rsquared_SNPtest_vector(i))
							fprintf('[');
						endif;
						fprintf([num2str(Rsquared_SNPtest_vector(i))]);
						if (max(Rsquared_SNPtest_vector) == Rsquared_SNPtest_vector(i))
							fprintf(']');
						endif;
						fprintf(' ');
					endfor;
					fprintf('\n');

					Rsquared_distance_vector = sqrt((1-Rsquared_CNVtest_vector).^2 + (1-Rsquared_SNPtest_vector).^2);

					%% Logging output of combined CNV/SNP test values..
					fprintf('\tmin(Rsquared_distance_vector) = ');
					for i = 1:length(Rsquared_distance_vector)
						if (min(Rsquared_distance_vector) == Rsquared_distance_vector(i))
							fprintf('[');
						endif;
						fprintf([num2str(Rsquared_distance_vector(i))]);
						if (min(Rsquared_distance_vector) == Rsquared_distance_vector(i))
							fprintf(']');
						endif;
						fprintf(' ');
					endfor;
					fprintf('\n')

					%%% Find best fit CNV estimate by looking at (the more reliable?) SNP ratios.
					Rsquared_CNVtest_vector_min  = min(Rsquared_CNVtest_vector);
					Rsquared_SNPtest_vector_min  = min(Rsquared_SNPtest_vector);
					Rsquared_distance_vector_min = min(Rsquared_distance_vector);

					for i = length(Rsquared_SNPtest_vector):1
							% Find best fit.
						if (Rsquared_SNPtest_vector_min == Rsquared_SNPtest_vector(i))
							chrFitValues{chr}(segment)   = Rsquared_distance_vector_min;
							chrCopyNum_new{chr}(segment) = i;
						endif;
					endfor;
				else
					fprintf(['\nchr ' num2str(chr) '.' num2str(segment) ' initial CNV/SNP fit success.\n']);
					chrFitValues{chr}(segment)   = Rsquared_distance;
					fprintf(['\tRsquared_distance = ' num2str(Rsquared_distance) '\n']);
					chrCopyNum_new{chr}(segment) = round(chrCopyNum_new{chr}(segment));
				endif;
				fprintf(['\tchr' num2str(chr) '.' num2str(segment) ': ' num2str(chrCopyNum_new{chr}(segment)) '\n']);

				%%% If CNV estimate changed, update boolean.
				if (chrCopyNum_new{chr}(segment) != chrCopyNum{chr}(segment))
					chrCopyNum_changed = true;
				end;
			end;
		end;
	end;
	chrCopyNum = chrCopyNum_new;

	%%% Re-review to deal with poor best-fits (likely due to limited data on a segment).
	fprintf(['\n### Dealing with bad best-fit segments.\n']);
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			for segment = (length(chrCopyNum{chr})):1
				%%%
				%%% Calculate initial Rsquared distance from ideal (1,1).
				%%%
				CNVfit_testRsquared = CNVfit_Rsquared{chr}(segment);
				SNPfit_testRsquared = cell2mat(SNPfit_Rsquared{chr}(segment));
				Rsquared_distance   = sqrt((1-CNVfit_testRsquared)^2 + (1-SNPfit_testRsquared)^2);

				if (Rsquared_distance > 0.5)
					if (chrFitValues{chr}(segment) > 1)
						% Bad fit, need to fix by using best neighboring fit.
						if (segment == 1)
							prevFitVal  = chrFitValues{chr}(segment);
							prevCopyNum = chrCopyNum{chr}(segment);
						else
							prevFitVal  = chrFitValues{chr}(segment-1);
							prevCopyNum = chrCopyNum{chr}(segment-1);
						endif;
						if (segment == length(chrCopyNum{chr}))
							nextFitVal  = chrFitValues{chr}(segment);
							nextCopyNum = chrCopyNum{chr}(segment);
						else
							nextFitVal  = chrFitValues{chr}(segment+1);
							nextCopyNum = chrCopyNum{chr}(segment+1);
						endif;
						if (prevFitVal < nextFitVal)
							chrFitValues{chr}(segment)   = prevFitVal;
							chrCopyNum_new{chr}(segment) = prevCopyNum;
						else
							chrFitValues{chr}(segment)   = nextFitVal;
							chrCopyNum_new{chr}(segment) = nextCopyNum;
						endif;
					endif;
				endif;
			endfor;
			chrCopyNum_new2{chr} = chrCopyNum_new{chr};

			%% Repeat in reverse order to ensure best fits are used for all segments.
			for segment = 1:(length(chrCopyNum{chr}))
				%%%
				%%% Calculate initial Rsquared distance from ideal (1,1).
				%%%
				CNVfit_testRsquared = CNVfit_Rsquared{chr}(segment);
				SNPfit_testRsquared = cell2mat(SNPfit_Rsquared{chr}(segment));
				Rsquared_distance   = sqrt((1-CNVfit_testRsquared)^2 + (1-SNPfit_testRsquared)^2);

				if (Rsquared_distance > 0.5)
					if (chrFitValues{chr}(segment) > 1)
						% Bad fit, need to fix by using best neighboring fit.
						if (segment == 1)
							prevFitVal  = chrFitValues{chr}(segment);
							prevCopyNum = chrCopyNum_new{chr}(segment);
						else
							prevFitVal  = chrFitValues{chr}(segment-1);
							prevCopyNum = chrCopyNum_new{chr}(segment-1);
						end;
						if (segment == length(chrCopyNum{chr}))
							nextFitVal  = chrFitValues{chr}(segment);
							nextCopyNum = chrCopyNum_new{chr}(segment);
						else
							nextFitVal  = chrFitValues{chr}(segment+1);
							nextCopyNum = chrCopyNum_new{chr}(segment+1);
						end;
						if (prevFitVal < nextFitVal)
							chrFitValues{chr}(segment) = prevFitVal;
							chrCopyNum{chr}(segment)   = prevCopyNum;
						else
							chrFitValues{chr}(segment) = nextFitVal;
							chrCopyNum_new2{chr}(segment)   = nextCopyNum;
						end;
						chrCopyNum_changed = true;
					end;
				end;
				fprintf(['\tchr' num2str(chr) '.' num2str(segment) ': ' num2str(chrCopyNum{chr}(segment)) ' => ' num2str(chrCopyNum_new2{chr}(segment)) '\n']);

				%%% If CNV estimate changed, update boolean.
				if (chrCopyNum_new2{chr}(segment) != chrCopyNum{chr}(segment))
					chrCopyNum_changed = true;
				end;
			end;
		end;
	end;
	chrCopyNum = chrCopyNum_new2;

	%%% Merge any adjacent segments that now have the same best estimate of copy number.
	fprintf(['\n### Merging adjacent segments.\n']);
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			if (length(chrCopyNum{chr}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.
				% Add break representing left end of chromosome.
				breakCount_new         = 1;
				chr_breaks_new{chr}    = [];
				chrCopyNum_new{chr}    = [];
				chr_breaks_new{chr}(1) = 0.0;

				chrCopyNum_new{chr}(1) = chrCopyNum{chr}(1);
				for segment = 1:(length(chrCopyNum{chr})-1)
					if (round(chrCopyNum{chr}(segment)) == round(chrCopyNum{chr}(segment+1)))
						% two adjacent segments have identical copyNum and should be fused into one; don't add boundry to new list.
					else
						% two adjacent segments have different copyNum; add boundry to new list.
						breakCount_new                      = breakCount_new + 1;
						chr_breaks_new{chr}(breakCount_new) = chr_breaks{chr}(segment+1);
						chrCopyNum_new{chr}(breakCount_new) = chrCopyNum{chr}(segment+1);
					end;
				end;

				% add break representing right end of chromosome.
				breakCount_new = breakCount_new+1;
				chr_breaks_new{chr}(breakCount_new) = 1.0;

				% copy new lists to old.
				chr_breaks{chr} = chr_breaks_new{chr};
				chrCopyNum{chr} = [];
				chrCopyNum{chr} = chrCopyNum_new{chr};
			end;
		end;
	end;


	%%================================================================================================
	%% Convert chr segment breakpoints to ChARM output file, replacing original for later use.
	%%------------------------------------------------------------------------------------------------
	dataFile = [projectDir 'Common_ChARM.mat'];
	fprintf(['\n### Updating saved common_ChARM file for "' project '" : ' dataFile '$$$$\n']);
	i = 0;
	segmental_aneuploidy = [];
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			fprintf(['\t chr_breaks{' num2str(chr) '} = ']);
			for i = 1:length(chr_breaks{chr})
				fprintf([num2str(chr_breaks{chr}(i)) ' ']);
			end;
			fprintf('\n');
			for edge = 1:length(chr_breaks{chr})
				if (chr_breaks{chr}(edge) == 0) || (chr_breaks{chr}(edge) == 1)
					% nothing is added to file for start and end coordinates; these edges are later assumed.
				else
					i = i+1;
					segmental_aneuploidy(i).chr     = chr;                   % chromosome being examined.
					segmental_aneuploidy(i).break   = chr_breaks{chr}(edge); % percent along chromosome of edge.
				end;
			end;
		end;
	end;
	save(dataFile, 'segmental_aneuploidy');

	%%================================================================================================
	% Redo CNV_v6_6.m to update calculation of CNV estimates per standard genome bin
	%-------------------------------------------------------------------------------------------------
	CNV_v6_6(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString,CNV_verString,'not-used',displayBREAKS,'not-used',false);

	if (countIters == 10)
		chrCopyNum_changed = false;
	endif;
endwhile;

% Redraw CNV figures after analysis completes.
CNV_v6_6(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString,CNV_verString,'not-used',displayBREAKS,'not-used',true);


fprintf('\n');
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		fprintf(['\t chrCopyNum{' num2str(chr) '} = ']);
		for i = 1:length(chrCopyNum{chr})
			fprintf([num2str(chrCopyNum{chr}(i)) ' ']);
		end;
		fprintf('\n');
	end;
end;

%%==========================================================================
%% end stuff
%%==========================================================================
fprintf('\n### End of CNV_LOH_check.m processing.\n');

end


