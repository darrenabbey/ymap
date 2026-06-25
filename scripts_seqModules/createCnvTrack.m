function [] = createCnvTrack(outputDir, projectName, CNVplot2, basesPerBin, chrNames, maxPloidyToDisplay, ploidyMultiplier)

maxPloidyToDisplay = round(maxPloidyToDisplay);

fprintf(['[***] createCnvTrack.m\n']);
fprintf(['[***]\toutputDir    = ' outputDir '\n']);
fprintf(['[***]\tprojectName  = ' projectName '\n']);

if (isempty(strfind(projectName,'/')))
	projectName_ = projectName;
else
	idx = strfind(projectName,'/');
	projectName_ = substr(projectName,idx+1);
end
fprintf(['[***]\tprojectName_  = ' projectName_ '\n']);

fprintf(['[***]\toutputFile   = ' outputDir 'cnv.' projectName_ '.gff3\n']);
cnvTrackFid = fopen(fullfile(outputDir, ['cnv.' projectName_ '.gff3']), 'w');
if (cnvTrackFid == -1)
        printf('[***] createCnvTrack.m: Not a valid filename, skipping.');
else
	printf('[***] createCnvTrack.m: CNV track file created.');
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
			'key = ' projectName_ ' CNVs\n\n' ], ...
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

	%% change permissions of file.
	system(['chmod 774 ' outputDir 'cnv.' projectName_ '.gff3']);
end

end
