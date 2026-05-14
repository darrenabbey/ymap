#!/bin/bash
set -e

#===================================================================================================================================
# Decompose Sam files into FASTQ files for introduction into the sequence analysis pipeline.
#-----------------------------------------------------------------------------------------------------------------------------------
user=$1;
project=$2;
inputFile=$3;
main_dir=$(pwd)"/";

projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";


## Error handling in case something crashes.
trap 'bash queue_end.sh $user $project $main_dir $logName "Something went wrong. sam2fastq.sh:$LINENO"; echo -e "Something went wrong. sam2fastq.sh:$LINENO" > $projectDirectory"error.txt"; exit 1;' ERR;


echo "#|---- sam2fastq.sh ---- begin." >> $logName;

# import locations of auxillary software for pipeline analysis.
. $main_dir"local_installed_programs.sh";


## Check if SAM file contains single or paired reads, then extract.
header=$($samtools_exec view -H $projectDirectory$inputFile);
count=$(echo "$header" | grep -o "[.fastq|.fq]" | wc -l);

if [ $count == "1" ]; then
	echo "#|\tSingle end reads." >> $logName;
	finalOutput1=$projectDirectory"data.fastq";
	finalOutput2="";
	echo "#|\t$samtools_exec fastq -1 $finalOutput1 -2 $finalOutput1 -0 $finalOutput1 -s /dev/null $projectDirectory$inputFile -n" >> $logName;
	$samtools_exec fastq -1 $finalOutput1 -2 $finalOutput1 -0 $finalOutput1 -s /dev/null $projectDirectory$inputFile -n;

else
	echo "#|\tPaired end reads." >> $logName;
	finalOutput1=$projectDirectory"data_r1.fastq";
	finalOutput2=$projectDirectory"data_r2.fastq";
	echo "#|\t$samtools_exec collate -u -O $projectDirectory$inputFile | $samtools_exec fastq -1 $finalOutput1 -2 $finalOutput2 -0 /dev/null -s /dev/null -n" >> $logName;
	$samtools_exec collate -u -O $projectDirectory$inputFile | $samtools_exec fastq -1 $finalOutput1 -2 $finalOutput2 -0 /dev/null -s /dev/null -n;
fi;
echo "#|---- sam2fastq.sh ---- end." >> $logName;

##$samtools_exec collate -u -O $projectDirectory$inputFile | $samtools_exec fastq -1 $finalOutput1 -2 $finalOutput2 -0 /dev/null -s /dev/null -n;
