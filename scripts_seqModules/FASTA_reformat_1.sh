#!/bin/bash

if [ -z $1 ]
then
	echo;
	echo "# Command syntax is : 'bash FASTA_reformat_1.sh [FASTA seq file] > output.fasta'";
	echo "# ";
	echo "#        [FASTA seq file] : Genome sequence file in FASTA format.";
	echo "# ";
	echo "# This script will take a file containing multi-line FASTA entries and reformat";
	echo "# them to have only one line for the header and for the sequence for each entry.";
	echo "# ";
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

	# If line starts with ">" output with leading & trailing "\n"; else output without trailing "\n";
	counter=0;
	while read line; do
		if [[ $line == ">"* ]]
		then
			if [[ $counter -eq "1" ]]
			then
				echo -e "\n"$line;
			else
				echo $line;
			fi
		else
			echo -n $line;
		fi
		counter=1;
	done < $1

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
