#!/bin/sh
set -e

# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo "# Command syntax is : 'sh FASTQ_to_Illumina [FASTQ seq file]'";
	echo "# ";
	echo "#        [FASTQ seq file] : Genome sequence file in FASTQ format.";
	echo "# ";
	echo "# This script will take a file containing single-line long-read FASTQ entries and fragment";
	echo "# them into many entries at 300bp long per entry, repeated at every offset to try";
	echo "# and generate simulated Illumina reads for input into YMAP for homolog identification.";
	echo "#";
	echo "# Output is a *.fastq file. Headers in FASTQ file do not reflect headers in original FASTQ,";
	echo "# but are unique as needed for alignment purposes.";
	echo "#";
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
tempdir=$2;
mkdir $tempdir;
#========================

	###
	### This retains quality scores, rather than making up arbitrary scores.
	###

	finalName="output.fastq";

	# Grab sequence lines | break into 300 bp fragments | erase blank lines.
	sed -n '2~4p' < $1 | perl -p -e 's/.{'300'}/$&\n/g' | grep -v '^\s*$' > $tempdir/temp2.text &
	# Grab quality lines | break into 300 bp fragments | erase blank lines.
	sed -n '4~4p' < $1 | perl -p -e 's/.{'300'}/$&\n/g' | grep -v '^\s*$' > $tempdir/temp4.text &

	wait;

	lineCount=$(wc -l < $tempdir/temp2.text);

	# Build unique sequence header lines.
	seq 1 $lineCount | awk '{print "@" $1}' > $tempdir/temp1.text &
	# Build matched quality header lines.
	seq 1 $lineCount | awk '{print "+" $1}' > $tempdir/temp3.text &

	wait;

	# interleave the four files to recreate a FASTQ file.
	paste -d '\n' $tempdir/temp1.text $tempdir/temp2.text $tempdir/temp3.text $tempdir/temp4.text > $CALLDIR/$finalName;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
