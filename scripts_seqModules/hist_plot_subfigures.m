%% =========================================================================================
% Draw histplots to right of main chromosome cartoons.
%-------------------------------------------------------------------------------------------
if (HistPlot == true)
	width     = 0.020;
	height    = chrom_height(chrom);
	bottom    = chrom_posY(chrom);
	histAll   = [];
	histAll2  = [];
	smoothed  = [];
	smoothed2 = [];
	fprintf(['chrom = ' num2str(chrom) '\n']);
	for segment = 1:length(chromCopyNum{chrom})
		sub_pos = [(left+chrom_width(chrom)+0.005)+width*(segment-1), bottom-0.007, width, height+0.007];
		% Debug line to verify layout bounding boxes
		fprintf('Chrom %d, Segment %d Layout Position: [%.3f, %.3f, %.3f, %.3f]\n', chrom, segment, sub_pos);
		axes('Position', sub_pos);

		start_idx = round(1 + length(CNVplot2{chrom}) * chrom_breaks{chrom}(segment));
		end_idx   = round(length(CNVplot2{chrom}) * chrom_breaks{chrom}(segment+1));
		segment_data = CNVplot2{chrom}(start_idx:end_idx);
		if (Low_quality_ploidy_estimate)
			histAll{segment} = segment_data * ploidy * ploidyAdjust;
		else
			histAll{segment} = segment_data * ploidy;
		end;

		% Make a histogram of CNV data, then smooth it for display.
		histogram_end      = 15;             % end point in copy numbers for the histogram, this should be way outside the expected range.
		valid_data         = histAll{segment}(histAll{segment} > 0 & histAll{segment} <= histogram_end);
		histAll{segment}   = [valid_data, 0, histogram_end];
		smoothed{segment}  = smooth_gaussian(hist(histAll{segment},histogram_end*20),2,10);

		% Make a smoothed version of just the endpoints used to ensure histogram bounds.
		histAll2_data      = [0, histogram_end];
		smoothed2{segment} = smooth_gaussian(hist(histAll2_data, histogram_end*20), 2, 10);

		% Subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints.
		smoothed{segment}  = smoothed{segment}-smoothed2{segment};
		smoothed{segment}  = smoothed{segment}/max(smoothed{segment});

		% Draw lines to mark whole copy number changes.
		hold on;
		plot([0;300], [0; 0],'color',[0.00 0.00 0.00]);
		for i = 1:15
			plot([0;300],[20*i; 20*i],'color',[0.75 0.75 0.75]);
		end;

		% Draw the histogram.
		area(smoothed{segment},1:300,'FaceColor',[0 0 0]);

		% Draw red ticks between histplot segments
		if (displayBREAKS) && (show_annotations)
			if (segment > 1)
				plot([0 0], [-maxY*20/10*1.5 0],  'Color',[1 0 0],'LineWidth',2);
			end;
		end;

		% Ensure axes are consistent with main chrom plots.
		hold off;
		axis off;
		set(gca,'YTick',[]);
		set(gca,'XTick',[]);
		xlim([0,1]);
		if (show_annotations)
			ylim([-maxY*20/10*1.5,maxY*20]);
		else
			ylim([0,maxY*20]);
		end;
	end;
end;
