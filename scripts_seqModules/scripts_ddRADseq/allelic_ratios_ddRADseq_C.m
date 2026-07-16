function [] = allelic_ratios_ddRADseq_C(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
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
%    Centromere_format          : Controls how centromeres are depicted.   [0..2]   '2' is pinched cartoon default.
%    bases_per_bin              : Controls bin sizes for SNP/CGH fractions of plot.
%    scale_type                 : 'Ratio' or 'Log2Ratio' y-axis scaling of copy number.
%                                 'Log2Ratio' does not properly scale CGH data by ploidy.
%    chrom_max_width              : max width of chroms as fraction of figure width.
Centromere_format           = 0;
chrom_max_width               = 0.8;
colorBars                   = true;
blendColorBars              = false;
show_annotations            = true;
Yscale_nearest_even_ploidy  = true;
Linear_display              = true;
Linear_displayBREAKS        = false;

fprintf('\n');
fprintf('#################################\n');
fprintf('## allelic_ratios_ddRADseq_C.m ##\n');
fprintf('#################################\n');


%%=========================================================================
% Load FASTA file name from 'reference.txt' file for project.
%--------------------------------------------------------------------------
userReference    = [main_dir 'users/' user '/genomes/' genome '/reference.txt'];
defaultReference = [main_dir 'users/default/genomes/' genome '/reference.txt'];
if (exist(userReference,'file') == 0)
	FASTA_string = strtrim(fileread(defaultReference));
else
	FASTA_string = strtrim(fileread(userReference));
end;
[FastaPath,FastaName,FastaExt] = fileparts(FASTA_string);


%%=========================================================================
% Control variables.
%--------------------------------------------------------------------------
projectDir = [main_dir 'users/' user '/projects/' project '/'];
genomeDir  = [main_dir 'users/' genomeUser '/genomes/' genome '/'];
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
	useParent  = false;
	parentDir  = projectDir;
	parentUSer = user;
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
num_chroms = length(chrom_size);

%% This block is normally calculated in FindChromSizes_4 in CNV analysis.
for usedchrom = 1:num_chroms
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


%%=========================================================================
%%= No further control variables below. ===================================
%%=========================================================================

% Sanitize user input of euploid state.
ploidyBase = round(str2num(ploidyBaseString));
if (ploidyBase > 4);   ploidyBase = 4;   end;
if (ploidyBase < 1);   ploidyBase = 1;   end;
fprintf(['\nEuploid base = "' num2str(ploidyBase) '"\n']);

% basic plot parameters not defined per genome.
TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
bases_per_bin    = max(chrom_size)/700;
maxY             = 50; % ploidyBase*2;
cen_tel_Xindent  = 5;
cen_tel_Yindent  = maxY/5;

%define colors for colorBars plot
colorNoData = [1.0   1.0   1.0  ]; %used when no data is available for the bin.
colorInit   = [0.5   0.5   0.5  ]; %external; used in blending at ends of chrom.
colorHET    = [0.0   0.0   0.0  ]; % near 1:1 ratio SNPs
colorOddHET = [0.0   1.0   0.0  ]; % Het, but not near 1:1 ratio SNPs.
colorHOM    = [1.0   0.0   0.0  ]; % Hom SNPs;

colorAB     = [0.667 0.667 0.667]; % heterozygous.
colorA      = [1.0   0.0   1.0  ]; % homozygous a:magenta.
colorB      = [0.0   1.0   1.0  ]; % homozygous b:cyan.

fprintf(['\nGenerating LOH-map figure from ''' project ''' vs. (hapmap)''' hapmap ''' data.\n']);

% Initializes vectors used to hold number of SNPs in each interpretation catagory for each chromosome region.
for chrom = 1:length(chrom_sizes)
	% 4 SNP interpretation catagories tracked.
	%	1 : phased ratio data.
	%	2 : unphased ratio data.
	%   3 : phased coordinate data.
	%   4 : unphased coordinate data.
	chrom_length = ceil(chrom_size(chrom)/bases_per_bin);
	for j = 1:4
		chrom_SNPdata{chrom,j} = cell(1,chrom_length);
	end;
	% fprintf(['0|' num2str(chrom) ':' num2str(length(chrom_SNPdata{chrom,1})) '\n']);
end;


%%================================================================================================
% Load SNP/LOH data.
%-------------------------------------------------------------------------------------------------
if (useHapmap)
	load([projectDir 'SNP_' SNP_verString '.all3.mat']);
	% child data:  'C_chrom_SNP_data_positions','C_chrom_SNP_data_ratios','C_chrom_count','C_chrom_baseCall','C_chrom_SNP_homologA','C_chrom_SNP_homologB','C_chrom_SNP_flipHomologs'
	% parent data: 'P_chrom_SNP_data_positions','P_chrom_SNP_data_ratios','P_chrom_count','P_chrom_baseCall','P_chrom_SNP_homologA','P_chrom_SNP_homologB','P_chrom_SNP_flipHomologs'
	%
	% C_chrom_SNP_data_positions = coordinate of SNP.
	% C_chrom_SNP_data_ratios    = allelic ratio of SNP.
	% C_chrom_count              = number of reads at SNP coordinate.
	% C_chrom_baseCall           = majority basecall of SNP.
	% C_chrom_SNP_homologA       = hapmap homolog a basecall.
	% C_chrom_SNP_homologB       = hapmap homolog b basecall.
	% C_chrom_SNP_flipHomologs   = does hapmap entry need flipped?
else
	load([projectDir 'SNP_' SNP_verString '.all1.mat']);
	% child data:  'C_chrom_SNP_data_positions','C_chrom_SNP_data_ratios','C_chrom_count'
	% parent data: 'P_chrom_SNP_data_positions','P_chrom_SNP_data_ratios','P_chrom_count'
	%
	% C_chrom_SNP_data_positions = coordinate of SNP.
	% C_chrom_SNP_data_ratios    = allelic ratio of SNP.
	% C_chrom_count              = number of reads at SNP coordinate.
end;

%
% Data to be used in secondary fire-plot:
%	X:Y = C_chrom_SNP_data_positions:C_chrom_SNP_data_ratios
%

%% ----------------------------------------------------------------------------------------
% Clean up ratio data by discarding perfectly homozygous data and low read depth data.
%------------------------------------------------------------------------------------------
for chrom = 1:num_chroms
	if (chrom_in_use(chrom) == 1)
		C_chrom_SNP_data_positions{chrom}(C_chrom_SNP_data_ratios{chrom} == 0) = [];
		C_chrom_count{             chrom}(C_chrom_SNP_data_ratios{chrom} == 0) = [];
		C_chrom_SNP_data_ratios{   chrom}(C_chrom_SNP_data_ratios{chrom} == 0) = [];

		C_chrom_SNP_data_positions{chrom}(C_chrom_SNP_data_ratios{chrom} == 1) = [];
		C_chrom_count{             chrom}(C_chrom_SNP_data_ratios{chrom} == 1) = [];
		C_chrom_SNP_data_ratios{   chrom}(C_chrom_SNP_data_ratios{chrom} == 1) = [];

		C_chrom_SNP_data_positions{chrom}(C_chrom_count{chrom} < 20) = [];
		C_chrom_SNP_data_ratios{   chrom}(C_chrom_count{chrom} < 20) = [];
		C_chrom_count{             chrom}(C_chrom_count{chrom} < 20) = [];
	end;
end;


%% ----------------------------------------------------------------------------------------
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

fig = figure(1);
largestchrom = find(chrom_width == max(chrom_width));
largestchrom = largestchrom(1);


%% -----------------------------------------------------------------------------------------
% Setup for linear-view figure generation.
%-------------------------------------------------------------------------------------------
if (Linear_display == true)
	Linear_fig = figure(2);
	Linear_genome_size   = sum(chrom_size);
	Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
	maxY                 = 50; % ploidyBase*2;
	Linear_left          = Linear_left_start;
	axisLabelPosition_horiz = 0.01125;
end;
axisLabelPosition_vert = 0.01125;


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
		figure(fig);
		% make standard chrom cartoons.
		left   = chrom_posX(chrom);
		bottom = chrom_posY(chrom);
		width  = chrom_width(chrom);
		height = chrom_height(chrom);
		subplot('Position',[left bottom width height]);
		hold on;
		fprintf(['\tfigposition = [' num2str(left) ' | ' num2str(bottom) ' | ' num2str(width) ' | ' num2str(height) ']\n']);

		% standard : axes labels etc.
		xlim([0,chrom_size(chrom)/bases_per_bin]);

		%% standard : modify y axis limits to show annotation locations if any are provided.
		if (length(annotations) > 0)
			ylim([-maxY/10*1.5,maxY]);
		else
			ylim([0,maxY]);
		end;
		set(gca,'YTick',[]);
		set(gca,'YTickLabel',[]);
		set(gca,'TickLength',[(TickSize*chrom_size(largestchrom)/chrom_size(chrom)) 0]); %ensures same tick size on all subfigs.
		if (chrom_figReversed(chrom) == 0)
			text(-50000/5000/2*3, maxY/2,chrom_label{chrom}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
		else
			text(-50000/5000/2*3, maxY/2,[chrom_label{chrom} '\fontsize{' int2str(round(stacked_chrom_font_size/2)) '}' char(10) '(reversed)'], 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
		end;
		set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
		set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

		% standard : This section sets the Y-axis labelling.
		text(axisLabelPosition_vert, maxY/4*0, '0'  ,'HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
		text(axisLabelPosition_vert, maxY/4*1, '1/4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
		text(axisLabelPosition_vert, maxY/4*2, '1/2','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
		text(axisLabelPosition_vert, maxY/4*3, '3/4','HorizontalAlignment','right','Fontsize',stacked_axis_font_size);
		text(axisLabelPosition_vert, maxY/4*4, '1'  ,'HorizontalAlignment','right','Fontsize',stacked_axis_font_size);

		set(gca,'FontSize',gca_stacked_font_size);
		if (chrom == find(chrom_posY == max(chrom_posY)))
			title([ project ' allelic fraction map'],'Interpreter','none','FontSize',stacked_title_size);
		end;
		% standard : end axes labels etc.

		% standard : show allelic ratio data.
		chrom_length                     = ceil(chrom_size(chrom)/bases_per_bin);
		dataX                          = (C_chrom_SNP_data_positions{chrom}/bases_per_bin)';
		dataY1                         = (C_chrom_SNP_data_ratios{chrom}*maxY)';
		dataY2                         = maxY - dataY1;
		if (length(dataX) > 0)
			[imageX,imageY,imageC] = smoothhist2D_4([dataX dataX 0 chrom_length], [dataY2 (maxY-dataY2) 0 0], 4,[chrom_length maxY],[chrom_length maxY]);
			imageC_correction      = imageC*0;
			for y = 1:maxY
				imageC_correction(y,:) = 1-abs(y-maxY/2)/(maxY/2);
			end;
			if (useHapmap)
				% Data only from hapmap loci, doesn't require adjustment.
				imageC = imageC.*(1+imageC_correction);
			else
				% With all data, the heterozygous data needs to be emphasized.
				imageC = imageC.*(1+imageC_correction.^2*16);
			end;
			image(imageX, imageY, imageC);
		end;
		% standard : end show allelic ratio data.

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
			% top left corner.
			c_ = [1.0 1.0 1.0];
			x_ = [leftEnd   leftEnd   leftEnd+dx];
			y_ = [maxY-dy   maxY      maxY      ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% bottom left corner.
			x_ = [leftEnd   leftEnd   leftEnd+dx];
			y_ = [dy        0         0         ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% top right corner.
			x_ = [rightEnd   rightEnd   rightEnd-dx];
			y_ = [maxY-dy    maxY       maxY      ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% bottom right corner.
			x_ = [rightEnd   rightEnd   rightEnd-dx];
			y_ = [dy         0          0         ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% top centromere.
			x_ = [x1-dx   x1        x2        x2+dx];
			y_ = [maxY    maxY-dy   maxY-dy   maxY];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% bottom centromere.
			x_ = [x1-dx   x1   x2   x2+dx];
			y_ = [0       dy   dy   0    ];
			f = fill(x_,y_,c_);
			set(f,'linestyle','none');
			% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
			plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
			     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy     ],...
			     'Color',[0 0 0]);
		end;
		% standard : end show centromere.

		% standard : show annotation locations
		if (show_annotations) && (length(annotations) > 0)
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
		end;
		% standard : end show annotation locations.
		hold off;

		%% Linear figure draw section
		if (Linear_display == true)
			figure(Linear_fig);
			Linear_width = Linear_chrom_max_width*chrom_size(chrom)/Linear_genome_size;
			subplot('Position',[Linear_left Linear_base Linear_width Linear_height]);
			hold on;
			Linear_left = Linear_left + Linear_width + Linear_chrom_gap;

			% linear : show allelic ratio data as 2D-smoothed scatter-plot.
			chrom_length                     = ceil(chrom_size(chrom)/bases_per_bin);
			dataX                          = (C_chrom_SNP_data_positions{chrom}/bases_per_bin)';
			dataY1                         = C_chrom_SNP_data_ratios{chrom};
			dataY2                         = (dataY1*maxY)';
			dataX(C_chrom_count{chrom}  <= 20) = [];
			dataY2(C_chrom_count{chrom} <= 20) = [];
			if (length(dataX) > 0)
				[imageX,imageY,imageC] = smoothhist2D_4([dataX dataX 0 chrom_length], [dataY2 (maxY-dataY2) 0 0], 4,[chrom_length maxY],[chrom_length maxY]);
				imageC_correction      = imageC*0;
				for y = 1:maxY
					imageC_correction(y,:) = 1-abs(y-maxY/2)/(maxY/2);
				end;
				if (useHapmap)
					% Data only from hapmap loci, doesn't require adjustment.
					imageC = imageC.*(1+imageC_correction);
				else
					% With all data, the heterozygous data needs to be emphasized.
					imageC = imageC.*(1+imageC_correction.^2*16);
				end;
				hold on;
				image(imageX, imageY, imageC);
			end;
			% linear : end show allelic ratio data.


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
				c_ = [1.0 1.0 1.0];
				% top left corner.
				x_ = [leftEnd   leftEnd   leftEnd+dx];        y_ = [maxY-dy   maxY      maxY        ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% bottom left corner.     
				x_ = [leftEnd   leftEnd   leftEnd+dx];        y_ = [dy        0         0           ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% top right corner.
				x_ = [rightEnd   rightEnd   rightEnd-dx];     y_ = [maxY-dy    maxY       maxY      ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% bottom right corner.
				x_ = [rightEnd   rightEnd   rightEnd-dx];     y_ = [dy         0          0         ];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% top centromere.
				x_ = [x1-dx   x1        x2        x2+dx];     y_ = [maxY    maxY-dy   maxY-dy   maxY];    f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% bottom centromere.
				x_ = [x1-dx   x1   x2   x2+dx];               y_ = [0       dy   dy   0    ];             f = fill(x_,y_,c_);    set(f,'linestyle','none');
				% draw outlines of chromosome cartoon.   (drawn after horizontal lines to that cartoon edges are not interrupted by horiz lines.
				plot([leftEnd   leftEnd   leftEnd+dx   x1-dx   x1        x2        x2+dx   rightEnd-dx   rightEnd   rightEnd   rightEnd-dx   x2+dx   x2   x1   x1-dx   leftEnd+dx   leftEnd],...
				     [dy        maxY-dy   maxY         maxY    maxY-dy   maxY-dy   maxY    maxY          maxY-dy    dy         0             0       dy   dy   0       0            dy],...
				      'Color',[0 0 0]);
			end;
			% linear : end show centromere.

			% linear : show annotation locations
			if (show_annotations) && (length(annotations) > 0)
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
			if (first_chrom == true)
				% This section sets the Y-axis labelling.
				text(axisLabelPosition_horiz, maxY/4*0, '0'  ,'HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*1, '1/4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*2, '1/2','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*3, '3/4','HorizontalAlignment','right','Fontsize',linear_axis_font_size);
				text(axisLabelPosition_horiz, maxY/4*4, '1'  ,'HorizontalAlignment','right','Fontsize',linear_axis_font_size);
			end;
			set(gca,'FontSize',linear_gca_font_size);
			% linear : end final reformatting.
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

			hold off;

			% shift back to main figure generation.
			figure(fig);
			first_chrom = false;
		end;
	end;
end;

%% Save figures.
% disabling stacked figure saving since the figure is not displayed, left
% for debug
%{
set(fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
saveas(fig,        [projectDir 'fig.allelic_ratio-map.b1.' figVer 'eps'], 'epsc');
saveas(fig,        [projectDir 'fig.allelic_ratio-map.b1.' figVer 'png'], 'png');
delete(fig);
%}

set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.b2.' figVer 'eps'], 'epsc');
saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.b2.' figVer 'png'], 'png');
delete(Linear_fig);

%% ========================================================================
% end stuff
%==========================================================================
end
