#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTA_make-chr-sizes.sh [fasta file] > chrom.sizes'";
	echo -e "# ";
	echo -e "#        [fasta file]   : FASTA formatted genome sequence file.";
	echo -e "#        chrom.sizes    : a two-column text file with lines of <chromosome name> <size in bases>.";
	echo -e "# ";
	echo -e "# Script processes input FASTA file into a two-column text file with lines of <chromosome name> <size in bases>";
	echo -e "for use with WIG-to-BigWIG.sh to create a BigWig file for use with IGV.";
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

	# Get fasta entry headers, chr names.
	#grep ">" $CALLDIR/$1 > $tempdir/tmp1;
	grep ">" $1 > $tempdir/tmp1;
	sed 's/>//g' $tempdir/tmp1 > $tempdir/tmp2;
	awk '{print $1}' $tempdir/tmp2 > $tempdir/tmp3;

	# Get fasta entry sequence lengths.
	#grep -v '>' $CALLDIR/$1 > $tempdir/tmp4;
	grep -v '>' $1 > $tempdir/tmp4;
	while read line; do echo -n "$line" | wc -c; done< $tempdir/tmp4 > $tempdir/tmp5;

	# Stitch columns made above into final "chrom.sizes" file.
	paste -d' ' $tempdir/tmp3 $tempdir/tmp5 > $tempdir/chrom.sizes;

	# Output final file.
	cat $tempdir/chrom.sizes;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
