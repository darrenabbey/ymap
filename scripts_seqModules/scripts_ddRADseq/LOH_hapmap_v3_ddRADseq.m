function [] = LOH_hapmap_v3_ddRADseq(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString, ...
                                     SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

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


%% ========================================================================
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


%%=========================================================================
% Load FASTA file name from 'reference.txt' file for project.
%--------------------------------------------------------------------------
userReference    = [main_dir 'users/' user '/genomes/' genome '/reference.txt'];
defaultReference = [main_dir 'users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string = strtrim(fileread(defaultReference));
else
	FASTA_string = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%=========================================================================
% Control variables for Candida albicans SC5314.
%--------------------------------------------------------------------------
projectDir  = [main_dir 'users/' user '/projects/' project '/'];

if (exist([[main_dir 'users/default/hapmaps/' hapmap '/']],'dir') == 7)
	hapmapDir = [main_dir 'users/default/hapmaps/' hapmap '/'];
elseif (exist([[main_dir 'users/' user '/hapmaps/' hapmap '/']],'dir') == 7)
	hapmapDir = [main_dir 'users/' user '/hapmaps/' hapmap '/'];
else
	hapmapDir = [main_dir 'users/' user '/projects/' project '/'];
end;

genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];


[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[Aneuploidy]                                                          = Load_dataset_information(projectDir);

num_chroms = length(chrom_sizes);

for i = 1:length(chrom_sizes)
	chrom_size(i)  = 0;
	cen_start(i) = 0;
	cen_end(i)   = 0;
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
num_chroms = length(chrom_size);

%% This block is normally calculated in FindChromSizes_4 in CNV analysis.
for usedchrom = 1:num_chroms
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


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

% Sanitize user input of euploid state.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
bases_per_bin    = max(chrom_size)/700;
maxY             = ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/5;

%define colors for colorBars plot
colorNoData = [1.0   1.0   1.0  ]; %used when no data is available for the bin.
colorInit   = [0.5   0.5   0.5  ]; %external; used in blending at ends of chrom.
colorHET    = [0.0   0.0   0.0  ]; % near 1:1 ratio SNPs
colorOddHET = [0.0   1.0   0.0  ]; % Het, but not near 1:1 ratio SNPs.
colorHOM    = [1.0   0.0   0.0  ]; % Hom SNPs;

colorAB     = [0.667 0.667 0.667]; % heterozygous.
colorA      = [1.0   0.0   1.0  ]; % homozygous a:magenta.
colorB      = [0.0   1.0   1.0  ]; % homozygous b:cyan.

fprintf(['\nGenerating LOH-map figure from ''' project ''' vs. (hapmap)''' hapmap ''' data.\n']);

% Initializes vectors used to hold copy number data.
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		% 1 category tracked : average read counts per bin.
		chrom_CNVdata{chrom} = zeros(1,ceil(chrom_size(chrom)/bases_per_bin));
		% fprintf(['0|' num2str(chrom) ':' num2str(length(chrom_CNVdata{chrom})) '\n']);
	end;
end;

% Initializes vectors used to hold number of SNPs in each interpretation catagory for each chromosome region.
for chrom = 1:length(chrom_sizes)
	% 4 SNP interpretation catagories tracked.
	%	1 : phased ratio data.
	%	2 : unphased ratio data.
	%   3 : phased coordinate data.
	%   4 : unphased coordinate data.
	chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
	for j = 1:4
		chrom_SNPdata{chrom,j} = cell(1,chrom_length);
	end;
	% fprintf(['0|' num2str(chrom) ':' num2str(length(chrom_SNPdata{chrom,1})) '\n']);
end;


%%================================================================================================
% Load SNP/LOH data.
%-------------------------------------------------------------------------------------------------
if (exist([projectDir 'SNP_' SNP_verString '.mat'],'file') == 0)
	fprintf('\nMAT file not found, regenerating.\n');
	datafile = [projectDir 'preprocessed_SNPs.ddRADseq.txt'];
	data     = fopen(datafile, 'r');
	lines_analyzed = 0;
	while not (feof(data))
		dataLine = fgetl(data);
		if (length(dataLine) > 0)
			if (dataLine(1) ~= '#')
				% process the loaded line into data channels.
				lines_analyzed              = lines_analyzed+1;
				chrom_num                     = sscanf(dataLine, '%s',1);
				fragment_start              = sscanf(dataLine, '%s',2);   for i = 1:size(sscanf(dataLine,'%s',1),2);   fragment_start(1)              = [];   end;
				fragment_end                = sscanf(dataLine, '%s',3);   for i = 1:size(sscanf(dataLine,'%s',2),2);   fragment_end(1)                = [];   end;
				phased_data_string          = sscanf(dataLine, '%s',4);   for i = 1:size(sscanf(dataLine,'%s',3),2);   phased_data_string(1)          = [];   end;
				unphased_data_string        = sscanf(dataLine, '%s',5);   for i = 1:size(sscanf(dataLine,'%s',4),2);   unphased_data_string(1)        = [];   end;
				phased_coordinates_string   = sscanf(dataLine, '%s',6);   for i = 1:size(sscanf(dataLine,'%s',5),2);   phased_coordinates_string(1)   = [];   end;
				unphased_coordinates_string = sscanf(dataLine, '%s',7);   for i = 1:size(sscanf(dataLine,'%s',6),2);   unphased_coordinates_string(1) = [];   end;

				% format = simple, one number per column.
				chrom_num                     = str2num(chrom_num);
				fragment_start              = str2num(fragment_start);
				fragment_end                = str2num(fragment_end);
				chrom_length                  = ceil(chrom_size(chrom_num)/bases_per_bin);
				chrom_bin                     = ceil(fragment_start/bases_per_bin);
				% fprintf(['chrom_num' num2str(chrom_num) '|chrom_bin = ' num2str(chrom_bin) '\n']);

				% format = '(number1,number2,...,numberN)'
				phased_data_string(1)       = [];
				phased_data_string(end)     = [];
				if (length(phased_data_string) == 0)
					phased_data             = [];
				else
					commaCount              = length(find(phased_data_string==','));
					if (commaCount == 0)
						phased_data         = str2num(phased_data_string);
					else
						phased_data         = strsplit(phased_data_string,',');   % function converts number lists from strings to numbers.
					end;
				end;

				% format = '(number1,number2,...,numberN)'
				phased_coordinates_string(1)           = [];
				phased_coordinates_string(end)         = [];
				if (length(phased_coordinates_string) == 0)
					phased_coordinates             = [];
				else
					commaCount              = length(find(phased_coordinates_string==','));
					if (commaCount == 0)
						phased_coordinates         = str2num(phased_coordinates_string);
					else
						phased_coordinates         = strsplit(phased_coordinates_string,',');   % function converts number lists from strings to numbers.
					end;
				end;

				% format = '(number1,number2,...,numberN)'
				unphased_data_string(1)     = [];
				unphased_data_string(end)   = [];
				if (length(unphased_data_string) == 0)
					unphased_data           = [];
				else
					commaCount              = length(find(unphased_data_string==','));
					if (commaCount == 0)
						unphased_data       = str2num(unphased_data_string);
					else
						unphased_data       = strsplit(unphased_data_string,',');  % function converts number lists from strings to numbers.
					end;
				end;

				% format = '(number1,number2,...,numberN)'
				unphased_coordinates_string(1)       = [];
				unphased_coordinates_string(end)     = [];
				if (length(unphased_coordinates_string) == 0)
					unphased_coordinates             = [];
				else
					commaCount              = length(find(unphased_coordinates_string==','));
					if (commaCount == 0)
						unphased_coordinates         = str2num(unphased_coordinates_string);
					else
						unphased_coordinates         = strsplit(unphased_coordinates_string,',');   % function converts number lists from strings to numbers.
					end;
				end;

				% add phased and unphased data to storage arrays.
				chrom_SNPdata{chrom_num,1}{chrom_bin} = phased_data;
				chrom_SNPdata{chrom_num,2}{chrom_bin} = unphased_data;

				% add phased and unphased data coordinates to storage arrays.
				chrom_SNPdata{chrom_num,3}{chrom_bin} = phased_coordinates;
				chrom_SNPdata{chrom_num,4}{chrom_bin} = unphased_coordinates;

				% fprintf(['chrom' num2str(chrom_num) '|chrom_bin = ' num2str(chrom_bin) '|' num2str(length(chrom_SNPdata{chrom_num,1})) '\n']);
			end;
		end;
	end;
	fclose(data);

	save([projectDir 'SNP_' SNP_verString '.mat'],'chrom_SNPdata');
else
	fprintf('\nMAT file found, loading.\n');
	load([projectDir 'SNP_' SNP_verString '.mat']);
end;


%% -----------------------------------------------------------------------------------------
% Setup for figure generation.
%-------------------------------------------------------------------------------------------
fig = figure(1);
set(gcf, 'Position', [0 70 1024 600]);

% calculate SNP bin values.
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		for chrom_bin = 1:length(chrom_SNPdata{chrom,1})
			SNPplot{chrom,1}{chrom_bin} = chrom_SNPdata{chrom,1}{chrom_bin};
			SNPplot{chrom,2}{chrom_bin} = chrom_SNPdata{chrom,2}{chrom_bin};
		end;
	end;
end;

%% Gather total SNP data counts per bin : not used...?
SNPdata_all = [];
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		for chrom_bin = 1:length(SNPplot{chrom,1})
			TOTplot{chrom}{chrom_bin} = length(chrom_SNPdata{chrom,1}{chrom_bin}) + length(chrom_SNPdata{chrom,2}{chrom_bin});   % TOT = phased+nonphased;
			SNPdata_all           = [SNPdata_all TOTplot{chrom}{chrom_bin}];
		end;
	end;
end;
medianRawY = median(SNPdata_all);

%% Gather median-normalized SNP data for LOWESS fitting : not used...?
SNPdata_all = [];
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		for chrom_bin = 1:length(SNPplot{chrom,1})
			TOTplot{chrom}{chrom_bin} = length(chrom_SNPdata{chrom,1}{chrom_bin}/medianRawY) + length(chrom_SNPdata{chrom,2}{chrom_bin}/medianRawY);   % TOT = phased+nonphased;
			SNPdata_all           = [SNPdata_all TOTplot{chrom}{chrom_bin}];
		end;
	end;
end;


%% ====================================================================
% Apply GC bias correction to SNP data.
%   Number of putative SNPs vs. GCbias per standard bin.
%----------------------------------------------------------------------
% Load standard bin GC_bias data from : standard_bins.GC_ratios.txt
fprintf(['standard_bins_GC_ratios_file :\n\t' main_dir 'users/' genomeUser '/genomes/' genome '/' FastaName '.GC_ratios.standard_bins.txt\n']);
standard_bins_GC_ratios_fid = fopen([main_dir 'users/' genomeUser '/genomes/' genome '/' FastaName '.GC_ratios.standard_bins.txt'], 'r');
fprintf(['\t' num2str(standard_bins_GC_ratios_fid) '\n']);
lines_analyzed = 0;
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		chrom_GCratioData{chrom} = zeros(1,ceil(chrom_size(chrom)/bases_per_bin));
	end;
end;
while not (feof(standard_bins_GC_ratios_fid))
	dataLine = fgetl(standard_bins_GC_ratios_fid);
	if (length(dataLine) > 0)
		if (dataLine(1) ~= '#')
			lines_analyzed = lines_analyzed+1;
			chrom            = str2num(sscanf(dataLine, '%s',1));
			fragment_start = sscanf(dataLine, '%s',2);  for i = 1:size(sscanf(dataLine,'%s',1),2);      fragment_start(1) = []; end;    fragment_start = str2num(fragment_start);
			fragment_end   = sscanf(dataLine, '%s',3);  for i = 1:size(sscanf(dataLine,'%s',2),2);      fragment_end(1) = [];   end;    fragment_end   = str2num(fragment_end);
			GCratio        = sscanf(dataLine, '%s',4);  for i = 1:size(sscanf(dataLine,'%s',3),2);      GCratio(1) = [];        end;    GCratio        = str2num(GCratio);
			position       = ceil(fragment_start/bases_per_bin);
			chrom_GCratioData{chrom}(position) = GCratio;
		end;
	end;
end;
fclose(standard_bins_GC_ratios_fid);


% Gather SNP and GCratio data for LOWESS fitting.
GCratioData_all = [];
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		GCratioData_all = [GCratioData_all chrom_GCratioData{chrom}];
	end;
end;
medianRawY = median(SNPdata_all);
fprintf(['medianRawY = ' num2str(medianRawY) '\n']);
fprintf(['SNPdata_all     => ' num2str(length(SNPdata_all)    ) '\n']);
fprintf(['GCratioData_all => ' num2str(length(GCratioData_all)) '\n']);

%% Clean up data by:
%%    deleting GC ratio data near zero.
%%    deleting CGH data beyond 3* the median value.  (rDNA, etc.)
SNPdata_clean                                            = SNPdata_all;
GCratioData_clean                                        = GCratioData_all;
SNPdata_clean(     GCratioData_clean < 0.01            ) = [];
GCratioData_clean( GCratioData_clean < 0.01            ) = [];
GCratioData_clean( SNPdata_clean > max(medianRawY*3,3) ) = [];
SNPdata_clean(     SNPdata_clean > max(medianRawY*3,3) ) = [];
GCratioData_clean( SNPdata_clean == 0                  ) = [];
SNPdata_clean(     SNPdata_clean == 0                  ) = [];

% Perform LOWESS fitting of SNP counts vs. GC-content : not used...?
rawData_X1     = GCratioData_clean;
rawData_Y1     = SNPdata_clean;
fprintf(['Lowess X:Y size : [' num2str(size(rawData_X1,1)) ',' num2str(size(rawData_X1,2)) ']:[' num2str(size(rawData_Y1,1)) ',' num2str(size(rawData_Y1,2)) ']\n']);
[fitX1, fitY1] = optimize_mylowess_SNP(rawData_X1,rawData_Y1);

% Correct data using normalization to LOWESS fitting
Y_target = 1;
% Initialize data structures, to simplify debugging.   These nested loops can be deleted without problems arising.
for chrom = 1:num_chroms
	for j = 1:2
		rawData_chrom_Y{chrom,j}        = [];
		normalizedData_chrom_Y{chrom,j} = [];
		rawData_chrom_X{chrom}          = [];
		rawDataAll_chrom_Y{chrom}       = [];
		fitDataAll_chrom_Y{chrom}       = [];
		fitData_chrom_Y{chrom}          = [];
	end;
end;
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		rawData_chrom_X{chrom}           = chrom_GCratioData{chrom};
		rawDataAll_chrom_Y{chrom}        = cell2mat(TOTplot{chrom});
		fitDataAll_chrom_Y{chrom}        = interp1(fitX1,fitY1,rawData_chrom_X{chrom},'spline');
		normalizedDataAll_chrom_Y{chrom} = rawDataAll_chrom_Y{chrom}./fitDataAll_chrom_Y{chrom}*Y_target;
		fitData_chrom_Y{chrom}           = interp1(fitX1,fitY1,rawData_chrom_X{chrom},'spline');

 		for chrom_bin = 1:length(SNPplot{chrom,1})
			rawData_chrom_Y{chrom,1}{chrom_bin}        = length(chrom_SNPdata{chrom,1}{chrom_bin});
			rawData_chrom_Y{chrom,2}{chrom_bin}        = length(chrom_SNPdata{chrom,2}{chrom_bin});

			normalizedData_chrom_Y{chrom,1}{chrom_bin} = length(rawData_chrom_Y{chrom,1}{chrom_bin})./fitData_chrom_Y{chrom}*Y_target;
			normalizedData_chrom_Y{chrom,2}{chrom_bin} = length(rawData_chrom_Y{chrom,2}{chrom_bin})./fitData_chrom_Y{chrom}*Y_target;
		end;
	end;
end;

% Move LOWESS-normalizd SNP data back into display pipeline.
SNPdata_all    = [];
SNPdata_all_1  = [];
SNPdata_all_2  = [];
cSNPdata_all   = [];
cSNPdata_all_1 = [];
cSNPdata_all_2 = [];
GCdata_all     = [];
GCdata_all_1   = [];
GCdata_all_2   = [];
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		TOTplot{chrom}        = rawDataAll_chrom_Y{chrom};
		cTOTplot{chrom}       = normalizedDataAll_chrom_Y{chrom};
		SNPdata_all         = [SNPdata_all    TOTplot{chrom}              ];
		cSNPdata_all        = [cSNPdata_all   cTOTplot{chrom}             ];
		GCdata_all          = [GCdata_all     rawData_chrom_X{chrom}        ];

		for chrom_bin = 1:length(SNPplot{chrom,1})
			cchrom_SNPdata{chrom,1}{chrom_bin} = normalizedData_chrom_Y{chrom,1}{chrom_bin};
			cchrom_SNPdata{chrom,2}{chrom_bin} = normalizedData_chrom_Y{chrom,2}{chrom_bin};
			SNPdata_all_1                = [SNPdata_all_1  length(chrom_SNPdata{chrom,1}{chrom_bin})  ];
			SNPdata_all_2                = [SNPdata_all_2  length(chrom_SNPdata{chrom,2}{chrom_bin})  ];
			cSNPdata_all_1               = [cSNPdata_all_1 length(cchrom_SNPdata{chrom,1}{chrom_bin}) ];
			cSNPdata_all_2               = [cSNPdata_all_2 length(cchrom_SNPdata{chrom,2}{chrom_bin}) ];
		end;
	end;
end;


%% Generate figure showing subplots of LOWESS fittings.
if (false)
	GCfig = figure(3);
	subplot(2,3,1);
	    plot(GCratioData_all,SNPdata_all,'k.','markersize',1);
	    hold on;	plot(fitX1,fitY1,'r','LineWidth',2);   hold off;
	    xlabel('GC ratio');   ylabel('SNP data');
	    xlim([0.0 1.0]);      ylim([0 max(medianRawY*5,5)]);   axis square;
	subplot(2,3,2);
		plot(GCdata_all,SNPdata_all_1,'r.','markersize',1);
		hold on;    plot(fitX1,fitY1,'k','LineWidth',2);   hold off;
		xlabel('GC ratio');   ylabel('SNP data');
		xlim([0.0 1.0]);      ylim([0 max(medianRawY*5,5)]);   axis square;
	subplot(2,3,3);
		plot(GCdata_all,SNPdata_all_2,'g.','markersize',1);
		hold on;    plot(fitX1,fitY1,'k','LineWidth',2);   hold off;
		xlabel('GC ratio');   ylabel('SNP data');
		xlim([0.0 1.0]);      ylim([0 max(medianRawY*5,5)]);   axis square;

	subplot(2,3,4);
		plot(GCratioData_all,cSNPdata_all,'k.','markersize',1);
		hold on;   plot([min(GCratioData_all) max(GCratioData_all)],[Y_target Y_target],'r','LineWidth',2);   hold off;
		xlabel('GC ratio');   ylabel('corrected SNP data');
		xlim([0.0 1.0]);      ylim([0 5]);                    axis square;
	subplot(2,3,5);
		plot(GCdata_all,cSNPdata_all_1,'r.','markersize',1);
		hold on;   plot([min(GCratioData_all) max(GCratioData_all)],[Y_target Y_target],'k','LineWidth',2);   hold off;
		xlabel('GC ratio');   ylabel('corrected SNP data');
		xlim([0.0 1.0]);      ylim([0 5]);                    axis square;
	subplot(2,3,6);
		plot(GCdata_all,cSNPdata_all_1,'g.','markersize',1);
		hold on;   plot([min(GCratioData_all) max(GCratioData_all)],[Y_target Y_target],'k','LineWidth',2);   hold off;
		xlabel('GC ratio');   ylabel('corrected SNP data');
		xlim([0.0 1.0]);      ylim([0 5]);                    axis square;

	saveas(GCfig, [projectDir '/fig.GCratio_vs_SNP.' figVer 'eps'], 'epsc');
	saveas(GCfig, [projectDir '/fig.GCratio_vs_SNP.' figVer 'png'], 'png');
end;


%% -----------------------------------------------------------------------------------------
% Setup for main figure generation.
%------------------------------------------------------------------------------------------
% load size definitions
[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

% threshold for full color saturation in SNP/LOH figure.
% synced to bases_per_bin as below, or defaulted to 50.
full_data_threshold = floor(bases_per_bin/100);

fig = figure(1);
data_mode = 1;
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		if (data_mode == 1)
			for chrom_bin = 1:length(chrom_SNPdata{chrom,1})
				% Regenerate chrom plot data if the save file does not exist.
				SNPs_count{chrom}(chrom_bin)                                     = length(chrom_SNPdata{chrom,1}{chrom_bin}) + length(chrom_SNPdata{chrom,2}{chrom_bin});   % the number of data points in this bin.
				SNPs_to_fullData_ratio{chrom}(chrom_bin)                         = SNPs_count{chrom}(chrom_bin)/full_data_threshold;                                % divide by the threshold for full color saturation in SNP/LOH figure.
				SNPs_to_fullData_ratio{chrom}(SNPs_to_fullData_ratio{chrom} > 1) = 1;                                                                           % any bins with more data than the threshold for full color saturation around limited to full saturation.

				% Number of phased coordinates in bin with non-1.0 allelic fractions.    
				HOMplot{chrom}(chrom_bin)                  = length(chrom_SNPdata{chrom,1}{chrom_bin});         % phased data.
				HOMplot2{chrom}(chrom_bin)                 = HOMplot{chrom}(chrom_bin)/full_data_threshold;   %
				HOMplot2{chrom}(HOMplot2{chrom} > 1)       = 1;                                           %

				% Number of unphased coordinates in bin with non-1.0 allelic fractions.
				HETplot{chrom}(chrom_bin)                  = length(chrom_SNPdata{chrom,2}{chrom_bin});         % unphased data.
				HETplot2{chrom}(chrom_bin)                 = HETplot{chrom}(chrom_bin)/full_data_threshold;   %
				HETplot2{chrom}(HETplot2{chrom} > 1)       = 1;                                           %
			end;
		end;
	end;
end;
fprintf('\n');
largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


%% -----------------------------------------------------------------------------------------
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------
if (Linear_display == true)
	Linear_fig = figure(2);
	Linear_genome_size   = sum(chrom_size);
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
	maxY                 = ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


%% -----------------------------------------------------------------------------------------
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
		figure(fig);
		% make standard chrom cartoons.
		left   = chrom_posX(chrom);
		bottom = chrom_posY(chrom);
		width  = chrom_width(chrom);
		height = chrom_height(chrom);
		subplot('Position',[left bottom width height]);
		fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
		hold on;

		c_prev = colorInit;
		c_post = colorInit;
		c_     = c_prev;
		infill = zeros(1,length(HETplot2{chrom}));
		colors = [];

		% determines the color of each bin.
		for i = 1:length(SNPs_to_fullData_ratio{chrom})+1;
			if (i-1 < length(SNPs_to_fullData_ratio{chrom}))
				c_tot_post = SNPs_to_fullData_ratio{chrom}(i)+SNPs_to_fullData_ratio{chrom}(i);
				if (c_tot_post == 0)
					c_post = colorNoData;
				else
					% darren
					colorMix = colorHET   *   HETplot2{chrom}(i)/SNPs_to_fullData_ratio{chrom}(i) + ...
					           colorHOM   *   HOMplot2{chrom}(i)/SNPs_to_fullData_ratio{chrom}(i);
					c_post =   colorMix   *   min(1,SNPs_to_fullData_ratio{chrom}(i)) + ...
					           colorNoData*(1-min(1,SNPs_to_fullData_ratio{chrom}(i)));
				end;
			else
				c_post = colorInit;
			end;
			colors(i,1) = c_post(1);
			colors(i,2) = c_post(2);
			colors(i,3) = c_post(3);
		end;

		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chrom_figReversed(chrom) == 1)
			colors        = flipud(colors);
		end;

		% standard : draw colorbars.
		for i = 1:length(HETplot2{chrom})+1;
			x_ = [i i i-1 i-1];
			y_ = [0 maxY maxY 0];
			c_post(1) = colors(i,1);
			c_post(2) = colors(i,2);
			c_post(3) = colors(i,3);
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

		% axes labels etc.
		hold off;
		xlim([0,chrom_size(chrom)/bases_per_bin]);

		%% modify y axis limits to show annotation locations if any are provided.
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

		% This section sets the Y-axis labelling.
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
		end;

		set(gca,'FontSize',gca_stacked_font_size);
		if (chrom == find(chrom_posY == max(chrom_posY)))
			title([ project ' SNP map'],'Interpreter','none','FontSize',stacked_title_size);
		end;
		hold on;
		% standard : end axes labels etc.

			if (displayBREAKS == true) && (show_annotations == true)
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
                                for segment = 2:length(chrom_breaks{chrom})-1
                                        bP = chrom_breaks{chrom}(segment)*chrom_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;

		%show centromere outlines and horizontal marks.
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
		%end show centromere.

		%show annotation locations
		if (show_annotations) && (length(annotations) > 0)
			plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
			hold on;
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
		%end show annotation locations.

	    %% Linear figure draw section
	    if (Linear_display == true)
	        figure(Linear_fig);
	        Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
	        subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
	        Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
	        hold on;

	        % linear : draw colorbars.
	        for i = 1:length(HETplot2{chrom})+1;
	            x_ = [i i i-1 i-1];
	            y_ = [0 maxY maxY 0];
	            c_post(1) = colors(i,1);
	            c_post(2) = colors(i,2);
	            c_post(3) = colors(i,3);
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

	        %show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS == true) && (show_annotations == true)
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
                                for segment = 2:length(chrom_breaks{chrom})-1
                                        bP = chrom_breaks{chrom}(segment)*chrom_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;

	        %show centromere.
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
	                  [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy],...
	                  'Color',[0 0 0]);
	        end;
	        %end show centromere.

	        %show annotation locations
	        if (show_annotations) && (length(annotations) > 0)
	            plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
	            hold on;
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
	        %end show annotation locations.

	        %% Final formatting stuff.
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
				switch ploidyBase
					case 1
						text(axisLabelPosition_horiz, maxY/2,   '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,     '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 2
						text(axisLabelPosition_horiz, maxY/4,   '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,   '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3, '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,     '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 3
						text(axisLabelPosition_horiz, maxY/2,   '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,     '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 4
						text(axisLabelPosition_horiz, maxY/4,   '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,   '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3, '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,     '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				end;
			end;
			set(gca,'FontSize',linear_gca_font_size);
			%end final reformatting.
			% adding title in the middle of the cartoon

			% note: adding title is done in the end since if placed upper
			% in the code somehow the plot function changes the title position
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

	        % shift back to main figure generation.
	        figure(fig);
	        hold on;
			first_chrom = false;
	    end;
	end;
end;

%% Save figures : SNP density plots (not useful for ddRADseq).
set(fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
saveas(fig,        [projectDir 'fig.SNP-map.1.' figVer 'eps'], 'epsc');
saveas(fig,        [projectDir 'fig.SNP-map.1.' figVer 'png'], 'png');
delete(fig);

set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
saveas(Linear_fig, [projectDir 'fig.SNP-map.2.' figVer 'eps'], 'epsc');
saveas(Linear_fig, [projectDir 'fig.SNP-map.2.' figVer 'png'], 'png');
delete(Linear_fig);

%% ========================================================================
% end stuff
%==========================================================================
end
