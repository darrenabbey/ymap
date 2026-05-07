#!/bin/bash
set -e

# If no data file option is given, describe script purpose and input.
if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTQ_filterLongReads.sh [dataset] [cutoff] [outfile]'";
	echo -e "# ";
	echo -e "#        [dataset] : FASTQ read file input.";
	echo -e "#        [cutoff]  : Reads longer than this are discarded.";
	echo -e "#        [outfile] : Destination file for FASTQ entries.";
	echo -e "# ";
	echo -e "# This script expects the input FASTQ to be well-formatted.";
	echo -e "# ";
	echo;
	exit 1;
else
	## FASTQ format per line, repeating.
	# echo -e "@ id";
	# echo -e "sequence"
	# echo -e "+ id"
	# echo -e "quality"

	filterCutoff=$2;

	# number of lines of each file.
	length_full1=$(wc -l $1 | awk '{print $1}');

	# initialize and clear output file.
	echo -e "null" >> $3;
	cp /dev/null $3;

	# open extra file descriptor for input.
	exec 4< $1;

	# read lines from input files, then append to output file in blocks of four lines.
	while read line1_1 <&4;
	do
		read line1_2 <&4;
		read line1_3 <&4;
		read line1_4 <&4;

		lengthOfRead=${#line1_2};

		if [[ $lengthOfRead -le $filterCutoff ]]
		then
			echo $line1_1 >> $3;
			echo $line1_2 >> $3;
			echo $line1_3 >> $3;
			echo $line1_4 >> $3;
		fi
	done

	# close the extra file descriptors.
	exec 4<&-;
fi
