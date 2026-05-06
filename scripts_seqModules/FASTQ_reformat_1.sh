set -e
if [ -z $1 ]
then
	echo;
	echo "### UNTESTED ###";
	echo "# Command syntax is : 'bash FASTQ_reformat_1.sh [FASTQ seq file] > output.fastq'";
	echo "# ";
	echo "#        [FASTQ seq file] : Genome sequence file in FASTQ format.";
	echo "# ";
	echo "# This script will take a file containing multi-line FASTQ entries and reformat";
	echo "# them to have only one line for the header and for the sequence for each entry.";
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

	# If line starts with "@" output with leading & trailing "\n"; else output without trailing "\n";
	while read line; do
		if [[ $line == "@"* ]]; then
			echo -e "\n"$line;
		else
			if [[ $line == "+"* ]]; then
				echo -e "\n"$line;
			else
				echo -n $line;
			fi
		fi
	done < $1

#========================
# Cleanup
rm $tempdir/*;
rmdir $tempdir;
fi
