# Input arguments:
#	2) FASTAinput   : Path & name of FASTA file to be processed.
#	4) logfile      : Path and file name of output log file.
#
import string, sys, os;
FASTAreference  = sys.argv[1];
kmer_length     = int(sys.argv[2]);
dest_dir        = sys.argv[3];

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

#------------------------------------------------------------------------------------------------------------
# Output dictionary to temp file, then reset dictionary.
def flush_dictionary():
	global file_cycle;
	global kmer_dictionary;
	global kmer_length;
	# output dictionary to file.
	with open('dictionaryCirc_'+str(kmer_length)+'mer__'+str(file_cycle)+'.txt', 'w') as f:
		[f.write('{0},{1}\n'.format(key, value)) for key, value in kmer_dictionary.items()];
	# reset dictionary.
	kmer_dictionary.clear();
	# increment counter.
	file_cycle      += 1;


##
##------------
##========================
## Generate kmer dictionary from reference FASTA file.
##========================
##------------
##


#============================================================================================================
# Reformat input FASTA to single-line entries.
#------------------------------------------------------------------------------------------------------------
#sys.stdout.write(FASTAreference);
#sys.stdout.write("\n");

callingDir = os.getcwd();
baseDir    = os.path.dirname(__file__);
os.system("cp "+FASTAreference+" reference_copy.fasta");
os.system("sh "+baseDir+"/../FASTA_reformat_1.sh reference_copy.fasta > reference_copy2.fasta");
os.system("mv reference_copy2.fasta reference_copy.fasta");

#============================================================================================================
# Initialize kmer_dictionary vector of length 4^kmer_length with zeros.
#------------------------------------------------------------------------------------------------------------
kmer_length_original = kmer_length;

# Initialize kmer count data structure.
kmer_dictionary      = {};

#============================================================================================================
# Process used chromosomes into k-mer counts array.
#------------------------------------------------------------------------------------------------------------
# Open reformatted FASTAreference file.
FASTA_reference = open("reference_copy.fasta",'r');

# Process reformatted FASTA file, entry by entry, to collect kmer counts.
while True:
	# FASTA entries are pairs of lines with the following structure.
	#    >Ca_a.chr1 (9638..10115) (478bp) [*]
	#    ATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGCATGC
	line1 = FASTA_reference.readline();
	line2 = FASTA_reference.readline();
	line2 = line2.strip();
	if not line2:
		break  # EOF, so exit file processing block.

	# Append last (kmer-1) bp of sequence(line2) to beginning of sequence; to make kmer dictionary of circular sequence.
	wraparound1 = line2[0:(kmer_length-1)];
	wraparound2 = line2[(len(line2)-(kmer_length-1)):];
	print(len(line2));
	print("Start: "+wraparound1);
	print("End:   "+wraparound2);
	line2 = wraparound2+line2;
	print(len(line2));

	first_char = line1[:1];
	if first_char == ">":
		# First line is header to FASTA entry, so file contents are formatted properly.
		# Determine chromosome/contig name by isolating the first space-delimited string, then removing the header character ">".
		sys.stdout.write(line1);
		chr_name = line1.strip().split('_');
		chr_name   = chr_name[0].replace(">","");

		# Run along chromosome coordinates, from start(0) to end (len(line2)-kmer_length_original+1), such that a kmer can be examined starting at each coordinate.
		# For each coordinate, add to k-mer count dictionary ("kmer_dictionary").
		for index in range(0, len(line2)-kmer_length_original+1):
			## current kmer string.
			test_string      = line2[index:(index+kmer_length_original)];
			test_string_RC   = rev_com(test_string);
			## determine kmer_counts vector position for the test_string and its reverse complement.
			if (test_kmer(test_string) == False):
				## Only make a dictionary entry for one of [seq, seq_RC] to reduce dictionary expansion.
				if test_string in kmer_dictionary:
					kmer_dictionary[test_string]          += 1;
				elif test_string_RC in kmer_dictionary:
					kmer_dictionary[test_string_RC]       += 1;
				else:
					# Make a new dictionary entry with alphabetically first of [seq, seq_RC] to avoid both versions being built into dictionary fragments.
					seq_strings = [test_string, test_string_RC];
					seq_strings.sort();
					kmer_dictionary[seq_strings[0]] = 1;
				## If dictionary is larger than [value], flush the contents to a file, reset it, and continue.
				if (sys.getsizeof(kmer_dictionary) > dictionary_max_mem):
					flush_dictionary();

# A final flush of the dictionary to make sure everything is recorded.
flush_dictionary();

# Close reformatted FASTA file.
FASTA_reference.close();

# Collect dictionary fragment files.
os.system("cat dictionaryCirc_"+str(kmer_length)+"mer__* > dictionaryCirc_"+str(kmer_length)+"mer.txt");

# Delete fragment files.
os.system("rm dictionaryCirc_"+str(kmer_length)+"mer__*");

# Sort collected dictionary file.
os.system("sort dictionaryCirc_"+str(kmer_length)+"mer.txt > sort_temp.txt");
os.system("mv sort_temp.txt dictionaryCirc_"+str(kmer_length)+"mer.txt");

quit();

# Merge multiple identical entries in dictionary file.
# Writing out batches of 500 lines instead of one at a time results in significant time savings. No additional time savings is apparent when writing out in batches of 50,000 lines.
DICTIONARY_data = open("dictionaryCirc_"+str(kmer_length)+"mer.txt",'r');
previous_line        = '# kmer_sequence, count\n';
output_batch_counter = 0;
output_batch         = '';
for current_line in DICTIONARY_data:
	previous_entry = previous_line.split(',');
	current_entry  = current_line.split(',');
	if (current_entry[0] == previous_entry[0]):
		# Define new previous_line with count of previous and current added. Do not output a line here!
		previous_line = previous_entry[0]+","+str(int(current_entry[1])+int(previous_entry[1]))+"\n";
	else:
		output_batch         += previous_line;
		output_batch_counter += 1;
		if (output_batch_counter == 500):
			with open("dictMerge_temp.txt", "a") as myfile:
				myfile.write(output_batch);
			output_batch_counter = 0;
			output_batch         = '';
		# Define new previous_line as current_line.
		previous_line = current_line;
if not (current_entry[0] == previous_entry[0]):
	output_batch         += previous_line;
with open("dictMerge_temp.txt", "a") as myfile:
	myfile.write(output_batch);
DICTIONARY_data.close();

# Clean up by removing intermediate dictionary version and moving final version to subdirectory.
os.system("mv dictMerge_temp.txt "+dest_dir+"/dictionaryCirc_"+str(kmer_length)+"mer.txt");
