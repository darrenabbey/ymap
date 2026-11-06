%==========================================================================
% draw_CNV_plot.m - Variable-Width Binned Copy Number Profile Painter
%==========================================================================

% Use the ACTUAL number of bins from your loaded file data to prevent crashes.
if preprocessed_CNVs
	actual_num_bins = sum(chroms == chrom);
else
	actual_num_bins = ceil(chrom_size(chrom) / bases_per_bin);
end;

fprintf(['linear-plot : chrom' num2str(chrom) ':' num2str(actual_num_bins) '\n']);

% Extract matching physical coordinate vectors for THIS chromosome's rows.
% (Assuming 'chroms', 'fragment_starts', and 'fragment_ends' are available from Step 7)
idx_c = (chroms == chrom);
chrom_starts = double(fragment_starts(idx_c))';
chrom_ends   = double(fragment_ends(idx_c))';

% Pre-allocate coordinate matrices for precise physical bounding boxes.
% Each bin needs 4 corners to draw a rectangle + 1 NaN separator
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

% Vectorized generation of true physical rectangle coordinates.
% Map physical base pairs directly to the display axis using bases_per_bin!
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

% Draw all variable-width blocks instantly using a single 'patch' call.
f_cnv = patch(X_matrix(:), Y_matrix(:), [0 0 0], 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0], 'LineStyle', '-');
