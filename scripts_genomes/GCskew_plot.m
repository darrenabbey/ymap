function [] = GCskew_plot(main_dir,genomeUser,genome,kmerLength,kmerStep);
addpath('../');
addpath('../scripts_seqModules/')

% hide figures during construction.
set(0,'DefaultFigureVisible','off');

%% ========================================================================

Centromere_format_default   = 2;
Yscale_nearest_even_ploidy  = true;
ChrNum                      = true;
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
	for i = 1:num_chrs
		if (chr_sizes(i).size <= kmerLength)
			chr_in_use(i) == 0;
		end;
	end;

	%%% Initialize data vectors.
	for i = 1:num_chrs
		%%% chr_size(chr_sizes(i).chr) = chr_sizes(i).size;
		GCskew_chr_xPos{i}               = zeros(1,chr_size(i));
		GCskew_chr_data{i}               = zeros(1,chr_size(i));
		GCskew_chr_data_cumulative{i}    = zeros(1,chr_size(i));
		GCcounters(i)                    = 0;
		ATskew_chr_xPos{i}               = zeros(1,chr_size(i));
		ATskew_chr_data{i}               = zeros(1,chr_size(i));
		ATskew_chr_data_cumulative{i}    = zeros(1,chr_size(i));
		ATcounters(i)                    = 0;
	end;

	% Makes sure chr_name{chr} elements aren't null, which causes next section to have problems.
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 0)
			chr_name{chr} = "";
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
			GCskew_line_chr   = GCskew_line_parts{1};
			GCskew_chr_name   = GCskew_line_chr(2:end);
			fprintf(['\nProcessing GC-skew file chromosome ''' GCskew_chr_name '''.\n']);

			% figure out which chromosome the name string corresponds to.
			chr_ID         = find(ismember(chr_name, GCskew_chr_name));
			fprintf(['\tchromosome identified as chr# ' num2str(chr_ID) '.\n']);

			GCcumulativeSkew = 0;
		else
			if (chr_in_use(chr_ID))
				%%% Contig data line.
				% T,0.2,1,-0.07692307692307693,0.43478260869565216,0.043478260869565216
				%	base (ATGC)
				%	GC-skew  = (G - C)/(G + C)
				%	alpha    = (G < C)=>1, else 0			(https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7717575/)
				%	AT-skew  = (A − T)/(A + T)
				%	GC-percs = (G+C)/kmer_length
				%	PP-skew  = ((A+G) - (T+C))/((A+G) + (T+C))	(purine-pyrimidine skew)

				GCcounters(chr_ID) += 1;

				%%% For GCskew data file containing all GCskews.
				GCskew_row = strsplit(GCskew_line, ",");
				GCskew_chr_xPos{chr_ID}(GCcounters(chr_ID)) = str2double(GCskew_row{1});
				dataValue                                   = str2double(GCskew_row{2});
				GCskew_chr_data{chr_ID}(GCcounters(chr_ID)) = dataValue;

				%%% accumulate cumulative GC-skew data.
				GCcumulativeSkew += dataValue;
				GCskew_chr_data_cumulative{chr_ID}(GCcounters(chr_ID)) = GCcumulativeSkew;
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
			ATskew_line_chr   = ATskew_line_parts{1};
			ATskew_chr_name   = ATskew_line_chr(2:end);
			fprintf(['\nProcessing AT-skew file chromosome ''' ATskew_chr_name '''.\n']);

			% figure out which chromosome the name string corresponds to.
			chr_ID         = find(ismember(chr_name, ATskew_chr_name));
			fprintf(['\tchromosome identified as chr# ' num2str(chr_ID) '.\n']);

			ATcumulativeSkew = 0;
		else
			if (chr_in_use(chr_ID))
				%%% Contig data line.
				% T,0.2,1,-0.07692307692307693,0.43478260869565216,0.043478260869565216
				%       base (ATGC)
				%       GC-skew  = (G - C)/(G + C)
				%       alpha    = (G < C)=>1, else 0                   (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7717575/)
				%       AT-skew  = (A − T)/(A + T)
				%       GC-percs = (G+C)/kmer_length
				%       PP-skew  = ((A+G) - (T+C))/((A+G) + (T+C))      (purine-pyrimidine skew)

				ATcounters(chr_ID) += 1;

				%%% For ATskew data file containing all ATskews.
				ATskew_row = strsplit(ATskew_line, ",");
				ATskew_chr_xPos{chr_ID}(ATcounters(chr_ID)) = str2double(ATskew_row{1});
				dataValue                                   = str2double(ATskew_row{2});
				ATskew_chr_data{chr_ID}(ATcounters(chr_ID)) = dataValue;

				%%% accumulate cumulative AT-skew data.
				ATcumulativeSkew += dataValue;
				ATskew_chr_data_cumulative{chr_ID}(ATcounters(chr_ID)) = ATcumulativeSkew;
			end;
		end;
		ATskew_line       = fgetl(ATskewData);
	end;

	%%% Truncate ends off data vectors.
	for i = 1:num_chrs
		if (chr_in_use(i) == 1)
			GCskew_chr_xPos{i}            = GCskew_chr_xPos{i}(1:GCcounters(i));
			GCskew_chr_data{i}            = GCskew_chr_data{i}(1:GCcounters(i));
			GCskew_chr_data_cumulative{i} = GCskew_chr_data_cumulative{i}(1:GCcounters(i));
			ATskew_chr_xPos{i}            = ATskew_chr_xPos{i}(1:ATcounters(i));
			ATskew_chr_data{i}            = ATskew_chr_data{i}(1:ATcounters(i));
			ATskew_chr_data_cumulative{i} = ATskew_chr_data_cumulative{i}(1:ATcounters(i));
		else
			GCskew_chr_xPos{i}            = 0;
			GCskew_chr_data{i}            = 0;
			GCskew_chr_data_cumulative{i} = 0;
			ATskew_chr_xPos{i}            = 0;
			ATskew_chr_data{i}            = 0;
			ATskew_chr_data_cumulative{i} = 0;
		end;
	end;

	%%% find highest/mediaun/lowest GC-skew across genome.
	for i = 1:num_chrs
		if (chr_in_use(i) == 1)
			if (length(GCskew_chr_data_cumulative{i}) > 0)
				maxSkewCumulative_chr(i) = max(GCskew_chr_data_cumulative{i});
			else
				maxSkewCumulative_chr(i) = 0;
			end;
			if (length(GCskew_chr_data_cumulative{i}) > 0)
				minSkewCumulative_chr(i) = min(GCskew_chr_data_cumulative{i});
			else
				minSkewCumulative_chr(i) = 0;
			end;
			if (length(GCskew_chr_data{i}) > 0)
				maxSkew_chr(i) = max(GCskew_chr_data{i});
			else
				maxSkew_chr(i) = 0;
			end;
			if (length(GCskew_chr_data{i}) > 0)
				minSkew_chr(i) = min(GCskew_chr_data{i});
			else
				minSkew_chr(i) = 0;
			end;
		else
			maxSkewCumulative_chr(i) = 0;
			minSkewCumulative_chr(i) = 0;
			maxSkew_chr(i)           = 0;
			minSkew_chr(i)           = 0;
		end;
	end;

	% lines end without semicolon so that values are output to log file.
	maxSkew_genome           = max(maxSkew_chr);
	minSkew_genome           = min(minSkew_chr);
	maxSkewCumulative_genome = max(maxSkewCumulative_chr);
	minSkewCumulative_genome = min(minSkewCumulative_chr);

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
	for i = 1:num_chrs
		GCskew_chr_data{i}            = GCskew_chr_data{i}/maxAbsVal;
		GCskew_chr_data_cumulative{i} = GCskew_chr_data_cumulative{i}/maxAbsValCumulative;

		ATskew_chr_data{i}            = ATskew_chr_data{i}/maxAbsVal;
		ATskew_chr_data_cumulative{i} = ATskew_chr_data_cumulative{i}/maxAbsValCumulative;
	end;

	%--------------------------------------------------------------------------
	% End GC/etc-skew file data load/process.
	%%=========================================================================


	%%
	source([pwd() '/custom_plots_section2.m']);
	%%

	% Draw chromosomes in order defined in figure_definitions.txt file.
	for chr_to_draw  = 1:length(chr_order)
		chr = chr_order(chr_to_draw);
		if (chr_in_use(chr) == 1)
			if (Standard_display)

	%%
	source([pwd() '/custom_plots_section3.m']);
	%%

				%%==================================================================================
				%% stacked plot section.
				yData1 = (GCskew_chr_data{chr}           +1)/2*maxY;
				yData2 = (ATskew_chr_data{chr}           +1)/2*maxY;
				yData3 = (GCskew_chr_data_cumulative{chr}+1)/2*maxY;
				yData4 = (ATskew_chr_data_cumulative{chr}+1)/2*maxY;
				xData  = GCskew_chr_xPos{chr}/bases_per_bin;
				if (chr_figReversed(chr) == 1)
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
				yData1 = (GCskew_chr_data{chr}           +1)/2*maxY;
				yData2 = (ATskew_chr_data{chr}           +1)/2*maxY;
				yData3 = (GCskew_chr_data_cumulative{chr}+1)/2*maxY;
				yData4 = (ATskew_chr_data_cumulative{chr}+1)/2*maxY;
				xData  = GCskew_chr_xPos{chr}/bases_per_bin;
				if (chr_figReversed(chr) == 1)
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
				if (chr == find(chr_posY == max(chr_posY)))
					title([ genome ' GC-skew map'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;

			first_chr = false;
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
