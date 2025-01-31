function results = genome_process_for_standard_bins_1(user,genome)
% This script attempts to reformat a FASTA genome file into a new FASTA genome fragmented by restriction digest sites.
%     for use in ddRADseq analysis.

% log file start, for in-process analysis.
fprintf(['Genome : [[[' genome '[[[\n']);

workingDir             = ['../users/' user '/genomes/' genome '/'];
nmer_length            = 10;

[centromeres, chr_sizes, figure_details, annotations, ploidy_default] = Load_genome_information_1(workingDir,genome);

%% Determine number of chromosomes from figure_details.
num_chrs   = 0;
chr_labels = [];
inUse      = zeros(1,length(figure_details));
allNames   = {};
for i = 1:length(figure_details)
	allNames{i}  = figure_details(i).name;
	if (figure_details(i).chr ~= 0)
		inUse(i) = 1;
		num_chrs = num_chrs+1;
		chr_names{figure_details(i).chr}  = figure_details(i).name;
		length_nts(figure_details(i).chr) = chr_sizes(figure_details(i).chr).size;
	end;
end;
testVar = inUse

%% Determine size of standard data display bin.
bases_per_bin = round(max(length_nts)/700);

%% Initialize the cell arrays needed to contain chromosome sequences.
sequences         = cell(1,length(figure_details));
rev_com_sequences = cell(1,length(figure_details));

%% Determine reference genome FASTA file in use.
reference_file = [workingDir '/reference.txt'];
refernce_fid   = fopen(reference_file, 'r');
refFASTA       = fgetl(refernce_fid);
fclose(refernce_fid);
FastaName      = strrep(refFASTA,'.fasta','');

if (exist([workingDir FastaName '.standard_bins.fasta'],'file') == 0)
    %% ====================================================================
    % Parse sequences from FASTQ file, or load MAT files if already generated for this genome.
    % ---------------------------------------------------------------------
    if (exist([workingDir FastaName '.seq.mat'],'file') == 0) && (exist([workingDir FastaName 'seqRevCom.mat'],'file') == 0)
		fprintf('\nParsing sequences from FASTQ file.');
		SequenceData = fastaread([workingDir refFASTA ],'Blockread',[1,inf],'TrimHeaders', true);
		% 'Blockread'   : read in specific entries from the FASTA file.
		% 'TrimHeaders' : trims the header lines for each FASTA entry to the first white-space delimited string.

		fprintf(['\n\tLoading FASTA file: \"' refFASTA '\"\n\n']);
		for i = 1:length(SequenceData)
			for j = 1:length(chr_names)
				if (strcmp(chr_names{j},SequenceData(i).Header) == 1)
					length_nts(j)        = length(SequenceData(i).Sequence);
					sequences{j}         = SequenceData(i).Sequence;
					rev_com_sequences{j} = rev_com(sequences{j});
				end;
			end;
		end;
		save([workingDir FastaName '.seq.mat']      ,'sequences');
		save([workingDir FastaName '.seqRevCom.mat'],'rev_com_sequences');
	else
		fprintf('\nLoading pre-determined sequences.');
		load([workingDir FastaName '.seq.mat']);
		load([workingDir FastaName '.seqRevCom.mat']);
	end;

    %% ====================================================================
    % Fragment genome by standard bin size into new FASTA file.
    % ---------------------------------------------------------------------
    % standard bin size is round(max(chr_lengths)/700);

    NewSequenceData = [];
    fragment = 1;
    fprintf('\nFragmenting genome into standard bins.');
    for chr = 1:length(figure_details)
		if (inUse(chr) == 1)
			start_coordinate = 1;
			fprintf(['\n\tFragmenting : ' allNames{chr} ]);
			for bp = start_coordinate:length(sequences{chr})
				if (mod(bp,bases_per_bin) == 0)
					% fragment chromosome at standard bin boundry.
					header_string                      = ['>' genome '.chr' num2str(chr) ' (' num2str(start_coordinate) '..' num2str(bp) ')'];
					sequence_string                    = sequences{chr}(start_coordinate:bp);
					NewSequenceData(fragment).Header   = header_string;
					NewSequenceData(fragment).Sequence = sequence_string;
					start_coordinate                   = bp+1;
					fragment                           = fragment+1;
				end;
				if (bp == length(sequences{chr}))
					header_string                      = ['>' genome '.chr' num2str(chr) ' (' num2str(start_coordinate) '..' num2str(length(sequences{chr})) ')'];
					sequence_string                    = sequences{chr}(start_coordinate:end);
					NewSequenceData(fragment).Header   = header_string;
					NewSequenceData(fragment).Sequence = sequence_string;
					fragment                           = fragment+1;
				end;
			end;
		else
			fprintf(['\n\tSkipping : ' allNames{chr} ]);
		end;
	end;

	% Annotate fragment headers with fragment length.
	fprintf('\nAdding fragment lengths to fragment headers.');
	for fragment = 1:(length(NewSequenceData))
		header_length = length(NewSequenceData(fragment).Sequence);
		% Header strings are ended in '[*]' to indicate the fragment is to be used in downstream scripting stages.
		NewSequenceData(fragment).Header = [NewSequenceData(fragment).Header ' (' num2str(length(NewSequenceData(fragment).Sequence)) 'bp) [*]'];
	end;

	outputFile = [workingDir FastaName '.standard_bins.fasta'];

	% Clear pre-existing processed genome file if it already exists.
	if (exist(outputFile,'file') == 0)
		fprintf('\nPre-existing standard bins processed genome file not found.');
	else
		fprintf('\nDeleting pre-existing standard bins processed genome file.');
		delete(outputFile);
	end;

	% Write out the fragmented chromosome as a genome FASTA file.
	fprintf('\nWriting out standard bin fragmented chromosomes structure as new FASTA file.\n\n');
	fastawrite(outputFile, NewSequenceData);
else
	outputFile = [workingDir FastaName '.standard_bins.fasta'];
	fprintf(['\nReference genome was already fragmented into standard bins.\nDigested genome is found at :\n\t' outputFile '\n\n']);
end;

end
