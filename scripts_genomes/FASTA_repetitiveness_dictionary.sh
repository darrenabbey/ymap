#!/bin/sh
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $5 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTA_repetitiveness_dictionary.sh [YMAP user name] [YMAP genome name] [YMAP main dir] [YMAP log file] [kmer length]'";
	echo -e "# ";
	echo -e "#        [YMAP user name]   : Name of user account.";
	echo -e "#        [YMAP genome name] : Name of installed genome.";
	echo -e "#        [YMAP main dir]    : Location of YMAP install.";
	echo -e "#        [YMAP log file]    : Log file for output.";
	echo -e "#        [kmer length]      : K-mer length.";
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
trap 'bash queue_end.sh $userAccount $genomeName $mainDir $logFile "Something went wrong. FASTA_repetitiveness_dictionary.sh:$LINENO"; echo -e "Something went wrong. FASTA_repetitiveness_dictionary.sh:$LINENO" > $genomeDirectory"error.txt"; exit 1;' ERR;


# load local installed program location variables.
. $mainDir"local_installed_programs.sh";

genomeFASTA=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.2.fasta";
RepetDictionary=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.repetitiveness_"$kmer_length".txt";

# Make temp dir.
tempdir=$(mktemp -d);
#========================

###
### Process entire FASTA using multiple threads.
###
	# copy input files to temp dir.
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
		fileName=$(basename $file);
		# make repetitiveness dictionary for each contig file.
		$python_exec $mainDir"scripts_genomes/scripts/repetitiveness.make_dictionary.py" $fileName $kmer_length $tempdir > $file.repet;
	done;
#	wait;

	#echo -e "Combining chromosome dictionaries."
	cat $tempdir/*.repet > $tempdir/library.temp;

	#echo -e "Sorting combined dictionary.";
	sort $tempdir/library.temp > $RepetDictionary;

###
### Process entire FASTA using a single thread.
###
#	# copy input files to temp dir.
#	cp $genomeFASTA $tempdir/reference.fasta;
#
#	$python_exec $mainDir"scripts_genomes/scripts/repetitiveness.make_dictionary.py" reference.fasta $kmer_length $tempdir > $RepetDictionary;

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
