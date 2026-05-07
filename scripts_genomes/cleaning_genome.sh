#!/bin/bash -e
#
# cleaning_genome.sh
#
set -e;
## All created files will have permission 760
umask 007;

### define script file locations.
user=$1;
genome=$2;
main_dir=$3;

#user="darren"
#genome="test_02";
#main_dir="/heap/hapmap/bermanlab/";

reflocation=$main_dir"users/"$user"/genomes/"$genome"/";				# Directory where FASTA file is kept.
logName=$reflocation"process_log.txt";
condensedLog=$reflocation"condensed_log.txt";
FASTA=`sed -n 1,1'p' $reflocation"reference.txt"`;					# Name of FASTA file.
FASTAname=$(echo $FASTA | sed 's/.fasta//g');						# name of genome file, without file type.
ddRADseq_FASTA=$FASTAname".MfeI_MboI.fasta";						# Name of digested reference for ddRADseq analysis.
standard_bin_FASTA=$FASTAname".standard_bins.fasta";					# Name of reference genome broken up into standard bins.
nameString1=`cat $reflocation"name.txt"`;

. $main_dir"config.sh";
if [ $debug -eq 1 ];
then
	echo -e "\tReached cleanup stage, but skipping it because the debug flag is on." >> $logName;
	echo -e "\tCreating complete.txt, so that the front-end recognizes the completion." >> $logName;

	completeFile=$reflocation"complete.txt";
	echo -e "complete" > $completeFile;
	timestamp=$(date +%T);
	echo $timestamp >> $completeFile;
	echo -e "\tGenerated 'complete.txt' file." >> $logName;
	chmod 0666 $completeFile;

	## changing working.txt to working_done.txt
	if [ -f $reflocation"working.txt" ]
	then
		mv $reflocation"working.txt" $reflocation"working_done.txt";
		echo -e "\t changed working.txt to working_done.txt" >> $logName;
	fi

	exit 0;
fi

##============================================#
# Intermediate file cleanup.                  #
#============================================##
echo -e "Cleaning and archiving." >> $condensedLog;
echo -e "Deleting unneeded intermediate files." >> $logName;

if [ -f $reflocation$genome".repetitiveness.txt" ]
then
	rm $reflocation$genome".repetitiveness.txt";
	echo -e "\t"$reflocation$genome".repetitiveness.txt" >> $logName;
fi


echo -e "\tGenerating 'complete.txt' file to let pipeline know installation of genome has completed." >> $logName;
## Generate "complete.txt" to indicate processing has completed normally.
timestamp=$(date +%T);

	timesLogFile=$main_dir"completion_times.log";
	if [ -f $timesLogFile ]
	then
		echo -n $user"("$genome")[genome]\t" >> $timesLogFile;
		cat $reflocation"working.txt" >> $timesLogFile;
		echo -e " -> "$timestamp >> $timesLogFile;
	fi

completeFile=$reflocation"complete.txt";
echo -e "complete" > $completeFile;
echo $timestamp >> $completeFile;
echo -e "\tGenerated 'complete.txt' file." >> $logName;
chmod 0666 $completeFile;
if [ -f $reflocation"working.txt" ]
then
	echo -e "\n"$timestamp >> $reflocation"working.txt"
	mv $reflocation"working.txt" $reflocation"working_done.txt";
	echo -e "\tworking.txt" >> $logName;
fi
echo -e "\n--== Last Line ==--\n" >> $logName;
