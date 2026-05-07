#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTA_to-uppercase.sh [FASTA seq file] > output.fasta'";
	echo -e "# ";
	echo -e "#        [FASTA seq file] : Genome sequence file in FASTA format.";
	echo -e "# ";
	echo -e "# This script will take a file containing FASTA entries and change any lowercase";
	echo -e "# bases to uppercase.";
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
