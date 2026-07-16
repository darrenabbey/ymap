function [] = GCskew_plot(main_dir,genomeUser,genome,kmerLength,kmerStep);
addpath('../');
addpath('../scripts_seqModules/')

% hide figures during construction.
set(0,'DefaultFigureVisible','off');

%% ========================================================================

Centromere_format_default   = 3;
Yscale_nearest_even_ploidy  = true;
chromNum                      = true;
show_annotations            = true;
analyze_rDNA                = true;
Standard_display            = true;
Linear_display              = true;


%%=========================================================================
% Control variables.
%--------------------------------------------------------------------------
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];

fprintf(['\n$$$ main_dir   : ' main_dir   '\n']);
fprintf([  '$$$ genomeUser   ' genomeUser '\n']);
fprintf([  '$$$ genome     : ' genome     '\n']);
fprintf([  '$$$ genomeDir  : ' genomeDir  '\n']);

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir 'users/' genomeUser '/genomes/' genome '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir 'users/' genomeUser '/genomes/' genome '/figure_options.txt'],'\t',1);

	option         = figure_options{3,1};
	if strcmp(option,'False')
		Make_figure_skew = false;
	else
		Make_figure_skew = true;
	end;
else
	Make_figure_skew = true;
end;

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


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

if (Make_figure_skew)
	fprintf([  '$$$ Making GC-skew figures.\n']);

	%%
	source([pwd() '/custom_plots_section1.m']);
	%%

	%%=========================================================================
	% Load/process GC/etc-skew file data.
	%--------------------------------------------------------------------------
	kmerLength = str2num(kmerLength);

	%%% Disable any chromosomes which are shorter than the kmer length being used.
	for i = 1:num_chroms
		if (chrom_sizes(i).size <= kmerLength)
			chrom_in_use(i) == 0;
		end;
	end;

	%%% Initialize data vectors.
	for i = 1:num_chroms
		%%% chrom_size(chrom_sizes(i).chrom) = chrom_sizes(i).size;
		GCskew_chrom_xPos{i}               = zeros(1,chrom_size(i));
		GCskew_chrom_data{i}               = zeros(1,chrom_size(i));
		GCskew_chrom_data_cumulative{i}    = zeros(1,chrom_size(i));
		GCcounters(i)                    = 0;
		ATskew_chrom_xPos{i}               = zeros(1,chrom_size(i));
		ATskew_chrom_data{i}               = zeros(1,chrom_size(i));
		ATskew_chrom_data_cumulative{i}    = zeros(1,chrom_size(i));
		ATcounters(i)                    = 0;
	end;

	% Makes sure chrom_name{chrom} elements aren't null, which causes next section to have problems.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 0)
			chrom_name{chrom} = "";
		end;
	end;

	%%%% Process GC skew file.
	GCskewFile  = [main_dir 'users/' genomeUser '/genomes/' genome '/datafile_g_0.GCskew.txt' ];
	GCskewData  = fopen(GCskewFile,"r");
	GCskew_line = fgetl(GCskewData);
	while ischar(GCskew_line)
		if (GCskew_line(1) == '>')
			%%% Contig header line.
			% >CDQK01000001.1 Cyberlindnera jadinii genome assembly cj1, scaffold CJ1, whole genome shotgun sequence

			% Get contig name string.
			GCskew_line_parts = strsplit(GCskew_line);
			GCskew_line_chrom   = GCskew_line_parts{1};
			GCskew_chrom_name   = GCskew_line_chrom(2:end);
			fprintf(['\nProcessing GC-skew file chromosome ''' GCskew_chrom_name '''.\n']);

			% figure out which chromosome the name string corresponds to.
			chrom_ID         = find(ismember(chrom_name, GCskew_chrom_name));
			fprintf(['\tchromosome identified as chrom# ' num2str(chrom_ID) '.\n']);

			GCcumulativeSkew = 0;
		else
			if (chrom_in_use(chrom_ID))
				%%% Contig data line.
				% T,0.2,1,-0.07692307692307693,0.43478260869565216,0.043478260869565216
				%	base (ATGC)
				%	GC-skew  = (G - C)/(G + C)
				%	alpha    = (G < C)=>1, else 0			(https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7717575/)
				%	AT-skew  = (A − T)/(A + T)
				%	GC-percs = (G+C)/kmer_length
				%	PP-skew  = ((A+G) - (T+C))/((A+G) + (T+C))	(purine-pyrimidine skew)

				GCcounters(chrom_ID) += 1;

				%%% For GCskew data file containing all GCskews.
				GCskew_row = strsplit(GCskew_line, ",");
				GCskew_chrom_xPos{chrom_ID}(GCcounters(chrom_ID)) = str2double(GCskew_row{1});
				dataValue                                   = str2double(GCskew_row{2});
				GCskew_chrom_data{chrom_ID}(GCcounters(chrom_ID)) = dataValue;

				%%% accumulate cumulative GC-skew data.
				GCcumulativeSkew += dataValue;
				GCskew_chrom_data_cumulative{chrom_ID}(GCcounters(chrom_ID)) = GCcumulativeSkew;
			end;
		end;
		GCskew_line       = fgetl(GCskewData);
	end;

	%%% Process AT skew file.
	ATskewFile  = [main_dir 'users/' genomeUser '/genomes/' genome '/datafile_g_0.ATskew.txt' ];
	ATskewData  = fopen(ATskewFile,"r");
	ATskew_line = fgetl(ATskewData);
	while ischar(ATskew_line)
		if (ATskew_line(1) == '>')
			%%% Contig header line.
			% >CDQK01000001.1 Cyberlindnera jadinii genome assembly cj1, scaffold CJ1, whole genome shotgun sequence

			% Get contig name string.
			ATskew_line_parts = strsplit(ATskew_line);
			ATskew_line_chrom   = ATskew_line_parts{1};
			ATskew_chrom_name   = ATskew_line_chrom(2:end);
			fprintf(['\nProcessing AT-skew file chromosome ''' ATskew_chrom_name '''.\n']);

			% figure out which chromosome the name string corresponds to.
			chrom_ID         = find(ismember(chrom_name, ATskew_chrom_name));
			fprintf(['\tchromosome identified as chrom# ' num2str(chrom_ID) '.\n']);

			ATcumulativeSkew = 0;
		else
			if (chrom_in_use(chrom_ID))
				%%% Contig data line.
				% T,0.2,1,-0.07692307692307693,0.43478260869565216,0.043478260869565216
				%       base (ATGC)
				%       GC-skew  = (G - C)/(G + C)
				%       alpha    = (G < C)=>1, else 0                   (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7717575/)
				%       AT-skew  = (A − T)/(A + T)
				%       GC-percs = (G+C)/kmer_length
				%       PP-skew  = ((A+G) - (T+C))/((A+G) + (T+C))      (purine-pyrimidine skew)

				ATcounters(chrom_ID) += 1;

				%%% For ATskew data file containing all ATskews.
				ATskew_row = strsplit(ATskew_line, ",");
				ATskew_chrom_xPos{chrom_ID}(ATcounters(chrom_ID)) = str2double(ATskew_row{1});
				dataValue                                   = str2double(ATskew_row{2});
				ATskew_chrom_data{chrom_ID}(ATcounters(chrom_ID)) = dataValue;

				%%% accumulate cumulative AT-skew data.
				ATcumulativeSkew += dataValue;
				ATskew_chrom_data_cumulative{chrom_ID}(ATcounters(chrom_ID)) = ATcumulativeSkew;
			end;
		end;
		ATskew_line       = fgetl(ATskewData);
	end;

	%%% Truncate ends off data vectors.
	for i = 1:num_chroms
		if (chrom_in_use(i) == 1)
			GCskew_chrom_xPos{i}            = GCskew_chrom_xPos{i}(1:GCcounters(i));
			GCskew_chrom_data{i}            = GCskew_chrom_data{i}(1:GCcounters(i));
			GCskew_chrom_data_cumulative{i} = GCskew_chrom_data_cumulative{i}(1:GCcounters(i));
			ATskew_chrom_xPos{i}            = ATskew_chrom_xPos{i}(1:ATcounters(i));
			ATskew_chrom_data{i}            = ATskew_chrom_data{i}(1:ATcounters(i));
			ATskew_chrom_data_cumulative{i} = ATskew_chrom_data_cumulative{i}(1:ATcounters(i));
		else
			GCskew_chrom_xPos{i}            = 0;
			GCskew_chrom_data{i}            = 0;
			GCskew_chrom_data_cumulative{i} = 0;
			ATskew_chrom_xPos{i}            = 0;
			ATskew_chrom_data{i}            = 0;
			ATskew_chrom_data_cumulative{i} = 0;
		end;
	end;

	%%% find highest/mediaun/lowest GC-skew across genome.
	for i = 1:num_chroms
		if (chrom_in_use(i) == 1)
			if (length(GCskew_chrom_data_cumulative{i}) > 0)
				maxSkewCumulative_chrom(i) = max(GCskew_chrom_data_cumulative{i});
			else
				maxSkewCumulative_chrom(i) = 0;
			end;
			if (length(GCskew_chrom_data_cumulative{i}) > 0)
				minSkewCumulative_chrom(i) = min(GCskew_chrom_data_cumulative{i});
			else
				minSkewCumulative_chrom(i) = 0;
			end;
			if (length(GCskew_chrom_data{i}) > 0)
				maxSkew_chrom(i) = max(GCskew_chrom_data{i});
			else
				maxSkew_chrom(i) = 0;
			end;
			if (length(GCskew_chrom_data{i}) > 0)
				minSkew_chrom(i) = min(GCskew_chrom_data{i});
			else
				minSkew_chrom(i) = 0;
			end;
		else
			maxSkewCumulative_chrom(i) = 0;
			minSkewCumulative_chrom(i) = 0;
			maxSkew_chrom(i)           = 0;
			minSkew_chrom(i)           = 0;
		end;
	end;

	% lines end without semicolon so that values are output to log file.
	maxSkew_genome           = max(maxSkew_chrom);
	minSkew_genome           = min(minSkew_chrom);
	maxSkewCumulative_genome = max(maxSkewCumulative_chrom);
	minSkewCumulative_genome = min(minSkewCumulative_chrom);

	% normalize skew variance so max/min is on range [-1..1] without shifting the zero point.
	if (maxSkew_genome > -minSkew_genome)
		maxAbsVal = maxSkew_genome;
	else
		maxAbsVal = -minSkew_genome;
	end;
	if (maxSkewCumulative_genome > -minSkewCumulative_genome)
		maxAbsValCumulative = maxSkewCumulative_genome;
	else
		maxAbsValCumulative = -minSkewCumulative_genome;
	end;

	%%% normalize the data to a range of [-1..0..1].
	for i = 1:num_chroms
		GCskew_chrom_data{i}            = GCskew_chrom_data{i}/maxAbsVal;
		GCskew_chrom_data_cumulative{i} = GCskew_chrom_data_cumulative{i}/maxAbsValCumulative;

		ATskew_chrom_data{i}            = ATskew_chrom_data{i}/maxAbsVal;
		ATskew_chrom_data_cumulative{i} = ATskew_chrom_data_cumulative{i}/maxAbsValCumulative;
	end;

	%--------------------------------------------------------------------------
	% End GC/etc-skew file data load/process.
	%%=========================================================================


	%%
	source([pwd() '/custom_plots_section2.m']);
	%%

	% Draw chromosomes in order defined in figure_definitions.txt file.
	for chrom_to_draw  = 1:length(chrom_order)
		chrom = chrom_order(chrom_to_draw);
		if (chrom_in_use(chrom) == 1)
			if (Standard_display)

	%%
	source([pwd() '/custom_plots_section3.m']);
	%%

				%%==================================================================================
				%% stacked plot section.
				yData1 = (GCskew_chrom_data{chrom}           +1)/2*maxY;
				yData2 = (ATskew_chrom_data{chrom}           +1)/2*maxY;
				yData3 = (GCskew_chrom_data_cumulative{chrom}+1)/2*maxY;
				yData4 = (ATskew_chrom_data_cumulative{chrom}+1)/2*maxY;
				xData  = GCskew_chrom_xPos{chrom}/bases_per_bin;
				if (chrom_figReversed(chrom) == 1)
					xData = fliplr(xData);
				end;
				plot(xData,yData1,'color',[0.75 0    0   ]);
				hold on;
				plot(xData,yData2,'color',[0.75 0    0.75]);
				plot(xData,yData3,'color',[0    0.75 0   ]);
				plot(xData,yData4,'color',[0    0.75 0.75]);
				%% end plot section.
				%%==================================================================================


	%%
	source([pwd() '/custom_plots_section4.m']);
	%%

			end;

			%% Linear figure draw section
			if (Linear_display)

	%%
	source([pwd() '/custom_plots_section5.m']);
	%%


				%%==================================================================================
				%% linear plot section.
				yData1 = (GCskew_chrom_data{chrom}           +1)/2*maxY;
				yData2 = (ATskew_chrom_data{chrom}           +1)/2*maxY;
				yData3 = (GCskew_chrom_data_cumulative{chrom}+1)/2*maxY;
				yData4 = (ATskew_chrom_data_cumulative{chrom}+1)/2*maxY;
				xData  = GCskew_chrom_xPos{chrom}/bases_per_bin;
				if (chrom_figReversed(chrom) == 1)
					xData = fliplr(xData);
				end;
				plot(xData,yData1,'color',[0.75 0    0   ]);
				hold on;
				plot(xData,yData2,'color',[0.75 0    0.75]);
				plot(xData,yData3,'color',[0    0.75 0   ]);
				plot(xData,yData4,'color',[0    0.75 0.75]);
				%% end plot section.
				%%==================================================================================

	%%
	source([pwd() '/custom_plots_section6.m']);
	%%

			end;

			if (Standard_display)
				% shift back to main figure generation.
				figure(Standard_fig);
				hold on;

				set(gca,'FontSize',gca_stacked_font_size);
				if (chrom == find(chrom_posY == max(chrom_posY)))
					title([ genome ' GC-skew map'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;

			first_chrom = false;
		end;
	end;

	if (Standard_display)
		% Save primary genome figure.
		set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
		saveas(Standard_fig, [genomeDir 'fig.skew-map.1.eps'], 'epsc');
		saveas(Standard_fig, [genomeDir 'fig.skew-map.1.png'], 'png');
		delete(Standard_fig);

		%% change permissions of figures.
		system(['chmod 774 ' genomeDir 'fig.skew-map.1.eps']);
		system(['chmod 774 ' genomeDir 'fig.skew-map.1.png']);
	end;

	if (Linear_display)
		% Save horizontal aligned genome figure.
		set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
		saveas(Linear_fig,   [genomeDir 'fig.skew-map.2.eps'], 'epsc');
		saveas(Linear_fig,   [genomeDir 'fig.skew-map.2.png'], 'png');
		delete(Linear_fig);

		%% change permissions of figures.
		system(['chmod 774 ' genomeDir 'fig.skew-map.2.eps']);
		system(['chmod 774 ' genomeDir 'fig.skew-map.2.png']);
	end;

	fprintf([  '$$$ GC-skew figures saved.\n']);
else
	fprintf([  '$$$ Not making GC-skew figures.\n']);
end;

end
