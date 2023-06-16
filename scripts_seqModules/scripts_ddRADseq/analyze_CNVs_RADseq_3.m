function [] = analyze_CNVs_RADseq_3(main_dir,user,genomeUser,project,parent,hapmap,genome,ploidyEstimate,ploidyBase)
% A componant of the sequence analysis pipeline, analyzing CNVs in ddRADsq data only.

% log file start, for in-process analysis.
fprintf(['project : [[[' project '[[[\n']);

CNV_verString   = 'v1';
INDEL_verString = 'v1';
SNP_verString   = 'v4';
rDNA_verString  = 'v1';
displayBREAKS   = true;
referenceCHR    = 1;


CNV_v6_fragmentLengthCorrected_9(main_dir,user,genomeUser,project,parent,genome,ploidyEstimate,ploidyBase, CNV_verString,displayBREAKS);

%% version showing CNV data as black dots instead of bars.
% CNV_v6_fragmentLengthCorrected_9_dots(main_dir,user,genomeUser,project,parent,genome,ploidyEstimate,ploidyBase, CNV_verString,displayBREAKS);


fprintf('*--- End of ''analyze_CNVs_RADseq_1.m'' was reached ---*\n');
% log file end, for in-process analysis.
fprintf(['project : ]]]' project ']]]\n']);
end
