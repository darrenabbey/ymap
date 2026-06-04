function [] = repetitiveness_plot(main_dir,genomeUser,genome,kmerLength);
addpath([pwd() '/../']);
addpath([pwd() '/../scripts_seqModules/']);
addpath([pwd() '/../scripts_seqModules/scripts_WGseq/'])

% hide figures during construction.
set(0,'DefaultFigureVisible','off');

%% ========================================================================

Centromere_format_default   = 3;
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

	option         = figure_options{2,1};
	if strcmp(option,'False')
		Make_figure_repet = false;
	else
		Make_figure_repet = true;
	end;
else
	Make_figure_repet = true;
end;

[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
Aneuploidy = [];  % later loaded from Load_dataset_information(projectDir) after ChARM algorithm is used.
num_chrs   = length(chr_sizes);

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


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

if (Make_figure_repet)
	fprintf([  '$$$ Making repetitiveness figures.\n']);

	%%
	source([pwd() '/custom_plots_section1.m']);
	%%


	%%=========================================================================
	% Load/process WIG file data.
	%--------------------------------------------------------------------------
	kmerLength = str2num(kmerLength);

	for i = 1:num_chrs
		% chr_size(chr_sizes(i).chr)    = chr_sizes(i).size;
		WIG_chr_data{i} = zeros(1,chr_size(i));
	end;

	% Makes sure chr_name{chr} elements aren't null, which causes next section to have problems.
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 0)
			chr_name{chr} = "";
		end;
	end;

	WIGfile  = [main_dir 'users/' genomeUser '/genomes/' genome '/datafile_g_0.repetitiveness_' num2str(kmerLength) '.wig' ];
	WIGdata  = fopen(WIGfile,"r");
	WIG_line = fgetl(WIGdata);
	while ischar(WIG_line)
		% fixedStep chrom=CDQK01000001.1 start=1 step=1
		if (WIG_line(1) == 'f')
			%%% Contig header line.

			% Get contig name string.
			WIG_line_parts = strsplit(WIG_line);
			WIG_line_chr   = WIG_line_parts{2};
			WIG_chr_name   = WIG_line_chr(7:end);
			fprintf(['\nProcessing WIG file chromosome ''' WIG_chr_name '''.\n']);

			% figure out which chromosome the name string corresponds to.
			chr_ID         = find(ismember(chr_name, WIG_chr_name));
			fprintf(['\tchromosome identified as chr# ' num2str(chr_ID) '.\n']);

			counter = 0;
		else
			if (chr_in_use(chr_ID))
				%%% Contig data line.
				counter += 1;
				WIG_chr_data{chr_ID}(counter) = str2double(WIG_line);
			end;
		end;
		WIG_line       = fgetl(WIGdata);
	end;

	% find highest/mediaun/lowest repetitiveness across genome.
	for i = 1:num_chrs
		if (size(WIG_chr_data{i}) > 0)
			maxRepet_chr(i) = max(WIG_chr_data{i});
			minRepet_chr(i) = min(WIG_chr_data{i});
			medRepet_chr(i) = median(WIG_chr_data{i});
		else
			maxRepet_chr(i) = 1;
			minRepet_chr(i) = 1;
			medRepet_chr(i) = 1;
		end;
	end;
	maxRepet_chr
	minRepet_chr
	medRepet_chr
	maxRepet_genome = max(maxRepet_chr);
	minRepet_genome = min(minRepet_chr);
	maxRepet_genome
	minRepet_genome

	%--------------------------------------------------------------------------
	% End WIG file data load/process.
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
				logData  = log(WIG_chr_data{chr}/kmerLength+0.5);
				maxValue = log(maxRepet_genome/kmerLength+0.5);
				xData = [1:length(logData)]/bases_per_bin;
				yData = logData/maxValue*maxY;
				if (chr_figReversed(chr) == 1)
					xData = fliplr(xData);
				end;
				plot(xData,yData,'color',[0 0 0]);
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
				logData  = log(WIG_chr_data{chr}/kmerLength+0.5);
				maxValue = log(maxRepet_genome/kmerLength+0.5);
				xData = [1:length(logData)]/bases_per_bin;
				yData = logData/maxValue*maxY;
				if (chr_figReversed(chr) == 1)
					xData = fliplr(xData);
				end;
				plot(xData,yData,'color',[0 0 0]);
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
					title([ genome ' Repetitiveness map'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;

			first_chr = false;
		end;
	end;

	if (Standard_display)
		% Save primary genome figure.
		set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
		saveas(Standard_fig, [genomeDir 'fig.repet-map.1.eps'], 'epsc');
		saveas(Standard_fig, [genomeDir 'fig.repet-map.1.png'], 'png');
		delete(Standard_fig);

		%% change permissions of figures.
		system(['chmod 774 ' genomeDir 'fig.repet-map.1.eps']);
		system(['chmod 774 ' genomeDir 'fig.repet-map.1.png']);
	end;

	if (Linear_display)
		% Save horizontal aligned genome figure.
		set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
		saveas(Linear_fig,   [genomeDir 'fig.repet-map.2.eps'], 'epsc');
		saveas(Linear_fig,   [genomeDir 'fig.repet-map.2.png'], 'png');
		delete(Linear_fig);

		%% change permissions of figures.
		system(['chmod 774 ' genomeDir 'fig.repet-map.2.eps']);
		system(['chmod 774 ' genomeDir 'fig.repet-map.2.png']);
	end;

	fprintf([  '$$$ Repetitiveness figures saved.\n']);
else
	fprintf([  '$$$ Not making repetitiveness figures.\n']);
end;

end
