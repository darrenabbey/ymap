#!/bin/bash
set -e

# If no data file option is given, describe script purpose and input.
if [[ -z $1 ]] || [[ -z $2 ]]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTQ_chop.sh [dataset] [length]'";
	echo -e "# ";
	echo -e "#        [dataset] : File containing FASTQ entries.";
	echo -e "#        [length]  : Number of lines at which to cut file in two.";
	echo -e "# ";
	echo -e "# This function is useful in trouble-shooting FASTQ file formatting issues.";
	echo -e "# ";
	echo;
	exit 1;
else
	length_full=$(wc -l $1 | awk '{print $1}');
	end_length=$((length_full-$2));
	head $1 -n $2 > ${1//.fastq/.1.fastq};
	tail $1 -n $end_length > ${1//.fastq/.2.fastq};
	rm $1;
fi
