function endBias_histogram(data,maxY);
	hold on;
	data2     = [];
	smoothed  = [];
	smoothed2 = [];

	% make a histogram of CNV data, then smooth it for display.
	histogram_end                                    = 15;   % end point in copy numbers for the histogram, this should be way outside the expected range.

	% endpoints added to ensure histogram bounds.
	data(end+1)              = 0;
	data(end+1)              = histogram_end;

	% crop off any copy data outside the range.
	data(data<0)             = [];
	data(data>histogram_end) = [];
	smoothed                 = smooth_gaussian(hist(data,histogram_end*20),2,10);

	% make a smoothed version of just the endpoints used to ensure histogram bounds.
	data2(1)                 = 0;
	data2(2)                 = histogram_end;
	smoothed2                = smooth_gaussian(hist(data2,histogram_end*20),2,10);

	% subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints.
	smoothed                 = smoothed-smoothed2;
	smoothed                 = smoothed/max(smoothed);

	% draw lines to mark whole copy number changes.
	plot([0;300], [0;       0      ],'color',[0.00 0.00 0.00]);
	hold on;
	for i = 1:15
		plot([0;300],[20*i;  20*i],'color',[0.75 0.75 0.75]);
	end;

	% draw histogram.
	area(smoothed,1:300,'FaceColor',[0 0 0]);

	% ensure subplot axes are consistent with main chr plots.
	hold off;
	axis off;
	set(gca,'YTick',[]);
	set(gca,'XTick',[]);
	xlim([0,1]);
	ylim([0,maxY*20]);
	% standard : end of CNV histograms at right.
	hold off;
end;
