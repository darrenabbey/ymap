#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTQ_rename_headers.sh [FASTQ seq file] > output.fastq'";
	echo -e "# ";
	echo -e "#        [FASTQ seq file] : DNA sequence data in FASTQ format.";
	echo -e "# ";
	echo -e "# This script will take a FASTQ file as input and replace headers with a simple incrementing value.";
	echo -e "# ";
	echo;
	exit 1;
else
# Absolute path this script is in.
BASEPATH=$(readlink -f "$0");
BASEDIR=$(dirname $BASEPATH);
#echo -e "Script found in: ${BASEDIR}"

# Absolute path the script is called from.
CALLDIR=${PWD}
#echo -e "Script executed from: ${CALLDIR}"

# Make temp dir.
tempdir=$(mktemp -d);
#========================

	# move input file to temp dir.
	cp $1 $tempdir;

	# simplify names.
	base_name1=$(basename $1);

	#echo -e ">default_read_name";
	#cat $tempdir/$base_name1 | head -n 2 | tail -n 1;

	# Call python script FASTQ_to_FASTA.py
	python3 $BASEDIR/FASTQ_rename_headers.py $tempdir/$base_name1;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
