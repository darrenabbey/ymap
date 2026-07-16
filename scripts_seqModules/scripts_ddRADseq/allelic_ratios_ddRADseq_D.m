function [] = allelic_ratios_ddRADseq_D(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
addpath('../');


%% =========================================================================================
% Load workspace variables saved in "allelic_ratios_ddRADseq_D.m"
%-------------------------------------------------------------------------------------------
projectDir  = [main_dir 'users/' user '/projects/' project '/'];
load([projectDir 'allelic_ratios_ddRADseq_B.workspace_variables.mat']);

if ((useHapmap) || (useParent))
	fprintf(['\n##\n## Hapmap in use, so "allelic_ratios_ddRADseq_D.m" is being processed.\n##\n']);

	%% =========================================================================================
	% Define colors for figure generation.
	%-------------------------------------------------------------------------------------------
	fprintf('\t|\tDefine colors used in figure generation.\n');
	phased_and_unphased_color_definitions;

	%% =========================================================================================
	% Calculate allelic fraction cutoffs for each chromosome and chromosome segment.
	%-------------------------------------------------------------------------------------------
	calculate_allelic_ratio_cutoffs;


	%%================================================================================================
	% Process SNP/hapmap data to determine colors for presentation.
	%-------------------------------------------------------------------------------------------------
	%%%% chrom_SNPdata{chrom,1}{pos} = phased SNP ratio data.
	%%%% chrom_SNPdata{chrom,2}{pos} = unphased SNP ratio data.
	%%%% chrom_SNPdata{chrom,3}{pos} = phased SNP position data.
	%%%% chrom_SNPdata{chrom,4}{pos} = unphased SNP position data.
	%%%% chrom_SNPdata{chrom,5}{pos} = flipper value for phased SNP.
	%%%% chrom_SNPdata{chrom,6}{pos} = flipper value for unphased SNP.
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			if (length(C_chrom_count{chrom}) > 1)
				%
				% Determining colors for each SNP coordinate.
				%
				for SNP = 1:length(C_chrom_count{chrom})
					coordinate                      = C_chrom_SNP_data_positions{chrom}(SNP);
					pos                             = ceil(coordinate/new_bases_per_bin);
					localCopyEstimate               = round(CNVplot2{chrom}(pos)*ploidy*ploidyAdjust);
					baseCall                        = C_chrom_baseCall{        chrom}{SNP};
					homologA                        = C_chrom_SNP_homologA{    chrom}{SNP};
					homologB                        = C_chrom_SNP_homologB{    chrom}{SNP};
					flipper                         = C_chrom_SNP_flipHomologs{chrom}(SNP);
					allelic_ratio                   = C_chrom_SNP_data_ratios{ chrom}(SNP);
					% Allelic ratio here is the ratio of the majority read call to all reads.
					% The consequence of this is that it will always be on the range [0.5 .. 1.0].
					if (flipper == 10)                         % Variable 'flipper' value of '10' indicates no phasing information is available in the hapmap.
						baseCall                = 'Z';     % Variable 'baseCall' value of 'Z' will prevent either hapmap allele from matching and so unphased ratio colors will be used in the following section.
						chrom_SNPdata{chrom,2}{pos} = [chrom_SNPdata{chrom,2}{pos} allelic_ratio 1-allelic_ratio];
						chrom_SNPdata{chrom,4}{pos} = [chrom_SNPdata{chrom,4}{pos} coordinate    coordinate     ];
						chrom_SNPdata{chrom,6}{pos} = [chrom_SNPdata{chrom,6}{pos} flipper       flipper        ];
					elseif (flipper == 1)
						temp                    = homologA;
						homologA                = homologB;
						homologB                = temp;
						if (baseCall == homologA)
							allelic_ratio = 1-allelic_ratio;
						end;
						chrom_SNPdata{chrom,1}{pos} = [chrom_SNPdata{chrom,1}{pos} allelic_ratio];
						chrom_SNPdata{chrom,3}{pos} = [chrom_SNPdata{chrom,3}{pos} coordinate   ];
						chrom_SNPdata{chrom,5}{pos} = [chrom_SNPdata{chrom,5}{pos} flipper      ];
					else % (flipper == 0)
						if (baseCall == homologA)
							allelic_ratio = 1-allelic_ratio;
						end;
						chrom_SNPdata{chrom,1}{pos} = [chrom_SNPdata{chrom,1}{pos} allelic_ratio];
						chrom_SNPdata{chrom,3}{pos} = [chrom_SNPdata{chrom,3}{pos} coordinate   ];
						chrom_SNPdata{chrom,5}{pos} = [chrom_SNPdata{chrom,5}{pos} flipper      ];
					end;

					% identify the segment containing the SNP.
					segmentID                       = 0;
					for segment = 1:(length(chromCopyNum{chrom}))
						segment_start           = chrom_breaks{chrom}(segment  )*chrom_size(chrom);
						segment_end             = chrom_breaks{chrom}(segment+1)*chrom_size(chrom);
						if (coordinate > segment_start) && (coordinate <= segment_end)
							segmentID       = segment;
						end;
					end;

					% Load cutoffs between Gaussian fits performed earlier.
					segment_copyNum                 = round(chromCopyNum{              chrom}(segmentID));
					actual_cutoffs                  = chromSegment_actual_cutoffs{     chrom}{segmentID};
					mostLikelyGaussians             = chromSegment_mostLikelyGaussians{chrom}{segmentID};
					SNPratio_int                    = (allelic_ratio)*199+1;

					% Identify the allelic ratio region containing the SNP.
					cutoffs                         = [1 actual_cutoffs 200];
					ratioRegionID                   = 0;
					for GaussianRegionID = 1:length(mostLikelyGaussians)
						cutoff_start            = cutoffs(GaussianRegionID  );
						cutoff_end              = cutoffs(GaussianRegionID+1);
						if (GaussianRegionID == 1)
							if (SNPratio_int >= cutoff_start) && (SNPratio_int <= cutoff_end)
								ratioRegionID   = mostLikelyGaussians(GaussianRegionID);
							end;
						else
							if (SNPratio_int > cutoff_start) && (SNPratio_int <= cutoff_end)
								ratioRegionID   = mostLikelyGaussians(GaussianRegionID);
							end;
						end;
					end;

					allelicFraction                = C_chrom_SNP_data_ratios{chrom}(SNP);
					if (segment_copyNum <= 0);              colorList = colorNoData;
					elseif (segment_copyNum == 1)
															colorList = alternate_color_1of1;
					elseif (segment_copyNum == 2)
						if (ratioRegionID == 3);            colorList = alternate_color_2of2;
						elseif (ratioRegionID == 2);        colorList = alternate_color_1of2;
						else                                colorList = alternate_color_2of2;
						end;
					elseif (segment_copyNum == 3)
						if (ratioRegionID == 4);            colorList = alternate_color_3of3;
						elseif (ratioRegionID == 3);        colorList = alternate_color_2of3;
						elseif (ratioRegionID == 2);        colorList = alternate_color_2of3;
						else                                colorList = alternate_color_3of3;
						end;
					elseif (segment_copyNum == 4)
						if (ratioRegionID == 5);            colorList = alternate_color_4of4;
						elseif (ratioRegionID == 4);        colorList = alternate_color_3of4;
						elseif (ratioRegionID == 3);        colorList = alternate_color_2of4;
						elseif (ratioRegionID == 2);        colorList = alternate_color_3of4;
						else                                colorList = alternate_color_4of4;
						end;
					elseif (segment_copyNum == 5)
						if (ratioRegionID == 6);            colorList = alternate_color_5of5;
						elseif (ratioRegionID == 5);        colorList = alternate_color_4of5;
						elseif (ratioRegionID == 4);        colorList = alternate_color_3of5;
						elseif (ratioRegionID == 3);        colorList = alternate_color_3of5;
						elseif (ratioRegionID == 2);        colorList = alternate_color_4of5;
						else                                colorList = alternate_color_5of5;
						end;
					elseif (segment_copyNum == 6)
						if (ratioRegionID == 7);            colorList = alternate_color_6of6;
						elseif (ratioRegionID == 6);        colorList = alternate_color_5of6;
						elseif (ratioRegionID == 5);        colorList = alternate_color_4of6;
						elseif (ratioRegionID == 4);        colorList = alternate_color_3of6;
						elseif (ratioRegionID == 3);        colorList = alternate_color_4of6;
						elseif (ratioRegionID == 2);        colorList = alternate_color_5of6;
						else                                colorList = alternate_color_6of6;
						end;
					elseif (segment_copyNum == 7)
						if (ratioRegionID == 8);            colorList = alternate_color_7of7;
						elseif (ratioRegionID == 7);        colorList = alternate_color_6of7;
						elseif (ratioRegionID == 6);        colorList = alternate_color_5of7;
						elseif (ratioRegionID == 5);        colorList = alternate_color_4of7;
						elseif (ratioRegionID == 3);        colorList = alternate_color_4of7;
						elseif (ratioRegionID == 3);        colorList = alternate_color_5of7;
						elseif (ratioRegionID == 2);        colorList = alternate_color_6of7;
						else                                colorList = alternate_color_7of7;
						end;
					elseif (segment_copyNum == 8)
						if (ratioRegionID == 9);            colorList = alternate_color_8of8;
						elseif (ratioRegionID == 8);        colorList = alternate_color_7of8;
						elseif (ratioRegionID == 7);        colorList = alternate_color_6of8;
						elseif (ratioRegionID == 6);        colorList = alternate_color_5of8;
						elseif (ratioRegionID == 5);        colorList = alternate_color_4of8;
						elseif (ratioRegionID == 4);        colorList = alternate_color_5of8;
						elseif (ratioRegionID == 3);        colorList = alternate_color_6of8;
						elseif (ratioRegionID == 2);        colorList = alternate_color_7of8;
						else                                colorList = alternate_color_8of8;
						end;
					elseif (segment_copyNum >= 9)
						if (ratioRegionID == 10);           colorList = alternate_color_9of9;
						elseif (ratioRegionID == 9);        colorList = alternate_color_8of9;
						elseif (ratioRegionID == 8);        colorList = alternate_color_7of9;
						elseif (ratioRegionID == 7);        colorList = alternate_color_6of9;
						elseif (ratioRegionID == 6);        colorList = alternate_color_5of9;
						elseif (ratioRegionID == 5);        colorList = alternate_color_5of9;
						elseif (ratioRegionID == 4);        colorList = alternate_color_6of9;
						elseif (ratioRegionID == 3);        colorList = alternate_color_7of9;
						elseif (ratioRegionID == 2);        colorList = alternate_color_8of9;
						else                                colorList = alternate_color_9of9;
						end;
					end;

					chrom_SNPdata_colorsC{chrom,1}(pos) = chrom_SNPdata_colorsC{chrom,1}(pos) + colorList(1);
					chrom_SNPdata_colorsC{chrom,2}(pos) = chrom_SNPdata_colorsC{chrom,2}(pos) + colorList(2);
					chrom_SNPdata_colorsC{chrom,3}(pos) = chrom_SNPdata_colorsC{chrom,3}(pos) + colorList(3);
					chrom_SNPdata_countC{ chrom  }(pos) = chrom_SNPdata_countC{ chrom  }(pos) + 1;
				end;

				%
				% Average color per bin.
				%
				for pos = 1:length(chrom_SNPdata_countC{chrom})
					if (chrom_SNPdata_countC{chrom}(pos) > 0)
						chrom_SNPdata_colorsC{chrom,1}(pos) = chrom_SNPdata_colorsC{chrom,1}(pos)/chrom_SNPdata_countC{chrom}(pos);
						chrom_SNPdata_colorsC{chrom,2}(pos) = chrom_SNPdata_colorsC{chrom,2}(pos)/chrom_SNPdata_countC{chrom}(pos);
						chrom_SNPdata_colorsC{chrom,3}(pos) = chrom_SNPdata_colorsC{chrom,3}(pos)/chrom_SNPdata_countC{chrom}(pos);
					else
						chrom_SNPdata_colorsC{chrom,1}(pos) = 1.0;
						chrom_SNPdata_colorsC{chrom,2}(pos) = 1.0;
						chrom_SNPdata_colorsC{chrom,3}(pos) = 1.0;
					end;
				end;
			end;
		end;
	end;


	save([projectDir 'SNP_' SNP_verString '.reduced_RedGreen.mat'],'chrom_SNPdata','new_bases_per_bin','chrom_SNPdata_colorsC','chrom_SNPdata_colorsP');


	%% ===============================================================================================
	% Setup for main figure generation.
	%-------------------------------------------------------------------------------------------------
	% load size definitions
    [linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
        ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
        stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
        gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

    Main_fig = figure();
	largestchrom = find(chrom_width == max(chrom_width));
	largestchrom = largestchrom(1);


	%% ===============================================================================================
	% Setup for linear-view figure generation.
	%-------------------------------------------------------------------------------------------------
	if (Linear_display == true)
		Linear_fig = figure();
		Linear_genome_size   = sum(chrom_size);
		Linear_TickSize      = -0.01;  %negative for outside, percentage of longest chrom figure.
		maxY                 = 1; % ploidyBase*2;
		Linear_left          = Linear_left_start;
		axisLabelPosition_horiz = 0.01125;
	end;
	axisLabelPosition_vert = 0.01125;


	%%================================================================================================
	% Make figures
	%-------------------------------------------------------------------------------------------------
	first_chrom = true;
	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) == 1)
			figure(Main_fig);

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
			text(-50000/5000/2*3, maxY/2,     chrom_label{chrom}, 'Rotation',90, 'HorizontalAlignment','center', 'VerticalAlign','bottom', 'Fontsize',stacked_chrom_font_size);
			set(gca,'XTick',0:(40*(5000/bases_per_bin)):(650*(5000/bases_per_bin)));
			set(gca,'XTickLabel',{'0.0','0.2','0.4','0.6','0.8','1.0','1.2','1.4','1.6','1.8','2.0','2.2','2.4','2.6','2.8','3.0','3.2'});

			% standard : This section sets the Y-axis labelling.
			axisLabelPosition = -50000/bases_per_bin;
			set(gca,'FontSize',gca_stacked_font_size);
			if (chrom == find(chrom_posY == max(chrom_posY)))
				title([ project ' allelic fraction map'],'Interpreter','none','FontSize',stacked_title_size);
			end;
			% standard : end axes labels etc.

			% standard : draw colorbars.
			for i = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
				colorR   = chrom_SNPdata_colorsC{chrom,1}(i);
				colorG   = chrom_SNPdata_colorsC{chrom,2}(i);
				colorB   = chrom_SNPdata_colorsC{chrom,3}(i);
				if (colorR < 1) || (colorG < 1) || (colorB < 1)
					plot([i i], [0 maxY],'Color',[colorR colorG colorB]);
				end;
			end;
			% standard : end draw colorbars

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

				% linear : draw colorbars
				for i = 1:ceil(chrom_size(chrom)/new_bases_per_bin)
					colorR   = chrom_SNPdata_colorsC{chrom,1}(i);
					colorG   = chrom_SNPdata_colorsC{chrom,2}(i);
					colorB   = chrom_SNPdata_colorsC{chrom,3}(i);
					if (colorR < 1) || (colorG < 1) || (colorB < 1)
						plot([i i], [0 maxY],'Color',[colorR colorG colorB]);
					end;
				end;
				% linear : end draw colorbars

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
				set(gca,'FontSize',linear_gca_font_size);
				% linear : end final reformatting.
				%end final reformatting.
				% adding title in the middle of the cartoon
				% note: adding title is done in the end since if placed upper
				% in the code somehow the plot function changes the title position
				if (rotate == 0 && chrom_size(chrom) ~= 0 )
				    title(chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				else
				    text((chrom_size(chrom)/bases_per_bin)/2,maxY+0.25,chrom_label{chrom},'Interpreter','none','FontSize',linear_chrom_font_size,'Rotation',rotate);
				end;

				hold off;

				% shift back to main figure generation.
				figure(Main_fig);
				first_chrom = false;
			end;
		end;
	end;

	%% Save figures.
	set(Main_fig,'PaperPosition',[0 0 stacked_fig_width stacked_fig_height]);
	saveas(Main_fig,   [projectDir 'fig.allelic_ratio-map.RedGreen.c1.eps'], 'epsc');
	saveas(Main_fig,   [projectDir 'fig.allelic_ratio-map.RedGreen.c1.png'], 'png');
	delete(Main_fig);

	set(Linear_fig,'PaperPosition',[0 0 linear_fig_width linear_fig_height]);
	saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.RedGreen.c2.eps'], 'epsc');
	saveas(Linear_fig, [projectDir 'fig.allelic_ratio-map.RedGreen.c2.png'], 'png');
	delete(Linear_fig);
elseif (useParent)
	% Dataset was compared to a parent, so don't draw a Red/Green alternate colors plot.
	fprintf(['\n##\n## Parent in use, so "allelic_ratios_ddRADseq_D.m" is being skipped.\n##\n']);
else
	% Dataset was not compared to a hapmap or parent, so don't draw a Red/Green alternate colors plot.
	fprintf(['\n##\n## Neither parent or hapmap in use, so "allelic_ratios_ddRADseq_D.m" is being skipped.\n##\n']);
end;

end
