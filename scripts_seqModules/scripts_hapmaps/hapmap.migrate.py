###
### migrate phasing from SNPdata_hapmap.txt to SNPdata_derived.txt
###	$python_exec $main_dir"scripts_seqModules/scripts_hapmaps/hapmap.migrate.py" $user $hapmap $main_dir
###

import string, sys, time;

user        = sys.argv[1];
hapmap      = sys.argv[2];
main_dir    = sys.argv[3];

##============================================================
def generate_lines_that_equal(string, fp):
	for line in fp:
		line2 = line.rstrip();
		if line2 == string:
			return line;
##============================================================


logName     = main_dir+"users/"+user+"/hapmaps/"+hapmap+"/process_log.txt";
inputFile1  = main_dir+"users/"+user+"/hapmaps/"+hapmap+"/SNPdata_hapmap.txt";
inputFile2  = main_dir+"users/"+user+"/hapmaps/"+hapmap+"/SNPdata_derived.temp.txt";
with open(logName, "a") as myfile:
	myfile.write("\t\t*==============================================================================*\n");
	myfile.write("\t\t| Log of 'scripts_seqModules/scripts_hapmaps/hapmap.migrate.py'                |\n");
	myfile.write("\t\t*------------------------------------------------------------------------------*\n");
	myfile.write("\t\t|\t\n");

t0 = time.process_time();

data = open(inputFile2,"r"); # derived file.
for line in data:
	dataLine = line.rstrip();
	# Trim dataLine by getting rid of last three columns, only one character per field.
	# Without this only the half of entries with the same allele order as in parent hapmap will be captured.
	dataLine_ = dataLine[:-3];

	firstChar = dataLine[0];
	if firstChar == '#':
		# print comment/header line to stdout.
		print(dataLine);
	else:
		# process data line vs hapmap file.
		with open(inputFile1, "r") as fp:
			for l_no, line2 in enumerate(fp):
				# search string
				if dataLine_ in line2:
					# print("### "+dataLine);
					print(line2, end="");
					break;
