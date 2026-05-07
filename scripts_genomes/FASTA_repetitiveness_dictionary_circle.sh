#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $2 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTA_repetitiveness_dictionary_circle.sh [FASTA seq file 1] [kmer length]'";
	echo -e "# ";
	echo -e "#        [FASTA seq file 1] : Single entry FASTA file, used to build kmer dictionary.";
	echo -e "#        [kmer length]      : K-mer length.";
	echo -e "# ";
	echo -e "# Assumes FASTA represents a circular chromosome/plasmid/genome.";
	echo -e "# Script will output list times each kmer was found in reference FASTA.";
	echo -e "#";
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

	# move input files to temp dir.
	cp $1 $tempdir;

	# simplify names.
	base_name1=$(basename $1);

	echo -e "Processing: "$1;
	python3 $BASEDIR/scripts/repetitiveness.make_dictionary_circle.py $tempdir/$base_name1 $2 $CALLDIR;
	# arg[1] : input file.
	# arg[2] : kmer length.
	# arg[3] : output file directory.

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
