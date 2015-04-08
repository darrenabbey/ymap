function [] = createCnvTrack(outputDir, projectName, CNVplot2, basesPerBin, chrNames, maxPloidyToDisplay, ploidyMultiplier)

maxPloidyToDisplay = round(maxPloidyToDisplay);

cnvTrackFid = fopen(fullfile(outputDir, ['cnv.' projectName '.gff3']), 'w');
fprintf(cnvTrackFid, ...
		[ '##gff-version 3\n\n' ...
		'[CNV]\n' ...
		'glyph = xyplot\n' ...
		'graph_type = histogram\n' ...
		'fgcolor = black\n' ...
		'bgcolor = black\n' ...
		'height = 50\n' ...
		'min_score = 0\n' ...
		'max_score = %d\n' ...
		'label = 1\n' ...
		'bump = 0\n' ...
		'scale = none\n' ...
		'balloon hover = Estimated CNV is $description\n' ...
		'key = ' projectName ' CNVs\n\n' ], ...
		maxPloidyToDisplay);

roundedBasesPerBin = round(basesPerBin);
for chr = 1:length(CNVplot2)
	for chrBin = 1:length(CNVplot2{chr})
		localCopyEstimate = CNVplot2{chr}(chrBin) * ploidyMultiplier;

		binStart = (chrBin - 1) * roundedBasesPerBin + 1;
		binEnd = binStart + roundedBasesPerBin - 1;
		fprintf(cnvTrackFid, '%s\tYmap\tCNV\t%d\t%d\t%.1f\t.\t.\tNote=%.1f\n', ...
			chrNames{chr}, binStart, binEnd, localCopyEstimate, localCopyEstimate);
	end
end

fclose(cnvTrackFid);

end