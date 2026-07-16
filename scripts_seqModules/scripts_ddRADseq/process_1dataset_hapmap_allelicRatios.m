function [] = process_1dataset_hapmap_allelicRatios(project1dir, project2dir, chrom_size, chrom_name, chrom_in_use, SNP_verString);


%%============================================================================================================
% Define file names for processing.
%-------------------------------------------------------------------------------------------------------------
fprintf('Define file names for processing.\n');
C_datafile = [project1dir 'putative_SNPs_v4.txt'];
P_datafile = [project2dir 'SNPdata_parent.txt'];


%%============================================================================================================
% Preallocate data vectors the length of each chromosome.
%-------------------------------------------------------------------------------------------------------------
fprintf('Preallocate data vectors for each chromosome.\n');
C_chrom_SNP_data_positions = cell(length(chrom_size),1);
C_chrom_SNP_data_ratios    = cell(length(chrom_size),1);
C_chrom_baseCall           = cell(length(chrom_size),1);
C_chrom_count              = cell(length(chrom_size),1);
C_chrom_SNP_homologA       = cell(length(chrom_size),1);
C_chrom_SNP_homologB       = cell(length(chrom_size),1);
C_chrom_SNP_flipHomologs   = cell(length(chrom_size),1);
C_chrom_SNP_keep           = cell(length(chrom_size),1);

P_chrom_SNP_data_positions = cell(length(chrom_size),1);
P_chrom_SNP_alleleA        = cell(length(chrom_size),1);
P_chrom_SNP_alleleB        = cell(length(chrom_size),1);
P_chrom_SNP_needToFlip     = cell(length(chrom_size),1);

for chromID = 1:length(chrom_size)
	if (chrom_in_use(chromID) == 1)
		C_chrom_SNP_data_positions{chromID} = zeros(chrom_size(chromID),1);
		C_chrom_SNP_data_ratios{   chromID} = zeros(chrom_size(chromID),1);
		C_chrom_count{             chromID} = zeros(chrom_size(chromID),1);
		C_chrom_baseCall{          chromID} = cell( chrom_size(chromID),1);
		C_chrom_SNP_homologA{      chromID} = cell( chrom_size(chromID),1);
		C_chrom_SNP_homologB{      chromID} = cell( chrom_size(chromID),1);
		C_chrom_SNP_flipHomologs{  chromID} = zeros(chrom_size(chromID),1);
		C_chrom_SNP_keep{          chromID} = ones(chrom_size(chromID),1);
		C_chrom_lines_analyzed(    chromID) = 0;
		P_chrom_SNP_data_positions{chromID} = zeros(chrom_size(chromID),1);
		P_chrom_SNP_alleleA{       chromID} = cell( chrom_size(chromID),1);
		P_chrom_SNP_alleleB{       chromID} = cell( chrom_size(chromID),1);
		P_chrom_SNP_needToFlip{    chromID} = zeros(chrom_size(chromID),1);
		P_chrom_lines_analyzed(    chromID) = 0;
	end;
end;


%%============================================================================================================
% Load project information.
%-------------------------------------------------------------------------------------------------------------
fprintf('Load project information.\n');
C_data      = fopen(C_datafile, 'r');
allele_list = ['A' 'T' 'G' 'C'];
old_chrom     = 0;
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
			if (C_chrom_num ~= old_chrom)
				fprintf(['\tchrom = ' num2str(C_chrom_num) '\n']);
			end;
			C_SNP_countA       = str2num(C_SNP_countA);
			C_SNP_countT       = str2num(C_SNP_countT);
			C_SNP_countG       = str2num(C_SNP_countG);
			C_SNP_countC       = str2num(C_SNP_countC);
			C_count_vector1    = [C_SNP_countA C_SNP_countT C_SNP_countG C_SNP_countC];
			C_chrom_read_max1    = max(C_count_vector1);
			C_SNP_coordinate   = str2num(C_SNP_coordinate);
			C_chrom_lines_analyzed(C_chrom_num) = C_chrom_lines_analyzed(C_chrom_num)+1;
			C_chrom_SNP_data_positions{C_chrom_num}(C_chrom_lines_analyzed(C_chrom_num)) = C_SNP_coordinate;
			C_chrom_SNP_data_ratios{   C_chrom_num}(C_chrom_lines_analyzed(C_chrom_num)) = C_chrom_read_max1/sum(C_count_vector1);
			C_chrom_count{             C_chrom_num}(C_chrom_lines_analyzed(C_chrom_num)) = sum(C_count_vector1);
			allele_call_id = find(C_count_vector1==max(C_count_vector1));
			if (length(allele_call_id) > 1)
				C_chrom_read_id = 'N';
			else
				C_chrom_read_id = allele_list(allele_call_id);
			end;
			C_chrom_baseCall{          C_chrom_num}{C_chrom_lines_analyzed(C_chrom_num)} = C_chrom_read_id;
			old_chrom = C_chrom_num;
		else
			old_chrom = 0;
		end;
	end;
end;
fclose(C_data);


%%============================================================================================================
% Load hapmap information.
%-------------------------------------------------------------------------------------------------------------
fprintf('Load hapmap information.\n');
P_data      = fopen(P_datafile, 'r');
old_chrom     = 0;
while not (feof(P_data))
	P_dataLine = fgetl(P_data);
	if (length(P_dataLine) > 0)
		% process the loaded line into data channels.
		P_SNP_chrom_name   = sscanf(P_dataLine, '%s',1);
		P_SNP_coordinate = sscanf(P_dataLine, '%s',2);   for i = 1:size(sscanf(P_dataLine,'%s',1),2);   P_SNP_coordinate(1) = [];   end;
		P_SNP_alleleA    = sscanf(P_dataLine, '%s',3);   for i = 1:size(sscanf(P_dataLine,'%s',2),2);   P_SNP_alleleA(1)    = [];   end;
		P_SNP_alleleB    = sscanf(P_dataLine, '%s',4);   for i = 1:size(sscanf(P_dataLine,'%s',3),2);   P_SNP_alleleB(1)    = [];   end;
		P_SNP_needToFlip = sscanf(P_dataLine, '%s',5);   for i = 1:size(sscanf(P_dataLine,'%s',4),2);   P_SNP_needToFlip(1) = [];   end;
		P_chrom_num        = find(strcmp(P_SNP_chrom_name, chrom_name));
		if (length(P_chrom_num) > 0)
			if (P_chrom_num ~= old_chrom)
				fprintf(['\tchrom = ' num2str(P_chrom_num) '\n']);
			end;
			P_SNP_coordinate                                                     = str2num(P_SNP_coordinate);
			P_SNP_needToFlip                                                     = str2num(P_SNP_needToFlip);
			P_chrom_lines_analyzed(P_chrom_num)                                      = P_chrom_lines_analyzed(P_chrom_num)+1;
			P_chrom_SNP_data_positions{P_chrom_num}(P_chrom_lines_analyzed(P_chrom_num)) = P_SNP_coordinate;
			P_chrom_SNP_alleleA{       P_chrom_num}{P_chrom_lines_analyzed(P_chrom_num)} = P_SNP_alleleA;
			P_chrom_SNP_alleleB{       P_chrom_num}{P_chrom_lines_analyzed(P_chrom_num)} = P_SNP_alleleB;
			P_chrom_SNP_needToFlip{    P_chrom_num}(P_chrom_lines_analyzed(P_chrom_num)) = P_SNP_needToFlip;
			old_chrom = P_chrom_num;
		else
			old_chrom = 0;
		end;
	end;
end;
fclose(P_data);


%%============================================================================================================
% Clean up data vectors.
%-------------------------------------------------------------------------------------------------------------
fprintf('Clean up data vectors.\n');
for chromID = 1:length(chrom_size)
	if (chrom_in_use(chromID) == 1)
		fprintf(['\tchrom = ' num2str(chromID) '\n']);
		C_chrom_SNP_data_ratios{   chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_count{             chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_baseCall{          chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = []; 
		C_chrom_SNP_homologA{      chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_SNP_homologB{      chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_SNP_flipHomologs{  chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_SNP_keep{          chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_SNP_data_positions{chromID}(C_chrom_SNP_data_positions{chromID} == 0)  = [];
		C_chrom_SNP_data_ratios{   chromID}(C_chrom_count{             chromID} <= 20) = [];
		C_chrom_SNP_data_positions{chromID}(C_chrom_count{             chromID} <= 20) = [];
		C_chrom_baseCall{          chromID}(C_chrom_count{             chromID} <= 20) = [];
		C_chrom_SNP_homologA{      chromID}(C_chrom_count{             chromID} <= 20) = []; 
		C_chrom_SNP_homologB{      chromID}(C_chrom_count{             chromID} <= 20) = []; 
		C_chrom_SNP_flipHomologs{  chromID}(C_chrom_count{             chromID} <= 20) = []; 
		C_chrom_SNP_keep{          chromID}(C_chrom_count{             chromID} <= 20) = []; 
		C_chrom_count{             chromID}(C_chrom_count{             chromID} <= 20) = [];

		P_chrom_SNP_alleleA{       chromID}(P_chrom_SNP_data_positions{chromID} == 0)  = [];
		P_chrom_SNP_alleleB{       chromID}(P_chrom_SNP_data_positions{chromID} == 0)  = [];
		P_chrom_SNP_needToFlip{    chromID}(P_chrom_SNP_data_positions{chromID} == 0)  = [];
		P_chrom_SNP_data_positions{chromID}(P_chrom_SNP_data_positions{chromID} == 0)  = [];
	end;
end;


%%============================================================================================================
% Determine hapmap information for dataset values.
%-------------------------------------------------------------------------------------------------------------
fprintf('Determine hapmap information for dataset values.\n');
start = 1;
for chromID = 1:length(chrom_size)
	if (chrom_in_use(chromID) == 1)
		fprintf(['\tchrom = ' num2str(chromID) '\n']);
		for projectDatumID = 1:length(C_chrom_SNP_data_positions{chromID})
			pos   = C_chrom_SNP_data_positions{chromID}(projectDatumID);
			found = false;
			for hapmapDatumID = start:length(P_chrom_SNP_data_positions{chromID})
				hapmap_pos = P_chrom_SNP_data_positions{chromID}(hapmapDatumID);
				if (pos == hapmap_pos)
					found = true;
					break;
				end;
			end;
			if (found == true)
				fprintf(['\tchrom' num2str(chromID) ':' num2str(pos) ' +\n']);
				C_chrom_SNP_homologA{    chromID}{projectDatumID} = P_chrom_SNP_alleleA{       chromID}{hapmapDatumID};;
				C_chrom_SNP_homologB{    chromID}{projectDatumID} = P_chrom_SNP_alleleB{       chromID}{hapmapDatumID};;
				C_chrom_SNP_flipHomologs{chromID}(projectDatumID) = P_chrom_SNP_needToFlip{    chromID}(hapmapDatumID);;
				C_chrom_SNP_keep{        chromID}(projectDatumID) = 1;
				start = projectDatumID;
			else
				% fprintf(['\tchrom' num2str(chromID) ':' num2str(pos) '\n']);
				C_chrom_SNP_keep{        chromID}(projectDatumID) = 0;
				start = 1;
			end;
		end;

		% Clean up data for chromosome.
		C_chrom_SNP_data_ratios{   chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_SNP_data_positions{chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_baseCall{          chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_SNP_homologA{      chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_SNP_homologB{      chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_SNP_flipHomologs{  chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_count{             chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
		C_chrom_SNP_keep{          chromID}(C_chrom_SNP_keep{chromID} == 0) = [];
	end;
end;


%%============================================================================================================
% Save processed data file.
%-------------------------------------------------------------------------------------------------------------
fprintf('Save output data file.\n');
save([project1dir 'SNP_' SNP_verString '.all2.mat'],'C_chrom_SNP_data_positions','C_chrom_SNP_data_ratios','C_chrom_count','C_chrom_baseCall','C_chrom_SNP_homologA','C_chrom_SNP_homologB','C_chrom_SNP_flipHomologs');
