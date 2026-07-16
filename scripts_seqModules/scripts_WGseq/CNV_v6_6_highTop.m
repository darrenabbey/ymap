function [] = CNV_v6_6_highTop(main_dir,user,genomeUser,project,genome,ploidyEstimateString,ploidyBaseString,CNV_verString,rDNA_verString,displayBREAKS, referencechrom);
addpath('../');

% hide figures during construction.
set(0,'DefaultFigureVisible','off');

fprintf('\t|\tCheck figure_options.txt to see if this figure is needed.\n');
if exist([main_dir '/users/' user '/projects/' project '/figure_options.txt'], 'file')
	figure_options = importdata([main_dir '/users/' user '/projects/' project '/figure_options.txt'],'\t',1);

        option         = figure_options{6,1};
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
	workingDir = [main_dir '/users/' user '/projects/' project '/'];
	versionFile = [workingDir 'figVer.txt'];
	if exist(versionFile, 'file') == 2
		figVer = ['v' fileread(versionFile) '.'];
	else
		figVer = '';
	end;


	%% ========================================================================
	Centromere_format_default	= 3;
	Yscale_nearest_even_ploidy	= true;
	HistPlot			= false;
	chromNum			= false;
	show_annotations		= true;
	Standard_display                = false;
	Linear_display			= true;
	Linear_displayBREAKS		= false;
	Low_quality_ploidy_estimate	= true;


	%%=========================================================================
	% Load FASTA file name from 'reference.txt' file for project.
	%--------------------------------------------------------------------------
	Reference	= [main_dir '/users/' genomeUser '/genomes/' genome '/reference.txt'];
	FASTA_string = strtrim(fileread(Reference));
	[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


	%%=========================================================================
	% Control variables.
	%--------------------------------------------------------------------------
	projectDir = [main_dir '/users/' user '/projects/' project '/'];
	genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];

	fprintf(['\n$$ projectDir : ' projectDir '\n']);
	fprintf([  '$$ genomeDir  : ' genomeDir  '\n']);
	fprintf([  '$$ genome	 : ' genome	 '\n']);
	fprintf([  '$$ project	: ' project	'\n']);

	[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
	Aneuploidy = [];

	num_chroms  = length(chrom_sizes);

	for i = 1:num_chroms
		chrom_size(i)  = 0;
		cen_start(i) = 0;
		cen_end(i)   = 0;
	end;
	for i = 1:num_chroms
		chrom_size(chrom_sizes(i).chrom)	= chrom_sizes(i).size;
		cen_start(centromeres(i).chrom) = centromeres(i).start;
		cen_end(centromeres(i).chrom)   = centromeres(i).end;
	end;
	if (length(annotations) > 0)
		fprintf(['\nAnnotations for ' genome '.\n']);
		for i = 1:length(annotations)
			annotation_chrom(i)	   = annotations(i).chrom;
			annotation_type{i}	  = annotations(i).type;
			annotation_start(i)	 = annotations(i).start;
			annotation_end(i)	   = annotations(i).end;
			annotation_fillcolor{i} = annotations(i).fillcolor;
			annotation_edgecolor{i} = annotations(i).edgecolor;
			annotation_size(i)	  = annotations(i).size;
			fprintf(['\t[' num2str(annotations(i).chrom) ':' annotations(i).type ':' num2str(annotations(i).start) ':' num2str(annotations(i).end) ':' annotations(i).fillcolor ':' ...
				annotations(i).edgecolor ':' num2str(annotations(i).size) ']\n']);
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
			chrom_id	       (figure_details(i).chrom) = figure_details(i).chrom;
			chrom_label      {figure_details(i).chrom} = figure_details(i).label;
			chrom_name       {figure_details(i).chrom} = figure_details(i).name;
			chrom_posX       (figure_details(i).chrom) = figure_details(i).posX;
			chrom_posY       (figure_details(i).chrom) = figure_details(i).posY*1.12;   %% + 0.1 + 0.025*figure_details(i).chrom;
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


	% Sanitize user input of euploid state base for species.
	ploidyBase = round(str2num(ploidyBaseString));
	if (ploidyBase > 4);   ploidyBase = 4;   end;
	if (ploidyBase < 1);   ploidyBase = 1;   end;
	fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

	% basic plot parameters not defined per genome.
	TickSize		= -0.005;  %negative for outside, percentage of longest chrom figure.
	maxY			= ploidyBase*2;
	cen_tel_Xindent		= 5;
	cen_tel_Yindent		= maxY/4;

	%% Load CNV and SNP figure resolutions.
	if (exist([genomeDir 'resolution.CNV.txt'],'file') == 0)
		bases_per_bin           = max(chrom_size)/700;
	else
		bases_per_bin           = max(chrom_size)/str2num(fileread([genomeDir 'resolution.CNV.txt']));
	end;
	if (exist([genomeDir 'resolution.SNPs.txt'],'file') == 0)
		bases_per_bin_SNP       = max(chrom_size)/700;
	else
		bases_per_bin_SNP       = max(chrom_size)/str2num(fileread([genomeDir 'resolution.SNPs.txt']));
	end;

	fprintf(['\nGenerating horizontal CNV highTop figure from ''' project ''' sequence data.\n']);


	%%================================================================================================
	% Load corrected CNV data for display.
	%-------------------------------------------------------------------------------------------------
	fprintf('\nCommon_CNV data file found, loading.\n');
	load([projectDir 'Common_CNV.mat']);   %% 'CNVplot2','genome_CNV'.


	%% -----------------------------------------------------------------------------------------
	% Calculate chromosome copy number from ploidy estimatre.
	%-------------------------------------------------------------------------------------------
	ploidy = str2num(ploidyEstimateString);
	[chrom_breaks, chromCopyNum, ploidyAdjust, chromCopyRsquared] = FindChromSizes_4(workingDir, Aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use, false);
	fprintf('\n');

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

	Standard_fig = figure(1);
	set(gcf, 'Position', [0 70 1024 600]);
	largestchrom = find(chrom_width == max(chrom_width));
	largestchrom = largestchrom(1);


	%% -----------------------------------------------------------------------------------------
	% Setup for linear-view figure generation.
	%-------------------------------------------------------------------------------------------
	if (Linear_display == true)
		Linear_fig		= figure(2);
		Linear_genome_size	= sum(chrom_size);
		Linear_TickSize		= -0.01;		% negative for outside, percentage of longest chrom figure.
		maxY			= ploidyBase*2;		% maximum y-axis of chromosome cartoons.
		Linear_left		= Linear_left_start;	% used to track left end of current chromosome.
		axisLabelPosition_horiz	= 0.01125;
	end;
	axisLabelPosition_vert		= 0.01125;
	maxY_highTop			= ploidyBase*2*3;

	%% Initialize copy numbers string.
	stringchromCNVs = '';


	%% -----------------------------------------------------------------------------------------
	% Median normalize CNV data before figure generation.
	%-------------------------------------------------------------------------------------------
	% Gather CNV data for LOWESS fitting.
	CNVdata_all = [];
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			CNVdata_all = [CNVdata_all   CNVplot2{chrom}];
		end;
	end;
	medianCNV = median(CNVdata_all)
	% avoid divding by zero
	if (medianCNV > 0)
		for chrom = 1:length(chrom_in_use)
			if (chrom_in_use(chrom) == 1)
				CNVplot2{chrom} = CNVplot2{chrom}/medianCNV;
			end;
		end;
	end;


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
			% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
			if (chrom_figReversed(chrom) == 1)
				CNVplot2{chrom} = fliplr(CNVplot2{chrom});
			end;

			if (Standard_display == true)
				%% Standard figure draw section.
				figure(Standard_fig);
				left   = chrom_posX(chrom);
				bottom = chrom_posY(chrom);
				width  = chrom_width(chrom);
				height = chrom_height(chrom)*1.7;
				subplot('Position',[left bottom width height]);
				fprintf(['chrom' num2str(chrom) ': figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
				hold on;


				%% show centromere.
				Centromere_format = Centromere_format_default;
				x1       = cen_start(chrom)/bases_per_bin;
				x2       = cen_end(chrom)/bases_per_bin;
				leftEnd  = 0;
				rightEnd = chrom_size(chrom)/bases_per_bin;
				if (Centromere_format == 0)
					source('cartoon_stacked_0.m');
				elseif (Centromere_format == 1)
					source('cartoon_stacked_1.m');
				elseif (Centromere_format == 2) % sausage!
					source('cartoon_stacked_2.m');
				elseif (Centromere_format == 3) % improved sausage! (standard plot)
					source('cartoon_stacked_3.m');
				end;
				% standard : end show centromere.


				%% standard : CNV plot section.
				c_ = [0 0 0];
				fprintf(['chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
				for i = 1:length(CNVplot2{chrom});
					x_ = [i i i-1 i-1];
					CNVhistValue = CNVplot2{chrom}(i);

					% The CNV-histogram values were normalized to a median value of 1.
					% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the
					% median line.
					startY = maxY/2;
					if (Low_quality_ploidy_estimate == true)
						endY = CNVhistValue*ploidy*ploidyAdjust;
						if isna(CNVhistValue)
							endY = ploidy*ploidyAdjust;
						end;
					else
						endY = CNVhistValue*ploidy;
						if isna(CNVhistValue)
							endY = ploidy;
						end;
					end;
					y_ = [startY endY endY startY];
					% makes a blackbar for each bin.
					f = fill(x_,y_,c_);
					set(f,'linestyle','none');
				end;
				% standard : end of : CNV plot section.


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
					text(-50000/5000/2*3, maxY*3/2,chrom_label{chrom}, 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', stacked_chrom_font_size);
				else
					%% [chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)']
					text(-50000/5000/2*3, maxY*3/2,[chrom_label{chrom} char(10) '(reversed)'], 'rotation',90, 'horizontalalignment', 'center', 'verticalalignment', 'bottom', 'fontsize', round(stacked_chrom_font_size/2));
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
					text(axisLabelPosition_vert, y_pos, num2str(label_val), 'HorizontalAlignment', 'right', 'Fontsize', stacked_axis_font_size/2);
				end;

				set(gca,'FontSize',gca_stacked_font_size/2);
				if (chrom == find(chrom_posY == max(chrom_posY)))
					title([ project ' CNV only'],'Interpreter','none','FontSize',stacked_title_size);
				end;
				hold on;
				% standard : end axes labels etc.

				%% standard : show segmental anueploidy breakpoints.
				if (displayBREAKS == true) && (show_annotations == true)
					chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
					for segment = 2:length(chrom_breaks{chrom})-1
						bP = chrom_breaks{chrom}(segment)*chrom_length;
						plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
					end;
				end;
				% standard : end of : show segmental aneuploidy breakpoints.

				% standard : show annotation locations
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
					annotation_location = (annotation_start+annotation_end)./2;
					for i = 1:length(annotation_location)
						if (annotation_chrom(i) == chrom)
							annotationLoc   = annotation_location(i)/bases_per_bin-0.5*(5000/bases_per_bin);
							annotationStart = annotation_start(i)/bases_per_bin-0.5*(5000/bases_per_bin);
							annotationEnd   = annotation_end(i)/bases_per_bin-0.5*(5000/bases_per_bin);
							if (strcmp(annotation_type{i},'dot') == 1)
								plot(annotationLoc,-maxY/10*1.5,'k:o','MarkerEdgeColor',annotation_edgecolor{i}, ...
																	  'MarkerFaceColor',annotation_fillcolor{i}, ...
																	  'MarkerSize',	 annotation_size(i));
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
			end;

%%%%%%%%%%%%%%%% Linear figure draw section

			%% Linear figure draw section.
			if (Linear_display == true)
				figure(Linear_fig);
				Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
				hold on;

				% linear : show centromere.
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
				% linear : end show centromere.

				%% linear : CNV plot section.
				c_ = [0 0 0];
				fprintf(['chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
				for i = 1:length(CNVplot2{chrom});
					x_ = [i i i-1 i-1];
					CNVhistValue = CNVplot2{chrom}(i);

					% The CNV-histogram values were normalized to a median value of 1.
					% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
					startY = maxY/2;
					if (Low_quality_ploidy_estimate == true)
						endY = CNVhistValue*ploidy*ploidyAdjust;
						if isna(CNVhistValue)
							endY = ploidy*ploidyAdjust;
						end;
					else
						endY = CNVhistValue*ploidy;
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
				if (Linear_displayBREAKS == true) && (show_annotations == true)
					chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
					for segment = 2:length(chrom_breaks{chrom})-1
							bP = chrom_breaks{chrom}(segment)*chrom_length;
							plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
					end;
				end;
				% linear : end of : show segmental aneuploidy breakpoints.

				%% linear : show annotation locations
				if (show_annotations) && (length(annotations) > 0)
					hold on;
					plot([leftEnd rightEnd], [-maxY/10*1.5 -maxY/10*1.5],'color',[0 0 0]);
					annotation_location = (annotation_start+annotation_end)./2;
					for i = 1:length(annotation_location)
						if (annotation_chrom(i) == chrom)
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
				% linear : end show annotation locations.

				%% linear : Final formatting stuff.
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
				%% linear : end final reformatting.

				% adding title in the middle of the cartoon
				% note: adding title is done in the end since if placed upper
				% in the code somehow the plot function changes the title position
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

			if (Standard_display == true)
				%% shift back to main figure generation.
				figure(Standard_fig);
				hold on;
			end;

			first_chrom = false;
		end;
	end;

	if (Standard_display == true)
		% Save primary genome figure. multiplying height to match height change here
		% commented out since fig.CNV-map.highTop.1 is not displayed to the user,
		% leaving code for debug options
		% set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height*2.71962616822]);
		fprintf('\n###\n### Saving stacked highTop figure.\n###\n');
		set(Standard_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
		saveas(Standard_fig, [projectDir 'fig.CNV-map.highTop.1.' figVer 'eps'], 'epsc');
		saveas(Standard_fig, [projectDir 'fig.CNV-map.highTop.1.' figVer 'png'], 'png');

		%% change permissions of figures.
		system(['chmod 774 ' projectDir 'fig.CNV-map.highTop.1.' figVer 'eps']);
		system(['chmod 774 ' projectDir 'fig.CNV-map.highTop.1.' figVer 'png']);
		delete(Standard_fig);
	end;

	if (Linear_display == true)
		% Save horizontal aligned genome figure, multiplying height since this is a taller figure than default.
		fprintf('\n###\n### Saving linear highTop figure.\n###\n');
		set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height*2.71962616822]);
		saveas(Linear_fig, [projectDir 'fig.CNV-map.highTop.2.' figVer 'eps'], 'epsc');
		saveas(Linear_fig, [projectDir 'fig.CNV-map.highTop.2.' figVer 'png'], 'png');
		delete(Linear_fig);

		%% change permissions of figures.
		system(['chmod 774 ' projectDir 'fig.CNV-map.highTop.2.' figVer 'eps']);
		system(['chmod 774 ' projectDir 'fig.CNV-map.highTop.2.' figVer 'png']);
	end;
end;

end
