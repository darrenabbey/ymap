#!/bin/bash
set -e
# If no data file option is given, describe script purpose and input.
if [ -z $1 ]
then
	echo;
	echo -e "# Command syntax is : 'bash FASTQ_trimming.sh [dataset]'";
	echo -e "# ";
	echo -e "#        [dataset] : read file to be trimmed of incomplete final read.";
	echo -e "# ";
	echo -e "# This script attempts to cleanup a FASTQ file which is not validly formatted due to early";
	echo -e "#      termination of data transfer.  This formatting problem results in FASTQC crashing.";
	echo -e "# ";
	echo;
	exit 1;   # exit with error.
else
	findStr=".fastq";
	replaceStr=".residue.fastq";
	residueName1=$(echo $1 | sed -e "s/$findStr$/$replaceStr/g");
	# If final files are found, don't process these data files.
	if [ -f $residueName1 ]
	then
		echo;
		echo -e "# ";
		echo -e "# Trimming of incomplete read entries in FASTQs has already been run on this datsaet.";
		echo -e "# ";
		exit 0;   # exit with no error.
	else
		## FASTQ format per line, repeating.
		# echo -e "@ id"
		# echo -e "sequence"
		# echo -e "+ id"
		# echo -e "quality"

		# number of lines of each file.
		echo -e "#\tTotal number of lines in file:";
		length_full1=$(wc -l $1 | awk '{print $1}');
		echo -e "#\t\tFile1: "$length_full1;

		# modulus of the number of lines by 4, as the fastq format is in blocks of 4 lines.
		# this will give us the number of extra lines in each file.
		echo -e "#\tLines at end of each file suggestive of a cropped entry:";
		length_extra1=(($length_full1 % 4));
		echo -e "#\t\tFile1: "$length_extra1;

		# If the number of extra lines is zero, then nothing needs to be done.
		# If the number of extra lines is more than zero, then create a trimmed file to replace the original.
		if [ "$length_extra1" -gt 0 ]
		then
			# the number of properly formated lines per file.
			echo -e "#\tNumber of properly formated lines per file:";
			length_base1=(($length_full1 - $length_extra1));
			echo -e "#\t\tFile1: "$length_base1;

			# find the residue lengths per file.
			# this is the number of lines of incomplete and extra reads.
			echo -e "#\tNumber of lines at the end of file to be removed:";
			length_residue1=$length_extra1;
			echo -e "#\t\tFile1: "$length_residue1;

			findStr=".fastq";
			replaceStr=".trimmed.fastq";
			trimmedName1=$(echo $1 | sed -e "s/$findStr$/$replaceStr/g");

			# make copy of the original read file which are trimmed to valid length.
			echo -e "#\tMaking trimmed valid fastq files:";
			echo -e "#\t\tFile1: "$trimmedName1;
			cat $1 | head -$length_base1 > $trimmedName1;

			# make residue file containing any incomplete or extra read lines.
			echo -e "#\tMaking file containing residual lines:";
			if [ "$length_residue1" -gt 0 ]
			then
				echo -e "#\t\tFile1: "$residueName1;
				cat $1 | tail -$length_residue1 > $residueName1;
			fi

			echo -e "#\tReplacing original files with trimmed versions.";
			# cleanup original raw files.
			rm $1;
			# rename produced valid FASTQ files to original file names.
			mv $trimmedName1 $1
		else
			echo -e "#\tFile trimming does not need performed on this dataset.";
		fi
	fi
fi
