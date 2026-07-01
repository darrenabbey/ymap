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
end
fprintf(['[***]\tproject_  = ' project_ '\n']);

fprintf(['[***]\toutputFile   = ' projectDir 'cnv.' project_ '.CNVs.gff3\n']);
cnvTrackFid = fopen(fullfile(projectDir, ['cnv.' project_ '.CNVs.gff3']), 'w');
if (cnvTrackFid == -1)
        printf('[***] createCnvTrack.m: Not a valid filename, skipping.\n');
else
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
			'key = ' project_ ' CNVs\n\n' ], ...
			maxPloidyToDisplay);

	roundedbases_per_bin = round(bases_per_bin);
	for chr = 1:length(CNVplot2)
		for chrBin = 1:length(CNVplot2{chr})
			localCopyEstimate = CNVplot2{chr}(chrBin) * ploidyMultiplier;
			binStart = (chrBin - 1) * roundedbases_per_bin + 1;
			binEnd = binStart + roundedbases_per_bin - 1;

			if (round(localCopyEstimate) == ploidyBase)
				fprintf(cnvTrackFid,[chr_name{chr} '\tYmap\tCNV\t-\t-\t-\t-\t-\t-\n']);
			else
				fprintf(cnvTrackFid, '%s\tYmap\tCNV\t%d\t%d\t%.1f\t.\t.\tNote=%s:%d-%d:%.1f\n', ...
					chr_name{chr}, binStart, binEnd, localCopyEstimate, chr_label{chr}, binStart, binEnd, localCopyEstimate);
			end;
		end
	end

	fclose(cnvTrackFid);

	%% change permissions of file.
	system(['chmod 774 ' projectDir 'cnv.' project_ '.gff3']);
	printf('[***] createCnvTrack.m: CNV track file created.\n');
end
