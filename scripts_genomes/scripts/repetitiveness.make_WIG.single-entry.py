# Input arguments:
#	1) repetitiveness dictionary = dictionary file previously generated.
#	2) reference                 = reference FASTA being processed.
#	3) kmer_length               = kmer length (23 usually)
#	4) tempdir                   = system tmp dir
#
import string, sys, os, csv;

dictionary	= sys.argv[1];
reference	= sys.argv[2];
kmer_length	= int(sys.argv[3]);
tempdir		= sys.argv[4];
out_file	= sys.argv[5];


#------------------------------------------------------------------------------------------------------------
# Variables used in building a complete kmer dictionary without it all being in memory at once.
dictionary_max_mem   = 800000000;   # byte size threshold for flushing dictionary fraction to file.
file_cycle           = 0;           # for tracking number of dictionary fraction files.

#------------------------------------------------------------------------------------------------------------
# Determines if the test sequence contains non-ATCG characters.
def test_kmer(seq):
	# tests if kmer sequence is only composed of valid DNA characters.
	# returns "False" if valid sequence, "True" if otherwise.
	err   = False;
	seq   = seq.upper();
	for index in range(len(seq)):
		if not ((seq[index] == 'A') or (seq[index] == 'T') or (seq[index] == 'C') or (seq[index] == 'G')):
			err = True;
	return err;

#------------------------------------------------------------------------------------------------------------
# Recursively reverse the input string.
def reverse(text):
	if len(text) <= 1:
		return text;
	return reverse(text[1:]) + text[0];

#------------------------------------------------------------------------------------------------------------
# Generate the reverse complement sequence of an input DNA sequence string.
def rev_com(seq):
	seq         = seq.upper();
	rev_seq     = reverse(seq);
	rev_com_seq = '';
	for index in range(len(seq)):
		if   rev_seq[index] == 'A':
			rev_com_seq += 'T';
		elif rev_seq[index] == 'T':
			rev_com_seq += 'A';
		elif rev_seq[index] == 'C':
			rev_com_seq += 'G';
		elif rev_seq[index] == 'G':
			rev_com_seq += 'C';
		else:
			rev_com_seq += 'n';
	return rev_com_seq;

##
##------------
##========================
## Reload kmer dictionary.
##========================
##------------
##

kmer_dictionary = {};

with open(dictionary, 'r') as f:
	#[f.write('{0},{1}\n'.format(key, value)) for key, value in kmer_dictionary.items()];
	for line in f:
		key   = line.split(',')[0];
		count = line.split(',')[1];
		kmer_dictionary[key] = count;




##
##------------
##========================
## Generate kmer counts from input FASTA file, using reference kmer dictionary.
##========================
##------------
##


#============================================================================================================
# Process used chromosomes into k-mer counts array.
#------------------------------------------------------------------------------------------------------------
# Open reformatted FASTAreference file.
FASTA_input = open(reference,'r');

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
		# First line is header to FASTA entry, so file contents are formatted properly.
		# Determine chromosome/contig name by isolating the first space-delimited string, then removing the header character ">".
		#sys.stdout.write("Processing: "+line1);
		chr_name = line1.strip().split(' ');
		chr_name = chr_name[0].replace(">","");
		chr_name = chr_name.replace("\n","");

		# Initialize output file for writing.
		# open file for writing, "w" is writing
		w = open(out_file, "w");
		w.write("fixedStep chrom=");
		w.write(chr_name);
		w.write(" start=1 step=1\n")
		w.close();


		# Initialize kmer count vector.
		input_length = len(line2);
		kmer_counts  = [0] * input_length;

		# Run along input sequence coordinates, from start(0) to end (len(line2)-kmer_length+1), such that a kmer can be examined starting at each coordinate.
		# For each coordinate, add to k-mer count dictionary ("kmer_dictionary").
		for index in range(0, len(line2)-kmer_length+1):
			## current kmer string.
			test_string      = line2[index:(index+kmer_length)];
			test_string_RC   = rev_com(test_string);
			## determine kmer_counts vector position for the test_string and its reverse complement.
			if (test_kmer(test_string) == False):
				#sys.stdout.write(test_string+"\n");
				if test_string in kmer_dictionary: # increment counter vector.
					for index2 in range(index, index+kmer_length):
						kmer_counts[index2] += int(kmer_dictionary[test_string]);
						#sys.stdout.write(str(index2)+" ");
					#sys.stdout.write("\n");
				elif test_string_RC in kmer_dictionary: # increment counter vector.
					for index2 in range(index, index+kmer_length):
						kmer_counts[index2] += int(kmer_dictionary[test_string_RC]);
		# Output kmer_counts tabulated for this FASTA entry.
		# open file for writing, "w" is writing
		w = csv.writer(open(out_file, "a"));

		# loop over dictionary keys and values
		for key, val in enumerate(kmer_counts):
			# write every value to file
			w.writerow([val]);

FASTA_input.close();
