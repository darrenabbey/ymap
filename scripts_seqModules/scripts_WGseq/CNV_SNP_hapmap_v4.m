function [] = CNV_SNP_hapmap_v4(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString, SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');
workingDir      = [main_dir 'users/' user '/projects/' project '/'];
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
if exist([main_dir 'users/' user '/projects/' project '/figure_options.txt'], 'file')
	figure_options = readtable([main_dir 'users/' user '/projects/' project '/figure_options.txt']);
	option         = figure_options{9,1};
	if strcmp(option,'False')
		Make_figure_linear = false;
	else
		Make_figure_linear = true;
	end;

	option         = figure_options{10,1};
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
%    bases_per_bin              : Controls bin sizes for SNP/CGH fractions of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CGH data by ploidy.
%    Chr_max_width              : max width of chrs as fraction of figure width.
Centromere_format           = 0;
Chr_max_width               = 0.8;
colorBars                   = true;
blendColorBars              = false;
show_annotations            = true;
Yscale_nearest_even_ploidy  = true;
AnglePlot                   = true;   % Show histogram of alleleic fraction at the left end of standard figure chromosomes.
FillColors                  = true;   %     Fill histogram using colors.
show_uncalibrated           = false;  %     Fill with single color instead of ratio call colors.
HistPlot                    = true;   % Show histogram of CNV at the right end of standard figure chromosomes.
ChrNum                      = true;   % Show numerical etimates of copy number to the right of standard figure chromosomes.
Standard_display            = Make_figure_standard;
Linear_display              = Make_figure_linear;   % Figure version with chromosomes laid out horizontally.
Linear_displayBREAKS        = false;
Low_quality_ploidy_estimate = true    % Estimate error in overall ploidy estimate, assuming most common value is actually euploid.


%% =========================================================================================
% Load FASTA file name from 'reference.txt' file for project.
%-------------------------------------------------------------------------------------------
userReference    = [main_dir 'users/' user '/genomes/' genome '/reference.txt'];
defaultReference = [main_dir 'users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string = strtrim(fileread(defaultReference));
else
	FASTA_string = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%% =========================================================================================
% Control variables.
%-------------------------------------------------------------------------------------------
projectDir = [main_dir 'users/' user '/projects/' project '/'];
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];
if (strcmp(hapmap,'') == 1)
	useHapmap = false;
else
	useHapmap = true;
	if (exist([main_dir 'users/default/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir  = [main_dir 'users/default/hapmaps/' hapmap '/'];   % system hapmap.
		hapmapUser = 'default';
	elseif (exist([main_dir 'users/' user '/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir  = [main_dir 'users/' user '/hapmaps/' hapmap '/'];  % user hapmap.
		hapmapUser = user;
	else
		useHapmap = false;
	end;
	parent = '';
end;
if (useHapmap == false)
	parentFile = [main_dir 'users/' user '/projects/' project '/parent.txt'];
	parent     = strtrim(fileread(parentFile));
	if (strcmp(project,parent) == 1)
		useParent = false;
	else
		useParent = true;
		if (exist([main_dir 'users/default/projects/' parent '/'], 'dir') == 7)
			parentDir  = [main_dir 'users/default/projects/' parent '/'];   % system parent.
			parentUser = 'default';
		else
			parentDir  = [main_dir 'users/' user '/projects/' parent '/'];  % user parent.
			parentUser = user;
		end;
	end;
end;
fprintf(['hapmap  = "' hapmap  '"\n']);
fprintf(['genome  = "' genome  '"\n']);
fprintf(['project = "' project '"\n']);
fprintf(['parent  = "' parent  '"\n']);


[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[Aneuploidy] = Load_dataset_information(projectDir);

num_chrs = length(chr_sizes);
for i = 1:length(chr_sizes)
	chr_size(i)  = 0;
	cen_start(i) = 0;
	cen_end(i)   = 0;
end;
for i = 1:length(chr_sizes)
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
num_chrs = length(chr_size);

%% This block is normally calculated in FindChrSizes_2 in CNV analysis.
for usedChr = 1:num_chrs
	if (chr_in_use(usedChr) == 1)
		% determine where the endpoints of ploidy segments are.
		chr_breaks{usedChr}(1) = 0.0;
		break_count = 1;
		if (length(Aneuploidy) > 0)
			for i = 1:length(Aneuploidy)
				if (Aneuploidy(i).chr == usedChr)
					break_count = break_count+1;
					chr_broken = true;
					chr_breaks{usedChr}(break_count) = Aneuploidy(i).break;
				end;
			end;
		end;
		chr_breaks{usedChr}(length(chr_breaks{usedChr})+1) = 1;
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


%% =========================================================================================
% Define colors for figure generation.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tDefine colors used in figure generation.\n');
phased_and_unphased_color_definitions;


% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chr figure.
bases_per_bin    = max(chr_size)/700;
maxY             = ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/5;


%%================================================================================================
% Setup for SNP/LOH data calculations.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tInitialize color tracking vectors.\n');
% Initializes vectors used to hold allelic ratios for each chromosome segment.
for chr = 1:length(chr_sizes)
	% Build data structure for SNP information:  chr_SNPdata{chr,j}{chr_bin} = [];
	%       1 : phased SNP ratio data.
	%       2 : unphased SNP ratio data.
	%       3 : phased SNP position data.
	%       4 : unphased SNP position data.
	%       5 : phased SNP allele strings.   (baseCall:alleleA/alleleB)
	%       6 : unphased SNP allele strings.
	chr_length = ceil(chr_size(chr)/bases_per_bin);

	% Vectors to track RGB values for displaying SNPs.
	for j = 1:3
		chr_SNPdata_colorsC{chr,j}           = zeros(chr_length,1);
		chr_SNPdata_colorsP{chr,j}           = zeros(chr_length,1);
	end;

	% Track the number of SNP colors per standard bin.
	chr_SNPdata_countC{chr} = zeros(chr_length,1);
	chr_SNPdata_countP{chr} = zeros(chr_length,1);
end;


%% =========================================================================================
% Load GC-bias corrected CGH data.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tLoad CNV data.\n');
load([projectDir 'Common_CNV.mat']);       % 'CNVplot2','genome_CNV'
[chr_breaks, chrCopyNum, ploidyAdjust] = FindChrSizes_4(Aneuploidy,CNVplot2,ploidy,num_chrs,chr_in_use);

fprintf('*** dragon 1\n');
for chr = 1:length(chr_breaks)
	for segment = 1:length(chrCopyNum{chr})
		fprintf(['*** chr_breaks{' num2str(chr) '}(' num2str(segment) ')  = ' num2str(chr_breaks{chr}(segment)) '\n']);
	end;
end;
fprintf(['\n']);
for chr = 1:length(chrCopyNum)
	for segment = 1:length(chrCopyNum{chr})
		fprintf(['*** chrCopyNum{' num2str(chr) '}(' num2str(segment) ')  = ' num2str(chrCopyNum{chr}(segment)) '\n']);
	end;
end;



largestChr = find(chr_width == max(chr_width));
largestChr = largestChr(1);

createCnvTrack(projectDir, project, CNVplot2, bases_per_bin, chr_name, ploidyBase*2, ploidy * ploidyAdjust);

%% =========================================================================================
% Load SNP/LOH data.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tLoad SNP data.\n');
load([projectDir 'SNP_' SNP_verString '.mat']);
%    'chr_SNPdata{chr,i}(chr_bin)'
%        i = 1 : phased ratio data.
%        i = 2 : unphased ratio data.
%        i = 3 : phased coordinate data.
%        i = 4 : unphased coordinate data.
%        i = 5 : phased allele string.
%        i = 6 : unphased allele string.


%% =========================================================================================
% Test adjacent segments for no change in copy number estimate.
%...........................................................................................
% Adjacent pairs of segments with the same copy number will be fused into a single segment.
% Segments with a <= zero copy number will be fused to an adjacetn segment.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tTest adjacent chromosome segments for no change in copy number estimate.\n');
for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		if (length(chrCopyNum{chr}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.
			%% Merge any adjacent segments with the same copy number.
			% add break representing left end of chromosome.
			breakCount_new         = 1;
			chr_breaks_new{chr}    = [];
			chrCopyNum_new{chr}    = [];
			chr_breaks_new{chr}(1) = 0.0;

			%fprintf(['\nlength(chrCopyNum{chr}) = ' num2str(length(chrCopyNum{chr})) '\n']);
			%if (length(chrCopyNum{chr}) > 0)
				%fprintf(['chrCopyNum{chr}(1) = ' num2str(chrCopyNum{chr}(1)) '\n']);

				% dragon: attempt to clean up poor behavior with zero copy number estimates leading to no SNP/LOH data presented.
				for segment = 1:(length(chrCopyNum{chr}))
					if (round(chrCopyNum{chr}(segment)) == 0)
						chrCopyNum{chr}(segment) = 1;
					end;
				end;

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
			%end;

			% add break representing right end of chromosome.
			breakCount_new = breakCount_new+1;
			chr_breaks_new{chr}(breakCount_new) = 1.0;

			% output status to log file.
			fprintf(['@@@2 chr = ' num2str(chr) '\n']);
			fprintf(['@@@2    chr_breaks_old = ' num2str(chr_breaks{chr})     '\n']);
			fprintf(['@@@2    chrCopyNum_old = ' num2str(chrCopyNum{chr})     '\n']);
			fprintf(['@@@2    chr_breaks_new = ' num2str(chr_breaks_new{chr}) '\n']);
			fprintf(['@@@2    chrCopyNum_new = ' num2str(chrCopyNum_new{chr}) '\n']);

			% copy new lists to old.
			chr_breaks{chr} = chr_breaks_new{chr};
			chrCopyNum{chr} = [];
			chrCopyNum{chr} = chrCopyNum_new{chr};
		else
			% output status to log file.
			fprintf(['@@@2 chr = ' num2str(chr) '\n']);
			fprintf(['@@@2    Only one CNV segment on this chromosome\n']);
		end;
	end;
end;


%% =========================================================================================
% Save workspace variables for use in "CNV_SNP_hapmap_v4_RedGreen.m"
%-------------------------------------------------------------------------------------------
fprintf('\t|\tSave workspace variables for later use in RedGreen alternate plot.\n');
save([projectDir 'CNV_SNP_hapmap_v4.workspace_variables.mat']);

%% change permissions of file.
system(['chmod 664 ' projectDir 'CNV_SNP_hapmap_v4.workspace_variables.mat']);


%%================================================================================================
% Process SNP/hapmap data to determine colors to be presented for each SNP locus.
%-------------------------------------------------------------------------------------------------
fprintf('\t|\tDetermine colors per SNP using hapmap.\n');
%% =========================================================================================
% Calculate allelic fraction cutoffs for each segment and populate data structure containing
% SNP phasing information.
%       chr_SNPdata{chr,1}{chr_bin} = phased SNP ratio data.
%       chr_SNPdata{chr,2}{chr_bin} = unphased SNP ratio data.
%       chr_SNPdata{chr,3}{chr_bin} = phased SNP position data.
%       chr_SNPdata{chr,4}{chr_bin} = unphased SNP position data.
%       chr_SNPdata{chr,5}{chr_bin} = phased SNP allele strings.   (baseCall:alleleA/alleleB)
%       chr_SNPdata{chr,6}{chr_bin} = unphased SNP allele strings.
%-------------------------------------------------------------------------------------------
% Prepare data for "calculate_allelic_ratio_cutoffs.m".
temp_holding = chr_SNPdata;
calculate_allelic_ratio_cutoffs;
chr_SNPdata = temp_holding;

%% =========================================================================================
% Define new colors for SNPs, using Gaussian fitting crossover points as ratio cutoffs.
%-------------------------------------------------------------------------------------------
alleleRatiosFid = openAlleleRatiosTrack(projectDir, project);

for chr = 1:num_chrs
	% avoid running over chromosomes with empty copy number
	if (chr_in_use(chr) == 1 && ~isempty(chrCopyNum{chr}))
		chrName = chr_name{chr};
		for chr_bin = 1:ceil(chr_size(chr)/bases_per_bin)
			%
			% Determining colors for each SNP coordinate from calculated cutoffs.
			%
			localCopyEstimate                                     = round(CNVplot2{chr}(chr_bin)*ploidy*ploidyAdjust);
			allelic_ratios                                        = [chr_SNPdata{chr,1}{chr_bin} chr_SNPdata{chr,2}{chr_bin}];
			coordinates                                           = [chr_SNPdata{chr,3}{chr_bin} chr_SNPdata{chr,4}{chr_bin}];
			if (length(chr_SNPdata{chr,1}{chr_bin}) == 1) && (length(chr_SNPdata{chr,2}{chr_bin}) == 1)
				allele_strings                                = {chr_SNPdata{chr,5}{chr_bin} chr_SNPdata{chr,6}{chr_bin}};
			else
				allele_strings                                = [chr_SNPdata{chr,5}{chr_bin} chr_SNPdata{chr,6}{chr_bin}];
			end;

			if (length(allelic_ratios) > 0)
				for SNP = 1:length(allelic_ratios)
					% Load phased SNP data from earlier defined structure.
					allelic_ratio                         = allelic_ratios(SNP);
					coordinate                            = coordinates(SNP);
					if (length(allelic_ratios) > 1)
						allele_string                 = allele_strings{SNP};
					else
						allele_string                 = allele_strings;
					end;
					baseCall                              = allele_string(1);
					homologA                              = allele_string(3);
					homologB                              = allele_string(5);

					% identify the segment containing the SNP.
					segmentID                             = 0;
					for segment = 1:(length(chrCopyNum{chr}))
						segment_start                 = chr_breaks{chr}(segment  )*chr_size(chr);
						segment_end                   = chr_breaks{chr}(segment+1)*chr_size(chr);
						if (coordinate > segment_start) && (coordinate <= segment_end)
							segmentID             = segment;
						end;
					end;

					% Load cutoffs between Gaussian fits performed earlier.
					segment_copyNum                       = round(chrCopyNum{              chr}(segmentID));
					actual_cutoffs                        = chrSegment_actual_cutoffs{     chr}{segmentID};
					mostLikelyGaussians                   = chrSegment_mostLikelyGaussians{chr}{segmentID};

					% Calculate allelic ratio on range of [1..200].
					SNPratio_int                          = (allelic_ratio)*199+1;

					% Identify the allelic ratio region containing the SNP.
					cutoffs                               = [1 actual_cutoffs 200];
					ratioRegionID                         = 0;
					for GaussianRegionID = 1:length(mostLikelyGaussians)
						cutoff_start                  = cutoffs(GaussianRegionID  );
						cutoff_end                    = cutoffs(GaussianRegionID+1);
						if (GaussianRegionID == 1)
							if (SNPratio_int >= cutoff_start) && (SNPratio_int <= cutoff_end)
								ratioRegionID = mostLikelyGaussians(GaussianRegionID);
							end;
						else
							if (SNPratio_int > cutoff_start) && (SNPratio_int <= cutoff_end)
								ratioRegionID = mostLikelyGaussians(GaussianRegionID);
							end;
						end;
					end;

					if (segment_copyNum <= 0);
						colorList = colorNoData;
					elseif (segment_copyNum == 1)
						% allelic fraction cutoffs: [0.50000] => [A B]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 2);            colorList = colorB;
							else                                colorList = colorA;
							end;
						else
							% ratioRegion == 1 or 2 will require the same output color depending on below conditions.
							if (useHapmap || useParent);        colorList = unphased_color_1of1;
							else                                colorList = noparent_color_1of1;
							end;
						end;
					elseif (segment_copyNum == 2)
						%   allelic fraction cutoffs: [0.25000 0.75000] => [AA AB BB]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 3);            colorList = colorBB;
							elseif (ratioRegionID == 2);        colorList = colorAB;
							else                                colorList = colorAA;
							end;
						else
							if (useHapmap || useParent)
								if (ratioRegionID == 3);        colorList = unphased_color_2of2;
								elseif (ratioRegionID == 2);    colorList = unphased_color_1of2;
								else                            colorList = unphased_color_2of2;
								end;
							else
								if (ratioRegionID == 3);        colorList = noparent_color_2of2;
								elseif (ratioRegionID == 2);    colorList = noparent_color_1of2;
								else                            colorLost = noparent_color_2of2;
								end;
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
							if (useHapmap || useParent)
								if (ratioRegionID == 4);        colorList = unphased_color_3of3;
								elseif (ratioRegionID == 3);    colorList = unphased_color_2of3;
								elseif (ratioRegionID == 2);    colorList = unphased_color_2of3;
								else                            colorList = unphased_color_3of3;
								end;
							else
								if (ratioRegionID == 4);        colorList = noparent_color_3of3;
								elseif (ratioRegionID == 3);    colorList = noparent_color_2of3;
								elseif (ratioRegionID == 2);    colorList = noparent_color_2of3;
								else                            colorList = noparent_color_3of3;
								end;
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
							if (useHapmap || useParent)
								if (ratioRegionID == 5);        colorList = unphased_color_4of4;
								elseif (ratioRegionID == 4);    colorList = unphased_color_3of4;
								elseif (ratioRegionID == 3);    colorList = unphased_color_2of4;
								elseif (ratioRegionID == 2);    colorList = unphased_color_3of4;
								else                            colorList = unphased_color_4of4;
								end;
							else
								if (ratioRegionID == 5);        colorList = noparent_color_4of4;
								elseif (ratioRegionID == 4);    colorList = noparent_color_3of4;
								elseif (ratioRegionID == 3);    colorList = noparent_color_2of4;
								elseif (ratioRegionID == 2);    colorList = noparent_color_3of4;
								else                            colorList = noparent_color_4of4;
								end;
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
							if (useHapmap || useParent)
								if (ratioRegionID == 6);        colorList = unphased_color_5of5;
								elseif (ratioRegionID == 5);    colorList = unphased_color_4of5;
								elseif (ratioRegionID == 4);    colorList = unphased_color_3of5;
								elseif (ratioRegionID == 3);    colorList = unphased_color_3of5;
								elseif (ratioRegionID == 2);    colorList = unphased_color_4of5;
								else                            colorList = unphased_color_5of5;
								end;
							else
								if (ratioRegionID == 6);        colorList = noparent_color_5of5;
								elseif (ratioRegionID == 5);    colorList = noparent_color_4of5;
								elseif (ratioRegionID == 4);    colorList = noparent_color_3of5;
								elseif (ratioRegionID == 3);    colorList = noparent_color_3of5;
								elseif (ratioRegionID == 2);    colorList = noparent_color_4of5;
								else                            colorList = noparent_color_5of5;
								end;
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
							if (useHapmap || useParent)
								if (ratioRegionID == 7);        colorList = unphased_color_6of6;
								elseif (ratioRegionID == 6);    colorList = unphased_color_5of6;
								elseif (ratioRegionID == 5);    colorList = unphased_color_4of6;
								elseif (ratioRegionID == 4);    colorList = unphased_color_3of6;
								elseif (ratioRegionID == 3);    colorList = unphased_color_4of6;
								elseif (ratioRegionID == 2);    colorList = unphased_color_5of6;
								else                            colorList = unphased_color_6of6;
								end;
							else
								if (ratioRegionID == 7);        colorList = noparent_color_6of6;
								elseif (ratioRegionID == 6);    colorList = noparent_color_5of6;
								elseif (ratioRegionID == 5);    colorList = noparent_color_4of6;
								elseif (ratioRegionID == 4);    colorList = noparent_color_3of6;
								elseif (ratioRegionID == 3);    colorList = noparent_color_4of6;
								elseif (ratioRegionID == 2);    colorList = noparent_color_5of6;
								else                            colorList = noparent_color_6of6;
								end;
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
							if (useHapmap || useParent)
								if (ratioRegionID == 8);        colorList = unphased_color_7of7;
								elseif (ratioRegionID == 7);    colorList = unphased_color_6of7;
								elseif (ratioRegionID == 6);    colorList = unphased_color_5of7;
								elseif (ratioRegionID == 5);    colorList = unphased_color_4of7;
								elseif (ratioRegionID == 3);    colorList = unphased_color_4of7;
								elseif (ratioRegionID == 3);    colorList = unphased_color_5of7;
								elseif (ratioRegionID == 2);    colorList = unphased_color_6of7;
								else                            colorList = unphased_color_7of7;
								end;
							else
								if (ratioRegionID == 8);        colorList = noparent_color_7of7;
								elseif (ratioRegionID == 7);    colorList = noparent_color_6of7;
								elseif (ratioRegionID == 6);    colorList = noparent_color_5of7;
								elseif (ratioRegionID == 5);    colorList = noparent_color_4of7;
								elseif (ratioRegionID == 3);    colorList = noparent_color_4of7;
								elseif (ratioRegionID == 3);    colorList = noparent_color_5of7;
								elseif (ratioRegionID == 2);    colorList = noparent_color_6of7;
								else                            colorList = noparent_color_7of7;
								end;
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
							if (useHapmap || useParent)
								if (ratioRegionID == 9);        colorList = unphased_color_8of8;
								elseif (ratioRegionID == 8);    colorList = unphased_color_7of8;
								elseif (ratioRegionID == 7);    colorList = unphased_color_6of8;
								elseif (ratioRegionID == 6);    colorList = unphased_color_5of8;
								elseif (ratioRegionID == 5);    colorList = unphased_color_4of8;
								elseif (ratioRegionID == 4);    colorList = unphased_color_5of8;
								elseif (ratioRegionID == 3);    colorList = unphased_color_6of8;
								elseif (ratioRegionID == 2);    colorList = unphased_color_7of8;
								else                            colorList = unphased_color_8of8;
								end;
							else
								if (ratioRegionID == 9);        colorList = noparent_color_8of8;
								elseif (ratioRegionID == 8);    colorList = noparent_color_7of8;
								elseif (ratioRegionID == 7);    colorList = noparent_color_6of8;
								elseif (ratioRegionID == 6);    colorList = noparent_color_5of8;
								elseif (ratioRegionID == 5);    colorList = noparent_color_4of8;
								elseif (ratioRegionID == 4);    colorList = noparent_color_5of8;
								elseif (ratioRegionID == 3);    colorList = noparent_color_6of8;
								elseif (ratioRegionID == 2);    colorList = noparent_color_7of8;
								else                            colorList = noparent_color_8of8;
								end;
							end;
						end;
					elseif (segment_copyNum >= 9)
						% allelic fraction cutoffs: [0.05556 0.16667 0.27778 0.38889 0.50000 0.61111 0.72222 0.83333 0.94444] => [AAAAAAAAA AAAAAAAAB AAAAAAABB AAAAAABBB AAAAABBBB AAAABBBBB AAABBBBBB AABBB$
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
							if (useHapmap || useParent)
								if (ratioRegionID == 10);       colorList = unphased_color_9of9;
								elseif (ratioRegionID == 9);    colorList = unphased_color_8of9;
								elseif (ratioRegionID == 8);    colorList = unphased_color_7of9;
								elseif (ratioRegionID == 7);    colorList = unphased_color_6of9;
								elseif (ratioRegionID == 6);    colorList = unphased_color_5of9;
								elseif (ratioRegionID == 5);    colorList = unphased_color_5of9;
								elseif (ratioRegionID == 4);    colorList = unphased_color_6of9;
								elseif (ratioRegionID == 3);    colorList = unphased_color_7of9;
								elseif (ratioRegionID == 2);    colorList = unphased_color_8of9;
								else                            colorList = unphased_color_9of9;
								end;
							else
								if (ratioRegionID == 10);       colorList = noparent_color_9of9;
								elseif (ratioRegionID == 9);    colorList = noparent_color_8of9;
								elseif (ratioRegionID == 8);    colorList = noparent_color_7of9;
								elseif (ratioRegionID == 7);    colorList = noparent_color_6of9;
								elseif (ratioRegionID == 6);    colorList = noparent_color_5of9;
								elseif (ratioRegionID == 5);    colorList = noparent_color_5of9;
								elseif (ratioRegionID == 4);    colorList = noparent_color_6of9;
								elseif (ratioRegionID == 3);    colorList = noparent_color_7of9;
								elseif (ratioRegionID == 2);    colorList = noparent_color_8of9;
								else                            colorList = noparent_color_9of9;
								end;
							end;
						end;
					end;
					chr_SNPdata_colorsC{chr,1}(chr_bin) = chr_SNPdata_colorsC{chr,1}(chr_bin) + colorList(1);
					chr_SNPdata_colorsC{chr,2}(chr_bin) = chr_SNPdata_colorsC{chr,2}(chr_bin) + colorList(2);
					chr_SNPdata_colorsC{chr,3}(chr_bin) = chr_SNPdata_colorsC{chr,3}(chr_bin) + colorList(3);
					chr_SNPdata_countC{ chr  }(chr_bin) = chr_SNPdata_countC{ chr  }(chr_bin) + 1;

					if (~all(colorList == colorNoData))
						writeAlleleRatioLine(alleleRatiosFid, chrName, coordinate, ...
							homologA, homologB, ...
							colorList);
					end

					% Troubleshooting output.
					% fprintf(['chr = ' num2str(chr) '; seg = ' num2str(segment) '; bin = ' num2str(chr_bin) '; ratioRegionID = ' num2str(ratioRegionID) '\n']);
				end;
			end;
		end;

		%
		% Average colors of SNPs found in bin.
        	%
		fprintf('\t|\tDetermine average color for SNPs in chromosome bin.\n');
		for chr_bin = 1:ceil(chr_size(chr)/bases_per_bin)
			allelic_ratios                                      = [chr_SNPdata{chr,1}{chr_bin} chr_SNPdata{chr,2}{chr_bin}];
			if (length(allelic_ratios) > 0)
				if (chr_SNPdata_countC{chr}(chr_bin) > 0)
					chr_SNPdata_colorsC{chr,1}(chr_bin) = chr_SNPdata_colorsC{chr,1}(chr_bin)/chr_SNPdata_countC{chr}(chr_bin);
					chr_SNPdata_colorsC{chr,2}(chr_bin) = chr_SNPdata_colorsC{chr,2}(chr_bin)/chr_SNPdata_countC{chr}(chr_bin);
					chr_SNPdata_colorsC{chr,3}(chr_bin) = chr_SNPdata_colorsC{chr,3}(chr_bin)/chr_SNPdata_countC{chr}(chr_bin);
				else
					chr_SNPdata_colorsC{chr,1}(chr_bin) = 1.0;
					chr_SNPdata_colorsC{chr,2}(chr_bin) = 1.0;
					chr_SNPdata_colorsC{chr,3}(chr_bin) = 1.0;
				end;
			else
				chr_SNPdata_colorsC{chr,1}(chr_bin) = 1.0;
				chr_SNPdata_colorsC{chr,2}(chr_bin) = 1.0;
				chr_SNPdata_colorsC{chr,3}(chr_bin) = 1.0;
			end;
		end;
	end;
end;

fclose(alleleRatiosFid);

%% change file permissions.
system(['chmod 664 ' projectDir 'allele_ratios.' project  '.bed']);

%% =========================================================================================
% Setup for main figure generation.
%-------------------------------------------------------------------------------------------
% load size definitions
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chr_gap,Linear_Chr_max_width,Linear_height...
    ,Linear_base,rotate,linear_chr_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chr_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chr_in_use,num_chrs,chr_label,chr_size);

fprintf('\t|\tCount SNPs per chromosome bin.\n');
% threshold for full color saturation in SNP/LOH figure.
% synced to bases_per_bin as below, or defaulted to 50.
full_data_threshold = floor(bases_per_bin/100);
fig = figure(1);

for chr = 1:num_chrs
	if (chr_in_use(chr) == 1)
		for chr_bin = 1:length(chr_SNPdata{chr,1})
			% the number of heterozygous data points in this bin.
			SNPs_count{chr}(chr_bin)                                     = length(chr_SNPdata{chr,1}{chr_bin}) + length(chr_SNPdata{chr,2}{chr_bin});

			% divide by the threshold for full color saturation in SNP/LOH figure.
			SNPs_to_fullData_ratio{chr}(chr_bin)                         = SNPs_count{chr}(chr_bin)/full_data_threshold;

			% any bins with more data than the threshold for full color saturation are limited to full saturation.
			SNPs_to_fullData_ratio{chr}(SNPs_to_fullData_ratio{chr} > 1) = 1;

			phased_plot{chr}(chr_bin)                                    = length(chr_SNPdata{chr,1}{chr_bin});             % phased data.
			phased_plot2{chr}(chr_bin)                                   = phased_plot{chr}(chr_bin)/full_data_threshold;   %
			phased_plot2{chr}(phased_plot2{chr} > 1)                     = 1;                                               %

			unphased_plot{chr}(chr_bin)                                  = length(chr_SNPdata{chr,2}{chr_bin});             % unphased data.
			unphased_plot2{chr}(chr_bin)                                 = unphased_plot{chr}(chr_bin)/full_data_threshold; %
			unphased_plot2{chr}(unphased_plot2{chr} > 1)                 = 1;                                               %
		end;
	end;
end;


fprintf('\n');
largestChr = find(chr_width == max(chr_width));
largestChr = largestChr(1);


%% =========================================================================================
% Setup for figure generation.
%-------------------------------------------------------------------------------------------
if (Standard_display == true)
	fprintf('\t|\tSetup for main figure generation.\n');
	fig = figure(1);
end;


%% =========================================================================================
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------
if (Linear_display == true)
	fprintf('\t|\tSetup for linear figure generation.\n');
	Linear_fig           = figure(2);
	Linear_genome_size   = sum(chr_size);
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chr figure.
	maxY                 = ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


%% =========================================================================================
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
		if (Standard_display == true)
			figure(fig);

			% make standard chr cartoons.
			left          = chr_posX(chr);
			bottom        = chr_posY(chr);
			width         = chr_width(chr);
			height        = chr_height(chr);
			subPlotHandle = subplot('Position',[left bottom width height]);
			fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
			hold on;
		end;

		c_prev = colorInit;
		c_post = colorInit;
		c_     = c_prev;
		infill = zeros(1,length(unphased_plot2{chr}));
		colors = [];

		%% determine color of each bin.
		for chr_bin = 1:ceil(chr_size(chr)/bases_per_bin)
			c_tot_post = SNPs_to_fullData_ratio{chr}(chr_bin)+SNPs_to_fullData_ratio{chr}(chr_bin);
			if (c_tot_post == 0)
				c_post = colorNoData;
				fprintf('.');
				if (mod(chr_bin,100) == 0);   fprintf('\n');   end;
			else
				% Average of SNP position colors defined earlier.
				colorMix = [chr_SNPdata_colorsC{chr,1}(chr_bin) chr_SNPdata_colorsC{chr,2}(chr_bin) chr_SNPdata_colorsC{chr,3}(chr_bin)];

				% Determine color to draw bin, accounting for limited data and data saturation.
				c_post =   colorMix   *   min(1,SNPs_to_fullData_ratio{chr}(chr_bin)) + ...
				           colorNoData*(1-min(1,SNPs_to_fullData_ratio{chr}(chr_bin)));
			end;
			colors(chr_bin,1) = c_post(1);
			colors(chr_bin,2) = c_post(2);
			colors(chr_bin,3) = c_post(3);
		end;
		% standard : end determine color of each bin.

		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chr_figReversed(chr) == 1)
			colors        = flipud(colors);
			CNVplot2{chr} = fliplr(CNVplot2{chr});
		end;

		if (Standard_display == true)
			%% standard : draw colorbars.
			for chr_bin = 1:ceil(chr_size(chr)/bases_per_bin)
				x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
				y_ = [0 maxY maxY 0];
				c_post(1) = colors(chr_bin,1);
				c_post(2) = colors(chr_bin,2);
				c_post(3) = colors(chr_bin,3);
				% makes a colorBar for each bin, using local smoothing
				if (c_(1) > 1); c_(1) = 1; end;
				if (c_(2) > 1); c_(2) = 1; end;
				if (c_(3) > 1); c_(3) = 1; end;
				if (blendColorBars == false)
					f = fill(x_,y_,c_);
				else
					f = fill(x_,y_,c_/2+c_prev/4+c_post/4);
				end;
				c_prev = c_;
				c_     = c_post;
				set(f,'linestyle','none');
			end;
			% standard : end draw colorbars.

			%% standard : cgh plot section.
			c_ = [0 0 0];
			fprintf(['\nmain-plot : chr' num2str(chr) ':' num2str(length(CNVplot2{chr})) '\n']);
			fprintf(['ploidy     = ' num2str(ploidy)     '\n']);
			fprintf(['ploidyBase = ' num2str(ploidyBase) '\n']);
			for chr_bin = 1:length(CNVplot2{chr});   % ceil(chr_size(chr)/bases_per_bin)
				x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
				CNVhistValue = CNVplot2{chr}(chr_bin);

				% The CNV-histogram values were normalized to a median value of 1.
				% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
				startY = maxY/2;
				if (Low_quality_ploidy_estimate == true)
					endY = min(maxY,CNVhistValue*ploidy*ploidyAdjust);
				else
					endY = min(maxY,CNVhistValue*ploidy);
				end;
				y_ = [startY endY endY startY];

				% makes a blackbar for each bin.
				f = fill(x_,y_,c_);
				set(f,'linestyle','none');
			end;

			% standard : draw lines across plots for easier interpretation of CNV regions.
			x2 = chr_size(chr)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			% standard : end cgh plot section.

			% standard : axes labels etc.
			hold off;
			xlim([0,chr_size(chr)/bases_per_bin]);

			% standard : modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			set(gca,'TickLength',[(TickSize*chr_size(largestChr)/chr_size(chr)) 0]); %ensures same tick size on all subfigs.
			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});
			if (chr_figReversed(chr) == 0)
				text(-50000/5000/2*3, maxY/2,chr_label{chr}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chr_font_size);
			else
				text(-50000/5000/2*3, maxY/2,[chr_label{chr} '\fontsize{' int2str(round(stacked_chr_font_size/2)) '}' char(10) '(reversed)'], 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chr_font_size);
			end;
			switch ploidyBase
				case 1
					text(axisLabelPosition_vert, maxY/2,     '1','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 2
					text(axisLabelPosition_vert, maxY/4,     '1','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 3
					text(axisLabelPosition_vert, maxY/2,     '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 4
					text(axisLabelPosition_vert, maxY/4,     '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '8','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 5
					text(axisLabelPosition_vert, maxY/2,     '5','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '10','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 6
					text(axisLabelPosition_vert, maxY/4,     '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '9','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 7
					text(axisLabelPosition_vert, maxY/2,     '7','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '14','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 8
					text(axisLabelPosition_vert, maxY/4,     '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '8','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,  '12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '16','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
			end;
			set(gca,'FontSize',gca_stacked_font_size);
			if (chr == find(chr_posY == max(chr_posY)))
				title([ project ' vs. (hapmap)' hapmap ' SNP/LOH map'],'Interpreter','none','FontSize',stacked_title_size);
			end;
			hold on;
			% standard : end axes labels etc.

			if (displayBREAKS == true) && (show_annotations == true)
				chr_length = ceil(chr_size(chr)/bases_per_bin);
				for segment = 2:length(chr_breaks{chr})-1
					bP = chr_breaks{chr}(segment)*chr_length;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;

			%% standard : show centromere outlines and horizontal marks.
			x1 = cen_start(chr)/bases_per_bin;
			x2 = cen_end(chr)/bases_per_bin;
			leftEnd  = 0.5*5000/bases_per_bin;
			rightEnd = (chr_size(chr) - 0.5*5000)/bases_per_bin;
			if (Centromere_format == 0)
				% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
				dx = cen_tel_Xindent; %5*5000/bases_per_bin;
				dy = cen_tel_Yindent; %maxY/10;
				% draw white triangles at corners and centromere locations.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'LineStyle', 'none');    % top left corner.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [dy        0         0   ],         [1.0 1.0 1.0], 'LineStyle', 'none');    % bottom left corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'LineStyle', 'none');    % top right corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [dy        0         0   ],         [1.0 1.0 1.0], 'LineStyle', 'none');    % bottom right corner.
				fill([x1-dx     x1        x2           x2+dx],[maxY      maxY-dy   maxY-dy  maxY],[1.0 1.0 1.0], 'LineStyle', 'none');    % top centromere.
				fill([x1-dx     x1        x2           x2+dx],[0         dy        dy       0   ],[1.0 1.0 1.0], 'LineStyle', 'none');    % bottom centromere.
				% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
				plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx    rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
				     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY     maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy     ],...
				      'Color',[0 0 0]);
			end;
			% standard : end show centromere.

			%% standard : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				hold on;
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chr(i) == chr)
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

			%% standard : make CGH histograms to the right of the main chr cartoons.
			if (HistPlot == true)
				width     = 0.020;
				height    = chr_height(chr);
				bottom    = chr_posY(chr);
				histAll   = [];
				histAll2  = [];
				smoothed  = [];
				smoothed2 = [];
				for segment = 1:length(chrCopyNum{chr})
					subplot('Position',[(left+chr_width(chr)+0.005)+width*(segment-1) bottom width height]);
					% The CNV-histogram values were normalized to a median value of 1.
					for i = round(1+length(CNVplot2{chr})*chr_breaks{chr}(segment)):round(length(CNVplot2{chr})*chr_breaks{chr}(segment+1))
						if (Low_quality_ploidy_estimate == true)
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
					plot([0;       0      ],[0; 1],'color',[0.00 0.00 0.00]);
					hold on;
					for i = 1:15
						plot([20*i;  20*i],[0; 1],'color',[0.75 0.75 0.75]);
					end;

					% draw histogram.
					area(smoothed{segment},'FaceColor',[0 0 0]);

					% Draw red ticks between histplot segments
					if (displayBREAKS == true) && (show_annotations == true)
						if (segment > 1)
							plot([-maxY*20/10*1.5 0],[0 0],  'Color',[1 0 0],'LineWidth',2);
						end;
					end;

					% Flip subfigure around the origin.
					view(-90,90);
					set(gca,'YDir','Reverse');

					% ensure subplot axes are consistent with main chr plots.
					hold off;
					axis off;
					set(gca,'YTick',[]);
					set(gca,'XTick',[]);
					ylim([0,1]);
					if (show_annotations == true)
						xlim([-maxY*20/10*1.5,maxY*20]);
					else
						xlim([0,maxY*20]);
					end;
				end;
			end;
			% standard : end of CGH histograms at right.

			% standard : places chr copy number to the right of the main chr cartoons.
			if (ChrNum == true)
				% subplot to show chr copy number value.
				width  = 0.020;
				height = chr_height(chr);
				bottom = chr_posY(chr);
				if (HistPlot == true)
					subplot('Position',[(left + chr_width(chr) + 0.005 + width*(length(chrCopyNum{chr})-1) + width+0.001) bottom width height]);
				else
					subplot('Position',[(left + chr_width(chr) + 0.005) bottom width height]);
				end;
				axis off square;
				set(gca,'YTick',[]);
				set(gca,'XTick',[]);
				if (length(chrCopyNum{chr}) > 0)
					if (length(chrCopyNum{chr}) == 1)
						chr_string = num2str(chrCopyNum{chr}(1));
					else
						chr_string = num2str(chrCopyNum{chr}(1));
						for i = 2:length(chrCopyNum{chr})
							chr_string = [chr_string ',' num2str(chrCopyNum{chr}(i))];
						end;
					end;
					text(0.1,0.5, chr_string,'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',stacked_copy_font_size);
				end;
			end;
			% standard : end of chr copy number at right of the main chr cartons.


			%% =========================================================================================
			% Draw angleplots to left of main chromosome cartoons.
			%-------------------------------------------------------------------------------------------
			apply_phasing = true;
			angle_plot_subfigures;
		end;

%%%%%%%%%%%%%%%% Linear figure draw section

		%% Linear figure draw section
		if (Linear_display == true)
			figure(Linear_fig);

			Linear_width = Linear_Chr_max_width*chr_size(chr)/Linear_genome_size;

			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			Linear_left = Linear_left + Linear_width + Linear_chr_gap;
			hold on;

			%% linear : draw colorbars.
			for chr_bin = 1:ceil(chr_size(chr)/bases_per_bin)
				x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
				y_ = [0 maxY maxY 0];
				c_post(1) = colors(chr_bin,1);
				c_post(2) = colors(chr_bin,2);
				c_post(3) = colors(chr_bin,3);
				% makes a colorBar for each bin, using local smoothing
				if (c_(1) > 1); c_(1) = 1; end;
				if (c_(2) > 1); c_(2) = 1; end;
				if (c_(3) > 1); c_(3) = 1; end;
				if (blendColorBars == false)
					f = fill(x_,y_,c_);
				else
					f = fill(x_,y_,c_/2+c_prev/4+c_post/4);
				end;
				c_prev = c_;
				c_     = c_post;
				set(f,'linestyle','none');
			end;
			% linear : end draw colorbars.

			%% linear : cgh plot section.
			c_ = [0 0 0];
			fprintf(['linear-plot : chr' num2str(chr) ':' num2str(length(CNVplot2{chr})) '\n']);
			for chr_bin = 1:ceil(chr_size(chr)/bases_per_bin)
				x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
				CNVhistValue = CNVplot2{chr}(chr_bin);
				% The CNV-histogram values were normalized to a median value of 1.
				% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
				startY = maxY/2;
				if (Low_quality_ploidy_estimate == true)
					endY = min(maxY,CNVhistValue*ploidy*ploidyAdjust);
				else
					endY = min(maxY,CNVhistValue*ploidy);
				end;
				y_ = [startY endY endY startY];
				% makes a blackbar for each bin.
				f = fill(x_,y_,c_);
				set(f,'linestyle','none');
			end;
			% linear : end CGH plot section.

			%% linear : draw lines across plots for easier interpretation of CNV regions.
			x2 = chr_size(chr)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			% linear : end cgh plot section.

			%% linear : show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS == true) && (show_annotations == true)
				chr_length = ceil(chr_size(chr)/bases_per_bin);
				for segment = 2:length(chr_breaks{chr})-1
					bP = chr_breaks{chr}(segment)*chr_length;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;
			% linear : end segmental aneuploidy breakpoint section.

			%% linear : show centromere.
			x1 = cen_start(chr)/bases_per_bin;
			x2 = cen_end(chr)/bases_per_bin;
			leftEnd  = 0.5*5000/bases_per_bin;
			rightEnd = (chr_size(chr) - 0.5*5000)/bases_per_bin;
			if (Centromere_format == 0)
				% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
				dx = cen_tel_Xindent; %5*5000/bases_per_bin;
				dy = cen_tel_Yindent; %maxY/10;
				% draw white triangles at corners and centromere locations.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'linestyle', 'none');  % top left corner.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [dy        0         0   ],         [1.0 1.0 1.0], 'linestyle', 'none');  % bottom left corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'linestyle', 'none');  % top right corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [dy        0         0   ],         [1.0 1.0 1.0], 'linestyle', 'none');  % bottom right corner.
				fill([x1-dx     x1        x2           x2+dx],[maxY      maxY-dy   maxY-dy  maxY],[1.0 1.0 1.0], 'linestyle', 'none');  % top centromere.
				fill([x1-dx     x1        x2           x2+dx],[0         dy        dy       0   ],[1.0 1.0 1.0], 'linestyle', 'none');  % bottom centromere.
				% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
				plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
				      [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy],...
				      'Color',[0 0 0]);
			end;
			% linear : end show centromere.

			% linear : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				hold on;
				annotation_location = (annotation_start+annotation_end)./2;
				for i = 1:length(annotation_location)
					if (annotation_chr(i) == chr)
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
			xlim([0,chr_size(chr)/bases_per_bin]);
			% modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			set(gca,'TickLength',[(Linear_TickSize*chr_size(largestChr)/chr_size(chr)) 0]); %ensures same tick size on all subfigs.
			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',[]);
			if (first_chr)
				% This section sets the Y-axis labelling.
				switch ploidyBase
					case 1
						text(axisLabelPosition_horiz, maxY/2,     '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 2
						text(axisLabelPosition_horiz, maxY/4,     '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 3
						text(axisLabelPosition_horiz, maxY/2,     '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 4
						text(axisLabelPosition_horiz, maxY/4,     '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 5
						text(axisLabelPosition_horiz, maxY/2,     '5','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '10','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 6
						text(axisLabelPosition_vert, maxY/4,      '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
						text(axisLabelPosition_vert, maxY/2,      '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
						text(axisLabelPosition_vert, maxY/4*3,    '9','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
						text(axisLabelPosition_vert, maxY,       '12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					case 7
						text(axisLabelPosition_horiz, maxY/2,     '7','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '14','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 8
						text(axisLabelPosition_horiz, maxY/4,     '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,  '12','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '16','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				end;
			end;
			set(gca,'FontSize',linear_gca_font_size);
			%end final reformatting.

			% adding title in the middle of the cartoon
			% note: adding title is done in the end since if placed upper
			% in the code somehow the plot function changes the title position
			% location
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

		if (Standard_display == true)
			% shift back to main figure generation.
			figure(fig);

			hold on;
		end;

		first_chr = false;
	end;
end;


%% ========================================================================
% end stuff
%==========================================================================

if (Standard_display == true)
	fprintf('\n###\n### Saving main figure.\n###\n');
	set(   fig,        'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(fig,        [projectDir 'fig.CNV-SNP-map.1.' figVer 'eps'], 'epsc');
	saveas(fig,        [projectDir 'fig.CNV-SNP-map.1.' figVer 'png'], 'png' );
	delete(fig);

	%% change permissions of figures.
	system(['chmod 664 ' projectDir 'fig.CNV-SNP-map.1.' figVer 'eps']);
	system(['chmod 664 ' projectDir 'fig.CNV-SNP-map.1.' figVer 'png']);
end;

if (Linear_display == true)
	fprintf('\n###\n### Saving linear figure.\n###\n');
	set(   Linear_fig, 'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.2.' figVer 'eps'], 'epsc');
	saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.2.' figVer 'png'], 'png' );
	delete(Linear_fig);

	%% change permissions of figures.
	system(['chmod 664 ' projectDir 'fig.CNV-SNP-map.2.' figVer 'eps']);
	system(['chmod 664 ' projectDir 'fig.CNV-SNP-map.2.' figVer 'png']);
end;

end
