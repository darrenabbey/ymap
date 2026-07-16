	%%//=========================================================================
	%%//= No further control variables below. ===================================
	%%//=========================================================================

	%%// Load CNV and SNP figure resolutions.
	if (exist([genomeDir 'resolution.CNV.txt'],'file') == 0)
		bases_per_bin           = max(chrom_size)/700;
	else
		bases_per_bin           = max(chrom_size)/str2num(fileread([genomeDir 'resolution.CNV.txt']));
	end;

	% basic plot parameters not defined per genome.
	TickSize         = -0.005;  %negative for outside, percentage of longest chrom figure.
	ploidyBase       = 2;
	maxY             = ploidyBase*2;
	cen_tel_Xindent  = 5;
	cen_tel_Yindent  = maxY/4;

	fprintf(['\nGenerating GC/AT-skew figure from ''' genome ''' sequence data.\n']);

	largestchrom = find(chrom_width == max(chrom_width));
	largestchrom = largestchrom(1);

	%%// -----------------------------------------------------------------------------------------
	%// Setup for linear-view figure generation.
	%//-------------------------------------------------------------------------------------------
	%// load size definitions
	[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chrom_gap,Linear_chrom_max_width,Linear_height...
	    ,Linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
	    stacked_fig_width,stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,...
	    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size);

	if (Standard_display)
		Standard_fig = figure();
	end;

	if (Linear_display)
		Linear_fig           = figure();
		Linear_genome_size   = sum(chrom_size);
		Linear_TickSize      = -0.01;            %// negative for outside, percentage of longest chrom figure.
		Linear_maxY          = 10;
		Linear_left          = Linear_left_start;
		axisLabelPosition_horiz = 0.01125;
	end;
	axisLabelPosition_vert = 0.01125;

	%%// -----------------------------------------------------------------------------------------
	%// Make figures
	%//-------------------------------------------------------------------------------------------
	first_chrom = true;

	%// Determine order to draw chromosome cartoons in.
	chrom_order = [];
	for test_chrom = 1:num_chroms
		chrom_pos = find(chrom_figOrder==test_chrom);
		chrom_order = [chrom_order chrom_pos];
	end;
