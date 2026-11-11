%==========================================================================
% createCnvTrack.m - Variable-Width Bins, notes only on non-baseline CNVs.
%==========================================================================

fprintf(['[***] createCnvTrack.m\n']);
fprintf(['[***]\tprojectDir  = ' projectDir '\n']);
fprintf(['[***]\tproject     = ' project '\n']);

maxPloidyToDisplay = round(ploidyBase*2);
ploidyMultiplier   = ploidy*ploidyAdjust;

%%
%% Reduce the data to bins falling outside the expected ploidy (ploidyBase).
%%

if (isempty(strfind(project,'/')))
	project_ = project;
else
	idx = strfind(project,'/');
	project_ = substr(project,idx+1);
end;
fprintf(['[***]\tproject_  = ' project_ '\n']);

fprintf(['[***]\toutputFile   = ' projectDir 'cnv.' project_ '.CNVs.gff3\n']);
cnvTrackFid = fopen(fullfile(projectDir, ['cnv.' project_ '.CNVs.gff3']), 'w');
if (cnvTrackFid == -1)
	printf('[***] createCnvTrack.m: Not a valid filename, skipping.\n');
else
	fprintf(cnvTrackFid, [ '##gff-version 3\n' ]);

	roundedbases_per_bin = round(bases_per_bin);
	num_chroms           = length(chrom_in_use);

	for chrom = 1:num_chroms
		if (chrom_in_use(chrom) ~= 1)
			continue;
		end;

		if preprocessed_CNVs
			num_bins = sum(chroms == chrom);
		else
			num_bins = ceil(chrom_size(chrom)/bases_per_bin);
		end;

		if (num_bins == 0 || isempty(CNVplot2{chrom}))
			continue;
		end;

		% Extract copy number estimates as a 1 x num_bins row vector.
		localCopyEstimates = reshape(CNVplot2{chrom}(1:num_bins), 1, []) * ploidyMultiplier;

		% Assign variable bin start and end coordinates (1-based inclusive for GFF3).
		if preprocessed_CNVs
			chromMask = (chroms == chrom);
			binStarts = reshape(fragment_starts(chromMask), 1, []);
			binEnds   = reshape(fragment_ends(chromMask),   1, []);
			binStarts = binStarts(1:num_bins);
			binEnds   = binEnds(1:num_bins);
		else
			binStarts = 1:roundedbases_per_bin:((num_bins - 1) * roundedbases_per_bin + 1);
			binEnds   = min(binStarts + roundedbases_per_bin - 1, chrom_size(chrom));
		end;

		% Identify baseline/missing bins vs. deviating bins.
		isBaseline = (round(localCopyEstimates) == ploidyBase) | isnan(localCopyEstimates);

		% Default all comments (column 9) to a period.
		noteCol = repmat({'.'}, 1, num_bins);

		% Populate Note=... only for deviating bins
		devIdx = find(~isBaseline);
		for k = devIdx
			noteCol{k} = sprintf('Note=%s:%d-%d:%.1f', chrom_label{chrom}, binStarts(k), binEnds(k), localCopyEstimates(k));
		end;

		% Combine numeric columns and comment column into a 4 x num_bins cell array
		outputCells = [num2cell(binStarts); num2cell(binEnds); num2cell(localCopyEstimates); noteCol];
		rowFormat   = sprintf('%s\tYmap\tregion\t%%d\t%%d\t%%.1f\t.\t.\t%%s\n', chrom_name{chrom});
		fprintf(cnvTrackFid, rowFormat, outputCells{:});
	end;
	fclose(cnvTrackFid);

	%% change permissions of file.
	system(['chmod 774 ' projectDir 'cnv.' project_ '.CNVs.gff3']);
	printf('[***] createCnvTrack.m: CNV track file created.\n');
end;

