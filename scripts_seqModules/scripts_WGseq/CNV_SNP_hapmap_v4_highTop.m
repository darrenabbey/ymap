function [] = CNV_SNP_hapmap_v4_highTop(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString, SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

workingDir      = [main_dir '/users/' user '/projects/' project '/'];
fprintf('\n\n\t*===============================================================================*\n');
fprintf(    '\t| Generate CNV/SNP/LOH highTop plot in script "CNV_SNP_hapmap_v4_highTop.m".    |\n');
fprintf(    '\t*-------------------------------------------------------------------------------*\n');
tic;

% hide figures during construction.
set(0,'DefaultFigureVisible','off');

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir '/users/' user '/projects/' project '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir '/users/' user '/projects/' project '/figure_options.txt'],'\t',1);

	option         = figure_options{12,1};
	if strcmp(option,'False')
		Make_figure = false;
	else
		Make_figure = true;
	end
else
	Make_figure = true;
end;

if (Make_figure == true)
	%%=========================================================================
	% Load project figure version.
	%--------------------------------------------------------------------------
	versionFile = [workingDir 'figVer.txt'];
	if exist(versionFile, 'file') == 2
		figVer = ['v' fileread(versionFile) '.'];
	else
		figVer = '';
	end;


	%% =========================================================================================
	% Load workspace variables saved in "CNV_SNP_hapmap_v4.m"
	%-------------------------------------------------------------------------------------------
	projectDir  = [main_dir '/users/' user '/projects/' project '/'];
	load([projectDir 'CNV_SNP_hapmap_v4.workspace_variables.mat']);


	%% ========================================================================
	Centromere_format_default	= 3;
	Yscale_nearest_even_ploidy	= true;
	HistPlot			= false;
	chromNum			= false;
	show_annotations		= true;
	Standard_display		= false;
	Linear_display			= true;
	Linear_displayBREAKS		= false;
	Low_quality_ploidy_estimate	= true;


	%% =========================================================================================
	% Load SNP/LOH data.
	%-------------------------------------------------------------------------------------------
	fprintf('\t|\tLoad SNP data.\n');
	load([projectDir 'SNP_' SNP_verString '.mat']);
	%    'chrom_SNPdata{chrom,i}(chrom_bin_SNP)'
	%        i = 1 : phased ratio data.
	%        i = 2 : unphased ratio data.
	%        i = 3 : phased coordinate data.
	%        i = 4 : unphased coordinate data.
	%        i = 5 : phased allele string.
	%        i = 6 : unphased allele string.


	%%================================================================================================
	% Process SNP/hapmap data to determine colors to be presented for each SNP locus.
	%-------------------------------------------------------------------------------------------------
	fprintf('\t|\tDetermine colors per SNP using hapmap.\n');
	%% =========================================================================================
	% Calculate allelic fraction cutoffs for each segment and populate data structure containing
	% SNP phasing information.
	%       chrom_SNPdata{chrom,1}{chrom_bin_SNP} = phased SNP ratio data.
	%       chrom_SNPdata{chrom,2}{chrom_bin_SNP} = unphased SNP ratio data.
	%       chrom_SNPdata{chrom,3}{chrom_bin_SNP} = phased SNP position data.
	%       chrom_SNPdata{chrom,4}{chrom_bin_SNP} = unphased SNP position data.
	%       chrom_SNPdata{chrom,5}{chrom_bin_SNP} = phased SNP allele strings.   (baseCall:alleleA/alleleB)
	%       chrom_SNPdata{chrom,6}{chrom_bin_SNP} = unphased SNP allele strings.
	%-------------------------------------------------------------------------------------------
	fprintf('\n\n### Calculate allelic ratio cutoffs using Gaussian fitting.\n');
	temp_holding = chrom_SNPdata;
	makeFitFigures = false;
	calculate_allelic_ratio_cutoffs;
	chrom_SNPdata = temp_holding;


	%% =========================================================================================
	% Define new colors for SNPs, using Gaussian fitting crossover points as ratio cutoffs.
	% Generate allele ratio track file.
	%-------------------------------------------------------------------------------------------
	source('../createAlleleRatiosTrack.m');


	%% =========================================================================================
	% Setup for main figure generation.
	%-------------------------------------------------------------------------------------------
	% load size definitions
	[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
	    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
	    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
	    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

	fprintf('\t|\tCount SNPs per chromosome bin.\n');
	% threshold for full color saturation in SNP/LOH figure.
	% synced to bases_per_bin as below, or defaulted to 50.

	%DRAGON Threshold set for good figures with Candida albicans. Other species with less SNPs may not be ideal.
	%full_data_threshold = 45;	%floor(bases_per_bin_SNP/100);	% C. albicans, highly heterozygous.
	%full_data_threshold = 4;	%floor(bases_per_bin_SNP/1000);	% C. parapsilosis, far less heterozygous.

	if (exist([genomeDir 'threshold.SNPs.txt'],'file') == 0)
		% default if no threshold.SNPs.txt file is found; works well for Candida albicans or genomes with large numbers of SNPs.
		full_data_threshold = 45;
	else
		full_data_threshold = str2num(fileread([genomeDir 'threshold.SNPs.txt']));
	end;

	Standard_fig = figure(1);

	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			for chrom_bin_SNP = 1:length(chrom_SNPdata{chrom,1})
				% the number of heterozygous data points in this bin.
				SNPs_count{chrom}(chrom_bin_SNP)                                 = length(chrom_SNPdata{chrom,1}{chrom_bin_SNP}) + length(chrom_SNPdata{chrom,2}{chrom_bin_SNP});

				% divide by the threshold for full color saturation in SNP/LOH figure.
				SNPs_to_fullData_ratio{chrom}(chrom_bin_SNP)                     = SNPs_count{chrom}(chrom_bin_SNP)/full_data_threshold;

				% any bins with more data than the threshold for full color saturation are limited to full saturation.
				SNPs_to_fullData_ratio{chrom}(SNPs_to_fullData_ratio{chrom} > 1) = 1;

				phased_plot{chrom}(chrom_bin_SNP)                                = length(chrom_SNPdata{chrom,1}{chrom_bin_SNP});             % phased data.
				phased_plot2{chrom}(chrom_bin_SNP)                               = phased_plot{chrom}(chrom_bin_SNP)/full_data_threshold;   %
				phased_plot2{chrom}(phased_plot2{chrom} > 1)                     = 1;                                                   %

				unphased_plot{chrom}(chrom_bin_SNP)                              = length(chrom_SNPdata{chrom,2}{chrom_bin_SNP});             % unphased data.
				unphased_plot2{chrom}(chrom_bin_SNP)                             = unphased_plot{chrom}(chrom_bin_SNP)/full_data_threshold; %
				unphased_plot2{chrom}(unphased_plot2{chrom} > 1)                 = 1;                                                   %
			end;
		end;
	end;

	fprintf('\n');
	largestchrom = find(chrom_width == max(chrom_width));
	largestchrom = largestchrom(1);


	%% =========================================================================================
	% Setup for figure generation.
	%-------------------------------------------------------------------------------------------
	if (Standard_display)
		fprintf('\t|\tSetup for main figure generation.\n');
		fig = figure(1);
	end;


	%% =========================================================================================
	% Setup for linear-view figure generation.
	%-------------------------------------------------------------------------------------------
	if (Linear_display)
		fprintf('\t|\tSetup for linear figure generation.\n');
		Linear_fig		= figure(2);
		Linear_genome_size	= sum(chrom_size);
		Linear_TickSize		= -0.01;		% negative for outside, percentage of longest chrom figure.
		maxY			= ploidyBase*2;		% maximum y-axis of chromosome cartoons.
		Linear_left		= Linear_left_start;	% used to track left end of current chromosome.
		axisLabelPosition_horiz	= 0.01125;
	end;
	axisLabelPosition_vert		= 0.01125;
	maxY_highTop			= ploidyBase*2*3;


	%% =========================================================================================
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
			c_prev = colorInit;
			c_post = colorInit;
			c_     = c_prev;
			infill = zeros(1,length(unphased_plot2{chrom}));
			colors = [];

			%% determine color of each bin.
			for chrom_bin_SNP = 1:ceil(chrom_size(chrom)/bases_per_bin_SNP)
				c_tot_post = SNPs_to_fullData_ratio{chrom}(chrom_bin_SNP)+SNPs_to_fullData_ratio{chrom}(chrom_bin_SNP);
				if (c_tot_post == 0)
					c_post = colorNoData;
					fprintf('.');
					if (mod(chrom_bin_SNP,100) == 0);   fprintf('\n');   end;
				else
					% Average of SNP position colors defined earlier.
					colorMix = [chrom_SNPdata_colorsC{chrom,1}(chrom_bin_SNP) chrom_SNPdata_colorsC{chrom,2}(chrom_bin_SNP) chrom_SNPdata_colorsC{chrom,3}(chrom_bin_SNP)];

					% Determine color to draw bin, accounting for limited data and data saturation.
					c_post =   colorMix   *   min(1,SNPs_to_fullData_ratio{chrom}(chrom_bin_SNP)) + ...
					           colorNoData*(1-min(1,SNPs_to_fullData_ratio{chrom}(chrom_bin_SNP)));
				end;
				colors(chrom_bin_SNP,1) = c_post(1);
				colors(chrom_bin_SNP,2) = c_post(2);
				colors(chrom_bin_SNP,3) = c_post(3);
			end;
			% standard : end determine color of each bin.

			% reverse order of color and CNV bins if chromosome is indicated as reversed in figure_definitions.txt file.
			if (chrom_figReversed(chrom) == 1)
				colors        = flipud(colors);
				CNVplot2{chrom} = fliplr(CNVplot2{chrom});
			end;

			if (Standard_display)
				figure(Standard_fig);

				% make standard chrom cartoons.
				left          = chrom_posX(chrom);
				bottom        = chrom_posY(chrom);
				width         = chrom_width(chrom);
				height        = chrom_height(chrom)*1.7;
				subplot('Position',[left bottom width height]);
				fprintf(['chrom' num2str(chrom) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
				hold on;

				%% standard : draw colorbars.
				for chrom_bin_SNP = 1:ceil(chrom_size(chrom)/bases_per_bin_SNP)
					x_ = [chrom_bin_SNP*bases_per_bin_SNP/bases_per_bin chrom_bin_SNP*bases_per_bin_SNP/bases_per_bin (chrom_bin_SNP-1)*bases_per_bin_SNP/bases_per_bin (chrom_bin_SNP-1)*bases_per_bin_SNP/bases_per_bin];
					y_ = [0 maxY maxY 0];
					c_post(1) = colors(chrom_bin_SNP,1);
					c_post(2) = colors(chrom_bin_SNP,2);
					c_post(3) = colors(chrom_bin_SNP,3);
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
				%% standard : end draw colorbars.

				%% standard : show centromere outlines/outline.
				Centromere_format = Centromere_format_default;
				x1       = cen_start(chrom)/bases_per_bin;
				x2       = cen_end(chrom)/bases_per_bin;
				leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
				rightEnd = chrom_size(chrom)/bases_per_bin;         % chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source('cartoon_stacked_0.m');
				elseif (Centromere_format == 1)
					source('cartoon_stacked_1.m');
				elseif (Centromere_format == 2) % sausage!
					source('cartoon_stacked_2.m');
				elseif (Centromere_format == 3) % improved sausage! (standard plot)
					source('cartoon_stacked_3.m');
				end;
				%% standard : end show centromere/outline.

				%% standard : CNV plot section.
				c_ = [0 0 0];
				fprintf(['\nmain-plot : chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
				fprintf(['ploidy     = ' num2str(ploidy)     '\n']);
				fprintf(['ploidyBase = ' num2str(ploidyBase) '\n']);
				for chrom_bin = 1:length(CNVplot2{chrom});   % ceil(chrom_size(chrom)/bases_per_bin)
					x_ = [chrom_bin chrom_bin chrom_bin-1 chrom_bin-1];
					CNVhistValue = CNVplot2{chrom}(chrom_bin);

					% The CNV-histogram values were normalized to a median value of 1.
					% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
					startY = maxY/2;
					if (Low_quality_ploidy_estimate)
						endY = min(maxY,CNVhistValue*ploidy*ploidyAdjust);
						if isna(CNVhistValue)
							endY = ploidy*ploidyAdjust;
						end;
					else
						endY = min(maxY,CNVhistValue*ploidy);
						if isna(CNVhistValue)
							endY = ploidy;
						end;
					end;
					y_ = [startY endY endY startY];

					% makes a blackbar for each bin.
					f = fill(x_,y_,c_);
					set(f,'linestyle','none');
				end;

				% standard : draw ploidy lines across plots for easier interpretation of CNV regions.
				% Inside chrom bounds grey lines.
				x2 = chrom_size(chrom)/bases_per_bin;
				for lineNum = 1:(ploidyBase*2-1)
					if lineNum ~= ploidyBase
						line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
					end;
				end;
				% Above chrom bounds grey lines.
				for lineNum = (ploidyBase*2+1):ploidyBase*6
					line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
				end;
				% Baseline ploidy black line.
				plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
				% standard : end ploidy lines plot section.

				% standard : axes labels etc.
				hold off;

				% standard : limit x-axis to range of chromosome.
				xlim([0,chrom_size(chrom)/bases_per_bin]);

				% standard : modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY_highTop]);
				else
					ylim([0,maxY_highTop]);
				end;
				%set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
				set(gca,'TickLength',[TickSize 0]);
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});
				if (chrom_figReversed(chrom) == 0)
					text(-50000/5000/2*3, maxY/2,chrom_label{chrom}, 'rotation', 90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)']
					text(-50000/5000/2*3, maxY/2,[chrom_label{chrom} char(10) '(reversed)'], 'rotation', 90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size/2);
				end;

				% standard : This section sets the Y-axis labelling, omitting crowded labels.
				max_label = ploidyBase * 6;
				if ploidyBase <= 2
					label_step = 1; % Plenty of room: label every step (1, 2, 3...)
				elseif mod(ploidyBase, 2) == 0
					label_step = ploidyBase / 2; % Even larger ploidy (e.g., 4 steps by 2, 6 steps by 3...)
				else
					label_step = ploidyBase; % Odd larger ploidy (e.g., 3 steps by 3, 5 steps by 5...)
				end;
				for label_val = label_step : label_step : max_label
					y_pos = maxY * (label_val / (ploidyBase * 2));
					text(axisLabelPosition_vert, y_pos, num2str(label_val), 'HorizontalAlignment', 'right', 'Fontsize', stacked_axis_font_size / 2);
				end;

				set(gca,'FontSize',gca_stacked_font_size);
				if (chrom == find(chrom_posY == max(chrom_posY)))
					if (useHapmap == false)
						if (project == parent)
							title([ project ' CNV & SNP/LOH'],'Interpreter','none','FontSize',stacked_title_size);
						else
							title([ project ' CNV & SNP/LOH vs. ' parent],'Interpreter','none','FontSize',stacked_title_size);
						end;
					else
						title([ project ' CNV & SNP/LOH vs. ' hapmap],'Interpreter','none','FontSize',stacked_title_size);
					end;
				end;
				hold on;
				% standard : end axes labels etc.

				if (displayBREAKS) && (show_annotations)
					chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
					for segment = 2:length(chrom_breaks{chrom})-1
						bP = chrom_breaks{chrom}(segment)*chrom_length;
						plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
					end;
				end;

				%% standard : show annotation locations
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
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
				% standard : end show annotation locations.


				%% =========================================================================================
				% Draw histplots to right of main chromosome cartoons.
				%-------------------------------------------------------------------------------------------
				hist_plot_subfigures_highTop;

				% standard : places chrom copy number to the right of the main chrom cartoons.
				if (chromNum)
					% subplot to show chrom copy number value.
					width  = 0.020;
					height = chrom_height(chrom);
					bottom = chrom_posY(chrom);
					if (HistPlot)
						subplot('Position',[(left + chrom_width(chrom) + 0.005 + width*(length(chromCopyNum{chrom})-1) + width+0.001) bottom width height]);
					else
						subplot('Position',[(left + chrom_width(chrom) + 0.005) bottom width height]);
					end;
					axis off square;
					set(gca,'YTick',[]);
					set(gca,'XTick',[]);
					if (length(chromCopyNum{chrom}) > 0)
						if (length(chromCopyNum{chrom}) == 1)
							chrom_string = num2str(chromCopyNum{chrom}(1));
						else
							chrom_string = num2str(chromCopyNum{chrom}(1));
							for i = 2:length(chromCopyNum{chrom})
								chrom_string = [chrom_string ',' num2str(chromCopyNum{chrom}(i))];
							end;
						end;
						text(0.1,0.5, chrom_string,'horizontalalignment', 'left', 'verticalalignment', 'middle', 'fontsize', linear_axis_font_size);
					end;
				end;
				% standard : end of chrom copy number at right of the main chrom cartons.


				%% =========================================================================================
				% Draw angleplots to left of main chromosome cartoons.
				%-------------------------------------------------------------------------------------------
				apply_phasing = true;
				angle_plot_subfigures;
			end;

%%%%%%%%%%%%%%%% Linear figure draw section

			%% Linear figure draw section
			if (Linear_display)
				figure(Linear_fig);
				Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
				hold on;

				%% linear : draw colorbars.
				for chrom_bin_SNP = 1:ceil(chrom_size(chrom)/bases_per_bin_SNP)
					x_ = [chrom_bin_SNP*bases_per_bin_SNP/bases_per_bin chrom_bin_SNP*bases_per_bin_SNP/bases_per_bin (chrom_bin_SNP-1)*bases_per_bin_SNP/bases_per_bin (chrom_bin_SNP-1)*bases_per_bin_SNP/bases_per_bin];
					y_ = [0 maxY maxY 0];
					c_post(1) = colors(chrom_bin_SNP,1);
					c_post(2) = colors(chrom_bin_SNP,2);
					c_post(3) = colors(chrom_bin_SNP,3);
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

				%% linear : show centromere/outline.
				Centromere_format = Centromere_format_default;
				x1       = cen_start(chrom)/bases_per_bin;
				x2       = cen_end(chrom)/bases_per_bin;
				leftEnd  = 0;                                   % 0.5*(5000/bases_per_bin);
				rightEnd = chrom_size(chrom)/bases_per_bin;         % chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
				if (Centromere_format == 0)
					source('cartoon_linear_0.m');
				elseif (Centromere_format == 1)
					source('cartoon_linear_1.m');
				elseif (Centromere_format == 2) % sausage!
					source('cartoon_linear_2.m');
				elseif (Centromere_format == 3) % improved sausage! (standard plot)
					source('cartoon_linear_3.m');
				end;
				% linear : end show centromere/outline.

				%% linear : CNV plot section.
				c_ = [0 0 0];
				fprintf(['linear-plot : chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
				for chrom_bin = 1:ceil(chrom_size(chrom)/bases_per_bin)
					x_ = [chrom_bin chrom_bin (chrom_bin-1) (chrom_bin-1)];
					CNVhistValue = CNVplot2{chrom}(chrom_bin);
					% The CNV-histogram values were normalized to a median value of 1.
					% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
					startY = maxY/2;
					if (Low_quality_ploidy_estimate)
						endY = CNVhistValue*ploidy*ploidyAdjust;
						if isna(CNVhistValue)
							endY = ploidy*ploidyAdjust;
						end;
					else
						endY = maxY,CNVhistValue*ploidy;
						if isna(CNVhistValue)
							endY = ploidy;
						end;
					end;
					y_ = [startY endY endY startY];
					% makes a blackbar for each bin.
					f = fill(x_,y_,c_);
					set(f,'linestyle','none');
				end;
				% linear : end CNV plot section.

				%% linear : draw ploidy lines across plots for easier interpretation of CNV regions.
				% Inside chrom bounds grey lines.
				x2 = chrom_size(chrom)/bases_per_bin;
				for lineNum = 1:(ploidyBase*2-1)
					if lineNum ~= ploidyBase
						line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
					end;
				end;
				% Above chrom bounds grey lines.
				for lineNum = (ploidyBase*2+1):ploidyBase*6
					line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
				end;
				% Baseline ploidy black line.
				plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);
				%% linear : end CNV plot ploidy lines section.

				%% linear : show segmental anueploidy breakpoints.
				if (Linear_displayBREAKS) && (show_annotations)
					chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
					for segment = 2:length(chrom_breaks{chrom})-1
						bP = chrom_breaks{chrom}(segment)*chrom_length;
						plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
					end;
				end;
				% linear : end segmental aneuploidy breakpoint section.

				% linear : show annotation locations
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
					annotation_location = (annotation_start+annotation_end)./2;
					for i = 1:length(annotation_location)
						if (annotation_chrom(i) == chrom)
							annotationloc   = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
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
				xlim([0,chrom_size(chrom)/bases_per_bin]);

				%% linear : modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY_highTop]);
				else
					ylim([0,maxY_highTop]);
				end;
				%set(gca,'TickLength',[(Linear_TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
				set(gca,'TickLength',[Linear_TickSize 0]);
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTickLabel',[]);

				if (first_chrom)
					% standard : This section sets the Y-axis labelling, omitting crowded labels.
					max_label = ploidyBase * 6;
					if ploidyBase <= 2
						label_step = 1; % Plenty of room: label every step (1, 2, 3...)
					elseif mod(ploidyBase, 2) == 0
						label_step = ploidyBase / 2; % Even larger ploidy (e.g., 4 steps by 2, 6 steps by 3...)
					else
						label_step = ploidyBase; % Odd larger ploidy (e.g., 3 steps by 3, 5 steps by 5...)
					end;
					for label_val = label_step : label_step : max_label
						y_pos = maxY * (label_val / (ploidyBase * 2));
						text(axisLabelPosition_vert, y_pos, num2str(label_val), 'HorizontalAlignment', 'right', 'Fontsize', linear_axis_font_size);
					end;
				end;
				set(gca,'FontSize',linear_gca_font_size);
				%end final reformatting.

				% adding title in the middle of the cartoon
				% note : adding title is done in the end since if placed upper
				% in the code somehow the plot function changes the title position
				% location
				if (rotate == 0 && chrom_size(chrom) ~= 0 )
					if (chrom_figReversed(chrom) == 0)
						title(chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
					else
						%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
						title([chrom_label{chrom} char(10) '(reversed)'],'Interpreter','tex','FontSize',round(linear_chrom_font_size/2),'Rotation',rotate);
					end;
				else
					if (chrom_figReversed(chrom) == 0)
						text((chrom_size(chrom)/bases_per_bin)/2,maxY_highTop+0.5,chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
					else
						%% [chrom_label{chrom} '\fontsize{' int2str(round(linear_chrom_font_size/2)) '}' char(10) '(reversed)']
						text((chrom_size(chrom)/bases_per_bin)/2,maxY_highTop+0.5,[chrom_label{chrom} char(10) '(reversed)'],'Interpreter','tex','FontSize',round(linear_chrom_font_size/2),'Rotation',rotate);
					end;
				end;
			end;

			if (Standard_display)
				% shift back to main figure generation.
				figure(Standard_fig);

				hold on;
			end;

			first_chrom = false;
		end;
	end;

	if (Standard_display)
		% Save primary genome figure. multiplying height to match height change here
                % commented out since fig.CNV-map.highTop.1 is not displayed to the user,
                % leaving code for debug options
                % set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height*2.71962616822]);
		fprintf('\n###\n### Saving stacked highTop figure.\n###\n');
		set(   Standard_fig, 'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
		saveas(Standard_fig, [projectDir 'fig.CNV-SNP-map.highTop.1.' figVer 'eps'], 'epsc');
		saveas(Standard_fig, [projectDir 'fig.CNV-SNP-map.highTop.1.' figVer 'png'], 'png' );
		delete(Standard_fig);

		%% change permissions of figures.
		system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.highTop.1.' figVer 'eps']);
		system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.highTop.1.' figVer 'png']);
	end;

	if (Linear_display)
		% Save horizontal aligned genome figure, multiplying height since this is a taller figure than default.
		fprintf('\n###\n### Saving linear highTop figure.\n###\n');
		set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height*2.71962616822]);
		saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.highTop.2.' figVer 'eps'], 'epsc');
		saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.highTop.2.' figVer 'png'], 'png' );
		delete(Linear_fig);

		%% change permissions of figures.
		system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.highTop.2.' figVer 'eps']);
		system(['chmod 774 ' projectDir 'fig.CNV-SNP-map.highTop.2.' figVer 'png']);
	end;
end
