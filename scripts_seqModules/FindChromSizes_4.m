function [chrom_breaks, chromCopyNum, ploidyAdjust, chromCopyRsquared] = FindChromSizes_4(workingDir, Aneuploidy,CNVplot,Ploidy,num_chroms,chrom_in_use, makeFitFigures)

%%%================================================================================================
%%%
%%% FindChromSizes determines chromosome sizes from
%%%    initial ploidy estimate and CGH data.
%%%
%%%------------------------------------------------------------------------------------------------

maxY                   = 10;
chrom_breaks             = [];
chromCopyNum             = [];
chromCopyRsquared        = [];
chromCopyNum1            = [];
chromCopyNum2            = [];
chromCopyNum_vector      = [];
chromCopyRsquared_vector = [];


%%%================================================================================================
%%% Precalculation of chromosome segment copy numbers.
%%%------------------------------------------------------------------------------------------------
chromCounter = 0;
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		chromCounter += 1;

		% determine where the endpoints of ploidy segments are.
		chrom_breaks{chrom}(1) = 0.0;
		break_count = 1;
		if (length(Aneuploidy) > 0)
			for i = 1:length(Aneuploidy)
				%if (Aneuploidy(i).dataset == dataset) && (Aneuploidy(i).chrom == chrom)
				if (Aneuploidy(i).chrom == chrom)
					break_count = break_count+1;
					chrom_broken = true;
					chrom_breaks{chrom}(break_count) = Aneuploidy(i).break;
				end;
			end;
		end;
		chrom_breaks{chrom}(length(chrom_breaks{chrom})+1) = 1;
		chrom_breaks{chrom} = unique(chrom_breaks{chrom});

		fprintf(['chrom' num2str(chromCounter) ' (' num2str(length(chrom_breaks{chrom})) ' breaks)\n']);
		for segment = 1:length(chrom_breaks{chrom})-1
			smoothed = [];
			smoothed2 = [];
			segment_CGHdata = [];
			segment_CGHdata2  = [];
			% find set of CGH data for this segment of this chromosome.
			for i = 1:length(CNVplot{chrom})
				% val = ploidy estimate adjusted copy number for each CGH probe.
				if (i <= length(CNVplot{chrom})*chrom_breaks{chrom}(segment+1)) && ...
				   (i >= length(CNVplot{chrom})*chrom_breaks{chrom}(segment))
					val = CNVplot{chrom}(i);
					segment_CGHdata = [segment_CGHdata val];
				end;
			end;
			if (Ploidy == 0)
				segment_CGHdata = segment_CGHdata*2;
			else
				segment_CGHdata = segment_CGHdata*Ploidy;
			end;

			% make smoothed histogram of CGH data for this segment.
			segment_CGHdata(segment_CGHdata==0) = [];
			segment_CGHdata(length(segment_CGHdata)+1) = 0;   % endpoints added to ensure histogram bounds.
			segment_CGHdata(length(segment_CGHdata)+1) = maxY;

			% clearing
			segment_CGHdata(segment_CGHdata<0) = [];
			segment_CGHdata(segment_CGHdata>maxY) = [];
			histogram_width = 200;
			smoothed        = smooth_gaussian(hist(segment_CGHdata,histogram_width),5,20);

			% make a smoothed version of just the endpoints used to ensure histogram bounds.
			segment_CGHdata2(1) = 0;
			segment_CGHdata2(2) = maxY;
			smoothed2 = smooth_gaussian(hist(segment_CGHdata2,histogram_width),5,20);

			% subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints.
			smoothed = smoothed - smoothed2;
			smoothed = smoothed/max(smoothed);

			% find initial estimage of peak location from smoothed segment CGH data.
			peakLocation = find(smoothed==max(smoothed));
			% fit Gaussian to segment CGH data.
			show_fitting = 0;

			%%% Perform Gaussian curve fitting to CNV data, to generate chromosome segment copy number estimates. (No fit figures made.)
			descriptionString   = ['T1_chrom' num2str(chromCounter) '.' num2str(segment)];
			[CGHsegment_height, CGHsegment_location, CGHsegment_width, Rsquared] = fit_Gaussian_model2(workingDir, smoothed, peakLocation, 'cubic',show_fitting,20, true, descriptionString);
			fprintf(['\t### fit_Gaussian_model2 description string = ' descriptionString '\n']);
			fprintf(['\t!!! [raw] chromCopyNum{' num2str(chrom) '}(' num2str(segment) ') = ' num2str(round(CGHsegment_location/(histogram_width/maxY)*10)/10) '\n']);

			if (isnan(round(CGHsegment_location/(histogram_width/maxY)*10)/10))
				chromCopyNum{chrom}(segment)      = 1;
			elseif (peakLocation > 1)
				% calculate copy number from Gaussian location.
				chromCopyNum{chrom}(segment)      = round(CGHsegment_location/(histogram_width/maxY)*10)/10;
			else
				chromCopyNum{chrom}(segment)      = 1;
			end;
			chromCopyRsquared{chrom}(segment) = Rsquared;

			chromCopyNum_vector      = [chromCopyNum_vector      chromCopyNum{chrom}(segment)     ];
			chromCopyRsquared_vector = [chromCopyRsquared_vector chromCopyRsquared{chrom}(segment)];
		end;
	end;
end;


%%%================================================================================================
%%% Adjustment of ploidy estimate.
%%%------------------------------------------------------------------------------------------------
%%%	Assumes most common copy number to really be a whole number. (2.1 -> 2, etc.)
%%%	Zero data indicate erroneous copy number estimates and are first excluded.
%%%------------------------------------------------------------------------------------------------
chromCopyNum_vector(chromCopyNum_vector == 0) = [];
common_copyNum = mode(chromCopyNum_vector);
chromCounter = 0;
for chrom = 1:length(chromCopyNum)
	if (chrom_in_use(chrom) == 1)
		chromCounter += 1;
		fprintf(['\n']);
		for segment = 1:length(chromCopyNum{chrom})
			fprintf(['chrom' num2str(chromCounter) '.' num2str(segment) '\n']);
			fprintf(['\t!!! chromCopyNum{' num2str(chrom) '}(' num2str(segment) ')  = ' num2str(chromCopyNum{chrom}(segment)) '\n']);
			fprintf(['\t!!! common_copyNum    = ' num2str(common_copyNum) '\n']);

			% avoid dividing by Nan if common_copyNum is NaN (since the whole copy vector can be empty)
			if (~isnan(common_copyNum))
				% rounds to 1 decimal place.
				chromCopyNum2{chrom}(segment) = round(chromCopyNum{chrom}(segment)/common_copyNum*round(common_copyNum)*10)/10;
			else
			chromCopyNum2{chrom}(segment) = 0;
			end;
			fprintf(['\t!!! chromCopyNum2{' num2str(chrom) '}(' num2str(segment) ') = ' num2str(chromCopyNum2{chrom}(segment)) '\n\n']);
		end;
	end;
end;
chromCopyNum1  = chromCopyNum;
chromCopyNum   = chromCopyNum2;


%%%================================================================================================
%%% Test adjacent segments for no change in copy number estimate.
%%%------------------------------------------------------------------------------------------------
%%%	Adjacent pairs of segments with the same copy number will be fused into a single segment.
%%%	Segments with a <= zero copy number will be fused to an adjacent segment.
%%%------------------------------------------------------------------------------------------------
fprintf('Test adjacent chromosome segments for no change in copy number estimate.\n');
chromCounter = 0;
for chrom = 1:length(chromCopyNum)
	if (chrom_in_use(chrom) == 1)
		chromCounter += 1;
		if (length(chromCopyNum{chrom}) > 1)  % more than one segment, so lets examine if adjacent segments have different copyNums.
			%% Merge any adjacent segments with the same copy number.
			% add break representing left end of chromosome.
			breakCount_new         = 1;
			chrom_breaks_new{chrom}    = [];
			chromCopyNum_new{chrom}    = [];
			chrom_breaks_new{chrom}(1) = 0.0;

			% attempt to clean up poor behavior(?) with zero copy number estimates leading to no SNP/LOH data presented.
			for segment = 1:(length(chromCopyNum{chrom}))
				if (round(chromCopyNum{chrom}(segment)) == 0)
					chromCopyNum{chrom}(segment) = 1;
				end;
			end;

			chromCopyNum_new{chrom}(1) = chromCopyNum{chrom}(1);
			for segment = 1:(length(chromCopyNum{chrom})-1)
				if (round(chromCopyNum{chrom}(segment)) == round(chromCopyNum{chrom}(segment+1)))
					% two adjacent segments have identical copyNum and should be fused into one; don't add boundry to new list.
				else
					% two adjacent segments have different copyNum; add boundry to new list.
					breakCount_new                      = breakCount_new + 1;
					chrom_breaks_new{chrom}(breakCount_new) = chrom_breaks{chrom}(segment+1);
					chromCopyNum_new{chrom}(breakCount_new) = chromCopyNum{chrom}(segment+1);
				end;
			end;

			% add break representing right end of chromosome.
			breakCount_new = breakCount_new+1;
			chrom_breaks_new{chrom}(breakCount_new) = 1.0;
			chrom_breaks_new{chrom} = unique(chrom_breaks_new{chrom});

			% output status to log file.
			fprintf(['\t@@@2 chrom = ' num2str(chromCounter) '\n']);
			fprintf(['\t@@@2    chrom_breaks_old = ' num2str(chrom_breaks{chrom})     '\n']);
			fprintf(['\t@@@2    chromCopyNum_old = ' num2str(chromCopyNum{chrom})     '\n']);
			fprintf(['\t@@@2    chrom_breaks_new = ' num2str(chrom_breaks_new{chrom}) '\n']);
			fprintf(['\t@@@2    chromCopyNum_new = ' num2str(chromCopyNum_new{chrom}) '\n']);

			% copy new lists to old.
			chrom_breaks{chrom} = chrom_breaks_new{chrom};
			chromCopyNum{chrom} = [];
			chromCopyNum{chrom} = chromCopyNum_new{chrom};
		else
			% output status to log file.
			fprintf(['\t@@@2 chrom = ' num2str(chromCounter) '\n']);
			fprintf(['\t@@@2    Only one CNV segment on this chromosome\n']);
		end;
	end;
end;


%%%================================================================================================
%%% Regenerate chromosome segment copy numbers after segments cleaned up above.
%%%------------------------------------------------------------------------------------------------
%%%	Generate Gaussian fit figures for each chromosome segment if requested by makeFitFigures.
%%%------------------------------------------------------------------------------------------------
chromCopyNum             = [];
chromCopyRsquared        = [];
chromCopyNum_vector      = [];
chromCopyRsquared_vector = [];

chromCounter = 0;
for chrom = 1:length(chrom_in_use)
	if (chrom_in_use(chrom) == 1)
		chromCounter += 1;
		for segment = 1:length(chrom_breaks{chrom})-1
			smoothed         = [];
			smoothed2        = [];
			segment_CGHdata  = [];
			segment_CGHdata2 = [];

			%%% Grab CGH data for this segment of this chromosome.
			for i = 1:length(CNVplot{chrom})
				% val = ploidy estimate adjusted copy number for each CGH fragment.
				if (i <= length(CNVplot{chrom})*chrom_breaks{chrom}(segment+1)) && ...
				   (i >= length(CNVplot{chrom})*chrom_breaks{chrom}(segment))
					val = CNVplot{chrom}(i);
					segment_CGHdata = [segment_CGHdata val];
				end;
			end;
			if (Ploidy == 0)
				%%% Assumes diploid when ploidy value wasn't entered somehow.
				segment_CGHdata = segment_CGHdata*2;
			else
				segment_CGHdata = segment_CGHdata*Ploidy;
			end;

			% make smoothed histogram of CGH data for this segment.
			segment_CGHdata(segment_CGHdata==0) = [];
			segment_CGHdata(length(segment_CGHdata)+1) = 0;   % endpoints added to ensure histogram bounds.
			segment_CGHdata(length(segment_CGHdata)+1) = maxY;

			% clearing
			segment_CGHdata(segment_CGHdata<0) = [];
			segment_CGHdata(segment_CGHdata>maxY) = [];
			histogram_width = 200;
			smoothed        = smooth_gaussian(hist(segment_CGHdata,histogram_width),5,20);

			% make a smoothed version of just the endpoints used to ensure histogram bounds.
			segment_CGHdata2(1) = 0;
			segment_CGHdata2(2) = maxY;
			smoothed2 = smooth_gaussian(hist(segment_CGHdata2,histogram_width),5,20);

			% subtract the smoothed endpoints from the histogram to remove the influence of the added endpoints.
			smoothed = smoothed - smoothed2;
			smoothed = smoothed/max(smoothed);

			% find initial estimage of peak location from smoothed segment CGH data.
			peakLocation = find(smoothed==max(smoothed));
			% fit Gaussian to segment CGH data.
			show_fitting = 0;

			%%% Perform Gaussian curve fitting to CNV data, to generate chromosome segment copy number estimates, after merging adjacent segments when needed. (Fit figures are made.)
			descriptionString   = ['chrom' num2str(chromCounter) '.' num2str(segment)];
			[CGHsegment_height, CGHsegment_location, CGHsegment_width, Rsquared] = fit_Gaussian_model2(workingDir, smoothed, peakLocation, 'cubic',show_fitting,20, makeFitFigures, descriptionString);
			fprintf(['\t### fit_Gaussian_model2 description string = ' descriptionString '\n']);
			fprintf(['\t!!! [raw] chromCopyNum{' num2str(chrom) '}(' num2str(segment) ') = ' num2str(round(CGHsegment_location/(histogram_width/maxY)*10)/10) '\n']);

			if (isnan(round(CGHsegment_location/(histogram_width/maxY)*10)/10))
				chromCopyNum{chrom}(segment)      = 1;
			elseif (peakLocation > 1)
				% calculate copy number from Gaussian location.
				chromCopyNum{chrom}(segment)      = round(CGHsegment_location/(histogram_width/maxY)*10)/10;
			else
				chromCopyNum{chrom}(segment)      = 1;
			end;
			chromCopyRsquared{chrom}(segment) = Rsquared;

			chromCopyNum_vector      = [chromCopyNum_vector      chromCopyNum{chrom}(segment)     ];
			chromCopyRsquared_vector = [chromCopyRsquared_vector chromCopyRsquared{chrom}(segment)];
		end;
	end;
end;


%%% Set ploidy adjust according to copy num, avoid dividing by Nan if common_copyNum is NaN (since the whole copy vector can be empty)
if (~isnan(common_copyNum))
    ploidyAdjust = round(common_copyNum)/common_copyNum;
else
    ploidyAdjust = Ploidy;
end;
if (ploidyAdjust == 0)
    ploidyAdjust = Ploidy;
end;

end

