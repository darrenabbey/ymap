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

	###
	### A much faster way to do this step.
	###

	# Grabs header lines | replace the starting '@' with '>'.
	sed -n '1~4p' < $1 | sed -i 's/^./>/' > $tempdir/temp1.text;

	# Grabs sequence lines.
	sed -n '2~4p' < $1 > $tempdir/temp2.text;

	# Interleave the two files to create a FASTA formatted file.
	paste -d '\n' $tempdir/temp1.text $tempdir/temp2.text;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
