	%%//=========================================================================
	%%//= No further control variables below. ===================================
	%%//=========================================================================

	%%// Load CNV and SNP figure resolutions.
	if (exist([genomeDir 'resolution.CNV.txt'],'file') == 0)
		bases_per_bin           = max(chr_size)/700;
	else
		bases_per_bin           = max(chr_size)/str2num(fileread([genomeDir 'resolution.CNV.txt']));
	end;

	% basic plot parameters not defined per genome.
	TickSize         = -0.005;  %negative for outside, percentage of longest chr figure.
	ploidyBase       = 2;
	maxY             = ploidyBase*2;
	cen_tel_Xindent  = 5;
	cen_tel_Yindent  = maxY/4;

	fprintf(['\nGenerating GC/AT-skew figure from ''' genome ''' sequence data.\n']);

	largestChr = find(chr_width == max(chr_width));
	largestChr = largestChr(1);

	%%// -----------------------------------------------------------------------------------------
	%// Setup for linear-view figure generation.
	%//-------------------------------------------------------------------------------------------
	%// load size definitions
	[linear_fig_height,linear_fig_width,Linear_left_start,Linear_chr_gap,Linear_Chr_max_width,Linear_height...
	    ,Linear_base,rotate,linear_chr_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,...
	    stacked_fig_width,stacked_chr_font_size,stacked_title_size,stacked_axis_font_size,...
	    gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chr_in_use,num_chrs,chr_label,chr_size);

	if (Standard_display)
		Standard_fig = figure();
	end;

	if (Linear_display)
		Linear_fig           = figure();
		Linear_genome_size   = sum(chr_size);
		Linear_TickSize      = -0.01;            %// negative for outside, percentage of longest chr figure.
		Linear_maxY          = 10;
		Linear_left          = Linear_left_start;
		axisLabelPosition_horiz = 0.01125;
	end;
	axisLabelPosition_vert = 0.01125;

	%%// -----------------------------------------------------------------------------------------
	%// Make figures
	%//-------------------------------------------------------------------------------------------
	first_chr = true;

	%// Determine order to draw chromosome cartoons in.
	chr_order = [];
	for test_chr = 1:num_chrs
		chr_pos = find(chr_figOrder==test_chr);
		chr_order = [chr_order chr_pos];
	end;
