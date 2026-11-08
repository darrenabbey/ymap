%%================================================================================================
% draw_colorbars_plot.m - Variable-Width SNP/LOH Color Bar Painter
%-------------------------------------------------------------------------------------------------

% 1. Determine the TRUE number of variable rows.
if preprocessed_SNPs
	actual_num_bins = sum(chroms == chrom);
else
	actual_num_bins = ceil(chrom_size(chrom) / bases_per_bin_SNP);
end;

fprintf(['colorbar-plot : chrom' num2str(chrom) ':' num2str(actual_num_bins) '\n']);

% 2. Extract and align the current chromosome's actual raw colors.
c_current = colors(1:actual_num_bins, 1:3);

% Construct previous and next arrays for neighboring-bin window smoothing
initial_c = [1.0 1.0 1.0]; % Default to baseline white background padding
c_prev    = [initial_c; c_current(1:end-1, :)];
c_post    = [c_current(2:end, :); c_current(end, :)];

% Apply neighbor blending filter if enabled
if blendColorBars
        final_colors = (c_current * 0.5) + (c_prev * 0.25) + (c_post * 0.25);
else
        final_colors = c_current;
end

% Hard clamp the final color arrays onto valid double range boundaries [0..1]
final_colors(final_colors > 1) = 1;
final_colors(final_colors < 0) = 0;

% 3. Extract literal physical coordinate segments matching this chromosome's rows.
idx_c        = (chroms == chrom);
chrom_starts = double(fragment_starts(idx_c))';
chrom_ends   = double(fragment_ends(idx_c))';

% 4. Pre-allocate 2D patch coordinate matrices (4 points per column element).
X_matrix_cb = zeros(4, actual_num_bins);
Y_matrix_cb = zeros(4, actual_num_bins);

% 5. Divide physical nucleotide coordinates by the master bases_per_bin_SNP to determine figure coordinates.
X_matrix_cb(1, :) = chrom_ends   / bases_per_bin_SNP;   % Bottom Right
X_matrix_cb(2, :) = chrom_ends   / bases_per_bin_SNP;   % Top Right
X_matrix_cb(3, :) = chrom_starts / bases_per_bin_SNP;   % Top Left
X_matrix_cb(4, :) = chrom_starts / bases_per_bin_SNP;   % Bottom Left

Y_matrix_cb(1, :) = 0;
Y_matrix_cb(2, :) = maxY;
Y_matrix_cb(3, :) = maxY;
Y_matrix_cb(4, :) = 0;

% 6. Render the entire physical color bar instantly using a single call.
f_cb = patch(X_matrix_cb, Y_matrix_cb, 'k');

% Apply color matrix directly to the patch handle, 1 color per face via FaceColor 'flat'
set(f_cb, 'CData', final_colors, 'FaceColor', 'flat', 'EdgeColor', 'none', 'linestyle', 'none');


%%================================================================================================
% old code.
%-------------------------------------------------------------------------------------------------
% %% standard : draw colorbars.
% num_bins_SNP = ceil(chrom_size(chrom)/bases_per_bin_SNP);
%
% % Extract the current chromosome's raw colors.
% c_current = colors(1:num_bins_SNP, 1:3);
%
% % Construct previous and next arrays for smoothing.
% initial_c = [0 0 0];
% c_prev = [initial_c; c_current(1:end-1, :)];
% c_post = [c_current(2:end, :); c_current(end, :)];
%
% % Color blending
% if blendColorBars
%	final_colors = (c_current * 0.5) + (c_prev * 0.25) + (c_post * 0.25);
% else
%	final_colors = c_current;
% end
%
% % Ensure the final colors are on range [0..1] before rendering.
% final_colors(final_colors > 1) = 1;
% final_colors(final_colors < 0) = 0;
%
% % Build 2D patch coordinate matrices (4 points per column).
% scale_factor = bases_per_bin_SNP / bases_per_bin;
% bins_vector_cb = 1:num_bins_SNP;
%
% X_matrix_cb = zeros(4, num_bins_SNP);
% Y_matrix_cb = zeros(4, num_bins_SNP);
%
% X_matrix_cb(1, :) = bins_vector_cb * scale_factor;
% X_matrix_cb(2, :) = bins_vector_cb * scale_factor;
% X_matrix_cb(3, :) = (bins_vector_cb - 1) * scale_factor;
% X_matrix_cb(4, :) = (bins_vector_cb - 1) * scale_factor;
%
% Y_matrix_cb(1, :) = 0;
% Y_matrix_cb(2, :) = maxY;
% Y_matrix_cb(3, :) = maxY;
% Y_matrix_cb(4, :) = 0;
%
% % Render 2D matrix patch.
% f_cb = patch(X_matrix_cb, Y_matrix_cb, 'k');
%
% % Apply color matrix directly to the patch handle, 1 color per face via FaceColor 'flat'.
% set(f_cb, 'CData', final_colors, 'FaceColor', 'flat', 'EdgeColor', 'none', 'linestyle', 'none');
