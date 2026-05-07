#!/bin/bash
set -e

# If no data file option is given, describe script purpose and input.
if [ -z $5 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTA_repetitiveness-to-WIG.sh [YMAP user name] [YMAP genome name] [YMAP main dir] [YMAP log file] [kmer length]'";
	echo -e "# ";
	echo -e "#        [YMAP user name]   : Name of user account.";
	echo -e "#        [YMAP genome name] : Name of installed genome.";
	echo -e "#        [YMAP main dir]    : Location of YMAP install.";
	echo -e "#        [YMAP log file]    : Log file for output.";
	echo -e "#        [kmer length]      : K-mer length.";
	echo -e "# ";
	echo -e "# Script will output figure WIG formatted text file containing repetitiveness scores per bp of FASTA.";
	echo -e "#";
	echo;
	exit 1;
else
userAccount=$1;
genomeName=$2;
mainDir=$3;
logFile=$4;
kmer_length=$5;

genomeDirectory=$mainDir"users/"$userAccount"/genomes/"$genomeName"/";

## Error handling in case something crashes.
trap 'bash queue_end.sh $userAccount $genomeName $mainDir $logFile "Something went wrong. FASTA_repetitiveness-to-WIG.sh:$LINENO"; echo -e "Something went wrong. FASTA_repetitiveness-to-WIG.sh:$LINENO" > $genomeDirectory"error.txt"; exit 1;' ERR;


# Absolute path the script is called from.
CALLDIR=${PWD}

# load local installed program location variables.
. $mainDir"local_installed_programs.sh";

genomeFASTA=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.2.fasta";
RepetDictionary=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.repetitiveness_"$kmer_length".txt";
genomeWIG=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.repetitiveness_"$kmer_length".wig";

# Make temp dir.
tempdir=$(mktemp -d);
#========================

	# move input files to temp dir.
	cp $RepetDictionary $tempdir/dictionary.txt;
	cp $genomeFASTA $tempdir/reference.fasta;

	# simplify name of input FASTA file.
	base_name1="datafile_g_0.fasta";

	# split input reference.fasta into multiple files, with one FASTA entry each.
	cd $tempdir;
	split -l 2 reference.fasta contig.;
	cd $CALLDIR;

	# process all contig files.
	for file in $tempdir/contig.*
	do
		# make wig file for each contig file, output results to standard.
		$python_exec $mainDir"scripts_genomes/scripts/repetitiveness.make_WIG.single-entry.py" $tempdir/dictionary.txt $file $kmer_length $tempdir $file.wig;
	done;
#	wait;

	# output results to final wig file.
	cat $tempdir/*.wig > $genomeWIG;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
