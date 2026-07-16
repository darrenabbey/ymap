%% standard : draw colorbars.
num_bins_SNP = ceil(chrom_size(chrom)/bases_per_bin_SNP);

% Extract the current chromosome's raw colors.
c_current = colors(1:num_bins_SNP, 1:3);

% Construct previous and next arrays for smoothing.
initial_c = [0 0 0];
c_prev = [initial_c; c_current(1:end-1, :)];
c_post = [c_current(2:end, :); c_current(end, :)];

% Color blending
if blendColorBars
	final_colors = (c_current * 0.5) + (c_prev * 0.25) + (c_post * 0.25);
else
	final_colors = c_current;
end

% Ensure the final colors are on range [0..1] before rendering.
final_colors(final_colors > 1) = 1;
final_colors(final_colors < 0) = 0;

% Build 2D patch coordinate matrices (4 points per column).
scale_factor = bases_per_bin_SNP / bases_per_bin;
bins_vector_cb = 1:num_bins_SNP;

X_matrix_cb = zeros(4, num_bins_SNP);
Y_matrix_cb = zeros(4, num_bins_SNP);

X_matrix_cb(1, :) = bins_vector_cb * scale_factor;
X_matrix_cb(2, :) = bins_vector_cb * scale_factor;
X_matrix_cb(3, :) = (bins_vector_cb - 1) * scale_factor;
X_matrix_cb(4, :) = (bins_vector_cb - 1) * scale_factor;

Y_matrix_cb(1, :) = 0;
Y_matrix_cb(2, :) = maxY;
Y_matrix_cb(3, :) = maxY;
Y_matrix_cb(4, :) = 0;

% Render 2D matrix patch.
f_cb = patch(X_matrix_cb, Y_matrix_cb, 'k');

% Apply color matrix directly to the patch handle, 1 color per face via FaceColor 'flat'.
set(f_cb, 'CData', final_colors, 'FaceColor', 'flat', 'EdgeColor', 'none', 'linestyle', 'none');
