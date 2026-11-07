function [] = analyze_CNV_SNPs_hapmap(main_dir, user, genomeUser, project, parent_or_hapmap, genome, ploidyEstimateString,ploidyBaseString)

testPloidy     = ploidyEstimateString
testPloidyBase = ploidyBaseString

workingDir      = [main_dir '/users/' user '/projects/' project '/'];
figureDir       = workingDir;
INDEL_verString = 'v1';
SNP_verString   = 'v4';
LOH_verString   = 'v2';
CNV_verString   = 'v1';
displayBREAKS   = true;
referenceChrom  = 1;

parent = parent_or_hapmap;
hapmap = parent_or_hapmap;

fprintf('\n');
fprintf(['[analyze_CNV_SNPs_hapmap.m data inputs:\n']);
fprintf(['    hapmap  : ' hapmap '\n']);
fprintf(['    project : ' project '\n']);
fprintf(['    Ploidy  : ' ploidyEstimateString '\n']);
fprintf('\n');

try
	CNV_SNP_hapmap_v4(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
catch err
	err_file = fullfile(main_dir, 'users', user, 'projects', project, 'error.txt');
	fileID = fopen(err_file, 'a');
	if fileID ~= -1
		if ~isempty(err.stack)
			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\n', err.stack(1).name, err.stack(1).line, err.message);
		else
			fprintf(fileID, 'Something went wrong. [No Stack]|%s\n', err.message);
		end;
		fclose(fileID);
	end;
	rethrow(err);
end;

try
	CNV_SNP_hapmap_v4_highTop(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
catch err
	err_file = fullfile(main_dir, 'users', user, 'projects', project, 'error.txt');
	fileID = fopen(err_file, 'a');
	if fileID ~= -1
		if ~isempty(err.stack)
			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\n', err.stack(1).name, err.stack(1).line, err.message);
		else
			fprintf(fileID, 'Something went wrong. [No Stack]|%s\n', err.message);
		end;
		fclose(fileID);
	end;
	rethrow(err);
end;

%try
%	CNV_SNP_hapmap_v4_RedGreen(main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
%catch err
%	err_file = fullfile(main_dir, 'users', user, 'projects', project, 'error.txt');
%	fileID = fopen(err_file, 'a');
%	if fileID ~= -1
%		if ~isempty(err.stack)
%			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\n', err.stack(1).name, err.stack(1).line, err.message);
%		else
%			fprintf(fileID, 'Something went wrong. [No Stack]|%s\n', err.message);
%		end;
%		fclose(fileID);
%	end;
%	rethrow(err);
%end;

%try
%	CNV_manualLOH_v1( main_dir,user,genomeUser,project,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
%catch err
%	err_file = fullfile(main_dir, 'users', user, 'projects', project, 'error.txt');
%	fileID = fopen(err_file, 'a');
%	if fileID ~= -1
%		if ~isempty(err.stack)
%			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\n', err.stack(1).name, err.stack(1).line, err.message);
%		else
%			fprintf(fileID, 'Something went wrong. [No Stack]|%s\n', err.message);
%		end;
%		fclose(fileID);
%	end;
%	rethrow(err);
%end;

fprintf('*--- End of ''analyze_CNV_SNPs_hapmap.m'' was reached ---*\n');
% log file end, for in-process analysis
fprintf(['ProjectName : ]]]project''' project '''|||hapmap''' hapmap ''']]]\n']);
end
