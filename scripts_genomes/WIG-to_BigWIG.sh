#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $3 ]
then
	echo;
	echo -e "# Command syntax is : 'bash WIG-to_BigWIG.sh [wig file] [chrom.sizes file] [bigwig file]'";
	echo -e "# ";
	echo -e "#        [wig file]     : one of the ASCII wiggle formats, not including track lines.";
	echo -e "#        [chrom.sizes]  : a two-column text file with lines of <chromosome name> <size in bases>.";
	echo -e "#        [bigwig file]  : output indexed bigwig file.";
	echo -e "# ";
	echo -e "# Script converts a text formatted WIG file to a binary formatted BigWIG file. Files are";
	echo -e "# used to visualize custom data tracks in IGV.";
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

	# Make bigwig file.
	echo -e "Convert wig file to bigWig file.";
	cd $BASEDIR;
	#./scripts/wigToBigWig $CALLDIR/$1 $CALLDIR/$2 $CALLDIR/$3;
	$wigToBigWig_exec $1 $2 $3;
	cd $CALLDIR;

#========================
# Cleanup (automatic at script close.)
fi
