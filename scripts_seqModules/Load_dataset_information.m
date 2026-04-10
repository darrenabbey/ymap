function [segmental_aneuploidy] = Load_dataset_information(projectDir)

%%=========================================================================
% Load Common_ChARM.mat file for project : 'segmental_aneuploidy'.
%--------------------------------------------------------------------------
if (exist([projectDir 'Common_ChARM.mat'],'file') ~= 0)
	dataFile = [projectDir 'Common_ChARM.mat'];
	fprintf(['\nLoading Common_ChARM.mat file for "' projectDir '" : ' dataFile '\n']);
	load(dataFile);
else
	fprintf(['\nThe Common_ChARM.mat file for "' projectDir '" was not found.\n']);
	fprintf(['Analyze your dataset with "ChARM_v4.m" first.\n']);
	segmental_aneuploidy = [];
end;

end
