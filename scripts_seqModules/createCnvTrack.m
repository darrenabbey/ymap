%==========================================================================
% createCnvTrack.m - Variable-Width Bins.
%==========================================================================

fprintf('[***] createCnvTrack.m\n');
fprintf('[***]\tprojectDir  = %s\n', projectDir);
fprintf('[***]\tproject     = %s\n', project);

maxPloidyToDisplay = round(ploidyBase * 2);
ploidyMultiplier   = ploidy * ploidyAdjust;

if (isempty(strfind(project, '/')))
	project_ = project;
else
	idx = strfind(project, '/');
	project_ = substr(project, idx(end) + 1);
end
fprintf('[***]\tproject_  = %s\n', project_);

outputFile = fullfile(projectDir, ['cnv.' project_ '.gff3']);
fprintf('[***]\toutputFile   = %s\n', outputFile);

cnvTrackFid = fopen(outputFile, 'w');
if (cnvTrackFid == -1)
	fprintf('[***] createCnvTrack.m: Not a valid filename, skipping.\n');
else
	fprintf(cnvTrackFid, '##gff-version 3\n');

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
			binIndices   = 1:num_bins;
			binStarts    = (binIndices - 1) * roundedbases_per_bin + 1;
			binEnds      = binStarts + roundedbases_per_bin - 1;
			binEnds(end) = min(binEnds(end), chrom_size(chrom));
		end;

		% Pack values column-wise (each column becomes one GFF3 line).
		dataMatrix = [ ...
			double(binStarts); ...
			double(binEnds); ...
			double(localCopyEstimates); ...
			double(binStarts); ...
			double(binEnds); ...
			double(localCopyEstimates) ...
		];

		% Build chromosome-specific template and write all rows at once.
		rowFormat = sprintf('%s\tYmap\tregion\t%%d\t%%d\t%%.1f\t.\t.\tNote=%s:%%d-%%d:%%.1f\n', chrom_name{chrom}, chrom_label{chrom});
		fprintf(cnvTrackFid, rowFormat, dataMatrix);
	end;
	fclose(cnvTrackFid);

	%% change permissions of file.
	system(['chmod 774 "' outputFile '"']);
	fprintf('[***] createCnvTrack.m: CNV track file created.\n');
end;

%	roundedbases_per_bin = round(bases_per_bin);
%	for chrom = 1:length(CNVplot2)
%		for chromBin = 1:length(CNVplot2{chrom})
%			localCopyEstimate = CNVplot2{chrom}(chromBin) * ploidyMultiplier;
%			binStart = (chromBin - 1) * roundedbases_per_bin + 1;
%			binEnd = binStart + roundedbases_per_bin - 1;
%
%			fprintf(cnvTrackFid, '%s\tYmap\tregion\t%d\t%d\t%.1f\t.\t.\tNote=%s:%d-%d:%.1f\n', ...
%				chrom_name{chrom}, binStart, binEnd, localCopyEstimate, chrom_label{chrom}, binStart, binEnd, localCopyEstimate);
%		end
%	end
%
%	fclose(cnvTrackFid);
%
%	%% change permissions of file.
%	system(['chmod 774 ' projectDir 'cnv.' project_ '.gff3']);
%	printf('[***] createCnvTrack.m: CNV track file created.\n');
