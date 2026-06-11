#!/bin/sh
set -e

# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo "# Command syntax is : 'sh FASTA_to_Illumina [FASTA seq file] (FASTQ.GZ file)'";
	echo "# ";
	echo "#        [FASTA seq file] : Genome sequence file in FASTA format.";
	echo "#        (FASTQ.GZ file)  : Optional output file in GZ compressed FASTQ format.";
	echo "# ";
	echo "# This script will take a file containing single-line FASTA entries and fragment";
	echo "# them into many entries at 300bp long per entry, repeated at every offset to try";
	echo "# and generate simulated Illumina reads for input into YMAP for homolog identification.";
	echo "#";
	echo "# Output is a *.fastq.gz file, defaults to 'output.fastq.gz' if not provided.";
	echo "# Headers in FASTQ file do not reflect headers in original FASTA, but are unique";
	echo "# as needed for alignment purposes.";
	echo "#";
	echo;
	exit 1;
else
# Absolute path this script is in.
BASEPATH=$(readlink -f "$0");
BASEDIR=$(dirname $BASEPATH);
#echo "Script found in: ${BASEDIR}"

# Absolute path the script is called from: the YAMP project directory.
CALLDIR=${PWD}
#echo "Script executed from: ${CALLDIR}"

# Make temp dir.
tempdir=$2;
mkdir $tempdir;
#========================

	###
	### This makes up arbitrary flat quality scores, as there is no original quality data in a FASTA.
	###

	finalName="output.fastq";

	# reformat to one line per entry.
	sh $BASEDIR/FASTA_reformat_1.sh $1 > $tempdir/temp.text;

	# Grab sequence lines | break into 300 bp fragments | erase blank lines.
	sed -n '2~2p' < $tempdir/temp.text | perl -p -e 's/.{'300'}/$&\n/g' | grep -v '^\s*$' > $tempdir/temp2.text;

	# Make fake quality scores.
	sed -i 's/[^#\n]/Z/g' $tempdir/temp2.text > $tempdir/temp4.text;

	lineCount=$(wc -l < $tempdir/temp2.text);

        # Build unique sequence header lines.
        seq 1 $lineCount | awk '{print "@" $1}' > $tempdir/temp1.text;
	# Build unique sequence header lines.
	seq 1 $lineCount | awk '{print "+" $1}' > $tempdir/temp3.text;

	# interleave the four files to recreate a FASTQ file.
        paste -d '\n' $tempdir/temp1.text $tempdir/temp2.text $tempdir/temp3.text $tempdir/temp4.text > $CALLDIR/$finalName;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
