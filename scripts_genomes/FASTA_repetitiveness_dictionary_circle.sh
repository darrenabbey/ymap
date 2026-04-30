#!/bin/sh

# If no data file option is given, describe script purpose and input.
if [ -z $2 ]
then
	echo;
	echo "# Command syntax is : 'sh FASTA_repetitiveness_dictionary_circle.sh [FASTA seq file 1] [kmer length]'";
	echo "# ";
	echo "#        [FASTA seq file 1] : Single entry FASTA file, used to build kmer dictionary.";
	echo "#        [kmer length]      : K-mer length.";
	echo "# ";
	echo "# Assumes FASTA represents a circular chromosome/plasmid/genome.";
	echo "# Script will output list times each kmer was found in reference FASTA.";
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
tempdir=$(mktemp -d);
#========================

	# move input files to temp dir.
	cp $1 $tempdir;

	# simplify names.
	base_name1=$(basename $1);

	echo "Processing: "$1;
	python3 $BASEDIR/scripts/repetitiveness.make_dictionary_circle.py $tempdir/$base_name1 $2 $CALLDIR;
	# arg[1] : input file.
	# arg[2] : kmer length.
	# arg[3] : output file directory.

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
