function [] = CNV_manualLOH_v1(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

% hide figures during construction.
set(0,'DefaultFigureVisible','off');


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
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin              : Controls bin sizes for SNP/CNV fractions of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CNV data by ploidy.
%    chrom_max_width              : max width of chroms as fraction of figure width.
Linear_displayBREAKS   = false;

manualLOH_file = [main_dir '/users/' user '/projects/' project '/manualLOH.txt'];
fprintf(['\nLooking for "manualLOH.txt" file at : ' manualLOH_file '\n']);
if (exist(manualLOH_file,'file') == 0)
	fprintf(['\nNO MANUAL LOH BOX FILE WAS FOUND.\n']);
else
	fprintf(['\nA MANUAL LOH BOX FILE WAS FOUND, DRAWING FIGURE.\n']);

	Centromere_format           = 0;
	chrom_max_width               = 0.8;
	colorBars                   = true;
	blendColorBars              = false;
	show_annotations            = true;
	Yscale_nearest_even_ploidy  = true;
	AnglePlot                   = true;   % Show histogram of alleleic fraction at the left end of standard figure chromosomes.
	FillColors                  = true;   % Fill histogram using colors.
	show_uncalibrated           = false;  % Fill with single color instead of ratio call colors.
	HistPlot                    = true;   % Show histogram of CNV at the right end of standard figure chromosomes.
	chromNum                      = true;   % Show numerical etimates of copy number to the right of standard figure chromosomes.
	Linear_display              = true;   % Figure version with chromosomes laid out horizontally.
	Low_quality_ploidy_estimate = true    % Estimate error in overall ploidy estimate, assuming most common value is actually euploid.
	Output_CGD_annotations      = true;   % Generate CGD annotation files for analyzed datasets.


	%% =========================================================================================
	% Load FASTA file name from 'reference.txt' file for project.
	%-------------------------------------------------------------------------------------------
	userReference    = [main_dir '/users/' user '/genomes/' genome '/reference.txt'];
	defaultReference = [main_dir '/users/default/genomes/' genome '/reference.txt'];
	if (exist(userReference,'file') == 0)
		FASTA_string = strtrim(fileread(defaultReference));
	else
		FASTA_string = strtrim(fileread(userReference));
	end;
	[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


	%% =========================================================================================
	% Control variables for Candida albicans SC5314.
	%-------------------------------------------------------------------------------------------
	projectDir  = [main_dir '/users/' user '/projects/' project '/'];

	if (exist([[main_dir '/users/default/hapmaps/' hapmap '/']],'dir') == 7)
		hapmapDir  = [main_dir '/users/default/hapmaps/' hapmap '/'];
		hapmapUser = 'default';
		useHapmap  = true;
	elseif (exist([[main_dir '/users/' user '/hapmaps/' hapmap '/']],'dir') == 7)
		hapmapDir  = [main_dir '/users/' user '/hapmaps/' hapmap '/'];
		hapmapUser = user;
		useHapmap  = true;
	else
		hapmapDir  = [main_dir '/users/' user '/projects/' project '/'];
		parentFile = [main_dir '/users/' user '/projects/' project '/parent.txt'];
		hapmapUser = strtrim(fileread(parentFile));
		useHapmap  = false;
	end;

	genomeDir  = [main_dir '/users/' genomeUser '/genomes/' genome '/'];


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

	%% This block is normally calculated in FindChromSizes during CNV analysis.
	for usedchrom = 1:length(chrom_in_use)
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
	maxY             = ploidyBase*2;
	cen_tel_Xindent  = 5;
	cen_tel_Yindent  = maxY/5;

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

	fprintf(['\nGenerating LOH-map figure from ''' project ''' vs. (hapmap)''' hapmap ''' data.\n']);


	%% =========================================================================================
	% Load GC-bias corrected CNV data.
	%-------------------------------------------------------------------------------------------
	load([projectDir 'Common_CNV.mat']);       % 'CNVplot2','genome_CNV'
	[chrom_breaks, chromCopyNum, ploidyAdjust, chromCopyRsquared] = FindChromSizes_4(workingDir, Aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use, false)
	largestchrom = find(chrom_width == max(chrom_width));
	largestchrom = largestchrom(1);


	%% =========================================================================================
	% Test adjacent segments for no change in copy number estimate.
	%...........................................................................................
	% Adjacent pairs of segments with the same copy number will be fused into a single segment.
	% Segments with a <= zero copy number will be fused to an adjacetn segment.
	%-------------------------------------------------------------------------------------------
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			if (length(chromCopyNum{chrom}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.
				%% Merge any adjacent segments with the same copy number.
				% add break representing left end of chromosome.
				breakCount_new         = 1;
				chrom_breaks_new{chrom}    = [];
				chromCopyNum_new{chrom}    = [];
				chrom_breaks_new{chrom}(1) = 0.0;
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


	%% =========================================================================================
	% Setup for figure generation.
	%-------------------------------------------------------------------------------------------
	% load size definitions
	[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height,...
	    Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
	    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
	    gca_stacked_font_size,stacked_copy_font_size,max_chromom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);
	fig = figure(1);


	%% =========================================================================================
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


	%% =========================================================================================
	% Load manual LOH annotations from 'manualLOH.txt'
	%...........................................................................................
	% Example :	4   891320  1798508 153 204 204
	% Columns
	%	chromID
	%	startbp
	%	endbp
	%	R
	%	G
	%	B
	%-------------------------------------------------------------------------------------------
	manualLOH           = [];
	manualLOH_file_name = [main_dir '/users/' user '/projects/' project '/manualLOH.txt'];
	manualLOH_fid       = fopen(manualLOH_file_name, 'r');
	lines_analyzed      = 0;
	fprintf(['\t*----------------------*\n']);
	fprintf(['\t| Loading manualLOH.txt \n']);
	while not (feof(manualLOH_fid))
		lineData          = fgetl(manualLOH_fid);
		lines_analyzed    = lines_analyzed+1;
		manualLOH_chromID   = sscanf(lineData, '%s',1);
		manualLOH_startbp = sscanf(lineData, '%s',2);
		for i = 1:size(sscanf(lineData,'%s',1),2);
			manualLOH_startbp(1) = [];
		end;
		manualLOH_endbp   = sscanf(lineData, '%s',3);
		for i = 1:size(sscanf(lineData,'%s',2),2);
			manualLOH_endbp(1) = [];
		end;
		manualLOH_R   = sscanf(lineData, '%s',4);
		for i = 1:size(sscanf(lineData,'%s',3),2);
			manualLOH_R(1) = [];
		end;
		manualLOH_G   = sscanf(lineData, '%s',5);
		for i = 1:size(sscanf(lineData,'%s',4),2);
			manualLOH_G(1) = [];
		end;
		manualLOH_B   = sscanf(lineData, '%s',6);
		for i = 1:size(sscanf(lineData,'%s',5),2);
			manualLOH_B(1) = [];
		end;

		manualLOH_chromID   = str2double(manualLOH_chromID);
		manualLOH_startbp = str2double(manualLOH_startbp);
		manualLOH_endbp   = str2double(manualLOH_endbp);
		manualLOH_R       = str2double(manualLOH_R);
		manualLOH_G       = str2double(manualLOH_G);
		manualLOH_B       = str2double(manualLOH_B);

		manualLOH(lines_analyzed).chromID   = manualLOH_chromID;
		manualLOH(lines_analyzed).startbp = manualLOH_startbp;
		manualLOH(lines_analyzed).endbp   = manualLOH_endbp;
		manualLOH(lines_analyzed).R       = manualLOH_R;
		manualLOH(lines_analyzed).G       = manualLOH_G;
		manualLOH(lines_analyzed).B       = manualLOH_B;
		fprintf(['\t|     ' lineData '\n']);
	endwhile;
	fclose(manualLOH_fid);
	fprintf(['\t| manualLOH.txt loaded  \n']);
	fprintf(['\t*----------------------*\n']);


	%% =========================================================================================
	% Define colors for figure generation.
	%-------------------------------------------------------------------------------------------
	%define colors for colorBars plot
	colorNoData     = [1.0   1.0   1.0  ]; %used when no data is available for the bin.


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
			figure(fig);
			% make standard chrom cartoons.
			left          = chrom_posX(chrom);
			bottom        = chrom_posY(chrom);
			width         = chrom_width(chrom);
			height        = chrom_height(chrom);
			subPlotHandle = subplot('Position',[left bottom width height]);
			fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
			hold on;

			% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
			if (chrom_figReversed(chrom) == 1)
				% flip manual LOH data.
				if (length(manualLOH) > 0)
					for box = 1:length(manualLOH)
						if (manualLOH(box).chromID == chrom)
							manualLOH(box).startbp = chrom_size(chrom) - manualLOH(box).startbp + 1;
							manualLOH(box).endbp   = chrom_size(chrom) - manualLOH(box).endbp + 1;
						end;
					end;
				end;

				% flip CNV data
				CNVplot2{chrom} = fliplr(CNVplot2{chrom});
			end;

			% standard : draw manualLOH color boxes.
			if (length(manualLOH) > 0)
				for box = 1:length(manualLOH)
					if (manualLOH(box).chromID == chrom)
						bin_start = ceil(manualLOH(box).startbp/bases_per_bin);
						bin_end   = ceil(manualLOH(box).endbp/bases_per_bin);
						x_        = [bin_end bin_end bin_start-1 bin_start-1];
						y_        = [0 maxY maxY 0];
						c_(1)     = manualLOH(box).R/255;
						c_(2)     = manualLOH(box).G/255;
						c_(3)     = manualLOH(box).B/255;
						f         = fill(x_,y_,c_);
						set(f,'linestyle','none');
					end;
				end;
			end;

			%% standard : CNV plot section.
			c_ = [0 0 0];
			fprintf(['\nmain-plot : chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
			fprintf(['ploidy     = ' num2str(ploidy)     '\n']);
			fprintf(['ploidyBase = ' num2str(ploidyBase) '\n']);
			for chrom_bin = 1:length(CNVplot2{chrom});
				x_ = [chrom_bin chrom_bin chrom_bin-1 chrom_bin-1];
				CNVhistValue = CNVplot2{chrom}(chrom_bin);
				% The CNV-histogram values were normalized to a median value of 1.
				% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
				startY = maxY/2;
				if (Low_quality_ploidy_estimate == true)
					endY = CNVhistValue*ploidy*ploidyAdjust;
				else
					endY = CNVhistValue*ploidy;
				end;
				y_ = [startY endY endY startY];

				% makes a blackbar for each bin.
				f = fill(x_,y_,c_);
				set(f,'linestyle','none');
			end;

			% standard : draw lines across plots for easier interpretation of CNV regions.
			x2 = chrom_size(chrom)/bases_per_bin;
			for lineNum = 1:(ploidyBase*2-1)
				line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
			end;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			% standard : end CNV plot section.

			% standard : axes labels etc.
			hold off;
			xlim([0,chrom_size(chrom)/bases_per_bin]);

			% standard : modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
			if (chrom_figReversed(chrom) == 0)
				text(-50000/bases_per_bin/2*3, maxY/2,chrom_label{chrom}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
			else
				text(-50000/bases_per_bin/2*3, maxY/2,[chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)'], 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
			end;
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

			switch ploidyBase
				case 1
					text(axisLabelPosition_vert, maxY/2,     '1','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 2
					text(axisLabelPosition_vert, maxY/4,     '1','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 3
					text(axisLabelPosition_vert, maxY/2,     '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 4
					text(axisLabelPosition_vert, maxY/4,     '2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,       '8','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 5
					text(axisLabelPosition_vert, maxY/2,     '5','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '10','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 6
					text(axisLabelPosition_vert, maxY/4,     '3','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '6','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,   '9','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 7
					text(axisLabelPosition_vert, maxY/2,     '7','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '14','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
				case 8
					text(axisLabelPosition_vert, maxY/4,     '4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/2,     '8','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY/4*3,  '12','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
					text(axisLabelPosition_vert, maxY,      '16','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
			end;
			set(gca,'FontSize',stacked_axis_font_size);
			if (chrom == find(chrom_posY == max(chrom_posY)))
				title([ project ' vs. (hapmap)' hapmap ' SNP/LOH map'],'Interpreter','none','FontSize',stacked_title_size);
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
				fill([leftEnd   leftEnd   leftEnd+dx ],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'LineStyle', 'none');    % top left corner.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [dy        0         0   ],         [1.0 1.0 1.0], 'LineStyle', 'none');    % bottom left corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'LineStyle', 'none');    % top right corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [dy        0         0   ],         [1.0 1.0 1.0], 'LineStyle', 'none');    % bottom right corner.
				fill([x1-dx     x1        x2           x2+dx],[maxY      maxY-dy   maxY-dy  maxY],[1.0 1.0 1.0], 'LineStyle', 'none');    % top centromere.
				fill([x1-dx     x1        x2           x2+dx],[0         dy        dy       0   ],[1.0 1.0 1.0], 'LineStyle', 'none');    % bottom centromere.
				% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
				plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx    rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
				     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY     maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy     ],...
				      'Color',[0 0 0]);
			end;
			% standard : end show centromere.

			% standard : show annotation locations
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
			% standard : end show annotation locations.

			% standard : make CNV histograms to the right of the main chrom cartoons.
			if (HistPlot == true)
				width     = 0.020;
				height    = chrom_height(chrom);
				bottom    = chrom_posY(chrom);
				histAll   = [];
				histAll2  = [];
				smoothed  = [];
				smoothed2 = [];
				for segment = 1:length(chromCopyNum{chrom})
					subplot('Position',[(left+chrom_width(chrom)+0.005)+width*(segment-1) bottom width height]);
					% The CNV-histogram values were normalized to a median value of 1.
					for i = round(1+length(CNVplot2{chrom})*chrom_breaks{chrom}(segment)):round(length(CNVplot2{chrom})*chrom_breaks{chrom}(segment+1))
						if (Low_quality_ploidy_estimate == true)
							histAll{segment}(i) = CNVplot2{chrom}(i)*ploidy*ploidyAdjust;
						else
							histAll{segment}(i) = CNVplot2{chrom}(i)*ploidy;
						end;
					end;

					% make a histogram of CNV data, then smooth it for display.
					histogram_end                                    = 15;             % end point in copy numbers for the histogram, this should be way outside the expected range.
					histAll{segment}(histAll{segment}<=0)            = [];
					histAll{segment}(length(histAll{segment})+1)     = 0;              % endpoints added to ensure histogram bounds.
					histAll{segment}(length(histAll{segment})+1)     = histogram_end;
					histAll{segment}(histAll{segment}<0)             = [];             % crop off any copy data outside the range.
					histAll{segment}(histAll{segment}>histogram_end) = [];
					smoothed{segment}                                = smooth_gaussian(hist(histAll{segment},histogram_end*20),2,10);

					% make a smoothed version of just the endpoints used to ensure histogram bounds.
					histAll2{segment}(1)                             = 0;
					histAll2{segment}(2)                             = histogram_end;
					smoothed2{segment}                               = smooth_gaussian(hist(histAll2{segment},histogram_end*20),2,10);

					% subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints.
					smoothed{segment}                                = (smoothed{segment}-smoothed2{segment});
					smoothed{segment}                                = smoothed{segment}/max(smoothed{segment});

					% draw lines to mark whole copy number changes.
					plot([0;       0      ],[0; 1],'color',[0.00 0.00 0.00]);
					hold on;
					for i = 1:15
						plot([20*i;  20*i],[0; 1],'color',[0.75 0.75 0.75]);
					end;

					% draw histogram.
					area(smoothed{segment},'FaceColor',[0 0 0]);

					% Draw red ticks between histplot segments
					if (displayBREAKS == true) && (show_annotations == true)
						if (segment > 1)
							plot([-maxY*20/10*1.5 0],[0 0],  'Color',[1 0 0],'LineWidth',2);
						end;
					end;

					% Flip subfigure around the origin.
					view(-90,90);
					set(gca,'YDir','Reverse');

					% ensure subplot axes are consistent with main chrom plots.
					hold off;
					axis off;
					set(gca,'YTick',[]);    set(gca,'XTick',[]);
					ylim([0,1]);            xlim([0,maxY*20]);
					if (show_annotations == true)
						xlim([-maxY*20/10*1.5,maxY*20]);
					else
						xlim([0,maxY*20]);
					end;
				end;
			end;
			% standard : end of CNV histograms at right.

			% standard : places chrom copy number to the right of the main chrom cartoons.
			if (chromNum == true)
				% subplot to show chrom copy number value.
				width  = 0.020;
				height = chrom_height(chrom);
				bottom = chrom_posY(chrom);
				if (HistPlot == true)
					subplot('Position',[(left + chrom_width(chrom) + 0.005 + width*(length(chromCopyNum{chrom})-1) + width+0.001) bottom width height]);
				else
					subplot('Position',[(left + chrom_width(chrom) + 0.005) bottom width height]);
				end;
				axis off square;
				set(gca,'YTick',[]);
				set(gca,'XTick',[]);
				if (length(chromCopyNum{chrom}) == 1)
					chrom_string = num2str(chromCopyNum{chrom}(1));
				else
					chrom_string = num2str(chromCopyNum{chrom}(1));
					for i = 2:length(chromCopyNum{chrom})
						chrom_string = [chrom_string ',' num2str(chromCopyNum{chrom}(i))];
					end;
				end;
				text(0.1,0.5, chrom_string,'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',stacked_copy_font_size);
			end;
			% standard : end of chrom copy number at right of the main chrom cartons.

			%% END of standard figure draw section.



		    %% Linear figure draw section
		    if (Linear_display == true)
		        figure(Linear_fig);
		        Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
		        subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
		        Linear_left = Linear_left + Linear_width + Linear_chrom_gap;
		        hold on;

				% standard : draw manualLOH color boxes.
				if (length(manualLOH) > 0)
					for box = 1:length(manualLOH)
						if (manualLOH(box).chromID == chrom)
							bin_start = ceil(manualLOH(box).startbp/bases_per_bin);
							bin_end   = ceil(manualLOH(box).endbp/bases_per_bin);
							x_        = [bin_end bin_end bin_start-1 bin_start-1];
							y_        = [0 maxY maxY 0];
							c_(1)     = manualLOH(box).R/255;
							c_(2)     = manualLOH(box).G/255;
							c_(3)     = manualLOH(box).B/255;
							f         = fill(x_,y_,c_);
							set(f,'linestyle','none');
						end;
					end;
				end;

				% linear : CNV plot section.
				c_ = [0 0 0];
				fprintf(['linear-plot : chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
				for chrom_bin = 1:length(CNVplot2{chrom});
					x_ = [chrom_bin chrom_bin chrom_bin-1 chrom_bin-1];
					CNVhistValue = CNVplot2{chrom}(chrom_bin);
					% The CNV-histogram values were normalized to a median value of 1.
					% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
					startY = maxY/2;
					if (Low_quality_ploidy_estimate == true)
						endY = CNVhistValue*ploidy*ploidyAdjust;
					else
						endY = CNVhistValue*ploidy;
					end;
					y_ = [startY endY endY startY];
					% makes a blackbar for each bin.
					f = fill(x_,y_,c_);
					set(f,'linestyle','none');
				end;

				% linear : draw lines across plots for easier interpretation of CNV regions.
				x2 = chrom_size(chrom)/bases_per_bin;
				for lineNum = 1:(ploidyBase*2-1)
					line([0 x2], [maxY/(ploidyBase*2)*lineNum  maxY/(ploidyBase*2)*lineNum ],'Color',[0.85 0.85 0.85]);
				end;
				plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
				% linear : end CNV plot section.

				% linear : show segmental anueploidy breakpoints.
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
					fill([leftEnd   leftEnd   leftEnd+dx ],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'linestyle', 'none');  % top left corner.
					fill([leftEnd   leftEnd   leftEnd+dx ],       [dy        0         0   ],         [1.0 1.0 1.0], 'linestyle', 'none');  % bottom left corner.
					fill([rightEnd  rightEnd  rightEnd-dx],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'linestyle', 'none');  % top right corner.
					fill([rightEnd  rightEnd  rightEnd-dx],       [dy        0         0   ],         [1.0 1.0 1.0], 'linestyle', 'none');  % bottom right corner.
					fill([x1-dx     x1        x2           x2+dx],[maxY      maxY-dy   maxY-dy  maxY],[1.0 1.0 1.0], 'linestyle', 'none');  % top centromere.
					fill([x1-dx     x1        x2           x2+dx],[0         dy        dy       0   ],[1.0 1.0 1.0], 'linestyle', 'none');  % bottom centromere.
					% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
					plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
					      [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy],...
					      'Color',[0 0 0]);
				end;
				% linear : end show centromere.

		        % linear : show annotation locations
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
				if (first_chrom)
					% This section sets the Y-axis labelling.
					switch ploidyBase
					case 1
						text(axisLabelPosition_horiz, maxY/2,     '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 2
						text(axisLabelPosition_horiz, maxY/4,     '1','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 3
						text(axisLabelPosition_horiz, maxY/2,     '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 4
						text(axisLabelPosition_horiz, maxY/4,     '2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,       '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 5
						text(axisLabelPosition_horiz, maxY/2,     '5','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '10','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 6
						text(axisLabelPosition_horiz, maxY/4,     '3','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '6','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,   '9','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '12','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 7
						text(axisLabelPosition_horiz, maxY/2,     '7','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '14','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
					case 8
						text(axisLabelPosition_horiz, maxY/4,     '4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/2,     '8','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY/4*3,  '12','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
						text(axisLabelPosition_horiz, maxY,      '16','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
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


	%% ========================================================================
	% end stuff
	%==========================================================================

	%% Save figures.
	set(fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(fig,        [projectDir 'fig.CNV-manualLOH-map.1.' figVer 'eps'], 'epsc');
	saveas(fig,        [projectDir 'fig.CNV-manualLOH-map.1.' figVer 'png'], 'png');
	delete(fig);

	set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig, [projectDir 'fig.CNV-manualLOH-map.2.' figVer 'eps'], 'epsc');
	saveas(Linear_fig, [projectDir 'fig.CNV-manualLOH-map.2.' figVer 'png'], 'png');
	delete(Linear_fig);
end;

end
