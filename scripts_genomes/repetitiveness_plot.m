function [] = repetitiveness_plot(main_dir,genomeUser,genome,kmerLength);
addpath([pwd() '/../']);
addpath([pwd() '/../scripts_seqModules/']);
addpath([pwd() '/../scripts_seqModules/scripts_WGseq/'])

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

	option         = figure_options{2,1};
	if strcmp(option,'False')
		Make_figure_repet = false;
	else
		Make_figure_repet = true;
	end;
else
	Make_figure_repet = true;
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

if (Make_figure_repet)
	fprintf([  '$$$ Making repetitiveness figures.\n']);

	%%
	source([pwd() '/custom_plots_section1.m']);
	%%


	%%=========================================================================
	% Load/process WIG file data.
	%--------------------------------------------------------------------------
	kmerLength = str2num(kmerLength);

	for i = 1:num_chroms
		% chrom_size(chrom_sizes(i).chrom)    = chrom_sizes(i).size;
		WIG_chrom_data{i} = zeros(1,chrom_size(i));
	end;

	% Makes sure chrom_name{chrom} elements aren't null, which causes next section to have problems.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 0)
			chrom_name{chrom} = "";
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
			WIG_line_chrom   = WIG_line_parts{2};
			WIG_chrom_name   = WIG_line_chrom(7:end);
			fprintf(['\nProcessing WIG file chromosome ''' WIG_chrom_name '''.\n']);

			% figure out which chromosome the name string corresponds to.
			chrom_ID         = find(ismember(chrom_name, WIG_chrom_name));
			fprintf(['\tchromosome identified as chrom# ' num2str(chrom_ID) '.\n']);

			counter = 0;
		else
			if (chrom_in_use(chrom_ID))
				%%% Contig data line.
				counter += 1;
				WIG_chrom_data{chrom_ID}(counter) = str2double(WIG_line);
			end;
		end;
		WIG_line       = fgetl(WIGdata);
	end;

	% find highest/mediaun/lowest repetitiveness across genome.
	for i = 1:num_chroms
		if (size(WIG_chrom_data{i}) > 0)
			maxRepet_chrom(i) = max(WIG_chrom_data{i});
			minRepet_chrom(i) = min(WIG_chrom_data{i});
			medRepet_chrom(i) = median(WIG_chrom_data{i});
		else
			maxRepet_chrom(i) = 1;
			minRepet_chrom(i) = 1;
			medRepet_chrom(i) = 1;
		end;
	end;
	maxRepet_chrom
	minRepet_chrom
	medRepet_chrom
	maxRepet_genome = max(maxRepet_chrom);
	minRepet_genome = min(minRepet_chrom);
	maxRepet_genome
	minRepet_genome

	%--------------------------------------------------------------------------
	% End WIG file data load/process.
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
				logData  = log(WIG_chrom_data{chrom}/kmerLength+0.5);
				maxValue = log(maxRepet_genome/kmerLength+0.5);
				xData = [1:length(logData)]/bases_per_bin;
				yData = logData/maxValue*maxY;
				if (chrom_figReversed(chrom) == 1)
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
				logData  = log(WIG_chrom_data{chrom}/kmerLength+0.5);
				maxValue = log(maxRepet_genome/kmerLength+0.5);
				xData = [1:length(logData)]/bases_per_bin;
				yData = logData/maxValue*maxY;
				if (chrom_figReversed(chrom) == 1)
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
				if (chrom == find(chrom_posY == max(chrom_posY)))
					title([ genome ' Repetitiveness map'],'Interpreter','none','FontSize',stacked_title_size);
				end;
			end;

			first_chrom = false;
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
