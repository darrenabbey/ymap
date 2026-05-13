function [Rsquared] = testPloidyEstimate_CNV(workingDir, CNVplot, chr_breaks, ploidy, usedChr, segment, copyNum, makeFitFigures)
%%%================================================================================================
%%%
%%% Find R^2 value for CNV data gaussian fit to specific copy number.
%%%
%%%------------------------------------------------------------------------------------------------

maxY             = 10;
histogram_width  = 200;
show_fitting     = 0;

% Calculate Gaussian peak location from provided ploidy.
peakLocation = copyNum*(histogram_width/maxY);


%%%================================================================================================
%%% Generate Gaussian fit for chromosome segment if requested by makeFitFigures.
%%%------------------------------------------------------------------------------------------------
smoothed         = [];
smoothed2        = [];
segment_CNVdata  = [];
segment_CNVdata2 = [];

%%% Grab CNV data for this segment of this chromosome.
for i = 1:length(CNVplot{usedChr})
	if (i <= length(CNVplot{usedChr})*chr_breaks{usedChr}(segment+1)) && ...
	   (i >= length(CNVplot{usedChr})*chr_breaks{usedChr}(segment))
		segment_CNVdata = [segment_CNVdata CNVplot{usedChr}(i)];
	end;
end;
segment_CNVdata = segment_CNVdata*ploidy;

%%% Clean up segment data, then make smoothed histogram.
segment_CNVdata(segment_CNVdata == 0)      = [];	% Zero data removed.
segment_CNVdata(length(segment_CNVdata)+1) = 0;		% Endpoint added to ensure histogram bounds.
segment_CNVdata(length(segment_CNVdata)+1) = maxY;	% Endpoint added to ensure histogram bounds.
segment_CNVdata(segment_CNVdata < 0)       = [];	% Remove data lower than 0 endpoint.
segment_CNVdata(segment_CNVdata > maxY)    = [];	% Remove data higher than maxY endpoint.
smoothed                                   = hist(segment_CNVdata,histogram_width);
%smoothed                                  = smooth_gaussian(hist(segment_CNVdata,histogram_width),5,20);

%%% Make a smoothed version of just the endpoints used to ensure histogram bounds.
segment_CNVdata2(1)                        = 0;
segment_CNVdata2(2)                        = maxY;
smoothed2                                  = hist(segment_CNVdata2,histogram_width);
%smoothed2                                 = smooth_gaussian(hist(segment_CNVdata2,histogram_width),5,20);

%%% Subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints; normalize smoothed histogram height.
smoothed = smoothed - smoothed2;
smoothed = smoothed/max(smoothed);

%%% Perform Gaussian curve fitting to CNV data, to generate chromosome segment copy number estimates, after merging adjacent segments when needed. (Fit figures are made.)
descriptionString   = ['testCNV=' num2str(copyNum) '; chr=' num2str(usedChr) '; seg=' num2str(segment)];
[CNVsegment_height, CNVsegment_location, CNVsegment_width, Rsquared] = fit_Gaussian_model2(workingDir, smoothed, peakLocation, 'cubic',show_fitting,20, makeFitFigures, descriptionString);

end
