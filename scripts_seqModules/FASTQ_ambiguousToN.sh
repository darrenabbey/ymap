#!/bin/bash
set -e

# If no data file option is given, describe script purpose and input.
if [[ -z $1 ]] || [[ -z $2 ]]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTQ_ambiguousToN.sh [dataset] [outfile]'";
	echo -e "# ";
	echo -e "#        [dataset] : FASTQ read file input.";
	echo -e "#        [outfile] : Destination file for FASTQ entries.";
	echo -e "# ";
	echo -e "# This script converts non-ATCG characters in sequence lines to N.";
	echo -e "# ";
	echo;
	exit 1;
else
	## FASTQ format per line, repeating.
	# echo -e "@ id";
	# echo -e "sequence"
	# echo -e "+ id"
	# echo -e "quality"

	# number of lines of each file.
	length_full1=$(wc -l $1 | awk '{print $1}');

	# initialize and clear output file.
	echo -e "null" >> $2;
	cp /dev/null $2;

	# open extra file descriptor for input.
	exec 4< $1;

	# read lines from input files, then append to output file in blocks of four lines.
	while read line1_1 <&4;
	do
		read line1_2 <&4;
		read line1_3 <&4;
		read line1_4 <&4;

		# ambiguity characters : KMRYSWBVHDX.
		line1_2=`echo $line1_2 | sed 's/\K/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\M/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\R/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\Y/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\S/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\W/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\B/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\V/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\H/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\D/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\X/N/g'`;
		line1_2=`echo $line1_2 | sed 's/\./N/g'`;

		echo $line1_1 >> $2;
		echo $line1_2 >> $2;
		echo $line1_3 >> $2;
		echo $line1_4 >> $2;
	done

	# close the extra file descriptors.
	exec 4<&-;
fi
