# Input arguments:
#	1) FASTAinput  = $tempdir/$base_name1
#	2) kmer_length = $2
#	3) dest_dir    = $tempdir
#	4) out_file    = "output.txt"
#
import string, sys, os, csv;
FASTAinput      = sys.argv[1];
kmer_length     = int(sys.argv[2]);
kmer_step       = int(sys.argv[3]);
dest_dir        = sys.argv[4];

if len(sys.argv) > 5:
	out_file = sys.argv[5];
else:
	out_file = "output.txt";


##
##------------
##========================
## Generate GCskew from input FASTA file.
##========================
##------------
##

#============================================================================================================
# Reformat input FASTA to single-line entry.
#------------------------------------------------------------------------------------------------------------
callingDir = os.getcwd();
baseDir    = os.path.dirname(__file__);
#os.system("cp "+FASTAinput+" "+dest_dir+"/input_copy.fasta");
#os.system("sh "+baseDir+"/../FASTA_reformat_1.sh "+dest_dir+"/input_copy.fasta > "+dest_dir+"/input_copy2.fasta");
#os.system("mv "+dest_dir+"/input_copy2.fasta "+dest_dir+"/input_copy.fasta");



#============================================================================================================
# Process used chromosomes into k-mer counts array.
#------------------------------------------------------------------------------------------------------------
# Open reformatted FASTAreference file.
FASTA_input = open(FASTAinput,'r');

# Process reformatted input FASTA file.
while True:
	# FASTA entries are pairs of lines with the following structure.
	#    >Ca_a.chr1 (9638..10115) (478bp) [*]
	#    ATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGC
	line1 = FASTA_input.readline();
	line2 = FASTA_input.readline();
	line2 = line2.strip();
	if not line2:
		break  # EOF, so exit file processing block.

	first_char = line1[:1];
	if first_char == ">":
		with open(out_file, "w") as f:
			f.write(line1);
		# First line is header to FASTA entry, so file contents are formatted properly.
		# Determine chromosome/contig name by isolating the first space-delimited string, then removing the header character ">".
		sys.stdout.write("Processing: "+line1+"\n");
		chr_name = line1.strip().split('_');
		chr_name   = chr_name[0].replace(">","");

		# Initialize GC skew vector.
		input_length = len(line2);
		bp_coord  = [0] * input_length;
		GC_skews  = [0] * input_length;
		alphas    = [0] * input_length;
		AT_skews  = [0] * input_length;
		GC_percs  = [0] * input_length;
		PP_skews  = [0] * input_length;

		# Run along input sequence coordinates, from start(0) to end (len(line2)-kmer_length+1), such that a kmer can be examined starting at each coordinate.
		# For each coordinate, calculate skew values and output to file.
		bp_index = 0;
		for index in range(0, len(line2)-kmer_length+1, kmer_step):
			## current kmer string.
			test_string = line2[index:(index+kmer_length)];
			## characterize kmer string.
			G_count     = test_string.count('G')+test_string.count('g');
			C_count     = test_string.count('C')+test_string.count('c');
			A_count     = test_string.count('A')+test_string.count('a');
			T_count     = test_string.count('T')+test_string.count('t');
			Pur_count   = A_count + G_count;
			Pyr_count   = T_count + C_count;
			## Calculate GC skew.
			if ((G_count + C_count) == 0):
				GC_skew = 0;
			else:
				GC_skew = (G_count - C_count)/(G_count + C_count);
			## Calculate alpha (https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7717575/).
			if ((G_count + C_count) == 0):
				alpha = 0;
			elif (G_count < C_count):
				alpha = -1;
			else:
				alpha = 1;
			## Calculate AT skew.
			if ((A_count + T_count) == 0):
				AT_skew = 0;
			else:
				AT_skew = (A_count - T_count)/(A_count + T_count);
			## Calcualte GC%.
			GC_perc = (G_count+C_count)/kmer_length;
			## Calculate purine-pyrimidine skew
			if ((Pur_count + Pyr_count) == 0):
				PP_skew = 0;
			else:
				PP_skew = (Pur_count - Pyr_count)/(Pur_count + Pyr_count);

			## determine GC_skew vector position for the test_string and its reverse complement.
			#for index2 in range(index, index+kmer_length):
			#	GC_skews[index2] += GC_skew;
			#GC_skews[index+int((kmer_length-1)/2)] = GC_skew;
			#alphas[  index+int((kmer_length-1)/2)] = alpha;
			#AT_skews[index+int((kmer_length-1)/2)] = AT_skew;
			#GC_percs[index+int((kmer_length-1)/2)] = GC_perc;
			#PP_skews[index+int((kmer_length-1)/2)] = PP_skew;

			bp_coord[bp_index] = index+int((kmer_length-1)/2);1
			GC_skews[bp_index] = GC_skew;
			alphas[  bp_index] = alpha;
			AT_skews[bp_index] = AT_skew;
			GC_percs[bp_index] = GC_perc;
			PP_skews[bp_index] = PP_skew;

			bp_index += 1;

		# Output GC_skew tabulated for this FASTA entry.
		# open file for writing, "w" is writing
		w = csv.writer(open(out_file, "a"));

		# Loop over accumulated data.
		for key in range(0,bp_index-1):
			# write every value to file1.
			#w.writerow([line2[key],GC_skews[key],alphas[key],AT_skews[key],GC_percs[key],PP_skews[key]]);
			# write [bp coordinate, skew value] pairs.
			w.writerow([bp_coord[key],GC_skews[key]]);

FASTA_input.close();
