function [] = CNV_SNP_hapmap_v5_RADseq(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimateString,ploidyBaseString, ...
                                       SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');

%% ========================================================================
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin              : Controls bin sizes for SNP/CGH fractions of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CGH data by ploidy.
%    Chr_max_width              : max width of chrs as fraction of figure width.
Centromere_format           = 0;
Chr_max_width               = 0.8;
colorBars                   = true;
blendColorBars              = false;
show_annotations            = true;
Yscale_nearest_even_ploidy  = true;
HistPlot                    = true;
ChrNum                      = true;
Linear_display              = true;
Linear_displayBREAKS        = false;
Low_quality_ploidy_estimate = true;
Output_CGD_annotations      = false;   % Generate CGD annotation files for analyzed datasets.

fprintf('\n');
fprintf('#########################################\n');
fprintf('## CNV_SNP_hapmap_v5_RADseq_RedGreen.m ##\n');
fprintf('#########################################\n');


%% =========================================================================================
% Load FASTA file name from 'reference.txt' file for project.
%-------------------------------------------------------------------------------------------
userReference    = [main_dir 'users/' user '/genomes/' genome '/reference.txt'];
defaultReference = [main_dir 'users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)   
	FASTA_string = strtrim(fileread(defaultReference));
else                    
	FASTA_string = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%% =========================================================================================
% Control variables.
%-------------------------------------------------------------------------------------------
projectDir = [main_dir 'users/' user '/projects/' project '/'];
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];
fprintf(['hapmap  = "' hapmap  '"\n']);
fprintf(['genome  = "' genome  '"\n']);
fprintf(['project = "' project '"\n']);
fprintf(['parent  = "' parent  '"\n']);

if (strcmp(hapmap,'') == 1)
	useHapmap = false;
else
	useHapmap = true;
	if (exist([main_dir 'users/default/hapmaps/' hapmap '/'], 'dir') == 7)
		hapmapDir  = [main_dir 'users/default/hapmaps/' hapmap '/'];   % system hapmap.
		hapmapUser = 'default';
	else
		hapmapDir  = [main_dir 'users/' user '/hapmaps/' hapmap '/'];  % user hapmap.
		hapmapUser = user;
	end;
end;
if (strcmp(project,parent) == 1)
	useParent = false;
else
	useParent = true;
	if (exist([main_dir 'users/default/projects/' parent '/'], 'dir') == 7)
		parentDir  = [main_dir 'users/default/projects/' parent '/'];   % system parent.
		parentUser = 'default';
	else
		parentDir  = [main_dir 'users/' user '/projects/' parent '/'];  % user parent.
		parentUser = user;
	end;
end;


if (useHapmap)
%
% Only run when compared vs. a hapmap.
%
	[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
	[Aneuploidy]                                                          = Load_dataset_information(projectDir);

	num_chrs = length(chr_sizes);

	for i = 1:length(chr_sizes)
		chr_size(i)  = 0;
		cen_start(i) = 0;
		cen_end(i)   = 0;
	end;
	for i = 1:length(chr_sizes)
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
			chr_id    (figure_details(i).chr) = figure_details(i).chr;
			chr_label {figure_details(i).chr} = figure_details(i).label;
			chr_name  {figure_details(i).chr} = figure_details(i).name;
			chr_posX  (figure_details(i).chr) = figure_details(i).posX;
			chr_posY  (figure_details(i).chr) = figure_details(i).posY;
			chr_width (figure_details(i).chr) = figure_details(i).width;
			chr_height(figure_details(i).chr) = figure_details(i).height;
			chr_in_use(figure_details(i).chr) = str2num(figure_details(i).useChr);
		end;
	end;
	num_chrs = length(chr_size);

	%% This block is normally calculated in FindChrSizes_4 in CNV analysis.
	for usedChr = 1:num_chrs
		if (chr_in_use(usedChr) == 1)
			% determine where the endpoints of ploidy segments are.
			chr_breaks{usedChr}(1) = 0.0;
			break_count = 1;
			if (length(Aneuploidy) > 0)
				for i = 1:length(Aneuploidy)
					if (Aneuploidy(i).chr == usedChr)
						break_count = break_count+1;
						chr_broken = true;
						chr_breaks{usedChr}(break_count) = Aneuploidy(i).break;
					end;
				end;
			end;
			chr_breaks{usedChr}(length(chr_breaks{usedChr})+1) = 1;
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
	TickSize         = -0.005;  %negative for outside, percentage of longest chr figure.
	bases_per_bin    = max(chr_size)/700;
	bases_per_SNPbin = bases_per_bin*10;
	maxY             = ploidyBase*2;
	cen_tel_Xindent  = 5;
	cen_tel_Yindent  = maxY/5;

	fprintf(['\nGenerating LOH-map figure from ''' project ''' vs. (hapmap)''' hapmap ''' data.\n']);


	%% =========================================================================================
	% Load CGH data after correction for GC and chr-end biases.
	%-------------------------------------------------------------------------------------------
	load([projectDir 'Common_CNV.mat']);       % 'CNVplot2','genome_CNV'
	[chr_breaks, chrCopyNum, ploidyAdjust] = FindChrSizes_4(Aneuploidy,CNVplot2,ploidy,num_chrs,chr_in_use)
	largestChr = find(chr_width == max(chr_width));


	%%================================================================================================
	% Load SNP/LOH data.
	%-------------------------------------------------------------------------------------------------
	LOH_file = [projectDir 'SNP_' SNP_verString '.reduced_RedGreen.mat'];
	if (exist(LOH_file,'file') == 2)
		load(LOH_file);                                   % 'chr_SNPdata','new_bases_per_bin','chr_SNPdata_colorsC', 'chr_SNPdata_colorsP'
	else
		load([projectDir 'SNP_' SNP_verString '.mat']);   % 'chr_SNPdata'
		new_bases_per_bin = bases_per_bin;
	end;


	%% =========================================================================================
	% Test adjacent segments for no change in copy number estimate.
	%...........................................................................................
	% Adjacent pairs of segments with the same copy number will be fused into a single segment.
	% Segments with a <= zero copy number will be fused to an adjacent segment.
	%-------------------------------------------------------------------------------------------
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			if (length(chrCopyNum{chr}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.

				%% Clear any segments with a copy number of zero.
				% add break representing left end of chromosome.
				breakCount_new         = 0;
				chr_breaks_new{chr}    = [];
				chrCopyNum_new{chr}    = [];
				chr_breaks_new{chr}(1) = 0.0;
				for segment = 1:(length(chrCopyNum{chr}))
					if (round(chrCopyNum{chr}(segment)) <= 0)
						% segment has a zero copy number, so don't add right end break to list.
					else
						% segment has a non-zero copy number, so add right end break.
						breakCount_new                        = breakCount_new + 1;
						chr_breaks_new{chr}(breakCount_new+1) = chr_breaks{chr}(segment+1);
						chrCopyNum_new{chr}(breakCount_new  ) = chrCopyNum{chr}(segment  );
					end;
				end;
				% If the last segment has a zero copy number, trim off the last added edge.
				if (breakCount_new > 0)
					if (round(chrCopyNum{chr}(length(chrCopyNum{chr}))) <= 0)
						chr_breaks_new{chr}(breakCount_new+1) = [];
						chrCopyNum_new{chr}(breakCount_new  ) = [];
						breakCount_new = breakCount_new-1;
					end;
				end;
				% add break representing right end of chromosome.
				breakCount_new = breakCount_new+1;
				chr_breaks_new{chr}(breakCount_new+1) = 1.0;
				% copy new lists to old.
				chr_breaks{chr} = chr_breaks_new{chr};
				chrCopyNum{chr} = [];
				chrCopyNum{chr} = chrCopyNum_new{chr};

				%% Merge any adjacent segments with the same copy number.
				% add break representing left end of chromosome.
				breakCount_new         = 1;
				chr_breaks_new{chr}    = [];
				chrCopyNum_new{chr}    = [];
				chr_breaks_new{chr}(1) = 0.0;
				fprintf(['\nlength(chrCopyNum{chr}) = ' num2str(length(chrCopyNum{chr})) '\n']);
				if (length(chrCopyNum{chr}) > 0)
					fprintf(['chrCopyNum{chr}(1) = ' num2str(chrCopyNum{chr}(1)) '\n']);
					chrCopyNum_new{chr}(1) = chrCopyNum{chr}(1);
					for segment = 1:(length(chrCopyNum{chr})-1)
						if (round(chrCopyNum{chr}(segment)) == round(chrCopyNum{chr}(segment+1)))
							% two adjacent segments have identical copyNum and should be fused into one; don't add boundry to new list.
						else
							% two adjacent segments have different copyNum; add boundry to new list.
							breakCount_new                      = breakCount_new + 1;
							chr_breaks_new{chr}(breakCount_new) = chr_breaks{chr}(segment+1);
							chrCopyNum_new{chr}(breakCount_new) = chrCopyNum{chr}(segment+1);
						end;
					end;
				end;
				% add break representing right end of chromosome.
				breakCount_new = breakCount_new+1;
				chr_breaks_new{chr}(breakCount_new) = 1.0;
				fprintf(['@@@ chr = ' num2str(chr) '\n']);
				fprintf(['@@@    chr_breaks_old = ' num2str(chr_breaks{chr})     '\n']);
				fprintf(['@@@    chrCopyNum_old = ' num2str(chrCopyNum{chr})     '\n']);
				fprintf(['@@@    chr_breaks_new = ' num2str(chr_breaks_new{chr}) '\n']);
				fprintf(['@@@    chrCopyNum_new = ' num2str(chrCopyNum_new{chr}) '\n']);
				% copy new lists to old.
				chr_breaks{chr} = chr_breaks_new{chr};
				chrCopyNum{chr} = [];
				chrCopyNum{chr} = chrCopyNum_new{chr};
			end;
		end;
	end;


	%% ====================================================================
	% Initialize CGD annotation output file.
	%----------------------------------------------------------------------
	if (Output_CGD_annotations == true)
		CGDid = fopen([projectDir 'CGD_annotations.' project  '.txt'], 'w');
		fprintf(CGDid,['track name=' project ' description="WGseq annotation of SNPs" useScore=0 itemRGB=On\n']);
	end;


	%% =========================================================================================
	% Setup for main figure generation.
	%-------------------------------------------------------------------------------------------
	Main_fig = figure(1);
	set(gcf, 'Position', [0 70 1024 600]);


	%% =========================================================================================
	% Setup for linear-view figure generation.
	%-------------------------------------------------------------------------------------------
	if (Linear_display == true)
		Linear_fig = figure(2);
		Linear_genome_size   = sum(chr_size);

		Linear_Chr_max_width = 0.91;               % width for all chromosomes across figure.  1.00 - leftMargin - rightMargin - subfigure gaps.
		Linear_left_start    = 0.02;               % left margin (also right margin).
		Linear_left_chr_gap  = 0.07/(num_chrs-1);  % gaps between chr subfigures.

		Linear_height        = 0.6;
		Linear_base          = 0.1;
		Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chr figure.
		maxY                 = ploidyBase*2;
		Linear_left          = Linear_left_start;

		axisLabelPosition_horiz = -50000/bases_per_bin;
		axisLabelPosition_horiz = 0.01125;
	end;

	axisLabelPosition_vert = -50000/bases_per_bin;
	axisLabelPosition_vert = 0.01125;


	%% =========================================================================================
	% Make figures
	%-------------------------------------------------------------------------------------------
	first_chr = true;
	for chr = 1:num_chrs
		if (chr_in_use(chr) == 1)
			fprintf(['-------------------------------- drawing subfigures for [chr' num2str(chr) '] --------------------------------\n']);
			figure(Main_fig);
			% make standard chr cartoons.
			left   = chr_posX(chr);
			bottom = chr_posY(chr);
			width  = chr_width(chr);
			height = chr_height(chr);
			subplot('Position',[left bottom width height]);
			fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);
			hold on;

			% standard : draw colorbars.
			if (useHapmap)
	                        for i = 1:ceil(chr_size(chr)/new_bases_per_bin)
	                                colorR   = chr_SNPdata_colorsC{chr,1}(i);
	                                colorG   = chr_SNPdata_colorsC{chr,2}(i);
	                                colorB   = chr_SNPdata_colorsC{chr,3}(i);
	                                if (colorR < 1) || (colorG < 1) || (colorB < 1)
	                                        plot([i i], [0 maxY],'Color',[colorR colorG colorB]);
	                                end;
	                        end;
			elseif (useParent)
				for i = 1:ceil(chr_size(chr)/new_bases_per_bin)
					datumY_C = chr_SNPdata{chr,2}(i)*maxY;
					datumY_P = chr_SNPdata{chr,4}(i)*maxY;
					plot([i/2 i/2], [maxY datumY_C     ],'Color',[1.0 0.0 0.0]);
					plot([i/2 i/2], [0    maxY-datumY_P],'Color',[1/3 1/3 1/3]);
				end;
			else
				for i = 1:ceil(chr_size(chr)/new_bases_per_bin)
					datumY_C = chr_SNPdata{chr,2}(i)*maxY;
					datumY_P = chr_SNPdata{chr,4}(i)*maxY;
					plot([i/2 i/2], [maxY datumY_P     ],'Color',[1/3 1/3 1/3]);
					plot([i/2 i/2], [0    maxY-datumY_P],'Color',[1/3 1/3 1/3]);
				end;
			end;
			% end standard : draw color bars.


			%% standard : cgh plot section.
			c_ = [0 0 0];
			fprintf(['\nmain-plot : chr' num2str(chr) ':' num2str(length(CNVplot2{chr})) '\n']);
			for chr_bin = 1:length(CNVplot2{chr});
				x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
				if (CNVplot2{chr}(chr_bin) == 0)
					CNVhistValue = 1;
				else
					CNVhistValue = CNVplot2{chr}(chr_bin);
				end;
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
			x2 = chr_size(chr)/bases_per_bin;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			switch ploidyBase
				case 1
				case 2
					line([0 x2], [maxY/4*1 maxY/4*1],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/4*3 maxY/4*3],'Color',[0.85 0.85 0.85]);
				case 3
					line([0 x2], [maxY/6*1 maxY/6*1],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/6*2 maxY/6*2],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/6*4 maxY/6*4],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/6*5 maxY/6*5],'Color',[0.85 0.85 0.85]);
				case 4
					line([0 x2], [maxY/8*1 maxY/8*1],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*2 maxY/8*2],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*3 maxY/8*3],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*5 maxY/8*5],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*6 maxY/8*6],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*7 maxY/8*7],'Color',[0.85 0.85 0.85]);
			end;
			% standard : end cgh plot section.


			% standard : axes labels etc.
			hold off;
			xlim([0,chr_size(chr)/bases_per_bin]);
			% standard : modify y axis limits to show annotation locations if any are provided.
			if (length(annotations) > 0)
				ylim([-maxY/10*1.5,maxY]);
			else
				ylim([0,maxY]);
			end;
			set(gca,'YTick',[]);
			set(gca,'YTickLabel',[]);
			set(gca,'TickLength',[(TickSize*chr_size(largestChr)/chr_size(chr)) 0]); %ensures same tick size on all subfigs.
			text(-50000/5000/2*3, maxY/2,     chr_label{chr}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',20);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});
			% This section sets the Y-axis labelling.
			switch ploidyBase
				case 1
					text(axisLabelPosition_vert, maxY/2,   '1','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY,     '2','HorizontalAlignment','right','Fontsize',10);
				case 2
					text(axisLabelPosition_vert, maxY/4,   '1','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY/2,   '2','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY/4*3, '3','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY,     '4','HorizontalAlignment','right','Fontsize',10);
				case 3
					text(axisLabelPosition_vert, maxY/2,   '3','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY,     '6','HorizontalAlignment','right','Fontsize',10);
				case 4
					text(axisLabelPosition_vert, maxY/4,   '2','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY/2,   '4','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY/4*3, '6','HorizontalAlignment','right','Fontsize',10);
					text(axisLabelPosition_vert, maxY,     '8','HorizontalAlignment','right','Fontsize',10);
			end;
			set(gca,'FontSize',12);
			if (chr == find(chr_posY == max(chr_posY)))
				title([ project ' CNV map'],'Interpreter','none','FontSize',24);
			end;
			hold on;
			% standard : end axes labels etc.

			if ((displayBREAKS == true) && (show_annotations == true))
				chr_length = ceil(chr_size(chr)/bases_per_bin);
				for segment = 2:length(chr_breaks{chr})-1
					bP = chr_breaks{chr}(segment)*chr_length;
					plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
				end;
			end;
    
			% standard : show centromere outlines and horizontal marks.
			x1 = cen_start(chr)/bases_per_bin;
			x2 = cen_end(chr)/bases_per_bin;
			leftEnd  = 0.5*5000/bases_per_bin;
			rightEnd = (chr_size(chr) - 0.5*5000)/bases_per_bin;
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
					if (annotation_chr(i) == chr)
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


			% standard : make CGH histograms to the right of the main chr cartoons.
			if (HistPlot == true)
				width     = 0.020;
				height    = chr_height(chr);
				bottom    = chr_posY(chr);
				histAll   = [];
				histAll2  = [];
				smoothed  = [];
				smoothed2 = [];
				for segment = 1:length(chrCopyNum{chr})
					subplot('Position',[(left+chr_width(chr)+0.005)+width*(segment-1) bottom width height]);
					% The CNV-histogram values were normalized to a median value of 1.
					for i = round(1+length(CNVplot2{chr})*chr_breaks{chr}(segment)):round(length(CNVplot2{chr})*chr_breaks{chr}(segment+1))
						if (Low_quality_ploidy_estimate == true)
							histAll{segment}(i) = CNVplot2{chr}(i)*ploidy*ploidyAdjust;
						else
							histAll{segment}(i) = CNVplot2{chr}(i)*ploidy;
						end;
					end;

					% make a histogram of CGH data, then smooth it for display.
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

					% ensure subplot axes are consistent with main chr plots.
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
			% standard : end of CGH histograms at right.


			% standard : places chr copy number to the right of the main chr cartoons.
			if (ChrNum == true)
				% subplot to show chr copy number value.
				width  = 0.020;
				height = chr_height(chr);
				bottom = chr_posY(chr);
				if (HistPlot == true)
					subplot('Position',[(left + chr_width(chr) + 0.005 + width*(length(chrCopyNum{chr})-1) + width+0.001) bottom width height]);
				else
					subplot('Position',[(left + chr_width(chr) + 0.005) bottom width height]);
				end;
				axis off square;
				set(gca,'YTick',[]);
				set(gca,'XTick',[]);
				if (length(chrCopyNum{chr}) > 0)
					if (length(chrCopyNum{chr}) == 1)
						chr_string = num2str(chrCopyNum{chr}(1));
					else
						chr_string = num2str(chrCopyNum{chr}(1));
						for i = 2:length(chrCopyNum{chr})
							chr_string = [chr_string ',' num2str(chrCopyNum{chr}(i))];
						end;
					end;
					text(0.1,0.5, chr_string,'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',24);
				end;
			end;
			%% END standard draw section.


			%% Linear figure draw section
			if (Linear_display == true)
				figure(Linear_fig);
				Linear_width = Linear_Chr_max_width*chr_size(chr)/Linear_genome_size;
				subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
				Linear_left = Linear_left + Linear_width + Linear_left_chr_gap;
				hold on;
				title(chr_label{chr},'Interpreter','none','FontSize',20);

				% linear : draw colorbars.
				if (useHapmap)
					for i = 1:ceil(chr_size(chr)/new_bases_per_bin)
						colorR   = chr_SNPdata_colorsC{chr,1}(i);
						colorG   = chr_SNPdata_colorsC{chr,2}(i);
						colorB   = chr_SNPdata_colorsC{chr,3}(i);
						if (colorR < 1) || (colorG < 1) || (colorB < 1)
							plot([i i], [0 maxY],'Color',[colorR colorG colorB]);
						end;
					end;
				elseif (useParent)
					for i = 1:ceil(chr_size(chr)/new_bases_per_bin)
						datumY_C = chr_SNPdata{chr,2}(i)*maxY;
						datumY_P = chr_SNPdata{chr,4}(i)*maxY;
						plot([i/2 i/2], [maxY datumY_C     ],'Color',[1.0 0.0 0.0]);
						plot([i/2 i/2], [0    maxY-datumY_P],'Color',[1/3 1/3 1/3]);
					end;
				else
					for i = 1:ceil(chr_size(chr)/new_bases_per_bin)
						datumY_C = chr_SNPdata{chr,2}(i)*maxY;
						datumY_P = chr_SNPdata{chr,4}(i)*maxY;
						plot([i/2 i/2], [maxY datumY_P     ],'Color',[1/3 1/3 1/3]);
						plot([i/2 i/2], [0    maxY-datumY_P],'Color',[1/3 1/3 1/3]);
					end;
				end;
				% end linear : draw colorbars.

				% linear : cgh plot section.
				c_ = [0 0 0];
				fprintf(['linear-plot : chr' num2str(chr) ':' num2str(length(CNVplot2{chr})) '\n']);
				for chr_bin = 1:length(CNVplot2{chr});
					x_ = [chr_bin chr_bin chr_bin-1 chr_bin-1];
					if (CNVplot2{chr}(chr_bin) == 0)
						CNVhistValue = 1;
					else
						CNVhistValue = CNVplot2{chr}(chr_bin);
					end;
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
				x2 = chr_size(chr)/bases_per_bin;
				plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
				switch ploidyBase
					case 1
					case 2
						line([0 x2], [maxY/4*1 maxY/4*1],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/4*3 maxY/4*3],'Color',[0.85 0.85 0.85]);
					case 3
						line([0 x2], [maxY/6*1 maxY/6*1],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/6*2 maxY/6*2],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/6*4 maxY/6*4],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/6*5 maxY/6*5],'Color',[0.85 0.85 0.85]);
					case 4
						line([0 x2], [maxY/8*1 maxY/8*1],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/8*2 maxY/8*2],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/8*3 maxY/8*3],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/8*5 maxY/8*5],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/8*6 maxY/8*6],'Color',[0.85 0.85 0.85]);
						line([0 x2], [maxY/8*7 maxY/8*7],'Color',[0.85 0.85 0.85]);
				end;
				% linear : end cgh plot section.

				% linear : show segmental anueploidy breakpoints.
				if (Linear_displayBREAKS == true) && (show_annotations == true)
					chr_length = ceil(chr_size(chr)/bases_per_bin);
                        	        for segment = 2:length(chr_breaks{chr})-1
                                	        bP = chr_breaks{chr}(segment)*chr_length;
                                        	plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
	                                end;
        	                end;

				% linear : show centromere.
				x1 = cen_start(chr)/bases_per_bin;
				x2 = cen_end(chr)/bases_per_bin;
				leftEnd  = 0.5*5000/bases_per_bin;
				rightEnd = (chr_size(chr) - 0.5*5000)/bases_per_bin;
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
						if (annotation_chr(i) == chr)
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
				xlim([0,chr_size(chr)/bases_per_bin]);
				% modify y axis limits to show annotation locations if any are provided.
				if (length(annotations) > 0)
					ylim([-maxY/10*1.5,maxY]);
				else
					ylim([0,maxY]);
				end;
				set(gca,'YTick',[]);
				set(gca,'YTickLabel',[]);
				set(gca,'TickLength',[(Linear_TickSize*chr_size(largestChr)/chr_size(chr)) 0]); %ensures same tick size on all subfigs.
				set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
				set(gca,'XTickLabel',[]);
				if (first_chr)
					% This section sets the Y-axis labelling.
					switch ploidyBase
						case 1
							text(axisLabelPosition_horiz, maxY/2,   '1','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY,     '2','HorizontalAlignment','right','Fontsize',10);
						case 2
							text(axisLabelPosition_horiz, maxY/4,   '1','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY/2,   '2','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY/4*3, '3','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY,     '4','HorizontalAlignment','right','Fontsize',10);
						case 3
							text(axisLabelPosition_horiz, maxY/2,   '3','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY,     '6','HorizontalAlignment','right','Fontsize',10);
						case 4
							text(axisLabelPosition_horiz, maxY/4,   '2','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY/2,   '4','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY/4*3, '6','HorizontalAlignment','right','Fontsize',10);
							text(axisLabelPosition_horiz, maxY,     '8','HorizontalAlignment','right','Fontsize',10);
					end;
				end;
				set(gca,'FontSize',12);
				%end final reformatting.
	        
				% shift back to main figure generation.
				figure(Main_fig);
				hold on;

				first_chr = false;
			end;
		end;
	end;


	%% ========================================================================
	% end stuff
	%==========================================================================
	%% Save figures.
	set(Main_fig,'PaperPosition',[0 0 8 6]*2);
	saveas(Main_fig,        [projectDir 'fig.CNV-SNP-map.RedGreen.1.eps'], 'epsc');
	saveas(Main_fig,        [projectDir 'fig.CNV-SNP-map.RedGreen.1.png'], 'png');
	delete(Main_fig);

	if (Linear_display == true)
		set(Linear_fig,'PaperPosition',[0 0 8 0.62222222]*2);
		saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.RedGreen.2.eps'], 'epsc');
		saveas(Linear_fig, [projectDir 'fig.CNV-SNP-map.RedGreen.2.png'], 'png');
		delete(Linear_fig);
	end;
elseif (useParent)
%
% Only run when compared vs. a parent.
%
	% Dataset was compared to a parent, so don't draw a Red/Green alternate colors plot.
	fprintf(['\n##\n## Parent in use, so "CNV_SNP_hapmap_v5_RADseq_RedGreen.m" is being skipped.\n##\n']);
else
%
% Only run when compared vs. itself.
%
	% Dataset was not compared to a hapmap or parent, so don't draw a Red/Green alternate colors plot.
	fprintf(['\n##\n## Neither parent or hapmap in use, so "CNV_SNP_hapmap_v5_RADseq_RedGreen.m" is being skipped.\n##\n']);
end;

end