# Input arguments:
#	1) user            : Name of user account installing the genome file.
#	2) genome          : Name of installed genome.
#	3) main_dir        : Root directory.
#	4) logfile         : Path and file name of log file.
#
# Processing:
#	1) Load genome FASTA.
#	2) Output standard-bin fragmented genome FASTA.
#
import string, sys, re, time, os;
from pathlib import Path;
userName        = sys.argv[1];
genomeName      = sys.argv[2];
main_dir        = sys.argv[3];
logName         = sys.argv[4];


# Initialize time counter and log file section.
t0 = time.process_time();
with open(logName, "a") as myfile:
	myfile.write("\t\t\t*================================================================*\n")
	myfile.write("\t\t\t| Log of 'genome_process_for_standard_bins_1.py'                 |\n")
	myfile.write("\t\t\t*----------------------------------------------------------------*\n")


#============================================================================================================
# Determine name of reformatted reference FASTA file.
#------------------------------------------------------------------------------------------------------------
# Find name of genome FASTA file for species being examined.
#     Read in and parse : "Ymap_root/users/[userName]/genomes/[genomeName]/[genome]/reference.txt"
workingDir     = os.path.join(main_dir, 'users', userName, 'genomes', genomeName, '');
reference_file = os.path.join(workingDir, 'reference.txt');

with open(reference_file, 'r') as refFile:
	refFASTA = refFile.read().strip();

# Generate the name of the reformatted FASTA file: "test.fasta" => "test.2.fasta"
refFASTA       = refFASTA.replace(".fasta",".2.fasta");
with open(logName, "a") as myfile:
	myfile.write("\n\t\t\tFASTA reformatted to single-line entries : " + refFASTA);


#============================================================================================================
# Determine which chromosomes from reference FASTA are being examined.
#------------------------------------------------------------------------------------------------------------
# Look up chromosome name strings for genome in use.
#     Read in and parse : "Ymap_root/users/[userName]/genomes/[genomeName]/figure_definitions.txt"
figureDefinition_file  = workingDir + '/figure_definitions.txt';
with open(figureDefinition_file, 'r') as figureDefinitionFile:
	figureDefinitionData = figureDefinitionFile.readlines();

#       Example lines in figureDefinition_file:
#               Chr  Use   Label   Name                         posX   posY   width   height
#               1    1     Chr1    Ca21chr1_C_albicans_SC5314   0.15   0.8    0.8     0.0625
#               2    1     Chr2    Ca21chr2_C_albicans_SC5314   0.15   0.7    *       0.0625
#               0    0     Mito    Ca19-mtDNA                   0.0    0.0    0.0     0.0

with open(logName, "a") as myfile:
	myfile.write("\n\t\t\t\tDetermining number of chromosomes of interest in genome.");

# Process lines in a single pass to map chromosome data
valid_chromosomes = {};
chrName_maxcount = 0;

for line in figureDefinitionData:
	trimmed = line.strip();
	if trimmed and not trimmed.startswith("#"):
		line_parts = trimmed.split();
		chr_num_str = line_parts[0];

		if chr_num_str.isdigit():
			chr_num   = int(chr_num_str);
			chr_use   = int(float(line_parts[1]));
			chr_label = line_parts[2];
			chr_name  = line_parts[3];

			if chr_num > chrName_maxcount:
				chrName_maxcount = chr_num;

			if chr_num != 0:
				valid_chromosomes[chr_num] = chr_name;


# Pre-allocate and populate the chrName list in order
chrName = [""] * chrName_maxcount;
with open(logName, "a") as myfile:
	myfile.write("\n\t\t\t\tGathering name strings for chromosomes.");
	for chr_num in sorted(valid_chromosomes.keys()):
		chr_name = valid_chromosomes[chr_num];
		chrName[chr_num - 1] = chr_name;
		myfile.write(f"\n\t\t\t\t\tChr{chr_num} = {chr_name}");

chrCount = chrName_maxcount;


#============================================================================================================
# Determine chromosome sizes and standard bin size.
#------------------------------------------------------------------------------------------------------------
FASTA_file = os.path.join(workingDir, refFASTA);

with open(logName, "a") as myfile:
	myfile.write("\n\t\t\t#### Determine chromosome lengths.");

chr_lengths = [];
with open(FASTA_file, 'r') as FASTA_data:
	while True:
		line1 = FASTA_data.readline();
		line2 = FASTA_data.readline();
		if not line2:
			break;  # EOF

		if line1.startswith(">"):
			# Isolating the first space-delimited string, removing the header character ">"
			chr_name = line1.strip().split()[0].replace(">", "");

			# If the current chromosome is one of those in use...
			if chr_name in chrName:
				# .strip() handles the trailing newline so length calculations are perfectly precise
				chr_lengths.append(len(line2.strip()));

with open(logName, "a") as myfile:
	myfile.write(f"\n\t\t\t####     max_chr_length         = {max(chr_lengths)} bp");

# Calculate standard bin size
resolution_file = os.path.join(workingDir, "resolution.CNV.txt");
if os.path.isfile(resolution_file):
	txt = Path(resolution_file).read_text().strip();
	bases_per_bin = int(round(max(chr_lengths) / int(txt)));
else:
	bases_per_bin = int(round(max(chr_lengths) / 700));

with open(logName, "a") as myfile:
	myfile.write(f"\n\t\t\t####     bases_per_standard_bin = {bases_per_bin} bp");

# Reset timer
t0a = time.process_time();
t1  = t0a;
with open(logName, "a") as myfile:
	myfile.write("\n\t\t\t#### Start genome fragmentation.\n");


#============================================================================================================
# Digest chromosome sequences and output new FASTA file entries.
#------------------------------------------------------------------------------------------------------------
chr_num = 0;
old_chr_name = '';

# Process reformatted FASTA file, entry by entry, to digest into fragments.
with open(FASTA_file, 'r') as FASTA_data:
	while True:
		line1 = FASTA_data.readline()
		line2 = FASTA_data.readline()
		if not line2:
			break  # EOF

		if line1.startswith(">"):
			chr_num += 1

			# Determine chromosome name by isolating the first space-delimited string, removing ">"
			chr_name = line1.strip().split()[0].replace(">", "")

			# Log boundaries if the current chromosome is different than the last one seen
			if chr_name != old_chr_name:
				elapsed_time = time.process_time() - t1
				with open(logName, "a") as myfile:
					myfile.write(f"\t\t\t####\t{elapsed_time:.4f} seconds for this chr.\n")
					if chr_name in chrName:
						myfile.write(f"\t\t\t#### Fragmenting: {chr_name}\n")
					else:
						myfile.write(f"\t\t\t#### Not fragmenting: {chr_name}\n")
				t1 = time.process_time()
				old_chr_name = chr_name  # Update marker tracker

			# If the current chromosome is one of those in use...
			if chr_name in chrName:
				# Strip trailing newline characters to ensure base-count math accuracy
				clean_sequence = line2.strip()
				seq_len = len(clean_sequence)

				fragment_start = 1
				fragment_end = bases_per_bin

				while fragment_start <= seq_len:
					# Resolve safe bounding range limit
					current_end = min(fragment_end, seq_len)

					# Convert to standard 0-indexed Python string slicing
					start_idx = fragment_start - 1
					end_idx = current_end

					fragment_string = clean_sequence[start_idx:end_idx]
					fragment_length = current_end - fragment_start + 1

					# Print the newly generated bin partition details
					print(f">{genomeName}.chr{chr_num} ({fragment_start}..{current_end}) ({fragment_length}bp) [*]")
					print(fragment_string)

					fragment_start += bases_per_bin
					fragment_end += bases_per_bin

