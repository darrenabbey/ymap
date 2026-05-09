#!/bin/sh
set -e

# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo "# Command syntax is : 'sh FASTA_to-uppercase.sh [FASTA seq file] > output.fasta'";
	echo "# ";
	echo "#        [FASTA seq file] : Genome sequence file in FASTA format.";
	echo "# ";
	echo "# This script will take a file containing FASTA entries and change any lowercase";
	echo "# bases to uppercase.";
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

	# 1) For lines that start with any of "ATGC", convert characters in the line to uppercase.
	perl -pi -e 'if (/^[atgcATGC]/) { print uc } else { print }' $tempdir/$base_name1;

	# 2) Delete duplicate lines produced above.
	sed 'n; d' $tempdir/$base_name1 > $tempdir/$base_name1.2

	# Output results.
	cat $tempdir/$base_name1.2;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
