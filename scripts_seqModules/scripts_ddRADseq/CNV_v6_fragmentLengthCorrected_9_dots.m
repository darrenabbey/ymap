function [] = CNV_v6_fragmentLengthCorrected_9_dots(main_dir,user,genomeUser,project,parent,genome,ploidyEstimate,ploidyBase, ...
                                                    CNV_verString,displayBREAKS);
addpath('../');

%%=========================================================================
% Load project figure version.
%--------------------------------------------------------------------------
workingDir = [main_dir 'users/' user '/projects/' project '/'];
versionFile = [workingDir 'figVer.txt'];
if exist(versionFile, 'file') == 2
	figVer = ['v' fileread(versionFile) '.'];
else
	figVer = '';
end;


%% ========================================================================
% Generate CGH-type figures from RADseq data, using a reference dataset to correct for genome position-dependant biases.
%==========================================================================
Centromere_format_default   = 0;
Yscale_nearest_even_ploidy  = true;
HistPlot                    = true;
chromNum                      = true;
show_annotations            = true;
Linear_display              = true;
Linear_displayBREAKS        = false;
Low_quality_ploidy_estimate = true;
Smooth_place                = 1;    % 1 = smooth before reference normalization; 2 = smooth after reference normalization.


%%=========================================================================
% Load FASTA file name from 'reference.txt' file for project.
%--------------------------------------------------------------------------
Reference    = [main_dir 'users/' genomeUser '/genomes/' genome '/reference.txt'];
FASTA_string = strtrim(fileread(Reference));
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%=========================================================================
% Load restriction enzyme pair string from 'restrictionEnzymes.txt' file for project.
%--------------------------------------------------------------------------
restrictionEnzyme_file   = [main_dir 'users/' user '/projects/' project '/restrictionEnzymes.txt'];
restrictionEnzyme_string = strtrim(fileread(restrictionEnzyme_file));

if (strcmp(restrictionEnzyme_string,'BamHI_BclI') == 1)
	fit_length = 10000;
else
	fit_length = 1000;
end;

%%=========================================================================
% Control variables.
%--------------------------------------------------------------------------
projectDir = [main_dir 'users/' user       '/projects/' project '/'];
genomeDir  = [main_dir 'users/' genomeUser '/genomes/'  genome  '/'];
fprintf(['genome  = "' genome  '"\n']);
fprintf(['project = "' project '"\n']);
fprintf(['parent  = "' parent  '"\n']);

if (strcmp(project,parent) == 1)
	useParent  = false;
	parentUser = '';
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

[centromeres, chrom_sizes, figure_details, annotations, ploidy_default] = Load_genome_information(genomeDir);
[Aneuploidy] = [];

for i = 1:length(chrom_sizes)
	chrom_size(chrom_sizes(i).chrom)    = chrom_sizes(i).size;
end;
for i = 1:length(centromeres)
	cen_start(centromeres(i).chrom) = centromeres(i).start;
	cen_end(centromeres(i).chrom)   = centromeres(i).end;
end;
if (length(annotations) > 0)
	for i = 1:length(annotations)
		annotation_chrom(i)       = annotations(i).chrom;
		annotation_type{i}      = annotations(i).type;
		annotation_start(i)     = annotations(i).start;
		annotation_end(i)       = annotations(i).end;
		annotation_fillcolor{i} = annotations(i).fillcolor;
		annotation_edgecolor{i} = annotations(i).edgecolor;
		annotation_size(i)      = annotations(i).size;
	end;
end;
for i = 1:length(figure_details)
	if (figure_details(i).chrom == 0)
		key_posX   = figure_details(i).posX;
		key_posY   = figure_details(i).posY;
		key_width  = figure_details(i).width;
		key_height = figure_details(i).height;
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
num_chroms      = length(chrom_size);


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

% Sanitize user input of euploid state.
ploidyBase = round(str2num(ploidyBase));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
bases_per_bin    = max(chrom_size)/700;
maxY             = ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/5;

%% Determine reference genome FASTA file in use.
%  Read in and parse : "links_dir/main_script_dir/genome_specific/[genome]/reference.txt"
reference_file   = [main_dir 'users/' genomeUser '/genomes/' genome '/reference.txt'];
refernce_fid     = fopen(reference_file, 'r');
refFASTA         = fgetl(refernce_fid);
fclose(refernce_fid);


fprintf(['$$$ project = "' main_dir 'users/' user '/projects/' project '/fragment_CNV_data.mat"\n']);
if (useParent)
	fprintf(['$$$ parent  = "' main_dir 'users/' parentUser '/projects/' parent  '/fragment_CNV_data.mat"\n']);
end;



%
%%
%%%
%%%%
%%%%
%%%%
%%%
%%
%


%-------------------------------------------------------------------------------------------------
% Load 'Common_CNV.mat' file.
%-------------------------------------------------------------------------------------------------
fprintf('\nLoading "Common_CNV" data file for ddRADseq project.');
load([main_dir 'users/' user '/projects/' project '/Common_CNV.mat']);   % 'CNVplot2', 'genome_CNV'


Main_fig = figure(4);
set(gcf, 'Position', [0 70 1024 600]);

%% -----------------------------------------------------------------------------------------
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------
if (Linear_display == true)
	Linear_fig           = figure(5);
	Linear_genome_size   = sum(chrom_size);
	Linear_chrom_max_width = 0.91;               % width for all chromosomes across figure.  1.00 - leftMargin - rightMargin - subfigure gaps.
	Linear_left_start    = 0.02;               % left margin (also right margin).
	Linear_left_chrom_gap  = 0.07/(num_chroms-1);  % gaps between chrom subfigures.
	Linear_height        = 0.6;
	Linear_base          = 0.1;
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
	maxY                 = ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


%% -----------------------------------------------------------------------------------------
% Median normalize CNV data before figure generation.
%-------------------------------------------------------------------------------------------
% Gather CGH data for LOWESS fitting.
CNVdata_all      = [];
CNV_tracking_all = [];
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		CNVdata_all      = [CNVdata_all CNVplot2{chrom}];
		CNV_tracking_all = [CNV_tracking_all CNV_tracking{chrom}];
	end;
end;


% Calculate median of final CNV data per standard_bin.
% testData3                          = CNVdata_all
CNVdata_all(CNV_tracking_all == 0) = [];
% testData4                          = CNVdata_all
medianCNV                          = median(CNVdata_all);
fprintf(['\n\n***\n*** median CNV value of standard_bins = ' num2str(medianCNV) '\n***\n\n']);


for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		CNVplot2{chrom} = CNVplot2{chrom}/medianCNV;
	end;
end;


ploidy = str2num(ploidyEstimate);
fprintf(['\nPloidy string = "' num2str(ploidy) '"\n']);
[chrom_breaks, chromCopyNum, ploidyAdjust] = FindChromSizes_4(Aneuploidy,CNVplot2,ploidy,num_chroms,chrom_in_use)
largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


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
		figure(Main_fig);
		% make standard chrom cartoons.
		left   = chrom_posX(chrom);
		bottom = chrom_posY(chrom);
		width  = chrom_width(chrom);
		height = chrom_height(chrom);
		subplot('Position',[left bottom width height]);
		fprintf(['figposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\t']);
		hold on;

		% reverse order of color bins if chromosome is indicated as reversed in figure_definitions.txt file.
		if (chrom_figReversed(chrom) == 1)
			CNVplot2{chrom} = fliplr(CNVplot2{chrom});
		end;

		%% standard : cgh plot section.
		c_ = [0 0 0];
		fprintf(['chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
		for i = 1:length(CNVplot2{chrom});
			x_ = [i i i-1 i-1];
			if (CNVplot2{chrom}(i) == 0)
				CNVhistValue = 1;
			else
				CNVhistValue = CNVplot2{chrom}(i);
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

			% % makes a blackbar for each bin.
			% f = fill(x_,y_,c_);
			% set(f,'linestyle','none');
			% draw black dots for each bin.
			plot(x_,endY,'k.');
		end;
		x2 = chrom_size(chrom)/bases_per_bin;
		plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.

		%% standard : draw lines across plots for easier interpretation of CNV regions.
		switch ploidyBase
			case 1
			case 2
				line([0 x2], [maxY/4*1   maxY/4*1  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/4*3   maxY/4*3  ],'Color',[0.85 0.85 0.85]);
			case 3
				line([0 x2], [maxY/6*1   maxY/6*1  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/6*2   maxY/6*2  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/6*4   maxY/6*4  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/6*5   maxY/6*5  ],'Color',[0.85 0.85 0.85]);
			case 4
				line([0 x2], [maxY/8*1   maxY/8*1  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/8*2   maxY/8*2  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/8*3   maxY/8*3  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/8*5   maxY/8*5  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/8*6   maxY/8*6  ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/8*7   maxY/8*7  ],'Color',[0.85 0.85 0.85]);
			case 5
				line([0 x2], [maxY/10*2  maxY/10*2 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/10*4  maxY/10*4 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/10*6  maxY/10*6 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/10*8  maxY/10*8 ],'Color',[0.85 0.85 0.85]);
			case 6
				line([0 x2], [maxY/12*2  maxY/12*2 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/12*4  maxY/12*4 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/12*8  maxY/12*8 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/12*10 maxY/12*10],'Color',[0.85 0.85 0.85]);
			case 7
				line([0 x2], [maxY/14*2  maxY/14*2 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/14*4  maxY/14*4 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/14*6  maxY/14*6 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/14*8  maxY/14*8 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/14*10 maxY/14*10],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/14*12 maxY/14*12],'Color',[0.85 0.85 0.85]);
			case 8
				line([0 x2], [maxY/16*2  maxY/16*2 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/16*4  maxY/16*4 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/16*6  maxY/16*6 ],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/16*10 maxY/16*10],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/16*12 maxY/16*12],'Color',[0.85 0.85 0.85]);
				line([0 x2], [maxY/16*14 maxY/16*14],'Color',[0.85 0.85 0.85]);
		end;
		%% standard : end cgh plot section.

		% standard : axes labels etc.
		hold off;
		xlim([0,chrom_size(chrom)/bases_per_bin]);

		%% modify y axis limits to show annotation locations if any are provided.
		if (length(annotations) > 0)
			ylim([-maxY/10*1.5,maxY]);
		else
			ylim([0,maxY]);
		end;
		set(gca,'YTick',[]);
		set(gca,'YTickLabel',[]);
		set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
		if (chrom_figReversed(chrom) == 0)
			text(-50000/5000/2*3, maxY/2,chrom_label{chrom}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',20);
		else
			text(-50000/5000/2*3, maxY/2,[chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)'], 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',20);
		end;
		set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
		set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

		% standard : This section sets the Y-axis labelling.
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
		if (chrom == find(chrom_posY == max(chrom_posY)))
			title([ project ' CNV map'],'Interpreter','none','FontSize',24);
		end;

		hold on;
		%end axes labels etc.

		% standard : show segmental anueploidy breakpoints.
			if (displayBREAKS == true) && (show_annotations == true)
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
                                for segment = 2:length(chrom_breaks{chrom})-1
                                        bP = chrom_breaks{chrom}(segment)*chrom_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;

		% standard : show centromere.
		if (chrom_size(chrom) < 100000)
			Centromere_format = 1;
		else
			Centromere_format = Centromere_format_default;
		end;
		x1 = cen_start(chrom)/bases_per_bin;
		x2 = cen_end(chrom)/bases_per_bin;
		leftEnd  = 0.5*(5000/bases_per_bin);
		rightEnd = chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
		if (Centromere_format == 0)
			% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
			dx = cen_tel_Xindent;
			dy = cen_tel_Yindent;
			% draw white triangles at corners and centromere locations.
			fill([leftEnd   leftEnd   leftEnd+dx ],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % top left corner.
			fill([leftEnd   leftEnd   leftEnd+dx ],       [dy        0         0   ],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % bottom left corner.
			fill([rightEnd  rightEnd  rightEnd-dx],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % top right corner.
			fill([rightEnd  rightEnd  rightEnd-dx],       [dy        0         0   ],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % bottom right corner.
			fill([x1-dx     x1        x2           x2+dx],[maxY      maxY-dy   maxY-dy  maxY],[1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % top centromere.
			fill([x1-dx     x1        x2           x2+dx],[0         dy        dy       0   ],[1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % bottom centromere.
			% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
			plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
			     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0           0       dy   dy   0       0            dy     ],...
			      'Color',[0 0 0]);
		elseif (Centromere_format == 1)
			leftEnd  = 0;
			rightEnd = chrom_size(chrom)/bases_per_bin;

			% Minimal outline for examining very small sequence regions, such as C.albicans MTL locus.
			plot([leftEnd   leftEnd   rightEnd   rightEnd   leftEnd], [0   maxY   maxY   0   0], 'Color',[0 0 0]);
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
		%end show annotation locations.

		% standard : make CGH histograms to the right of the main chrom cartoons.
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
				for i = 2:length(chromCopyNum{chrom})
					chrom_string = [chrom_string ',' num2str(chromCopyNum{chrom}(i))];
				end;
			end;
			text(0.1,0.5, chrom_string,'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',24);
		end;


		%% Linear : figure draw section
		if (Linear_display == true)
			figure(Linear_fig);
			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			Linear_left = Linear_left + Linear_width + Linear_left_chrom_gap;
			hold on;
			title(chrom_label{chrom},'Interpreter','none','FontSize',20);

			% Linear : cgh plot section.
			c_ = [0 0 0];
			fprintf(['chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
			for i = 1:length(CNVplot2{chrom});
				x_ = [i i i-1 i-1];
				if (CNVplot2{chrom}(i) == 0)
					CNVhistValue = 1;
				else
					CNVhistValue = CNVplot2{chrom}(i);
				end;

				% DDD
				% The CNV-histogram values were normalized to a median value of 1.
				% The ratio of 'ploidy' to 'ploidyBase' determines where the data is displayed relative to the median line.
				startY = maxY/2;
				if (Low_quality_ploidy_estimate == true)
					endY = CNVhistValue*ploidy*ploidyAdjust;
				else
					endY = CNVhistValue*ploidy;
				end;
				y_ = [startY endY endY startY];

				% % makes a blackbar for each bin.
				% f = fill(x_,y_,c_);
				% set(f,'linestyle','none');
				% draw black dots for each bin.
				plot(x_,endY,'k.');
			end;
			x2 = chrom_size(chrom)/bases_per_bin;
			plot([0; x2], [maxY/2; maxY/2],'color',[0 0 0]);  % 2n line.
			% Linear : end CGH plot section.

			% Linear : draw lines across plots for easier interpretation of CNV regions.
			switch ploidyBase
				case 1
				case 2
					line([0 x2], [maxY/4*1   maxY/4*1  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/4*3   maxY/4*3  ],'Color',[0.85 0.85 0.85]);
				case 3
					line([0 x2], [maxY/6*1   maxY/6*1  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/6*2   maxY/6*2  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/6*4   maxY/6*4  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/6*5   maxY/6*5  ],'Color',[0.85 0.85 0.85]);
				case 4
					line([0 x2], [maxY/8*1   maxY/8*1  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*2   maxY/8*2  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*3   maxY/8*3  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*5   maxY/8*5  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*6   maxY/8*6  ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/8*7   maxY/8*7  ],'Color',[0.85 0.85 0.85]);
				case 5
					line([0 x2], [maxY/10*2  maxY/10*2 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/10*4  maxY/10*4 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/10*6  maxY/10*6 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/10*8  maxY/10*8 ],'Color',[0.85 0.85 0.85]);
				case 6
					line([0 x2], [maxY/12*2  maxY/12*2 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/12*4  maxY/12*4 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/12*8  maxY/12*8 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/12*10 maxY/12*10],'Color',[0.85 0.85 0.85]);
				case 7
					line([0 x2], [maxY/14*2  maxY/14*2 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/14*4  maxY/14*4 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/14*6  maxY/14*6 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/14*8  maxY/14*8 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/14*10 maxY/14*10],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/14*12 maxY/14*12],'Color',[0.85 0.85 0.85]);
				case 8
					line([0 x2], [maxY/16*2  maxY/16*2 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/16*4  maxY/16*4 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/16*6  maxY/16*6 ],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/16*10 maxY/16*10],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/16*12 maxY/16*12],'Color',[0.85 0.85 0.85]);
					line([0 x2], [maxY/16*14 maxY/16*14],'Color',[0.85 0.85 0.85]);
			end;
			%% Linear : end cgh plot section.

			% Linear : show segmental anueploidy breakpoints.
			if (Linear_displayBREAKS == true) && (show_annotations == true)
				chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
                                for segment = 2:length(chrom_breaks{chrom})-1
                                        bP = chrom_breaks{chrom}(segment)*chrom_length;
                                        plot([bP bP], [(-maxY/10*2.5) 0],  'Color',[1 0 0],'LineWidth',2);
                                end;
                        end;
			% Linear : end segmental aneuploidy breakpoint section.

			% Linear : show centromere.
			if (chrom_size(chrom) < 100000)
				Centromere_format = 1;
			else
				Centromere_format = Centromere_format_default;
			end;
			x1 = cen_start(chrom)/bases_per_bin;
			x2 = cen_end(chrom)/bases_per_bin;
			leftEnd  = 0.5*(5000/bases_per_bin);
			rightEnd = chrom_size(chrom)/bases_per_bin-0.5*(5000/bases_per_bin);
			if (Centromere_format == 0)
				% standard chromosome cartoons in a way which will not cause segfaults when running via commandline.
				dx = cen_tel_Xindent;
				dy = cen_tel_Yindent;
				% draw white triangles at corners and centromere locations.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % top left corner.
				fill([leftEnd   leftEnd   leftEnd+dx ],       [dy        0         0   ],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % bottom left corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [maxY-dy   maxY      maxY],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % top right corner.
				fill([rightEnd  rightEnd  rightEnd-dx],       [dy        0         0   ],         [1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % bottom right corner.
				fill([x1-dx     x1        x2           x2+dx],[maxY      maxY-dy   maxY-dy  maxY],[1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % top centromere.
				fill([x1-dx     x1        x2           x2+dx],[0         dy        dy       0   ],[1.0 1.0 1.0], 'EdgeColor',[1.0 1.0 1.0]);    % bottom centromere.
				% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
				plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx  leftEnd],...
				     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0           dy     ],...
				     'Color',[0 0 0]);
			elseif (Centromere_format == 1)
				leftEnd  = 0;
				rightEnd = chrom_size(chrom)/bases_per_bin;

				% Minimal outline for examining very small sequence regions, such as C.albicans MTL locus.
				plot([leftEnd   leftEnd   rightEnd   rightEnd   leftEnd], [0   maxY   maxY   0   0], 'Color',[0 0 0]);
			end;
			% Linear : end show centromere.

			% Linear : show annotation locations
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
			% Linear : end show annotation locations.

			% Linear :  Final formatting stuff.
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
			% Linear : end final reformatting.

			% shift back to main figure generation.
			figure(Main_fig);
			hold on;

			first_chrom = false;
		end;
	end;
end;


%% ========================================================================
% end stuff
%==========================================================================

% Save figures.
set(Main_fig,'PaperPosition',[0 0 8 6]*2);
saveas(Main_fig,   [projectDir 'fig.CNV-map.1.dots.' figVer 'eps'], 'epsc');
saveas(Main_fig,   [projectDir 'fig.CNV-map.1.dots.' figVer 'png'], 'png');
delete(Main_fig);

set(Linear_fig,'PaperPosition',[0 0 8 0.62222222]*2);
saveas(Linear_fig, [projectDir 'fig.CNV-map.2.dots.' figVer 'eps'], 'epsc');
saveas(Linear_fig, [projectDir 'fig.CNV-map.2.dots.' figVer 'png'], 'png');
delete(Linear_fig);

end
