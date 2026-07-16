num_bins = ceil(chrom_size(chrom)/bases_per_bin);
fprintf(['linear-plot : chrom' num2str(chrom) ':' num2str(length(CNVplot2{chrom})) '\n']);
% Pre-allocate coordinate matrices (4 points + 1 NaN separator per bin)
X_matrix = zeros(5, num_bins);
Y_matrix = zeros(5, num_bins);
startY = maxY / 2;
% Vectorized calculation of scaling factors
CNVhistValues = CNVplot2{chrom}(1:num_bins);
if (Low_quality_ploidy_estimate)
	scaleFactor = ploidy * ploidyAdjust;
else
	scaleFactor = ploidy;
end;
% Handle missing values and scale data
endY_values = CNVhistValues * scaleFactor;
endY_values(isnan(CNVhistValues)) = scaleFactor;
%endY_values = min(maxY, endY_values);
endY_values = max(0, endY_values);
% 3. Calculate heights relative to the midpoint baseline
startY = maxY / 2;
% 4. Build a continuous horizontal axis centered on bins
bin_centers = (1:num_bins) - 0.5;
% 5. Draw all blocks instantly using 'bar'
f_cnv = bar(bin_centers, endY_values, 1.0, 'stacked', 'basevalue', startY);
set(f_cnv, 'FaceColor', [0 0 0], 'EdgeColor', [0 0 0], 'LineStyle', '-');
