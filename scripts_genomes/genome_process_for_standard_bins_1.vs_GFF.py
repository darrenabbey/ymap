# Input arguments:
#	1) user            : Name of user account installing the genome file.
#	2) genome          : Name of installed genome.
#	3) main_dir        : Root directory.
#	4) GFF_annotations : Path and file name of GFF file.
#	5) logfile         : Path and file name of log file.
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
GFF_annotations = sys.argv[4];
logName         = sys.argv[5];


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
# Parse GFF annotations to extract and merge overlapping gene coordinates.
#------------------------------------------------------------------------------------------------------------
raw_gene_intervals = {};

with open(logName, "a") as myfile:
	myfile.write("\n\t\t\t#### Parsing GFF file for gene intervals.");

if os.path.isfile(GFF_annotations):
	with open(GFF_annotations, 'r') as gff_file:
		for line in gff_file:
			trimmed = line.strip();
			if not trimmed or trimmed.startswith('#'):
				continue;

			columns = trimmed.split('\t');
			if len(columns) == 9 and columns[2] == 'gene':
				gff_chr = columns[0];
				try:
					gff_start = int(columns[3]);
					gff_end = int(columns[4]);

					if gff_chr not in raw_gene_intervals:
						raw_gene_intervals[gff_chr] = [];
					raw_gene_intervals[gff_chr].append([gff_start, gff_end]);
				except ValueError:
					continue;

	# --- Merge Overlapping Gene Intervals ---
	gene_intervals = {};
	overlap_count = 0;

	for gff_chr, intervals in raw_gene_intervals.items():
		# Sort strictly by start coordinate.
		intervals.sort(key=lambda x: x[0]);

		merged = [];
		for interval in intervals:
			# If the list of merged intervals is empty or the current interval does not overlap with the previous one, append it.
			if not merged or merged[-1][1] < interval[0]:
				merged.append(interval);
			else:
				# There is an overlap! Merge by updating the end coordinate to the maximum.
				overlap_count += 1;
				merged[-1][1] = max(merged[-1][1], interval[1]);

		gene_intervals[gff_chr] = merged;

	with open(logName, "a") as myfile:
		myfile.write(f"\n\t\t\t#### Found and resolved {overlap_count} overlapping gene annotations across all chromosomes.");
else:
	with open(logName, "a") as myfile:
		myfile.write(f"\n\t\t\t#### WARNING: GFF file not found at {GFF_annotations}!");


#============================================================================================================
# Digest chromosome sequences using GFF feature intervals.
#------------------------------------------------------------------------------------------------------------
chr_num = 0;
old_chr_name = '';

with open(FASTA_file, 'r') as FASTA_data:
	while True:
		line1 = FASTA_data.readline();
		line2 = FASTA_data.readline();
		if not line2:
			break;  # EOF

		if line1.startswith(">"):
			chr_num += 1;
			chr_name = line1.strip().split()[0].replace(">", "");

			if chr_name != old_chr_name:
				elapsed_time = time.process_time() - t1;
				with open(logName, "a") as myfile:
					myfile.write(f"\t\t\t####\t{elapsed_time:.4f} seconds for this chr.\n");
					if chr_name in chrName:
						myfile.write(f"\t\t\t#### Fragmenting via merged GFF annotations: {chr_name}\n");
					else:
						myfile.write(f"\t\t\t#### Not fragmenting: {chr_name}\n");
				t1 = time.process_time();
				old_chr_name = chr_name;

			if chr_name not in chrName:
				continue;

			clean_sequence = line2.strip();
			seq_len = len(clean_sequence);

			# Retrieve consolidated gene boundaries for this chromosome.
			chrom_genes = gene_intervals.get(chr_name, []);

			bins = [];
			current_pos = 1;

			for g_start, g_end in chrom_genes:
				# If there's space before the gene region, create an intergenic bin.
				if g_start > current_pos:
					bins.append((current_pos, g_start - 1, "intergenic"));

				# Create the gene bin (bounded safely by chromosome length).
				bins.append((g_start, min(g_end, seq_len), "gene"));
				current_pos = g_end + 1;

				if current_pos > seq_len:
					break;

			# If there's remaining sequence after the final gene region, make a final intergenic bin.
			if current_pos <= seq_len:
				bins.append((current_pos, seq_len, "intergenic"));

			# Slice sequence based on calculated annotation bins.
			for b_start, b_end, b_type in bins:
				start_idx = b_start - 1;
				end_idx = b_end;

				fragment_string = clean_sequence[start_idx:end_idx];
				fragment_length = b_end - b_start + 1;

				if fragment_length > 0:
					print(f">{genomeName}.chr{chr_num} ({b_start}..{b_end}) ({fragment_length}bp) [{b_type}]");
					print(fragment_string);

