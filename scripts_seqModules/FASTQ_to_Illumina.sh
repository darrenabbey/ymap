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

	finalName="output.fastq"

	# simplify names.
	base_name1=$(basename $1);

	# Converts input FASTQ file to FASTA file by discarding quality scores.
	sh $BASEDIR/FASTQ_to_FASTA.sh $1 > $tempdir/$base_name1.1;

	# Ensure FASTA entries are single-line.
	sh $BASEDIR/FASTA_reformat_1.sh $tempdir/$base_name1.1 > $tempdir/$base_name1.2;

	# 1) For lines that don't start with ">", add a newline after every 300 characters. Put in placeholder headers of ">temp"
	perl -p -e 'if (!/^[>]/) { s/.{'300'}/$&\n>temp\n/g }' $tempdir/$base_name1.2 > $tempdir/$base_name1.3;

	# Call python script FASTA_to_FASTQ.py
	python3 $BASEDIR/FASTA_to_FASTQ.py $tempdir/$base_name1.3 > $tempdir/$base_name1.4;

	# Make sure FASTQ entries have unique header strings.
	sh $BASEDIR/FASTQ_rename_headers.sh $tempdir/$base_name1.4 > $tempdir/$base_name1.5;

	# Output results.
	cp $tempdir/$base_name1.5 $CALLDIR/$finalName;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
