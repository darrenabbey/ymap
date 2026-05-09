#!/bin/sh
set -e

# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo "# Command syntax is : 'sh FASTQ_to_FASTA.sh [FASTQ seq file] > output.fasta'";
	echo "# ";
	echo "#        [FASTQ seq file] : DNA sequence data in FASTQ format.";
	echo "# ";
	echo "# This script will take a FASTQ file as input and convert it into a FASTA file.";
	echo "# It does this by discarding the quality score data in the FASTQ file.";
	echo "# ";
	echo;
	exit 1;
else
# Absolute path this script is in.
BASEPATH=$(readlink -f "$0");
BASEDIR=$(dirname $BASEPATH);
#echo "Script found in: ${BASEDIR}"

# Absolute path the script is called from.
CALLDIR=${PWD}
#echo "Script executed from: ${CALLDIR}"

# Make temp dir.
tempdir=$(mktemp -d);
#========================

	# move input file to temp dir.
	cp $1 $tempdir;

	# simplify names.
	base_name1=$(basename $1);

	#echo ">default_read_name";
	#cat $tempdir/$base_name1 | head -n 2 | tail -n 1;

	# Call python script FASTQ_to_FASTA.py
	python3 $BASEDIR/FASTQ_to_FASTA.py $tempdir/$base_name1;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
