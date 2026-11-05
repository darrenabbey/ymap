# Input Arguments
#	1) user     : 'darren'
#	2) project  : 'test_Ca'
#	3) genome   : 'Candida_albicans_SC5314_etc'
#	4) main_dir : '/home/darren/public_html/Ymap/'
#	5) logName  :
#
# Process input files:
#	1) Raw SNP data                 : $main_dir"/users/"$user"/projects/"$project"/SNP_CNV_v1.txt".
#	2) FASTA file name              : $main_dir"/users/default/genomes/default/reference.txt",
#	                               or $main_dir"/users/"$user"/genomes/default/reference.txt" as $FastaName.
#	3) Coordinates of standard bins : $main_dir"/users/default/genomes/"$genome"/"$FastaName".standard_bins.fasta",
#	                               or $main_dir"/users/"$user"/genomes/"$genome"/"$FastaName".standard_bins.fasta".

# Generate output file:
#	1) a simplified pileup file containing number of parental het loci that are [HOM, HET, oddHET] in dataset per standard bin.
#		0) chr_num  : Numerical chromosome identifier, defined for each genome in "figure_details.txt".
#		1) bp_start : Start bp coordinate along chromosome.
#		2) bp_end   : End bp coordinate along chromosome.
#		3) list of phased data ratios.
#		4) list of unphased data ratios.
#		5) list of phased data coordinates.
#		6) list of unphased data coordinates.
#		7) list of phased data alleles.
#		8) list of unphased data alleles.
#		Comment lines in output begin with '#'.
#

import string, sys, re, time, os
genome           = sys.argv[1];
genomeUser       = sys.argv[2];
hapmap           = sys.argv[3];	# 'hapmap' or 'parent project'...            both will contain a 'SNPdata_parent.txt' format file.
hapmapUser       = sys.argv[4];	# 'hapmap user' or 'parent project user'...
project          = sys.argv[5];	# 'child project'.
projectUser      = sys.argv[6];	# 'child project user'.
main_dir         = sys.argv[7];
logName          = sys.argv[8];
runMode          = sys.argv[9];  # 'hapmap' or 'LOH' modes.

with open(logName, "a") as myfile:
	myfile.write("\t\t*=======================================================================================*\n");
	myfile.write("\t\t| Log of 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'   |\n");
	myfile.write("\t\t*---------------------------------------------------------------------------------------*\n");
	myfile.write("\t\t| Input arguments:\n");
	myfile.write("\t\t|     genome      = "+genome+"\n");
	myfile.write("\t\t|     genomeUser  = "+genomeUser+"\n");
	if (runMode == 'hapmap'):
		myfile.write("\t\t|     hapmap      = "+hapmap+"\n");
		myfile.write("\t\t|     hapmapUser  = "+hapmapUser+"\n");
	else:
		myfile.write("\t\t|     parent      = "+hapmap+"\n");
		myfile.write("\t\t|     parentUser  = "+hapmapUser+"\n");
	myfile.write("\t\t|     project     = "+project+"\n");
	myfile.write("\t\t|     projectUser = "+projectUser+"\n");
	myfile.write("\t\t|     main_dir    = "+main_dir+"\n");
	myfile.write("\t\t|     logName     = "+logName+"\n");
	myfile.write("\t\t|     runMode     = "+runMode+"\n");
	myfile.write("\t\t*---------------------------------------------------------------------------------------*\n")

# Figure out if input name 'hapmap' corresponds to a project or an actual hapmap.
if (runMode == 'hapmap'):
	parentDatafile  = main_dir+"/users/"+hapmapUser+"/hapmaps/"+hapmap+"/SNPdata_parent.txt";
	with open(logName, "a") as myfile:
		myfile.write("\t\t|\trunMode = 'hapmap'\n");
		myfile.write("\t\t|\t    Comparing project '"+project+"' to hapmap '"+hapmap+"'.\n");
elif (runMode == 'LOH'):
	parentDatafile = main_dir+"/users/"+projectUser+"/projects/"+project+"/SNPdata_parent.txt";
	with open(logName, "a") as myfile:
		myfile.write("\t\t|\trunMode = 'LOH'\n");
		myfile.write("\t\t|\t    Comparing project '"+project+"' to parent project '"+hapmap+"'.\n");

childDatafile = main_dir+"/users/"+projectUser+"/projects/"+project+"/SNP_CNV_v1.txt";

t0 = time.process_time();


#============================================================================================================
# Find location of genome being used.
#------------------------------------------------------------------------------------------------------------
genomeDirectory = main_dir+"/users/"+genomeUser+"/genomes/"+genome+"/";

with open(logName, "a") as myfile:
	myfile.write("\t\t|\tProcessing standard bin fragmented genome file.\n");


#============================================================================================================
# Load FastaName from 'reference.txt' for genome in use.
#------------------------------------------------------------------------------------------------------------
with open(logName, "a") as myfile:
	myfile.write("\t\t|\tIdentifying name of reference FASTA file.\n");
reference_file = genomeDirectory + '/reference.txt';
refFile        = open(reference_file,'r');
FastaName      = refFile.read().strip();
refFile.close();
FastaName      = FastaName.replace(".fasta", "");
with open(logName, "a") as myfile:
	myfile.write("\t\t|\t\t'"+FastaName+"'\n");


#============================================================================================================
# Process standard-bin fragmented reference genome file.
#------------------------------------------------------------------------------------------------------------
# Example FASTQ header line.
#     >Ca_a.chr1 (9638..10115) (478bp) [*]
# FASTA entries with header lines ending in '[gene]' or '[intergenic]' are usable.
with open(logName, "a") as myfile:
	myfile.write("\n\t\tProcessing standard bin fragmented genome file.");

# Find name of genome FASTA file for species being examined.
#     Read in and parse : "links_dir/main_script_dir/genome_specific/[genome]/reference.txt"
workingDir     = os.path.join(main_dir, 'users', genomeUser, 'genomes', genome, '');
reference_file = os.path.join(workingDir, 'reference.txt');
with open(reference_file, 'r') as refFile:
	refFASTA = refFile.read().strip();

# Open standard-fragmented genome FASTQ file.
fragments_FASTA_file = os.path.join(workingDir, refFASTA.replace('.fasta', '.standard_bins.fasta'));

fragments = [];
usable_labels = {'[*]', '[gene]', '[intergenic]'};

current_header = None;  # Tracks the active valid header line.

with open(fragments_FASTA_file, 'r') as fragments_FASTA_data:
	for line in fragments_FASTA_data:
		trimmed_line = line.strip();

		# Safely skip any single blank line instantly.
		if not trimmed_line:
			continue;

		# If the line is a header, store it and move to the next line.
		if trimmed_line.startswith(">"):
			current_header = trimmed_line;
			continue;

		# If we reach here, it's a sequence line. Process it using the stored header.
		if current_header:
			line_parts = current_header.split();

			if len(line_parts) > 3:
				chrGenomeAndNum_string = line_parts[0];
				bp_coordinate_string   = line_parts[1];
				fragment_size_string   = line_parts[2];
				fragment_usable_string = line_parts[3];

				if fragment_usable_string in usable_labels:
					# Parse chromosome number.
					string_fragments = chrGenomeAndNum_string.split(".");
					chrNum_string    = string_fragments[-1];
					chr_num          = int(chrNum_string.replace("chr", ""));

					# Parse coordinates.
					coordinates = bp_coordinate_string.replace('(', '').replace(')', '').replace('..', ' ').split();
					bp_start    = int(coordinates[0]);
					bp_end      = int(coordinates[1]);

					# Core initialization placeholders for downstream SNP string additions
					phasedData         = '(';
					unphasedData       = '(';
					phasedCoordinate   = '(';
					unphasedCoordinate = '(';
					phasedAllele       = '(';
					unphasedAllele     = '(';

					fragments.append([
						chr_num, bp_start, bp_end, 
						phasedData, unphasedData, 
						phasedCoordinate, unphasedCoordinate, 
						phasedAllele, unphasedAllele
					]);

			# Reset header tracker to prepare for the next record
			current_header = None;

fragment_counter = len(fragments);

with open(logName, "a") as myfile:
	myfile.write("\t\t|\tThe standard bin fragmented genome FASTA file has been loaded.\n");

# Put fragment counter into a general use variable.
numFragments = len(fragments);
#------------------------------------------------------------------------------------------------------------
# End of code section to parse standard-bin fragments file.
#============================================================================================================


print("### " + str(time.process_time()-t0) + "seconds to parse fragments from genome.")
t1 = time.process_time()
print("### Starting read count data processing.")


#============================================================================================================
# Process hapmap 'SNPdata_parent.txt' file to determine initial SNP loci.
#------------------------------------------------------------------------------------------------------------
with open(logName, "a") as myfile:
	myfile.write("\t\t|\tProcessing 'SNPdata_parent.txt' file -> het loci.\n");

# Look up chromosome name strings for genome in use.
#     Read in and parse : "links_dir/main_script_dir/genome_specific/[genome]/figure_definitions.txt"
# Read in and parse chromosome layout information
figureDefinition_file = os.path.join(genomeDirectory, 'figure_definitions.txt');
with open(figureDefinition_file, 'r') as f:
	figureDefinitionData = f.readlines();

# Example lines in figureDefinition_file:
#     Chr  Use   Label   Name                         posX   posY   width   height
#     1    1     Chr1    Ca21chr1_C_albicans_SC5314   0.15   0.8    0.8     0.0625
#     2    1     Chr2    Ca21chr2_C_albicans_SC5314   0.15   0.7    *       0.0625
#     0    0     Mito    Ca19-mtDNA                   0.0    0.0    0.0     0.0
# Determine the number of chromosomes of interest in genome.
with open(logName, "a") as myfile:
	myfile.write("\t\t|\tDetermining number of chromosomes of interest in genome.\n");

chrName_maxcount = 0;
for line in figureDefinitionData:
	trimmed = line.strip();
	if trimmed and not trimmed.startswith("#"):
		line_parts = trimmed.split();
		if line_parts:
			chr_num_str = line_parts[0];
			if chr_num_str.isdigit():
				chr_num = int(chr_num_str);
				chr_use = int(float(line_parts[1]));
				chr_label = line_parts[2];
				chr_name = line_parts[3];
				if chr_num > chrName_maxcount:
					chrName_maxcount = chr_num;

chrName = [];
chrNums = [];
chrNames = [];
chrLabels = [];
chrShorts = [];

with open(logName, "a") as myfile:
	myfile.write("\t\t|\tGathering name strings for chromosomes.\n");
	for line in figureDefinitionData:
		trimmed = line.strip();
		if trimmed and not trimmed.startswith("#"):
			line_parts = trimmed.split();
			# Check if line_parts has elements and if the FIRST element is a valid number string
			if line_parts and line_parts[0].isdigit():
				chr_num   = int(line_parts[0]);
				chr_use   = int(float(line_parts[1]));
				chr_label = line_parts[2];
				chr_name  = line_parts[3];

				chrNums.append(chr_num);
				chrLabels.append(chr_label);
				chrNames.append(chr_name);
				chrShorts.append(chr_label);
				chrName.append(chr_name);

				myfile.write(f"\t\t|\t\t{chr_num} : {chr_name} = {chr_label}\n");

chrCount = chrName_maxcount;
with open(logName, "a") as myfile:
	myfile.write(f"\t\t|\t\tMax chr string : {chrCount}\n");
	myfile.write("\t\t|\tProcessing datasetParent 'SNPdata_parent.txt' file => het loci.\n");

# High-speed map translation lookup to completely optimize away inner-loop iteration overhead
chr_name_to_num = {name: i + 1 for i, name in enumerate(chrName) if chrNums[i] != 0};

count            = 0;
old_chr          = 0;
fragment_found   = 0;
current_fragment = 0;
log_count        = 0;
log_offset       = 0;

print(f"### Number of Chromosomes = {chrCount}");
for x in range(chrCount):
	if chrNums[x] != 0:
		print(f"### \t{x+1} : {chrNames[x]}");
print(f"###{numFragments}");

with open(logName, "a") as myfile:
	myfile.write("\t\t|\tGathering read coverage data for each fragment.\n");
	myfile.write(f"\t\t|\tparent data file = '{parentDatafile}'\n");
	myfile.write(f"\t\t|\tchild data file  = '{childDatafile}'");

print(f"### parentDatafile = {parentDatafile}");


# Open matching read dataset streams
searchTarget     = open(childDatafile, 'r');
childLine        = '';
empty_line_count = 0;

with open(parentDatafile, 'r') as data:
	for line in data:
		#===============================================================================================================
		# Process the line from the parent 'SNPdata_parent.txt' line, describing one heterozgyous locus.
		#---------------------------------------------------------------------------------------------------------------
		# example lines from file:
		# if (runMode == 'LOH'):
		#       chromosome                   coord   allele1   allele2
		#       Ca21chr1_C_albicans_SC5314   3706    T         C
		# if (runMode == 'hapmap'):
		#       chromosome                   coord   allele1   allele2   phasingData  [phasingData]
		#       Ca21chr1_C_albicans_SC5314   3706    T         C         1            [11]

		if line.startswith("#") or not line.strip():
			continue;

		count += 1;
		parentLine = line.strip().split('\t');
		P_chr_name = parentLine[0];
		P_position = int(parentLine[1]);
		P_allele1 = parentLine[2];
		P_allele2 = parentLine[3];

		# Strip out non-useful phase labels (10, 11, 12).
		phasingData_1 = parentLine[4:];
		phasingData = [int(x) for x in phasingData_1 if int(x) not in (10, 11, 12)];

		if len(phasingData) == 0:
			phaseCall = 10;
		else:
			phaseCall = int(round(sum(phasingData) / float(len(phasingData))));

		# Retrieve integer chromosome ID instantly.
		P_chr = chr_name_to_num.get(P_chr_name, 0);

		# Find standard bin containing parent SNP locus.
		if P_chr != 0:
			if old_chr != P_chr:
				if log_offset != 0:
					log_offset_string = " " * (log_offset % 100);
					with open(logName, "a") as myfile:
						myfile.write(f"\n\t\t|\t\t{log_offset_string}");
				count = 1;
				fragment_found = 0;
				current_fragment = 0;

			if fragment_found == 0:
				for frag in range(current_fragment, numFragments):
					# Standardized 0-indexed fragment structural checks.
					if P_chr == fragments[frag] and P_position >= fragments[frag] and P_position <= fragments[frag]:
						fragment_found = 1;
						current_fragment = frag;
						break;

			if fragment_found == 1:
				if count % 50000 == 0:
					log_count += 1;
					log_offset += 1;
					with open(logName, "a") as myfile:
						if log_count % 100 == 0:
							if log_count - 1 == 0:
								myfile.write("\n\t\t|\t");
							else:
								myfile.write(f" {log_count - 1}\n\t\t|\t");
						myfile.write(".");

				if P_position >= fragments[current_fragment]:
					fragment_found = 0;

			#===============================================================================================================
			# Find line in child dataset corresponding to SNP from hapmap dataset 'SNPdata_parent.txt' file.
			#---------------------------------------------------------------------------------------------------------------
			if not childLine:
				childLine = searchTarget.readline();
				if not childLine:
					empty_line_count += 1;

			if empty_line_count < 2:
				childLine_parts = childLine.strip().split('\t');
				C_chr_name = childLine_parts[0];
				C_position = int(childLine_parts[1]);
				C_chr = chr_name_to_num.get(C_chr_name, 0);

				# Skip mismatched child chromosomes ahead
				while P_chr > C_chr:
					childLine = searchTarget.readline();
					if not childLine:
						C_chr = P_chr;
						break;
					childLine_parts = childLine.strip().split('\t');
					C_chr_name = childLine_parts[0];
					C_position = int(childLine_parts[1]);
					C_chr = chr_name_to_num.get(C_chr_name, 0);

				# Advance through the child rows until matching position coordinate is met
				while P_chr == C_chr and P_position > C_position:
					childLine = searchTarget.readline();
					if not childLine:
						break;
					childLine_parts = childLine.strip().split('\t');
					C_chr_name = childLine_parts[0];
					C_position = int(childLine_parts[1]);
					C_chr = chr_name_to_num.get(C_chr_name, 0);

				if P_chr > C_chr or (P_chr == C_chr and P_position > C_position) or (P_chr == C_chr and P_position < C_position):
					result = "";
				elif P_chr == C_chr and P_position == C_position:
					result = childLine;

				C_ratio = 0.0;
				if result == "":
					C_ratio = 0.0;
					C_valid = 0;
				else:
					C_chr_name = childLine_parts[0];
					C_position = childLine_parts[1];
					C_countTot = childLine_parts[2];
					C_refBase  = childLine_parts[3];

					C_countA   = int(float(childLine_parts[4]));
					C_countT   = int(float(childLine_parts[5]));
					C_countG   = int(float(childLine_parts[6]));
					C_countC   = int(float(childLine_parts[7]));

					C_counts   = [C_countA, C_countT, C_countG, C_countC];
					total_sum  = sum(C_counts);

					alleleData    = [(C_countA, 'A'), (C_countT, 'T'), (C_countG, 'G'), (C_countC, 'C')];
					sortedAlleles = sorted(alleleData, key=lambda x: x);
					C_maxCount    = sortedAlleles[3][0];
					C_maxAllele   = sortedAlleles[3][1];

					if total_sum == 0:
						C_ratio = 0.0;
						C_valid = 0;
					else:
						C_ratio = float(C_maxCount) / float(total_sum);

						if phaseCall == 1:
							P_allele1, P_allele2 = P_allele2, P_allele1;
							if C_maxAllele == P_allele1:
								C_ratio = 1.0 - C_ratio;
						elif phaseCall == 0:
							if C_maxAllele == P_allele1:
								C_ratio = 1.0 - C_ratio;
						else:
							C_maxAllele = 'Z';

						C_valid = 1;
						allele_string = f"{C_maxAllele}:{P_allele1}/{P_allele2}";

				C_chr = chr_name_to_num.get(P_chr_name, 0)

				#===============================================================================================================
				# Add allelic ratio data to standard-bin fragment data
				#---------------------------------------------------------------------------------------------------------------
				if fragment_found == 1 and C_valid == 1:
					if phaseCall in (0, 1):
						fragments[current_fragment] += f"{C_ratio},";
						fragments[current_fragment] += f"{C_position},";
						fragments[current_fragment] += f"{allele_string},";
					else:
						fragments[current_fragment][4] += f"{C_ratio},";
						fragments[current_fragment][6] += f"{C_position},";
						fragments[current_fragment][8] += f"{allele_string},";

				#===============================================================================================================
				# Output log file status updates and save coordinate anchors
				#---------------------------------------------------------------------------------------------------------------
				if old_chr != P_chr:
					print(f"### chr change : {old_chr} -> {P_chr}")
					with open(logName, "a") as myfile:
						myfile.write(f"\n\t\t|\t    {old_chr} -> {P_chr} = {P_chr_name}\n")
						myfile.write("\t\t|\t1........01........01........01........01........01........01........01........01........01........0")

					if log_offset != 0:
						log_offset_string = " " * (log_offset % 100)
						with open(logName, "a") as myfile:
							myfile.write(f"\n\t\t|\t{log_offset_string}")

				old_chr = P_chr
				last_fragment = current_fragment

				# Check boundaries safely using column index 2 (bp_end) 
				if P_position == fragments[current_fragment][2]:
					fragment_found = 0

searchTarget.close()

print(f"### {time.process_time() - t1:.4f} seconds to parse project SNP data.")
t2 = time.process_time()
print(f"### Number of fragments = {numFragments}")
print("### Data from each fragment: [chrNum, bpStart, bpEnd, Max, Ave, Length]")


#============================================================================================================
# Code section to output data per standard-bin fragment.
#------------------------------------------------------------------------------------------------------------
with open(logName, "a") as myfile:
	myfile.write("\n\t\t|\tOutputting LOH status counts of standard-bin fragmented genome.\n");

# Print the dynamic tab-delimited file headers
print('# chr_num\tbp_start\tbp_end\tphasedData\tunphasedData\tphasedCoordinate\tunphasedCoordinate\tphasedAllele\tunphasedAllele')

# Clean iteration through every element row in your matrix to avoid off-by-one missing end rows
for frag in fragments:
	# Output a line for each fragment.
	#     fragments[fragment-1] = [chr_num,bp_start,bp_end,phasedData,unphasedData]
	#     0) chr_num
	#     1) bp_start
	#     2) bp_end
	#     3) phasedData list
	#     4) unphasedData list

	# 0) chr_num, 1) bp_start, 2) bp_end
	chrNum_string  = str(frag[0]);
	bpStart_string = str(frag[1]);
	bpEnd_string   = str(frag[2]);

	# Strip trailing commas safely and append closing parenthesis
	phasedData_string   = frag[3].rstrip(',') + ")";
	unphasedData_string = frag[4].rstrip(',') + ")";

	phasedCoordinate_string   = frag[5].rstrip(',') + ")";
	unphasedCoordinate_string = frag[6].rstrip(',') + ")";

	phasedAllele_string   = frag[7].rstrip(',') + ")";
	unphasedAllele_string = frag[8].rstrip(',') + ")";

	# Print the finalized tab-delimited record row string
	print(
		f"{chrNum_string}\t{bpStart_string}\t{bpEnd_string}\t"
		f"{phasedData_string}\t{unphasedData_string}\t"
		f"{phasedCoordinate_string}\t{unphasedCoordinate_string}\t"
		f"{phasedAllele_string}\t{unphasedAllele_string}"
	);
#------------------------------------------------------------------------------------------------------------
# End of code section to output information about fragments.
#============================================================================================================

print("### ", time.process_time() - t1, "seconds to output basic stats of each fragment.");
print("### ", time.process_time() - t0, "seconds to complete processing of fragment definitions.");

with open(logName, "a") as myfile:
	myfile.write("\t\t|\tTime to process = " + str(time.process_time()-t0) +"\n");
	myfile.write("\t\t*-----------------------------------------------------------------------------------------*\n");
	myfile.write("\t\t| 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py' completed. |\n");
	myfile.write("\t\t*=========================================================================================*\n");
