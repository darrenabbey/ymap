%==========================================================================
% draw_CNV_plot.m - Variable-Width Binned Copy Number Profile Painter.
%==========================================================================

% Determine the TRUE number of variable rows.
if preprocessed_CNVs
	actual_num_bins = sum(chroms == chrom);
	idx_c = (chroms == chrom);
	chrom_starts = reshape(double(fragment_starts(idx_c)), 1, []);
	chrom_ends   = reshape(double(fragment_ends(idx_c)),   1, []);
else
	actual_num_bins = ceil(chrom_size(chrom) / bases_per_bin);
	chrom_starts = ((0:actual_num_bins-1) * bases_per_bin) + 1;
	chrom_ends   = min(chrom_starts + bases_per_bin - 1, chrom_size(chrom));
end

% Calculate scaling factors.
CNVhistValues = reshape(CNVplot2{chrom}(1:actual_num_bins), 1, []);
if (Low_quality_ploidy_estimate)
        scaleFactor = ploidy * ploidyAdjust;
else
        scaleFactor = ploidy;
end

% Handle missing values and scale data.
endY_values = CNVhistValues * scaleFactor;
endY_values(isnan(CNVhistValues)) = scaleFactor;
endY_values = min(maxY, endY_values);
endY_values = max(0, endY_values);
startY = maxY / 2;

% Pre-allocate 2D patch coordinate matrices (4 points per column element).
X_matrix = zeros(4, actual_num_bins);
Y_matrix = zeros(4, actual_num_bins);

% Divide physical nucleotide coordinates by the master bases_per_bin to determine figure coordinates.
X_matrix(1, :) = chrom_starts / bases_per_bin;   % Bottom Left.
X_matrix(2, :) = chrom_starts / bases_per_bin;   % Top Left.
X_matrix(3, :) = chrom_ends   / bases_per_bin;   % Top Right.
X_matrix(4, :) = chrom_ends   / bases_per_bin;   % Bottom Right.

Y_matrix(1, :) = startY;
Y_matrix(2, :) = endY_values;
Y_matrix(3, :) = endY_values;
Y_matrix(4, :) = startY;

% Render each column as an independent filled black rectangle (no NaN row needed).
f_cnv = patch(X_matrix, Y_matrix, [0 0 0], 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0], 'LineStyle', '-');

