# Input arguments: (Those with '[*]' at end are used here.)
#     2)  genome      : [String]: defines genome in use for project.             (ex. 'Ca_a') [*]
#     3)  workingDir  : [String]: Directory where links in system are stored.    (ex. '/home/bermanj/shared/links/) [*]
#
# Process input files:
#	1) fragmented genome file.
#		*) Load usable fragment definitions into array : fragments[i][chr#,bpStart,bpEnd, data_count,data_max,data_ave]
#                                                                            [0   ,1      ,2    , 3         ,4       ,5       ]
#	2) Read counts for strain of interest dataset.
#		-) Find max read count on fragment.
#		-) Find average read count along fragment.
#
# Generate output file:
#	3) Output values for each fragment in a tab-delimited text file.
#		Each line contains information for one fragment = [chr_num,bp_start,bp_end, data_count,data_max,length]
#		0) chr_num  : Numerical chromosome identifier, defined for each genome in "figure_details.txt".
#		1) bp_start : Start bp coordinate along chromosome.
#		2) bp_end   : End bp coordinate along chromosome.
#		3) GC_ratio : Ratio of bases as 'G' or 'C' in fragment.
#	4) Comment lines in output begin with '###'.
#

import sys, os, time;
userName    = sys.argv[1];
genomeName  = sys.argv[2];
main_dir    = sys.argv[3];
logName     = sys.argv[4];

t0 = time.process_time();
with open(logName, "a") as myfile:
	myfile.write("\t\t*================================================================*\n");
	myfile.write("\t\t| Log of 'genome_process_for_standard_bins.GC_bias_1.py'         |\n");
	myfile.write("\t\t*----------------------------------------------------------------*\n");


#============================================================================================================
# Process fragmented genome file.
#------------------------------------------------------------------------------------------------------------
# Example FASTQ header line.
#     >Ca_a.chr1 (9638..10115) (478bp) [*]
# FASTA entries with header lines ending in '[gene]' or '[intergenic]' are usable.
with open(logName, "a") as myfile:
	myfile.write("\n\t\tProcessing standard bin fragmented genome file.");

# Find name of genome FASTA file for species being examined.
#     Read in and parse : "links_dir/main_script_dir/genome_specific/[genome]/reference.txt"
workingDir     = os.path.join(main_dir, 'users', userName, 'genomes', genomeName, '');
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

					# Calculate precise GC ratio.
					clean_seq = trimmed_line.upper();
					g_count = clean_seq.count('G');
					c_count = clean_seq.count('C');
					t_count = clean_seq.count('T');
					a_count = clean_seq.count('A');

					total_bases = g_count + c_count + t_count + a_count;
					GC_ratio = (g_count + c_count) / float(total_bases) if total_bases > 0 else 0.0;

					fragments.append([chr_num, bp_start, bp_end, GC_ratio])
			# Reset header tracker to prepare for the next record
			current_header = None;

numFragments = len(fragments);
#------------------------------------------------------------------------------------------------------------
# End of code section to parse fragments from genome.
#============================================================================================================


print(f"### {time.process_time() - t0:.4f} seconds to parse fragments from genome.");
t1 = time.process_time();

print(f"### numFragments = {numFragments}");
print("### Data from each fragment: [chrNum, bpStart, bpEnd, GC_ratio]");


#============================================================================================================
# Code section to output information about genome fragments.
#------------------------------------------------------------------------------------------------------------
with open(logName, "a") as myfile:
	myfile.write("\n\t\tOutputting GC-ratios of standard-bin fragmented genome.");

# Loop cleanly through every parsed list element to prevent off-by-one missing end rows
for fragment in fragments:
	chr_num  = fragment[0];
	bp_start = fragment[1];
	bp_end   = fragment[2];
	GC_ratio = fragment[3];

	print(f"{chr_num}\t{bp_start}\t{bp_end}\t{GC_ratio:.6f}");

#------------------------------------------------------------------------------------------------------------
# End of code section to output information about fragments.
#============================================================================================================

print(f"### {time.process_time() - t1:.4f} seconds to output basic stats of each fragment.");
print(f"### {time.process_time() - t0:.4f} total script process runtime execution time.");

with open(logName, "a") as myfile:
	myfile.write("\n\t\tTime to process = " + str(time.process_time()-t0) );
	myfile.write("\n\t\t* 'py/genome_process_for_standard_bins.GC_bias_1.py' completed. *");
