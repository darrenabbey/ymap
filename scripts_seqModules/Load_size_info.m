function [linear_fig_height,linear_fig_width,linear_left_padding,linear_chrom_gap,linear_chrom_max_width,linear_height...
            ,linear_base,rotate,linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size,stacked_fig_height,stacked_fig_width,...
            stacked_chrom_font_size,stacked_title_size,stacked_axis_font_size,gca_stacked_font_size,stacked_copy_font_size,max_chrom_label_size] = Load_size_info(chrom_in_use,num_chroms,chrom_label,chrom_size)
	fprintf('\n---------------------------------Load_size_info.m started---------------------------------------------------\n');


%%%%//
%%%%// Calculating data used to determine size.
%%%%//
	%%// Calculate the number of chroms used
	num_chroms_used = 0;
	num_chroms
	chrom_in_use
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			num_chroms_used = num_chroms_used + 1;
		end;
	end;
	fprintf('num_chroms_used - %d\n',num_chroms_used);


	%%// Calculating the maximum length of chromosome label size for the height of linear figure
	%%// Also count the total used chromosomes.
	used_chrom_count = 0;
	max_chrom_label_size = 1;
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			if (numel(chrom_label{chrom}) > max_chrom_label_size)
				max_chrom_label_size = numel(chrom_label{chrom});
			end;
			used_chrom_count = used_chrom_count+1;
		end;
	end;
	fprintf('max_chrom_label_size - %d\n',max_chrom_label_size);

	system_dpi = 150;
	fprintf('using %d dpi\n',system_dpi);


%%%%//
%%%%// linear figure.
%%%%//
	fprintf('-----------------------------------Linear Figure -----------------------------------------------\n');
	%// setting size for linear figure
	linear_fig_plot_height   = 130; %// the height of each chromosom in the figure in px (including y-axis)
	linear_fig_charc_height  = 20;  %// the size to be allocated in px for each character in the label 

	linear_fig_height_px     = linear_fig_plot_height + linear_fig_charc_height*max_chrom_label_size; %// the total height of the linear figure in px
	%// normalize height according to dpi
	linear_fig_height        = linear_fig_height_px / system_dpi;

	linear_fig_width_px      = 2400;
	linear_fig_width         = linear_fig_width_px / system_dpi;

	%// base value in octave (the scaling here is from 0 to 1 and represent relative position
	linear_left_padding      = 0.02;               %// left margin
	linear_right_padding     = 0.02;               %// right margin
	linear_total_gap         = 0.07;               %// the size in precentage for total gap accross all figure
	linear_cartoon_height_px = 111;                %// the size of the chromosome cartoon in pixles (without y-axis) for proper scaling

	linear_chrom_gap           = linear_total_gap/(used_chrom_count-1);  %// gaps between chrom subfigures.

	linear_chrom_max_width     = 1 - linear_total_gap - linear_left_padding - linear_right_padding;  %// width for all chromosomes across figure.  1.00 - leftMargin - rightMargin - subfigure gaps.
	linear_height            = linear_cartoon_height_px/ linear_fig_height_px;                     %// the size
	linear_base              = 0.1;

	%// setting rotation
	%// if there are more than 5 characters in label 90 degrees rotation, else
	%// rotating accroding to lowest chromosome size.

	%// 45 degrees boundries
	lower_boundary = 0.10;
	upper_boundary = 0.25;

	%// gather chrom sizes.
	chrom_size_cleaned = [];
	for chrom = 1:length(chrom_in_use)
		if (chrom_in_use(chrom) == 1)
			chrom_size_cleaned(end+1) = chrom_size(chrom);
		end;
	end;

	%// removing any zero enteries in chromosom sizes
	chrom_size_cleaned = chrom_size_cleaned(chrom_size_cleaned ~= 0);

	%// calculate ratio between smallest chromosome size to largest.
	ratio = min(chrom_size_cleaned)/max(chrom_size_cleaned);
	rotate = 0;
	if (max_chrom_label_size > 10)
		rotate = 90;
	elseif ((lower_boundary <= ratio) && (ratio <= upper_boundary))
		%// set rotate to 45 here to use.
		rotate = 90;
	elseif (ratio < lower_boundary)
		rotate = 90;
	end;

	%// font definitions
	linear_axis_font_size = 10;
	linear_gca_font_size = 12;
	linear_chrom_font_size = 12;

	fprintf('linear figure parameters:\n');
	fprintf('height:%d px, width:%d px, rotate:%d\n',linear_fig_height_px,linear_fig_width_px,rotate);
	fprintf('chrom font size:%d, axis font size:%d px, gca font size:%d\n',linear_chrom_font_size,linear_axis_font_size,linear_gca_font_size);


%%%//
%%%// Stacked figure.
%%%//
	fprintf('-----------------------------------Stacked Figure -----------------------------------------------\n');

	stacked_plot_height = 205;                                 %// size in pixels of each cartoon height including gap
	stacked_fig_height_px = stacked_plot_height*num_chroms_used; %// the total height of the linear figure in px
	%// normalize height according to dpi
	stacked_fig_height = stacked_fig_height_px / system_dpi;

	stacked_fig_width_px = 2400;
	stacked_fig_width = stacked_fig_width_px / system_dpi;

	stacked_title_size = 18;
	stacked_axis_font_size = 10;
	gca_stacked_font_size = 12;
	stacked_chrom_font_size = 16;
	stacked_copy_font_size = 20;

	fprintf('stacked figure parameters:\n');
	fprintf('height:%d px, width:%d px, title size:%d\n',stacked_fig_height_px,stacked_fig_width_px,stacked_title_size);
	fprintf('chrom font size:%d, axis font size:%d px, gca font size:%d\n',stacked_chrom_font_size,stacked_axis_font_size,gca_stacked_font_size);

	fprintf('\n---------------------------------Load_size_info.m ended---------------------------------------------------\n');
end
