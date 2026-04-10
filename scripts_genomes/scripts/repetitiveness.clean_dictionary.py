# Input arguments:
#	1) dictionaryFile : Path & name of dictionary file to be processed.
#
import string, sys, os;
dictionaryFile  = sys.argv[1];

# Merge multiple identical entries in dictionary file.
# Writing out batches of 500 lines instead of one at a time results in significant time savings. No additional time savings is apparent when writing out in batches of 50,000 lines.
DICTIONARY_data      = open(dictionaryFile,'r');
previous_line        = '';
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

# Add last kmer line into output.
output_batch         += previous_line;

# Write output to file.
with open("dictMerge_temp.txt", "a") as myfile:
	myfile.write(output_batch);
DICTIONARY_data.close();

# Clean up by removing intermediate dictionary version and moving final version to subdirectory.
os.system("mv dictMerge_temp.txt "+dictionaryFile);
