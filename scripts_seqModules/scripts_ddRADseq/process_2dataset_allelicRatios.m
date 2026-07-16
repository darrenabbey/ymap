function [] = process_2dataset_allelicRatios(project1dir, project2dir, chrom_size, chrom_name, chrom_in_use, SNP_verString);


%%============================================================================================================
% Define files for processing.
%-------------------------------------------------------------------------------------------------------------
C_datafile = [project1dir 'putative_SNPs_v4.txt'];
P_datafile = [project2dir 'putative_SNPs_v4.txt'];


%%============================================================================================================
% Preallocate data vectors the length of each chromosome.
%-------------------------------------------------------------------------------------------------------------
fprintf(['process_2dataset_allelicRatios.m: Preallocate data vectors.\n']);
C_chrom_SNP_data_positions = cell(length(chrom_size),1);
C_chrom_SNP_data_ratios    = cell(length(chrom_size),1);
C_chrom_count              = cell(length(chrom_size),1);
P_chrom_SNP_data_positions = cell(length(chrom_size),1);
P_chrom_SNP_data_ratios    = cell(length(chrom_size),1);
P_chrom_count              = cell(length(chrom_size),1);
for chromID = 1:length(chrom_size)
	if (chrom_in_use(chromID) == 1)
		C_chrom_SNP_data_positions{chromID} = zeros(chrom_size(chromID),1);
		C_chrom_SNP_data_ratios{   chromID} = zeros(chrom_size(chromID),1);
		C_chrom_count{             chromID} = zeros(chrom_size(chromID),1);
		C_chrom_lines_analyzed(    chromID) = 0;
		P_chrom_SNP_data_positions{chromID} = zeros(chrom_size(chromID),1);
	 	P_chrom_SNP_data_ratios{   chromID} = zeros(chrom_size(chromID),1);
		P_chrom_count{             chromID} = zeros(chrom_size(chromID),1);
		P_chrom_lines_analyzed(    chromID) = 0;
	end;
end;


%%============================================================================================================
% Process project 1 dataset.
%-------------------------------------------------------------------------------------------------------------
fprintf(['process_2dataset_allelicRatios.m: Process project 1 dataset.\n']);
C_data     = fopen(C_datafile, 'r');
while not (feof(C_data))
	C_dataLine = fgetl(C_data);
	if (length(C_dataLine) > 0)
		% process the loaded line into data channels.
		C_SNP_chrom_name   = sscanf(C_dataLine, '%s',1);
		C_SNP_coordinate = sscanf(C_dataLine, '%s',2);   for i = 1:size(sscanf(C_dataLine,'%s',1),2);   C_SNP_coordinate(1) = [];   end;
		C_SNP_reference  = sscanf(C_dataLine, '%s',3);   for i = 1:size(sscanf(C_dataLine,'%s',2),2);   C_SNP_reference(1)  = [];   end;
		C_SNP_countA     = sscanf(C_dataLine, '%s',4);   for i = 1:size(sscanf(C_dataLine,'%s',3),2);   C_SNP_countA(1)     = [];   end;
		C_SNP_countT     = sscanf(C_dataLine, '%s',5);   for i = 1:size(sscanf(C_dataLine,'%s',4),2);   C_SNP_countT(1)     = [];   end;
		C_SNP_countG     = sscanf(C_dataLine, '%s',6);   for i = 1:size(sscanf(C_dataLine,'%s',5),2);   C_SNP_countG(1)     = [];   end;
		C_SNP_countC     = sscanf(C_dataLine, '%s',7);   for i = 1:size(sscanf(C_dataLine,'%s',6),2);   C_SNP_countC(1)     = [];   end;
		C_chrom_num        = find(strcmp(C_SNP_chrom_name, chrom_name));
		if (length(C_chrom_num) > 0)
			C_SNP_countA                                                         = str2num(C_SNP_countA);
			C_SNP_countT                                                         = str2num(C_SNP_countT);
			C_SNP_countG                                                         = str2num(C_SNP_countG);
			C_SNP_countC                                                         = str2num(C_SNP_countC);
			C_count_vector                                                       = [C_SNP_countA C_SNP_countT C_SNP_countG C_SNP_countC];
			C_SNP_coordinate                                                     = str2num(C_SNP_coordinate);
			C_chrom_lines_analyzed(C_chrom_num)                                      = C_chrom_lines_analyzed(C_chrom_num)+1;
			C_chrom_SNP_data_positions{C_chrom_num}(C_chrom_lines_analyzed(C_chrom_num)) = C_SNP_coordinate;
			C_chrom_SNP_data_ratios   {C_chrom_num}(C_chrom_lines_analyzed(C_chrom_num)) = max(C_count_vector)/sum(C_count_vector);
			C_chrom_count             {C_chrom_num}(C_chrom_lines_analyzed(C_chrom_num)) = sum(C_count_vector);
		end;
	end;
end;
fclose(C_data);


%%============================================================================================================
% Process project 2 dataset.
%-------------------------------------------------------------------------------------------------------------
fprintf(['process_2dataset_allelicRatios.m: Process project 2 dataset.\n']);
P_data     = fopen(P_datafile, 'r');
while not (feof(P_data))
	P_dataLine = fgetl(P_data);
	if (length(P_dataLine) > 0)
		% process the loaded line into data channels.
		P_SNP_chrom_name   = sscanf(P_dataLine, '%s',1);
		P_SNP_coordinate = sscanf(P_dataLine, '%s',2);   for i = 1:size(sscanf(P_dataLine,'%s',1),2);   P_SNP_coordinate(1) = [];   end;
		P_SNP_reference  = sscanf(P_dataLine, '%s',3);   for i = 1:size(sscanf(P_dataLine,'%s',2),2);   P_SNP_reference(1)  = [];   end;
		P_SNP_countA     = sscanf(P_dataLine, '%s',4);   for i = 1:size(sscanf(P_dataLine,'%s',3),2);   P_SNP_countA(1)     = [];   end;
		P_SNP_countT     = sscanf(P_dataLine, '%s',5);   for i = 1:size(sscanf(P_dataLine,'%s',4),2);   P_SNP_countT(1)     = [];   end;
		P_SNP_countG     = sscanf(P_dataLine, '%s',6);   for i = 1:size(sscanf(P_dataLine,'%s',5),2);   P_SNP_countG(1)     = [];   end;
		P_SNP_countC     = sscanf(P_dataLine, '%s',7);   for i = 1:size(sscanf(P_dataLine,'%s',6),2);   P_SNP_countC(1)     = [];   end;
		P_chrom_num        = find(strcmp(P_SNP_chrom_name, chrom_name));
		if (length(P_chrom_num) > 0)
			P_SNP_countA                                                         = str2num(P_SNP_countA);
			P_SNP_countT                                                         = str2num(P_SNP_countT);
			P_SNP_countG                                                         = str2num(P_SNP_countG);
			P_SNP_countC                                                         = str2num(P_SNP_countC);
			P_count_vector                                                       = [P_SNP_countA P_SNP_countT P_SNP_countG P_SNP_countC];
			P_SNP_coordinate                                                     = str2num(P_SNP_coordinate);
			P_chrom_lines_analyzed(P_chrom_num)                                      = P_chrom_lines_analyzed(P_chrom_num)+1;
			P_chrom_SNP_data_positions{P_chrom_num}(P_chrom_lines_analyzed(P_chrom_num)) = P_SNP_coordinate;
			P_chrom_SNP_data_ratios   {P_chrom_num}(P_chrom_lines_analyzed(P_chrom_num)) = max(P_count_vector)/sum(P_count_vector);
			P_chrom_count             {P_chrom_num}(P_chrom_lines_analyzed(P_chrom_num)) = sum(P_count_vector);
		end;
	end;
end;
fclose(P_data);


%%============================================================================================================
% Clean up data vectors.
%-------------------------------------------------------------------------------------------------------------
fprintf(['process_2dataset_allelicRatios.m: Clean up data.\n']);
for chromID = 1:length(chrom_size)
	if (chrom_in_use(chromID) == 1)
		C_chrom_SNP_data_ratios{   chromID}(C_chrom_SNP_data_positions{chromID} == 0) = [];
		C_chrom_count{             chromID}(C_chrom_SNP_data_positions{chromID} == 0) = [];
		C_chrom_SNP_data_positions{chromID}(C_chrom_SNP_data_positions{chromID} == 0) = [];
		C_chrom_SNP_data_ratios{   chromID}(C_chrom_count{chromID} < 20)              = [];
		C_chrom_SNP_data_positions{chromID}(C_chrom_count{chromID} < 20)              = [];
		C_chrom_count{             chromID}(C_chrom_count{chromID} < 20)              = [];

		P_chrom_SNP_data_ratios{   chromID}(P_chrom_SNP_data_positions{chromID} == 0) = [];
		P_chrom_count{             chromID}(P_chrom_SNP_data_positions{chromID} == 0) = [];
		P_chrom_SNP_data_positions{chromID}(P_chrom_SNP_data_positions{chromID} == 0) = [];
		P_chrom_SNP_data_ratios{   chromID}(P_chrom_count{chromID} < 20)              = [];
		P_chrom_SNP_data_positions{chromID}(P_chrom_count{chromID} < 20)              = [];
		P_chrom_count{             chromID}(P_chrom_count{chromID} < 20)              = [];
	end;
end;


%%============================================================================================================
% Save processed data file.
%-------------------------------------------------------------------------------------------------------------
fprintf(['process_2dataset_allelicRatios.m: Save data.\n']);
save([project1dir 'SNP_' SNP_verString '.all1.mat'],'C_chrom_SNP_data_ratios','C_chrom_SNP_data_positions','P_chrom_SNP_data_ratios','P_chrom_SNP_data_positions','C_chrom_count','P_chrom_count');
