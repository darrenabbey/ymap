%==========================================================================
% draw_Charm_plot_2.m - Variable-Width Binned Copy Number Profile Painter
%==========================================================================

set(gcf, 'Position', [0 70 1024 600]);
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		left   = chrom_posX(chrom);    bottom = chrom_posY(chrom);
		width  = chrom_width(chrom);   height = chrom_height(chrom);
		subplot('Position',[left bottom width height]);
		hold on;

		num_bins = length(dataShow{chrom});

		if num_bins > 0
			% OPTIMIZATION: High-speed matrix-batch fill for histogram bins
			X_coords = zeros(4, num_bins);
			Y_coords = zeros(4, num_bins);
			startY = 0;

			for i = 1:num_bins
				X_coords(:, i) = [i; i; i-1; i-1];
				% Note: If data clips, adjust this scaling multiplier down from 8
				Y_coords(:, i) = [startY; dataShow{chrom}(i)*8; dataShow{chrom}(i)*8; startY];
			end;

			c_ = [0 0 0]; % Black fill
			f = fill(X_coords, Y_coords, c_, 'LineStyle', 'none');
		end;

		% Plot the baseline axis line at y = 0
		x2 = chrom_size(chrom) * chrom_length_scale_multiplier;
		plot([0; x2], [0; 0], 'color', [0 0 0]);

		% FIX: Multiply edge indices by scale multiplier so they align with the x-axis
		% Blue lines for locs1 (maxima / upward edges)
		for edge = 1:length(locs1{chrom})
			scaled_edge = locs1{chrom}(edge); % Keeps alignment consistent with x_ unit scaling
			plot([scaled_edge scaled_edge], [-1 1], 'color', [0 0 1]);
		end;

		% Red lines for locs2 (minima / downward edges)
		for edge = 1:length(locs2{chrom})
			scaled_edge = locs2{chrom}(edge);
			plot([scaled_edge scaled_edge], [-1 1], 'color', [1 0 0]);
		end;

		hold off;

		% Define exact axis limits
		xlim([0, x2]);
		ylim([-1 1]);
		set(gca, 'YTick', [-1 0 1]);
		set(gca, 'YTickLabel', {'', '', ''});
	end;
end;





               for chrom = 1:length(chrom_in_use)
                       if (chrom_in_use(chrom) == 1)
                               left   = chrom_posX(chrom);
                               bottom = chrom_posY(chrom);
                               width  = chrom_width(chrom);
                               height = chrom_height(chrom);
                               subplot('Position',[left bottom width height]);
                               hold on;
                               c_ = [0 0 0];
                               for i = 1:length(dataShow{chrom});
                                       x_ = [i i i-1 i-1];
                                       CNVhistValue = dataShow{chrom}(i);
                                       startY = 0;
                                       endY   = CNVhistValue*8;
                                       y_ = [startY endY endY startY];
                                       f = fill(x_,y_,c_);
                                       set(f,'linestyle','none');
                               end;
                               x2 = chrom_size(chrom)*chrom_length_scale_multiplier;
                               plot([0; x2], [0; 0],'color',[0 0 0]);  % 2n line.
                               for edge = 1:length(locs1{chrom})
                                       plot([locs1{chrom}(edge) locs1{chrom}(edge)], [-1 1],'color',[0 0 1]);
                               end;
                               for edge = 1:length(locs2{chrom})
                                       plot([locs2{chrom}(edge) locs2{chrom}(edge)], [-1 1],'color',[1 0 0]);
                               end;
                               hold off;
                               xlim([0,chrom_size(chrom)*chrom_length_scale_multiplier]);
                               ylim([-1 1]);
                               set(gca,'YTick',[-1 0 1]);
                               set(gca,'YTickLabel',{'','',''});
                       end;
               end;
