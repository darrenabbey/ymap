#!/bin/bash
set -e

# If no data file option is given, describe script purpose and input.
if [[ -z $1 ]]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTA_to_Illumina [FASTA seq file] (FASTQ.GZ file)'";
	echo -e "# ";
	echo -e "#        [FASTA seq file] : Genome sequence file in FASTA format.";
	echo -e "#        (FASTQ.GZ file)  : Optional output file in GZ compressed FASTQ format.";
	echo -e "# ";
	echo -e "# This script will take a file containing single-line FASTA entries and fragment";
	echo -e "# them into many entries at 300bp long per entry, repeated at every offset to try";
	echo -e "# and generate simulated Illumina reads for input into YMAP for homolog identification.";
	echo -e "#";
	echo -e "# Output is a *.fastq.gz file, defaults to 'output.fastq.gz' if not provided.";
	echo -e "# Headers in FASTQ file do not reflect headers in original FASTA, but are unique";
	echo -e "# as needed for alignment purposes.";
	echo -e "#";
	echo;
	exit 1;
else
# Absolute path this script is in.
BASEPATH=$(readlink -f "$0");
BASEDIR=$(dirname $BASEPATH);
#echo -e "Script found in: ${BASEDIR}"

# Absolute path the script is called from: the YAMP project directory.
CALLDIR=${PWD}
#echo -e "Script executed from: ${CALLDIR}"

# Make temp dir.
tempdir=$2;
mkdir $tempdir;
#========================

	finalName="output.fastq"

	# simplify names.
	base_name1=$(basename $1);

	# reformat to one line per enctry.
	bash $BASEDIR/FASTA_reformat_1.sh $1 > $tempdir/$base_name1.1;

	# For lines that don't start with ">", add a newline after every 300 characters. Put in placeholder headers of ">temp"
	perl -p -e 'if (!/^[>]/) { s/.{'300'}/$&\n>temp\n/g }' $tempdir/$base_name1.1 > $tempdir/$base_name1.2;

	# Call python script FASTA_to_FASTQ.py
	python3 $BASEDIR/FASTA_to_FASTQ.py $tempdir/$base_name1.2> $tempdir/$base_name1.3;

	# Make sure FASTQ entries have unique header strings.
	bash $BASEDIR/FASTQ_rename_headers.sh $tempdir/$base_name1.3 > $tempdir/$base_name1.4;

	# Output results.
	cp $tempdir/$base_name1.4 $CALLDIR/$finalName;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
