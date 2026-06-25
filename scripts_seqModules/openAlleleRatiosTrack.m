function [alleleRatiosFid] = openAlleleRatiosTrack(projectDir, projectName)

fprintf(['[***] openAlleleRatiosTrack.m\n']);
fprintf(['[***]\tprojectDir   = ' projectDir '\n']);
fprintf(['[***]\tprojectName  = ' projectName '\n']);

if (isempty(strfind(projectName,'/')))
	projectName_ = projectName;
else
	idx = strfind(projectName,'/');
	projectName_ = substr(projectName,idx+1);
end
fprintf(['[***]\tprojectName_  = ' projectName_ '\n']);

alleleRatiosFid = fopen(fullfile(projectDir, ['allele_ratios.' projectName_  '.bed']), 'w');
if (alleleRatiosFid == -1)
        printf('[***] openAlleleRatiosTrack.m: Not a valid filename, skipping.');
else
	printf('[***] openAlleleRatiosTrack.m: CNV track file created.');

	fprintf(alleleRatiosFid, ['track name=' projectName_ 'AlleleRatios description="' projectName ' allele ratios" useScore=0 itemRGB=On\n']);
end

end
