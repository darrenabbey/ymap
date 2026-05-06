#!/bin/sh

# If no data file option is given, describe script purpose and input.
if [ -z $6 ]
then
	echo;
	echo "# Command syntax is : 'sh FASTA_GCskew_dictionary.sh [YMAP user name] [YMAP genome name] [YMAP main dir] [YMAP log file] [kmer length]'";
	echo "# ";
	echo "#        [YMAP user name]   : Name of user account.";
	echo "#        [YMAP genome name] : Name of installed genome.";
	echo "#        [YMAP main dir]    : Location of YMAP install.";
	echo "#        [YMAP log file]    : Log file for output.";
	echo "#        [kmer length]      : length of window to examine for GC-skew.";
	echo "# ";
	echo "# Script will output a figure showing GC skew.";
	echo "#     GC skew = (G-C)/(G+C)";
	echo "# Value is shown at each bp, calculated over the k-mer window.";
	echo "#";
	echo;
	exit 1;
else
userAccount=$1;
genomeName=$2;
mainDir=$3;
logFile=$4;
kmerLength=$5;
kmerStep=$6;

genomeDirectory=$mainDir"users/"$userAccount"/genomes/"$genomeName"/";

## Error handling in case something crashes.
trap 'sh queue_end.sh $userAccount $genomeName $mainDir $logFile "Something went wrong. FASTA_GCskew_dictionary.sh:$LINENO"; echo "Something went wrong. FASTA_GCskew_dictionary.sh:$LINENO" > $genomeDirectory"error.txt"; exit 1;' ERR;


# load local installed program location variables.
. $mainDir"local_installed_programs.sh";

genomeFASTA=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.2.fasta";
GCskew_file=$mainDir"users/"$userAccount"/genomes/"$genomeName"/datafile_g_0.GCskew.txt";

# Make temp dir.
tempdir=$(mktemp -d);
#========================

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
		# make repetitiveness dictionary for each contig file.
		#echo "1: "$file;
		#echo "2: "$kmerLength;
		#echo "3: "$tempdir;
		#echo "4: "$file.skew;
		$python_exec $mainDir"scripts_genomes/scripts/GCskew.make_dictionary.py" $file $kmerLength $kmerStep $tempdir $file.skew;
	done;
#	wait;

	# gather results from each contig into single final output file.
	touch $GCskew_file && rm $GCskew_file;
	for file in $tempdir/*.skew
	do
		cat $file >> $GCskew_file;
	done;


###
### Single process doesn't properly deal with multiple entrires in FASTA and output file does not have clear chromosome separations.
###
#	# move input files to temp dir.
#	cp $genomeFASTA $tempdir;
#
#	# simplify names.
#	base_name1='datafile_g_0.2.fasta';
#
#	echo "Processing: "$genomeName;
#	$python_exec $mainDir"scripts_genomes/scripts/GCskew.make_dictionary.py" $tempdir/$base_name1 $kmerLength $tempdir;
#	cp $tempdir/output.txt $GCskew_file;
#	# arg[1] : input file.
#	# arg[2] : kmer length.
#	# makes "output.txt" in tempdir.

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
