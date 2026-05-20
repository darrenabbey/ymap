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

	[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
	Aneuploidy = [];

	num_chrs  = length(chr_sizes);

	for i = 1:num_chrs
		chr_size(i)  = 0;
		cen_start(i) = 0;
		cen_end(i)   = 0;
	end;
	for i = 1:num_chrs
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
			fprintf(['\t[' num2str(annotations(i).chr) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' ...
				annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
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
			maxSkewCumulative_chr(i) = max(GCskew_chr_data_cumulative{i});
			minSkewCumulative_chr(i) = min(GCskew_chr_data_cumulative{i});
			maxSkew_chr(i)           = max(GCskew_chr_data{i});
			minSkew_chr(i)           = min(GCskew_chr_data{i});
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


	%%=========================================================================
	%%= No further control variables below. ===================================
	%%=========================================================================

	%% Load CNV and SNP figure resolutions.
	if (exist([genomeDir 'resolution.CNV.txt'],'file') == 0)
		bases_per_bin           = max(chr_size)/700;
	else
		bases_per_bin           = max(chr_size)/str2num(fileread([genomeDir 'resolution.CNV.txt']));
	end;

	% basic plot parameters not defined per genome.
	TickSize         = -0.005;  %negative for outside, percentage of longest chr figure.
	ploidyBase       = 2;
	maxY             = ploidyBase*2;
	cen_tel_Xindent  = 5;
	cen_tel_Yindent  = maxY/4;

	fprintf(['\nGenerating GC/AT-skew figure from ''' genome ''' sequence data.\n']);

	largestChr = find(chr_width == max(chr_width));
	largestChr = largestChr(1);


	%% -----------------------------------------------------------------------------------------
	% Setup for linear-view figure generation.
	%-------------------------------------------------------------------------------------------
	% load size definitions
	[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chr_gap,Linear_Chr_max_width,Linear_height...
	    ,Linear_base,rotate,linear_chr_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
	    stacked_fig_width,stacked_chr_font_size,stacked_title_size,stacked_axis_font_size,...
	    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chr_in_use,num_chrs,chr_label,chr_size);

	if (Standard_display)
		Standard_fig = figure();
	end;

	if (Linear_display)
		Linear_fig           = figure();
		Linear_genome_size   = sum(chr_size);
		Linear_TickSize      = -0.01;            % negative for outside, percentage of longest chr figure.
		Linear_maxY          = 10;
		Linear_left          = Linear_left_start;
		axisLabelPosition_horiz = 0.01125;
	end;
	axisLabelPosition_vert = 0.01125;

	%% -----------------------------------------------------------------------------------------
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

			% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
			if (chr_figReversed(chr) == 1)
				%%% reverse data.
			end;

			if (Standard_display)
				%% make standard chr cartoons.
				figure(Standard_fig);
				left   = chr_posX(chr);
				bottom = chr_posY(chr);
				width  = chr_width(chr);
				height = chr_height(chr);
				fprintf(['chr' num2str(chr) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
				subplot('Position',[left bottom width height]);
				hold on;

				%% Hide axis lines.
				box off;


				%% standard : show centromere.
				if (chr_size(chr) < 100000)
					Centromere_format = 0;
				else
					Centromere_format = Centromere_format_default;
				end;
				x1       = cen_start(chr)/bases_per_bin;
				x2       = cen_end(chr)/bases_per_bin;
				leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
				rightEnd = chr_size(chr)/bases_per_bin;         % chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source('../scripts_seqModules/scripts_WGseq/cartoon_stacked_0.m');
				elseif (Centromere_format == 1)
					source('../scripts_seqModules/scripts_WGseq/cartoon_stacked_1.m');
				elseif (Centromere_format == 2) % sausage! (standard plot)
					source('../scripts_seqModules/scripts_WGseq/cartoon_stacked_2.m');
				end;
				%% standard : end show centromere.


				%%==================================================================================
				%% stacked plot section. DRAGON
				yData1 = (GCskew_chr_data{chr}           +1)/2*maxY;
				yData2 = (ATskew_chr_data{chr}           +1)/2*maxY;
				yData3 = (GCskew_chr_data_cumulative{chr}+1)/2*maxY;
				yData4 = (ATskew_chr_data_cumulative{chr}+1)/2*maxY;
				xData  = GCskew_chr_xPos{chr}/bases_per_bin;
				plot(xData,yData1,'color',[0.75 0    0   ]);
				hold on;
				plot(xData,yData2,'color',[0.75 0    0.75]);
				plot(xData,yData3,'color',[0    0.75 0   ]);
				plot(xData,yData4,'color',[0    0.75 0.75]);
				%% end plot section.
				%%==================================================================================


				%axes labels etc.
				hold off;

				% standard : limit x-axis to range of chromosome.
				xlim([0,chr_size(chr)/bases_per_bin]);

				% modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY]);
				else
					ylim([0,maxY]);
				end;

				set(gca,'TickLength',[TickSize 0]);
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

				%% chromosome cartoon titles for standard figure.
				if (chr_figReversed(chr) == 0)
					text(-50000/5000/2*3, maxY/2, chr_label{chr}, 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chr_font_size);
				else
					text(-50000/5000/2*3, maxY/2, [chr_label{chr} '\fontsize{' int2str(round(stacked_chr_font_size/2)) '}' char(10) '(reversed)'], 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize',stacked_chr_font_size);
				end;

				% show annotation locations (standard)
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
					annotation_location = (annotation_start+annotation_end)./2;
					for i = 1:length(annotation_location)
						if (annotation_chr(i) == chr)
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
			end;

			%% Linear figure draw section
			if (Linear_display)
				figure(Linear_fig);
				Linear_width = Linear_Chr_max_width*chr_size(chr)/Linear_genome_size;
				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_chr_gap;
				hold on;

				%% linear : show centromere/outline.
				if (chr_size(chr) < 100000)
					Centromere_format = 0;
				else
					Centromere_format = Centromere_format_default;
				end;
				x1       = cen_start(chr)/bases_per_bin;
				x2       = cen_end(chr)/bases_per_bin;
				leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
				rightEnd = chr_size(chr)/bases_per_bin;         % chr_size(chr)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source('../scripts_seqModules/scripts_WGseq/cartoon_linear_0.m');
				elseif (Centromere_format == 1)
					source('../scripts_seqModules/scripts_WGseq/cartoon_linear_1.m');
				elseif (Centromere_format == 2) % sausage! (linear plot)
					source('../scripts_seqModules/scripts_WGseq/cartoon_linear_2.m');
				end;
				%% linear : end show centromere/outline.


				%%==================================================================================
				%% linear plot section. DRAGON
				yData1 = (GCskew_chr_data{chr}           +1)/2*maxY;
				yData2 = (ATskew_chr_data{chr}           +1)/2*maxY;
				yData3 = (GCskew_chr_data_cumulative{chr}+1)/2*maxY;
				yData4 = (ATskew_chr_data_cumulative{chr}+1)/2*maxY;
				xData  = GCskew_chr_xPos{chr}/bases_per_bin;
				plot(xData,yData1,'color',[0.75 0    0   ]);
				hold on;
				plot(xData,yData2,'color',[0.75 0    0.75]);
				plot(xData,yData3,'color',[0    0.75 0   ]);
				plot(xData,yData4,'color',[0    0.75 0.75]);
				%% end plot section.
				%%==================================================================================


				%% show annotation locations (linear)
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
					annotation_location = (annotation_start+annotation_end)./2;
					for i = 1:length(annotation_location)
						if (annotation_chr(i) == chr)
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
				xlim([0,chr_size(chr)/bases_per_bin]);

				% modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY]);
				else
					ylim([0,maxY]);
				end;

				set(gca,'TickLength',[Linear_TickSize 0]);
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTickLabel',[]);
				%% end final reformatting.

				% Adding chromosome titles above the middle of the chromosome cartoons.
				% note: adding title is done in the end since if placed earlier in the code somehow the plot function changes the title position.
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

			if (Standard_display)
				% shift back to main figure generation.
				figure(Standard_fig);
				hold on;

				set(gca,'FontSize',gca_stacked_font_size);
				if (chr == find(chr_posY == max(chr_posY)))
					title([ genome ' GC/AT-skew map'],'Interpreter','none','FontSize',stacked_title_size);
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
else
	fprintf([  '$$$ Not making GC-skew figures.\n']);
end;

end
