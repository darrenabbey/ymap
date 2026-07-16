function [] = allelic_ratios_ddRADseq_B(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');
workingDir = [main_dir 'users/' user '/projects/' project '/'];

%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;


%% ================================================================================================
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin              : Controls bin sizes for SNP/CGH fractions of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CGH data by ploidy.
%    chrom_max_width              : max width of chroms as fraction of figure width.
Centromere_format           = 0;
chrom_max_width               = 0.8;
colorBars                   = true;
blendColorBars              = false;
show_annotations            = true;
Yscale_nearest_even_ploidy  = true;
Linear_display              = true;
Linear_displayBREAKS        = false;

AnglePlot                   = true;   % Show histogram of alleleic fraction at the left end of standard figure chromosomes.
FillColors                  = true;   %     Fill histogram using colors.
show_uncalibrated           = false;  %     Fill with single color instead of ratio call colors.


fprintf('\n');
fprintf('#################################\n');
fprintf('## allelic_ratios_ddRADseq_B.m ##\n');
fprintf('#################################\n');


%%================================================================================================
% Load FASTA file name from 'reference.txt' file for project.
%-------------------------------------------------------------------------------------------------
userReference    = [main_dir 'users/' user '/genomes/' genome '/reference.txt'];
defaultReference = [main_dir 'users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string = strtrim(fileread(defaultReference));
else
	FASTA_string = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%================================================================================================
% Control variables.
%-------------------------------------------------------------------------------------------------
projectDir = [main_dir 'users/' user '/projects/' project '/'];
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];
if (strcmp(hapmap,'') == 1)
	useHapmap = false;
else
	useHapmap = true;
	if (exist([main_dir 'users/default/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir  = [main_dir 'users/default/hapmaps/' hapmap '/'];   % system hapmap.
		hapmapUser = 'default';
	else
		hapmapDir  = [main_dir 'users/' user '/hapmaps/' hapmap '/'];  % user hapmap.
		hapmapUser = user;
	end;
end;
if (strcmp(project,parent) == 1)
	useParent  = false;
	parentDir  = projectDir;
	parentUSer = user;
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


genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];
[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[Aneuploidy]                                                          = Load_dataset_information(projectDir);
num_chroms = length(chrom_sizes);

for chromID = 1:length(chrom_sizes)
	chrom_size(chromID)  = 0;
	cen_start(chromID) = 0;
	cen_end(chromID)   = 0;
end;
for chromID = 1:length(chrom_sizes)
	chrom_size(chrom_sizes(chromID).chrom)    = chrom_sizes(chromID).size;
	cen_start(centromeres(chromID).chrom) = centromeres(chromID).start;
	cen_end(centromeres(chromID).chrom)   = centromeres(chromID).end;
end;
if (length(annotations) > 0)
	fprintf(['\nAnnotations for ' genome '.\n']);
	for annoteID = 1:length(annotations)
		annotation_chrom(annoteID)       = annotations(annoteID).chrom;
		annotation_type{annoteID}      = annotations(annoteID).type;
		annotation_start(annoteID)     = annotations(annoteID).start;
		annotation_end(annoteID)       = annotations(annoteID).end;
		annotation_fillcolor{annoteID} = annotations(annoteID).fillcolor;
		annotation_edgecolor{annoteID} = annotations(annoteID).edgecolor;
		annotation_size(annoteID)      = annotations(annoteID).size;
		fprintf(['\t[' num2str(annotations(annoteID).chrom) ':' annotations(annoteID).type ':' num2str(annotations(annoteID).start) ':' num2str(annotations(annoteID).end) ':' annotations(annoteID).fillcolor ':' annotations(annoteID).edgecolor ':' num2str(annotations(annoteID).size) ']\n']);
	end;
end;
for detailID = 1:length(figure_details)
	if (figure_details(detailID).chrom == 0)
		if (strcmp(figure_details(detailID).label,'Key') == 1)
			key_posX   = figure_details(detailID).posX;
			key_posY   = figure_details(detailID).posY;
			key_width  = figure_details(detailID).width;
			key_height = figure_details(detailID).height;
		end;
	else
		chrom_id         (figure_details(detailID).chrom) = figure_details(detailID).chrom;
		chrom_label      {figure_details(detailID).chrom} = figure_details(detailID).label;
		chrom_name       {figure_details(detailID).chrom} = figure_details(detailID).name;
		chrom_posX       (figure_details(detailID).chrom) = figure_details(detailID).posX;
		chrom_posY       (figure_details(detailID).chrom) = figure_details(detailID).posY;
		chrom_width      (figure_details(detailID).chrom) = figure_details(detailID).width;
		chrom_height     (figure_details(detailID).chrom) = figure_details(detailID).height;
		chrom_in_use     (figure_details(detailID).chrom) = str2num(figure_details(detailID).usechrom);
		chrom_figOrder   (figure_details(detailID).chrom) = str2num(figure_details(detailID).figOrder);
		chrom_figReversed(figure_details(detailID).chrom) = str2num(figure_details(detailID).figReversed);
	end;
end;
num_chroms = length(chrom_size);

%% This block is normally calculated in FindChromSizes_2 in CNV analysis.
for usedchrom = 1:num_chroms
	if (chrom_in_use(usedchrom) == 1)
		% determine where the endpoints of ploidy segments are.
		chrom_breaks{usedchrom}(1) = 0.0;
		break_count = 1;
		if (length(Aneuploidy) > 0)
			for chromBreak = 1:length(Aneuploidy)
				if (Aneuploidy(chromBreak).chrom == usedchrom)
					break_count = break_count+1;
					chrom_broken  = true;
					chrom_breaks{usedchrom}(break_count) = Aneuploidy(chromBreak).break;
				end;
			end;
		end;
		chrom_breaks{usedchrom}(length(chrom_breaks{usedchrom})+1) = 1;
	end;
end;


%% =========================================================================================
%% =========================================================================================
%% =========================================================================================
%% = No further control variables below. ===================================================
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
TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
bases_per_bin    = max(chrom_size)/700;
maxY             = 1; % ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/5;


%% =========================================================================================
% Define colors for figure generation.
%-------------------------------------------------------------------------------------------
fprintf('\t|\tDefine colors used in figure generation.\n');
phased_and_unphased_color_definitions;


%%================================================================================================
% Load 'Common_CNV.mat' file containing CNV estimates per standard genome bin.
%-------------------------------------------------------------------------------------------------
fprintf('\nLoading "Common_CNV" data file for ddRADseq project.');
load([projectDir 'Common_CNV.mat']);   % 'CNVplot2', 'genome_CNV'
[chrom_breaks, chromCopyNum, ploidyAdjust] = FindChromSizes_4(Aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use);


%% =========================================================================================
% Test adjacent segments for no change in copy number estimate.
%...........................................................................................
% Adjacent pairs of segments with the same copy number will be fused into a single segment.
% Segments with a <= zero copy number will be fused to an adjacent segment.
%-------------------------------------------------------------------------------------------
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		if (length(chromCopyNum{chrom}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.
			%% Merge any adjacent segments with the same copy number.
			% add break representing left end of chromosome.
			breakCount_new         = 1;
			chrom_breaks_new{chrom}    = [];
			chromCopyNum_new{chrom}    = [];
			chrom_breaks_new{chrom}(1) = 0.0;
			fprintf(['\nlength(chromCopyNum{chrom}) = ' num2str(length(chromCopyNum{chrom})) '\n']);
			if (length(chromCopyNum{chrom}) > 0)
				fprintf(['chromCopyNum{chrom}(1) = ' num2str(chromCopyNum{chrom}(1)) '\n']);
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
			end;
			% add break representing right end of chromosome.
			breakCount_new = breakCount_new+1;
			chrom_breaks_new{chrom}(breakCount_new) = 1.0;
			fprintf(['@@@ chrom = ' num2str(chrom) '\n']);
			fprintf(['@@@    chrom_breaks_old = ' num2str(chrom_breaks{chrom})     '\n']);
			fprintf(['@@@    chromCopyNum_old = ' num2str(chromCopyNum{chrom})     '\n']);
			fprintf(['@@@    chrom_breaks_new = ' num2str(chrom_breaks_new{chrom}) '\n']);
			fprintf(['@@@    chromCopyNum_new = ' num2str(chromCopyNum_new{chrom}) '\n']);
			% copy new lists to old.
			chrom_breaks{chrom} = chrom_breaks_new{chrom};
			chromCopyNum{chrom} = [];
			chromCopyNum{chrom} = chromCopyNum_new{chrom};
		end;
	end;
end;


%%================================================================================================
% Setup for SNP/LOH data calculations.
%-------------------------------------------------------------------------------------------------
fprintf(['\nGenerating LOH-map figure from ''' project ''' vs. (hapmap)''' hapmap ''' data.\n']);
% Initializes vectors used to hold allelic ratios for each chromosome segment.
if (useHapmap)
	new_bases_per_bin = bases_per_bin;
else
	new_bases_per_bin = bases_per_bin/2;
end;
for chrom = 1:length(chrom_sizes)
	chrom_length = ceil(chrom_size(chrom)/new_bases_per_bin);

	% chrom_SNPdata{chrom,i} :: i = [1..4]
	%       1 : phased SNP ratio data.
	%       2 : unphased SNP ratio data.
	%       3 : phased SNP position data.
	%       4 : unphased SNP position data.
	%       5 : phased SNP flipper value.
	%       6 : unphased SNP flipper value.
	for j = 1:6
		for i = 1:chrom_length
			chrom_SNPdata{chrom,j}{i} = [];
		end;
	end;

	% Colors used to illustrate SNP/LOH data.
	%       chrom_SNPdata_colorsC           : colors scheme defined by hapmap or red for unspecified LOH.
	%       chrom_SNPdata_colorsC{chrom,i} :: i = [1..3] = [R, G, B]
	%       chrom_SNPdata_colorsP{chrom,i} :: i = [1..3] = [R, G, B]
	for j = 1:3
		% Track the RGB value sum per standard bin, then divide by the count to reach the average color per standard genome bin.
		chrom_SNPdata_colorsC{chrom,j}           = zeros(chrom_length,1);
		chrom_SNPdata_colorsP{chrom,j}           = zeros(chrom_length,1);
	end;

	% Track the number of SNP colors per standard bin.
	chrom_SNPdata_countC{chrom} = zeros(chrom_length,1);
	chrom_SNPdata_countP{chrom} = zeros(chrom_length,1);
end;


%%================================================================================================
% Load SNP/LOH data.
%-------------------------------------------------------------------------------------------------
if (useHapmap)
	if (exist([projectDir 'SNP_' SNP_verString '.all3.mat'],'file') == 0)
		fprintf('\nAllelic fraction MAT file 3 not found, generating.\n');
		process_2dataset_hapmap_allelicRatios(projectDir, projectDir, hapmapDir, chrom_size, chrom_name, chrom_in_use, SNP_verString);
	else
		fprintf('\nAllelic fraction MAT file 3 found, loading.\n');
	end;
	load([projectDir 'SNP_' SNP_verString '.all3.mat']);
	% child data:  'C_chrom_SNP_data_positions','C_chrom_SNP_data_ratios','C_chrom_count','C_chrom_baseCall','C_chrom_SNP_homologA','C_chrom_SNP_homologB','C_chrom_SNP_flipHomologs'
	%
	% C_chrom_SNP_data_positions = coordinate of SNP.
	% C_chrom_SNP_data_ratios    = allelic ratio of SNP.
	% C_chrom_count              = number of reads at SNP coordinate.
	% C_chrom_baseCall           = majority basecall of SNP.
	% C_chrom_SNP_homologA       = hapmap homolog a basecall.
	% C_chrom_SNP_homologB       = hapmap homolog b basecall.
	% C_chrom_SNP_flipHomologs   = does hapmap entry need flipped?   0 = 'correct phase, no', 1 = 'incorrect phase, yes', 10 = 'no phasing info'.
else
	if (exist([projectDir 'SNP_' SNP_verString '.all1.mat'],'file') == 0)
		fprintf('\nAllelic fraction MAT file 1 not found, generating.\n');
		process_2dataset_allelicRatios(projectDir, parentDir, chrom_size, chrom_name, chrom_in_use, SNP_verString);
	else
		fprintf('\nAllelic fraction MAT file 1 found, loading.\n');
	end;
	load([projectDir 'SNP_' SNP_verString '.all1.mat']);
	% child data:  'C_chrom_SNP_data_positions','C_chrom_SNP_data_ratios','C_chrom_count'
	% parent data: 'P_chrom_SNP_data_positions','P_chrom_SNP_data_ratios','P_chrom_count'
	%   
	% C_chrom_SNP_data_positions = coordinate of SNP.
	% C_chrom_SNP_data_ratios    = allelic ratio of SNP.
	% C_chrom_count              = number of reads at SNP coordinate.
end;


%%================================================================================================
% Save workspace variables for use in "allelic_ratios_ddRADseq_D.m"
%-------------------------------------------------------------------------------------------------
save([projectDir 'allelic_ratios_ddRADseq_B.workspace_variables.mat']);


%% =================================================================================================
% Calculate allelic fraction cutoffs for each segment.
%...................................................................................................
% Populate data structure containing SNP phasing information.
% if (useHapmap)
%	chrom_SNPdata{chrom,1}{chrom_bin} = phased SNP ratio data.
%	chrom_SNPdata{chrom,2}{chrom_bin} = unphased SNP ratio data.
%	chrom_SNPdata{chrom,3}{chrom_bin} = phased SNP position data.
%	chrom_SNPdata{chrom,4}{chrom_bin} = unphased SNP position data.
%	chrom_SNPdata{chrom,5}{chrom_bin} = flipper value for phased SNP.
%	chrom_SNPdata{chrom,6}{chrom_bin} = flipper value for unphased SNP.
% elseif (useParent)
%       chrom_SNPdata{chrom,1}{chrom_bin} = child SNP ratio data.
%       chrom_SNPdata{chrom,2}{chrom_bin} = parent SNP ratio data.
%       chrom_SNPdata{chrom,3}{chrom_bin} = child SNP position data.
%       chrom_SNPdata{chrom,4}{chrom_bin} = parent SNP position data.
% else
%       chrom_SNPdata{chrom,2}{chrom_bin} = child SNP ratio data.
%       chrom_SNPdata{chrom,4}{chrom_bin} = child SNP position data.
% end;
%---------------------------------------------------------------------------------------------------
calculate_allelic_ratio_cutoffs;


%%================================================================================================
% Process SNP/LOH data.
%-------------------------------------------------------------------------------------------------
if (useHapmap)
	alleleRatiosFid = openAlleleRatiosTrack(projectDir, project);

	%% =========================================================================================
	% Define new colors for SNPs, using Gaussian fitting crossover points as ratio cutoffs.
	%-------------------------------------------------------------------------------------------
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			chromName = chrom_name{chrom};
			if (length(C_chrom_count{chrom}) > 1)
				%
				% Determining colors for each SNP coordinate from calculated cutoffs.
				%
				for SNP = 1:length(C_chrom_SNP_data_positions{chrom})  % 'length(C_chrom_SNP_data_positions)' is the number of SNPs per chromosome.
					coordinate                      = C_chrom_SNP_data_positions{chrom}(SNP);
					chrom_bin                         = ceil(coordinate/new_bases_per_bin);
					localCopyEstimate               = round(CNVplot2{chrom}(chrom_bin)*ploidy*ploidyAdjust);
					baseCall                        = C_chrom_baseCall{        chrom}{SNP};
					homologA                        = C_chrom_SNP_homologA{    chrom}{SNP};
					homologB                        = C_chrom_SNP_homologB{    chrom}{SNP};
					flipper                         = C_chrom_SNP_flipHomologs{chrom}(SNP);
					allelic_ratio                   = C_chrom_SNP_data_ratios{ chrom}(SNP);
					if (flipper == 1)
						temp                    = homologA;
						homologA                = homologB;
						homologB                = temp;
						if (baseCall == homologA)
							allelic_ratio   = 1-allelic_ratio;
						end;
					elseif (flipper == 0)
						if (baseCall == homologA)
							allelic_ratio   = 1-allelic_ratio;
						end;
					else
						% Variable 'flipper' value of '10' indicates no phasing information is available in the hapmap.
						% Variable 'baseCall' value of 'Z' will prevent either hapmap allele from matching and so unphased ratio colors will be used in the following sections.
						baseCall                = 'Z';
					end;


					% identify the segment containing the SNP.
					segmentID                       = 0;
					for segment = 1:(length(chromCopyNum{chrom}))
						segment_start           = chrom_breaks{chrom}(segment  )*chrom_size(chrom);
						segment_end             = chrom_breaks{chrom}(segment+1)*chrom_size(chrom);
						if (coordinate > segment_start) && (coordinate <= segment_end)
							segmentID       = segment;
						end;
					end;


					% Load cutoffs between Gaussian fits performed earlier.
					segment_copyNum                 = round(chromCopyNum{              chrom}(segmentID));
					actual_cutoffs                  = chromSegment_actual_cutoffs{     chrom}{segmentID};
					mostLikelyGaussians             = chromSegment_mostLikelyGaussians{chrom}{segmentID};


					% Calculate allelic ratio on range of [1..200].
					SNPratio_int                    = (allelic_ratio)*199+1;


					% Identify the allelic ratio region containing the SNP.
					cutoffs                         = [1 actual_cutoffs 200];
					ratioRegionID                   = 0;
					for GaussianRegionID = 1:length(mostLikelyGaussians)
						cutoff_start            = cutoffs(GaussianRegionID  );
						cutoff_end              = cutoffs(GaussianRegionID+1);
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


					if (segment_copyNum <= 0);                          colorList = colorNoData;
					elseif (segment_copyNum == 1)
						% allelic fraction cutoffs: [0.50000] => [A B]
						if ((baseCall == homologA) || (baseCall == homologB))
							if (ratioRegionID == 2);            colorList = colorB;
							else                                colorList = colorA;
							end;
						else
							if (useHapmap || useParent)         colorList = unphased_color_1of1;
							else                                colorList = noparent_color_1of1;
							end;
						end;
					elseif (segment_copyNum == 2)
						%   allelic fraction cutoffs: [0.25000 0.75000] => [AA AB BB]
						%   cutoffs_1 from Gaussian fittings = [0.18342 0.19347 0.18844 0.16332 0.16332 0.15327 0.12814] => 0.1676;
						%   cutoffs_2 from Gaussian fittings = [0.82663 0.82161 0.80151 0.84171 0.83668 0.84673 0.84673] => 0.8317;
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
								else                            colorList = noparent_color_2of2;
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
								elseif (ratioRegionID == 5);    colorList = nopanret_color_4of6;
								elseif (ratioRegionID == 4);    colorList = nopanret_color_3of6;
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
					chrom_SNPdata_colorsC{chrom,1}(chrom_bin) = chrom_SNPdata_colorsC{chrom,1}(chrom_bin) + colorList(1);
					chrom_SNPdata_colorsC{chrom,2}(chrom_bin) = chrom_SNPdata_colorsC{chrom,2}(chrom_bin) + colorList(2);
					chrom_SNPdata_colorsC{chrom,3}(chrom_bin) = chrom_SNPdata_colorsC{chrom,3}(chrom_bin) + colorList(3);
					chrom_SNPdata_countC{ chrom  }(chrom_bin) = chrom_SNPdata_countC{ chrom  }(chrom_bin) + 1;

                    if (~all(colorList == colorNoData))
						writeAlleleRatioLine(alleleRatiosFid, chromName, coordinate, ...
							homologA, homologB, ...
							colorList);
					end

					% Troubleshooting output.
					% fprintf(['chrom = ' num2str(chrom) '; seg = ' num2str(segment) '; bin = ' num2str(chrom_bin) '; ratioRegionID = ' num2str(ratioRegionID) '\n']);
				end;
			end;
		end;
	end;

	%%
	%% Average colors per standard genome gin.
	%%
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			if (length(C_chrom_count{chrom}) > 1)
				for chrom_bin = 1:length(chrom_SNPdata_countC{chrom})
					if (chrom_SNPdata_countC{chrom}(chrom_bin) > 0)
						chrom_SNPdata_colorsC{chrom,1}(chrom_bin) = chrom_SNPdata_colorsC{chrom,1}(chrom_bin)/chrom_SNPdata_countC{chrom}(chrom_bin);
						chrom_SNPdata_colorsC{chrom,2}(chrom_bin) = chrom_SNPdata_colorsC{chrom,2}(chrom_bin)/chrom_SNPdata_countC{chrom}(chrom_bin);
						chrom_SNPdata_colorsC{chrom,3}(chrom_bin) = chrom_SNPdata_colorsC{chrom,3}(chrom_bin)/chrom_SNPdata_countC{chrom}(chrom_bin);
					else
						chrom_SNPdata_colorsC{chrom,1}(chrom_bin) = 1.0;
						chrom_SNPdata_colorsC{chrom,2}(chrom_bin) = 1.0;
						chrom_SNPdata_colorsC{chrom,3}(chrom_bin) = 1.0;
					end;
				end;
			end;
		end;
	end;
    fclose(alleleRatiosFid);
elseif (useParent)
	% Initialize values for display.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			for chrom_bin = 1:length(chrom_SNPdata_countC{chrom})
				colorList                       = [1.0 1.0 1.0];
				chrom_SNPdata_colorsC{chrom,1}(chrom_bin) = colorList(1);
				chrom_SNPdata_colorsC{chrom,2}(chrom_bin) = colorList(2);
				chrom_SNPdata_colorsC{chrom,3}(chrom_bin) = colorList(3);

				colorList                       = [1.0 1.0 1.0];
				chrom_SNPdata_colorsP{chrom,1}(chrom_bin) = colorList(1);
				chrom_SNPdata_colorsP{chrom,2}(chrom_bin) = colorList(2);
				chrom_SNPdata_colorsP{chrom,3}(chrom_bin) = colorList(3);
			end;
		end;
	end;
else
	% Initialize values for display.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			for chrom_bin = 1:length(chrom_SNPdata_countC{chrom})
				colorList                       = [1.0 1.0 1.0];
				chrom_SNPdata_colorsC{chrom,1}(chrom_bin) = colorList(1);
				chrom_SNPdata_colorsC{chrom,2}(chrom_bin) = colorList(2);
				chrom_SNPdata_colorsC{chrom,3}(chrom_bin) = colorList(3);
			end;
		end;
	end;
end;
save([projectDir 'SNP_' SNP_verString '.reduced.mat'],'chrom_SNPdata','new_bases_per_bin','chrom_SNPdata_colorsC','chrom_SNPdata_colorsP');



%%================================================================================================
% Make histogram of data.
%-------------------------------------------------------------------------------------------------
histogram_fig = figure();
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		%   1 : phased SNP ratio data.
		%   2 : unphased SNP ratio data.
		%   3 : phased SNP position data.
		%   4 : unphased SNP position data.
		data_phased   = [];
		data_unphased = [];
		for i = 1:length(chrom_SNPdata{chrom,1})
			data_phased   = [data_phased   chrom_SNPdata{chrom,1}{i}];
		end;
		for i = 1:length(chrom_SNPdata{chrom,2})
			data_unphased = [data_unphased chrom_SNPdata{chrom,2}{i}];
		end;
		if (useHapmap)
		elseif (useParent)
			data_phased   = [data_phased   1-data_phased  ];
			data_unphased = [data_unphased 1-data_unphased];
		else
			data_phased   = [data_phased   1-data_phased  ];
			data_unphased = [data_unphased 1-data_unphased];
		end;
		histogram_phased         = hist([data_phased   0 1],200);
		histogram_unphased       = hist([data_unphased 0 1],200);

		subplot(2,num_chroms,chrom);
		hold on;
		if (useHapmap)
			plot(1:200, log(histogram_unphased+1),  'Color',[1.0 0.0 0.0]);
			plot(1:200, log(histogram_phased+1),    'Color',[1/3 1/3 1/3]);
		else
			plot(1:200, log(histogram_unphased+1),  'Color',[1/3 1/3 1/3]);
			plot(1:200, log(histogram_phased+1),    'Color',[1.0 0.0 0.0]);
		end;
		ylim([0 6]);
		title([chrom_label{chrom}]);
        set(gca,'FontSize',10*(8/num_chroms));
		set(gca,'XTick',[0 50 100 150 200]);
		set(gca,'XTickLabel',{'0','1/4','1/2','3/4','1'});
		ylabel('log(data count)');
		xlabel('allelic ratio');
		hold off;

		subplot(2,num_chroms,chrom+num_chroms);
		hold on;
		if (useHapmap)
			plot(1:200, histogram_unphased,  'Color',[1.0 0.0 0.0]);
			plot(1:200, histogram_phased,    'Color',[1/3 1/3 1/3]);
		else
			plot(1:200, histogram_unphased,  'Color',[1/3 1/3 1/3]);
			plot(1:200, histogram_phased,    'Color',[1.0 0.0 0.0]);
		end;
		ylim([0 200]);
		title([chrom_label{chrom}]);
        set(gca,'FontSize',10*(8/num_chroms));
		set(gca,'XTick',[0 50 100 150 200]);
		set(gca,'XTickLabel',{'0','1/4','1/2','3/4','1'});
		ylabel('data count');
		xlabel('allelic ratio');
		hold off;
	end;
end;
set(histogram_fig,'PaperPosition',[0 0 8*(num_chroms/8)^2 1.5*(num_chroms/8)]*4);
%saveas(histogram_fig, [projectDir 'fig.allelic_fraction_histogram.' figVer 'eps'], 'epsc');
saveas(histogram_fig, [projectDir 'fig.allelic_fraction_histogram.' figVer 'png'], 'png');
delete(histogram_fig);


%%================================================================================================
% Setup for main figure generation.
%-------------------------------------------------------------------------------------------------
% load size definitions
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

fig = figure(1);
largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


%%================================================================================================
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------------
if (Linear_display == true)
	Linear_fig = figure(2);
	Linear_genome_size   = sum(chrom_size);
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
	maxY                 = 1; % ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


%%================================================================================================
% Make figures
%-------------------------------------------------------------------------------------------------
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
		figure(fig);
		% make standard chrom cartoons.
		left   = chrom_posX(chrom);
		bottom = chrom_posY(chrom);
		width  = chrom_width(chrom);
		height = chrom_height(chrom);
		subplot('Position',[left bottom width height]);
		hold on;
		fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);

		% standard : axes labels etc.
		xlim([0,chrom_size(chrom)/bases_per_bin]);

		%% standard : modify y axis limits to show annotation locations if any are provided.
		if (length(annotations) > 0)
			ylim([-maxY/10*1.5,maxY]);
		else
			ylim([0,maxY]);
		end;
		set(gca,'YTick',[]);
		set(gca,'YTickLabel',[]);
		set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
		if (chrom_figReversed(chrom) == 0)
			text(-50000/5000/2*3, maxY/2,chrom_label{chrom}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
		else
			text(-50000/5000/2*3, maxY/2,[chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)'], 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
		end;
		set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
		set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

		% standard : This section sets the Y-axis labelling.
		axisLabelPosition = -50000/bases_per_bin;
		set(gca,'FontSize',12);
		if (chrom == find(chrom_posY == max(chrom_posY)))
			Linear_base = 0.1;
			title([ project ' allelic fraction map'],'Interpreter','none','FontSize',stacked_title_size);
		end;
		% standard : end axes labels etc.


		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chrom_figReversed(chrom) == 1)
			chrom_SNPdata_colorsC{chrom,1} = fliplr(chrom_SNPdata_colorsC{chrom,1});
			chrom_SNPdata_colorsC{chrom,2} = fliplr(chrom_SNPdata_colorsC{chrom,2});
			chrom_SNPdata_colorsC{chrom,3} = fliplr(chrom_SNPdata_colorsC{chrom,3});
			chrom_SNPdata{chrom,1}         = fliplr(chrom_SNPdata{chrom,1});
			chrom_SNPdata{chrom,2}         = fliplr(chrom_SNPdata{chrom,2});
			chrom_SNPdata{chrom,3}         = fliplr(chrom_SNPdata{chrom,3});
			chrom_SNPdata{chrom,4}         = fliplr(chrom_SNPdata{chrom,4});
		end;


		% standard : draw colorbars.
		if (useHapmap)   % an experimental dataset vs. a hapmap.
			for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
				snpColorR = chrom_SNPdata_colorsC{chrom,1}(chrom_bin);
				snpColorG = chrom_SNPdata_colorsC{chrom,2}(chrom_bin);
				snpColorB = chrom_SNPdata_colorsC{chrom,3}(chrom_bin);
				if (snpColorR <= 1) || (snpColorG <= 1) || (snpColorB <= 1)
					plot([chrom_bin chrom_bin], [0 maxY],'Color',[snpColorR snpColorG snpColorB]);
				end;
			end;
		% Following variation will draw experimetnal vs. reference dataset like the above vs. hapmap figure.
		%	elseif (useParent)   % an experimental dataset vs. a reference dataset.
		%		for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
		%			snpColorR   = chrom_SNPdata_colorsP{chrom,1}(chrom_bin);
		%			snpColorG   = chrom_SNPdata_colorsP{chrom,2}(chrom_bin);
		%			snpColorB   = chrom_SNPdata_colorsP{chrom,3}(chrom_bin);
		%			if (snpColorR <= 1) || (snpColorG <= 1) || (snpColorB <= 1)
		%				plot([chrom_bin chrom_bin], [0 maxY],'Color',[snpColorR snpColorG snpColorB]);
		%			end;
		%		end;
		elseif (useParent)   % an experimental dataset vs. a reference dataset.
			for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
				%       chrom_SNPdata{chrom,1}{chrom_bin} = child SNP ratio data.
				%       chrom_SNPdata{chrom,2}{chrom_bin} = parent SNP ratio data.
				%       chrom_SNPdata{chrom,3}{chrom_bin} = child SNP position data.
				%       chrom_SNPdata{chrom,4}{chrom_bin} = parent SNP position data.

				bin_data_C              = chrom_SNPdata{chrom,1}{chrom_bin};
				for SNP = 1:length(bin_data_C)
					bin_data_C(SNP) = bin_data_C(SNP);
				end;
				allelic_ratio_C         = min(bin_data_C);
				datumY_C                = allelic_ratio_C*maxY;
				plot([chrom_bin/2 chrom_bin/2], [maxY datumY_C     ],'Color',hom_color);

				bin_data_P              = chrom_SNPdata{chrom,2}{chrom_bin};
				for SNP = 1:length(bin_data_P)
					bin_data_P(SNP) = bin_data_P(SNP);
				end;
				allelic_ratio_P         = min(bin_data_P);
				datumY_P                = allelic_ratio_P*maxY;
				plot([chrom_bin/2 chrom_bin/2], [0    maxY-datumY_P],'Color',het_color);
			end;
		else   % only an experimental dataset.
			for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
				%       chrom_SNPdata{chrom,1}{chrom_bin} = SNP ratio data.
				%       chrom_SNPdata{chrom,3}{chrom_bin} = SNP position data.

				bin_data = chrom_SNPdata{chrom,1}{chrom_bin};
				for SNP = 1:length(bin_data)
					bin_data(SNP) = max(bin_data(SNP), 1-bin_data(SNP));
				end;
				allelic_ratio = min(bin_data);
				datumY_C = allelic_ratio*maxY;
				plot([chrom_bin/2 chrom_bin/2], [maxY datumY_C     ],'Color',het_color);
				plot([chrom_bin/2 chrom_bin/2], [0    maxY-datumY_C],'Color',het_color);
			end;
		end;
		% standard : end draw colorbars.


		if (displayBREAKS == true) && (show_annotations == true)
			chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
			for segment = 2:length(chrom_breaks{chrom})-1
				bP = chrom_breaks{chrom}(segment)*chrom_length;
				plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
			end;
		end;

		% standard : show centromere outlines and horizontal marks.
		x1 = cen_start(chrom)/bases_per_bin;
		x2 = cen_end(chrom)/bases_per_bin;
		leftEnd  = 0.5*5000/bases_per_bin;
		rightEnd = (chrom_size(chrom) - 0.5*5000)/bases_per_bin;

		if (Centromere_format == 0)
			% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
			dx = cen_tel_Xindent; %5*5000/bases_per_bin;
			dy = cen_tel_Yindent; %maxY/10;
			% draw white triangles at corners and centromere locations.
			% top left corner.
			c_ = [1.0 1.0 1.0];
			x_ = [leftEnd   leftEnd   leftEnd+dx];
			y_ = [maxY-dy   maxY      maxY      ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% bottom left corner.
			x_ = [leftEnd   leftEnd   leftEnd+dx];
			y_ = [dy        0         0         ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% top right corner.
			x_ = [rightEnd   rightEnd   rightEnd-dx];
			y_ = [maxY-dy    maxY       maxY      ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% bottom right corner.
			x_ = [rightEnd   rightEnd   rightEnd-dx];
			y_ = [dy         0          0         ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% top centromere.
			x_ = [x1-dx   x1        x2        x2+dx];
			y_ = [maxY    maxY-dy   maxY-dy   maxY];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% bottom centromere.
			x_ = [x1-dx   x1   x2   x2+dx];
			y_ = [0       dy   dy   0    ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
			plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
			     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy     ],...
			     'Color',[0 0 0]);
		end;
		% standard : end show centromere.

		% standard : show annotation locations
		if (show_annotations) && (length(annotations) > 0)
			plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
			annotation_location = (annotation_start+annotation_end)./2;
			for annoteID = 1:length(annotation_location)
				if (annotation_chrom(annoteID) == chrom)
					annotationloc = annotation_location(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
					annotationStart = annotation_start(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
					annotationEnd   = annotation_end(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
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
		end;
		% standard : end show annotation locations.


		%% =========================================================================================
		% Draw angleplots to left of main chromosome cartoons.
		%-------------------------------------------------------------------------------------------
		apply_phasing = true;
		angle_plot_subfigures;


%%%%%%%%%%%%%%%% Linear figure draw section.


		%% Linear figure draw section
		if (Linear_display == true)
			figure(Linear_fig);
			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			hold on;
			Linear_left = Linear_left + Linear_width + Linear_chrom_gap;

			% linear : draw colorbars
			if (useHapmap)   % an experimental dataset vs. a hapmap.
				for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
					snpColorR   = chrom_SNPdata_colorsC{chrom,1}(chrom_bin);
					snpColorG   = chrom_SNPdata_colorsC{chrom,2}(chrom_bin);
					snpColorB   = chrom_SNPdata_colorsC{chrom,3}(chrom_bin);
					if (snpColorR < 1) || (snpColorG < 1) || (snpColorB < 1)
						plot([chrom_bin chrom_bin], [0 maxY],'Color',[snpColorR snpColorG snpColorB]);
					end;
				end;
			% Following variation will draw experimetnal vs. reference dataset like the above vs. hapmap figure.
			%	elseif (useParent)   % an experimental dataset vs. a reference dataset.
			%		for i = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
			%			snpColorR   = chrom_SNPdata_colorsC{chrom,1}(chrom_bin);
			%			snpColorG   = chrom_SNPdata_colorsC{chrom,2}(chrom_bin);
			%			snpColorB   = chrom_SNPdata_colorsC{chrom,3}(chrom_bin);
			%			if (snpColorR < 1) || (snpColorG < 1) || (snpColorB < 1)
			%				plot([i i], [0 maxY],'Color',[snpColorR snpColorG snpColorB]);
			%			end;
			%		end;
			elseif (useParent)   % an experimental dataset vs. a reference dataset.
				for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
					%       chrom_SNPdata{chrom,1}{chrom_bin} = child SNP ratio data.
					%       chrom_SNPdata{chrom,2}{chrom_bin} = parent SNP ratio data.
					%       chrom_SNPdata{chrom,3}{chrom_bin} = child SNP position data.
					%       chrom_SNPdata{chrom,4}{chrom_bin} = parent SNP position data.

					bin_data_C              = chrom_SNPdata{chrom,1}{chrom_bin};
					for SNP = 1:length(bin_data_C)
						bin_data_C(SNP) = bin_data_C(SNP);
					end;
					allelic_ratio_C         = min(bin_data_C);
					datumY_C                = allelic_ratio_C*maxY;
					plot([chrom_bin/2 chrom_bin/2], [maxY datumY_C     ],'Color',hom_color);

					bin_data_P              = chrom_SNPdata{chrom,2}{chrom_bin};
					for SNP = 1:length(bin_data_P)
						bin_data_P(SNP) = bin_data_P(SNP);
					end;
					allelic_ratio_P         = min(bin_data_P);
					datumY_P                = allelic_ratio_P*maxY;
					plot([chrom_bin/2 chrom_bin/2], [0    maxY-datumY_P],'Color',het_color);
				end;
			else   % only an experimental dataset.
				for chrom_bin = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
					%       chrom_SNPdata{chrom,2}{chrom_bin} = SNP ratio data.
					%       chrom_SNPdata{chrom,4}{chrom_bin} = SNP position data.

					bin_data = chrom_SNPdata{chrom,2}{chrom_bin};
					for SNP = 1:length(bin_data)
						bin_data(SNP) = max(bin_data(SNP), 1-bin_data(SNP));
					end;
					allelic_ratio = min(bin_data);
					datumY_C = allelic_ratio*maxY;
					plot([chrom_bin/2 chrom_bin/2], [maxY datumY_C     ],'Color',het_color);
					plot([chrom_bin/2 chrom_bin/2], [0    maxY-datumY_C],'Color',het_color);
				end;
			end;
			% linear : end draw colorbars.


			if (Linear_displayBREAKS == true) && (show_annotations == true)
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
                                for segment = 2:length(chrom_breaks{chrom})-1
                                        bP = chrom_breaks{chrom}(segment)*chrom_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;

			% linear : show centromere.
			x1 = cen_start(chrom)/bases_per_bin;
			x2 = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0.5*5000/bases_per_bin;
			rightEnd = (chrom_size(chrom) - 0.5*5000)/bases_per_bin;

			if (Centromere_format == 0)
				% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
				dx = cen_tel_Xindent; %5*5000/bases_per_bin;
				dy = cen_tel_Yindent; %maxY/10;
				% draw white triangles at corners and centromere locations.
				c_ = [1.0 1.0 1.0];
				% top left corner.
				x_ = [leftEnd   leftEnd   leftEnd+dx];        y_ = [maxY-dy   maxY      maxY        ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% bottom left corner.
				x_ = [leftEnd   leftEnd   leftEnd+dx];        y_ = [dy        0         0           ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% top right corner.
				x_ = [rightEnd   rightEnd   rightEnd-dx];     y_ = [maxY-dy    maxY       maxY      ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% bottom right corner.
				x_ = [rightEnd   rightEnd   rightEnd-dx];     y_ = [dy         0          0         ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% top centromere.
				x_ = [x1-dx   x1        x2        x2+dx];     y_ = [maxY    maxY-dy   maxY-dy   maxY];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% bottom centromere.
				x_ = [x1-dx   x1   x2   x2+dx];               y_ = [0       dy   dy   0    ];             f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
				plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
				     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy],...
				      'Color',[0 0 0]);
			end;
			% linear : end show centromere.

			% linear : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
				plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
				annotation_location = (annotation_start+annotation_end)./2;
				for annoteID = 1:length(annotation_location)
					if (annotation_chrom(annoteID) == chrom)
						annotationloc = annotation_location(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationStart = annotation_start(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
						annotationEnd   = annotation_end(annoteID)/bases_per_bin-0.5*(5000/bases_per_bin);
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
			set(gca,'FontSize',linear_gca_font_size);
			% linear : end final reformatting.

			% note: adding title is done in the end since if placed upper
			% in the code somehow the plot function changes the title position
			% adding title in the middle of the cartoon
			if (rotate == 0 && chrom_size(chrom) ~= 0 )
				if (chrom_figReversed(chrom) == 0)
					title(chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
					title([chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)'],'Interpreter','tex','FontSize',linear_chrom_font_size,'Rotation',rotate);
				end;
			else
				if (chrom_figReversed(chrom) == 0)
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
					text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,[chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)'],'Interpreter','tex','FontSize',linear_chrom_font_size,'Rotation',rotate);
				end;
			end;

			hold off;

			% shift back to main figure generation.
			figure(fig);
			first_chrom = false;
		end;
	end;
end;

%% Save figures.
set(fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
%saveas(fig,        [projectDir 'fig.allelic_ratio-map.c1.' figVer 'eps'], 'epsc');
saveas(fig,        [projectDir 'fig.allelic_ratio-map.c1.' figVer 'png'], 'png');
delete(fig);

set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
%saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.c2.' figVer 'eps'], 'epsc');
saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.c2.' figVer 'png'], 'png');
delete(Linear_fig);

%%================================================================================================
% end stuff
%=================================================================================================
end

