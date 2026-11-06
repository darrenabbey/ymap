%==========================================================================
% draw_Charm_plot_1.m - Variable-Width Binned Copy Number Profile Painter
%==========================================================================

set(gcf, 'Position', [0 70 1024 600]);
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		% Custom subplot placement.
		left   = chrom_posX(chrom);
		bottom = chrom_posY(chrom);
		width  = chrom_width(chrom);
		height = chrom_height(chrom);
		subplot('Position',[left bottom width height]);
		hold on;

		% FILTER GLOBAL BIN COORDINATES FOR THIS CHROMOSOME.
		chrom_mask = (chroms == chrom);
		chr_starts = fragment_starts(chrom_mask) * chrom_length_scale_multiplier;
		chr_ends   = fragment_ends(chrom_mask) * chrom_length_scale_multiplier;

		num_bins = length(dataShow{chrom});
		fprintf('chrom%d:%d\n', chrom, num_bins);

		if num_bins > 0
			% Pre-allocate coordinate matrices for batch-rendering
			X_coords = zeros(4, num_bins);
			Y_coords = zeros(4, num_bins);
			startY = maxY / 2;

			for i = 1:num_bins
				% ASSIGN REAL GENOMIC COORDINATES TO POLYGONS.
				% Left edges use chr_starts, right edges use chr_ends
				X_coords(:, i) = [chr_ends(i); chr_ends(i); chr_starts(i); chr_starts(i)];
				Y_coords(:, i) = [startY; dataShow{chrom}(i); dataShow{chrom}(i); startY];
			end;

			% Draw all genomic bins instantly
			c_ = [0 0 0]; % Black fill
			f = fill(X_coords, Y_coords, c_, 'LineStyle', 'none');
		end;

		% Plot the 2n baseline
		x2 = chrom_size(chrom) * chrom_length_scale_multiplier;
		plot([0; x2], [maxY/2; maxY/2], 'color', [0 0 0]);
		hold off;

		% Axis setups
		xlim([0, x2]);
		ylim([0, maxY]);
		set(gca, 'YTick', [0, maxY/2, maxY]);
		set(gca, 'YTickLabel', {'', '', ''});
	end;
end;
