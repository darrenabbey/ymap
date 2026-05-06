#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo "# Command syntax is : 'bash FASTA_repetitiveness_dictionary_clean.sh [YMAP user name] [YMAP genome name] [YMAP main dir] [YMAP log file] [kmer length]'";
	echo "# ";
	echo "#        [YMAP user name]   : Name of user account.";
	echo "#        [YMAP genome name] : Name of installed genome.";
	echo "#        [YMAP main dir]    : Location of YMAP install.";
	echo "#        [YMAP log file]    : Log file for output.";
	echo "#        [kmer length]      : K-mer length.";
	echo "#";
	echo "#        This script cleans up the dictionary file by condensing duplicate counts for";
	echo:"#        specific kmers into single summary counts. Such replicates are formed during";
	echo "#        initial dictionary construction due to multi-threaded algorithm used.";
	echo;
	exit 1;
else
userAccount=$1;
genomeName=$2;
mainDir=$3;
logFile=$4;
kmer_length=$5;

# load local installed program location variables.
. $mainDir"local_installed_programs.sh";

RepetDictionary=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.repetitiveness_"$kmer_length".txt";

# Make temp dir.
tempdir=$(mktemp -d);
#========================

	# move input files to temp dir.
        cp $RepetDictionary $tempdir;

	# simplify names.
        base_name1="datafile_g_0.repetitiveness_"$kmer_length".txt";

	# Clean dictionary.
	$python_exec $mainDir"scripts_genomes/scripts/repetitiveness.clean_dictionary.py" $tempdir/$base_name1;

	# Replace original dictionary with cleaned version.
	cp $tempdir/$base_name1 $RepetDictionary;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
