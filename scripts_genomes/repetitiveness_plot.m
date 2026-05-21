function [] = repetitiveness_plot(main_dir,genomeUser,genome,kmerLength);
addpath([pwd() '/../']);
addpath([pwd() '/../scripts_seqModules/']);
addpath([pwd() '/../scripts_seqModules/scripts_WGseq/'])

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

	option         = figure_options{2,1};
	if strcmp(option,'False')
		Make_figure_repet = false;
	else
		Make_figure_repet = true;
	end;
else
	Make_figure_repet = true;
end;

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
			%%% Contig data line.
			counter += 1;
			WIG_chr_data{chr_ID}(counter)=str2double(WIG_line);
		end;
		WIG_line       = fgetl(WIGdata);
	end;

	% find highest/mediaun/lowest repetitiveness across genome.
	for i = 1:num_chrs
		maxRepet_chr(i) = max(WIG_chr_data{i});
		minRepet_chr(i) = min(WIG_chr_data{i});
		medRepet_chr(i) = median(WIG_chr_data{i});
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
	source([pwd() '/custom_plots_section3.m']);
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
	source([pwd() '/custom_plots_section4.m']);
	%%

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
