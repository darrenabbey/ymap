#!/bin/sh

# If no data file option is given, describe script purpose and input.
if [ -z $3 ]
then
	echo;
	echo "# Command syntax is : 'sh WIG-to_BigWIG.sh [wig file] [chrom.sizes file] [bigwig file]'";
	echo "# ";
	echo "#        [wig file]     : one of the ASCII wiggle formats, not including track lines.";
	echo "#        [chrom.sizes]  : a two-column text file with lines of <chromosome name> <size in bases>.";
	echo "#        [bigwig file]  : output indexed bigwig file.";
	echo "# ";
	echo "# Script converts a text formatted WIG file to a binary formatted BigWIG file. Files are";
	echo "# used to visualize custom data tracks in IGV.";
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

	# Make bigwig file.
	echo "Convert wig file to bigWig file.";
	cd $BASEDIR;
	#./scripts/wigToBigWig $CALLDIR/$1 $CALLDIR/$2 $CALLDIR/$3;
	$wigToBigWig_exec $1 $2 $3;
	cd $CALLDIR;

#========================
# Cleanup (automatic at script close.)
fi
