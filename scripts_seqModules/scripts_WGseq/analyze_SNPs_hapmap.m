function [] = analyze_SNPs_hapmap(main_dir, user, genomeUser, project, parent_or_hapmap, genome, ploidyEstimateString,ploidyBaseString)
% analyze_CNVS(<Project Name>,<Project File>,<Ploidy Estimate)
% A componant of the sequence analysis pipeline, analyzing SNPs only.
%    <Project Name>    : the name of the project.
%    <Project File>    : the name of the project file, including directory location.
%    <Ploidy Estimate> : a numerical value for ploidy from other work.

% log file start, for in-process analysis.
fprintf(['project : [[[' project '[[[\n']);

workingDir             = [main_dir '/users/' user '/projects/' project '/'];
figureDir              = workingDir;
CNV_verString          = 'v1';
INDEL_verString        = 'v1';
SNP_verString          = 'v4';
rDNA_verString         = 'v1';
LOH_verString          = 'v2';
displayBREAKS          = true;
referenceChrom         = 1;

% Generate fittings Rsquared scatter plot figure.
try
	CNV_LOH_check(main_dir,user,genomeUser,project,parent_or_hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
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

% Generate main SNP/LOH figure.
try
	LOH_hapmap_v4(main_dir,user,genomeUser,project,parent_or_hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
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

parent = parent_or_hapmap;
hapmap = parent_or_hapmap;

% Generate fireplot.
try
	allelic_ratios_WGseq(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimateString,ploidyBaseString,SNP_verString,LOH_verString,CNV_verString,displayBREAKS);
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


fprintf('*--- End of ''analyze_SNPs.m'' was reached. ---*\n');
end
