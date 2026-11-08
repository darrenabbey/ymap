%==========================================================================
% draw_CNV_plot.m - Variable-Width Binned Copy Number Profile Painter
%==========================================================================

% 1. Determine the TRUE number of variable rows.
if preprocessed_CNVs
	actual_num_bins = sum(chroms == chrom);
else
	actual_num_bins = ceil(chrom_size(chrom) / bases_per_bin);
end;

fprintf(['linear-plot : chrom' num2str(chrom) ':' num2str(actual_num_bins) '\n']);

% 3. Extract literal physical coordinate segments matching this chromosome's rows.
idx_c = (chroms == chrom);
chrom_starts = double(fragment_starts(idx_c))';
chrom_ends   = double(fragment_ends(idx_c))';

% 4. Pre-allocate 2D patch coordinate matrices (4 points per column element).
X_matrix = zeros(5, actual_num_bins);
Y_matrix = zeros(5, actual_num_bins);

% Calculate scaling factors.
CNVhistValues = CNVplot2{chrom};
if (Low_quality_ploidy_estimate)
        scaleFactor = ploidy * ploidyAdjust;
else
        scaleFactor = ploidy;
end;

% Handle missing values and scale data.
endY_values = CNVhistValues * scaleFactor;
endY_values(isnan(CNVhistValues)) = scaleFactor;
endY_values = min(maxY, endY_values);
endY_values = max(0, endY_values);
startY = maxY / 2;

% 5. Divide physical nucleotide coordinates by the master bases_per_bin to determine figure coordinates.
X_matrix(1, :) = chrom_starts / bases_per_bin;   % Bottom Left.
X_matrix(2, :) = chrom_starts / bases_per_bin;   % Top Left.
X_matrix(3, :) = chrom_ends   / bases_per_bin;   % Top Right.
X_matrix(4, :) = chrom_ends   / bases_per_bin;   % Bottom Right.
X_matrix(5, :) = NaN;                            % Disconnect pen for next bar.

Y_matrix(1, :) = startY;
Y_matrix(2, :) = endY_values;
Y_matrix(3, :) = endY_values;
Y_matrix(4, :) = startY;
Y_matrix(5, :) = NaN;

% 6. Render the entire physical color bar instantly using a single call.
f_cnv = patch(X_matrix(:), Y_matrix(:), [0 0 0], 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0], 'LineStyle', '-');
