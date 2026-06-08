#!/bin/bash
set -e

#===================================================================================================================================
# Decompose Sam files into FASTQ files for introduction into the sequence analysis pipeline.
#-----------------------------------------------------------------------------------------------------------------------------------
user="$1";
project="$2";
inputFile="$3";
outputFile="$4";
main_dir=$(pwd);

projectDirectory="$main_dir/users/$user/projects/$project";
logName="$projectDirectory/process_log.txt";

## Error handling in case something crashes.
trap 'cd $main_dir"/scripts_seqModules/scripts_WGseq/"; bash queue_end.sh $user $project $main_dir $logName "Something went wrong. sam2fastq.sh:$LINENO"; echo -e "Something went wrong. sam2fastq.sh:$LINENO" > $projectDirectory"error.txt"; cd $main_dir; exit 1;' ERR;

echo -e "#|---- sam2fastq.sh ---- begin." >> $logName;

# import locations of auxillary software for pipeline analysis.
. $main_dir/local_installed_programs.sh;

## Check if SAM file contains single or paired reads, then extract.
SAMheader=$($samtools_exec view -H "$projectDirectory/$inputFile");
count=$(grep -E -o '\.fastq|\.fq' <<< "$SAMheader" | wc -l)

## Paired-end position data isn't used in YMAP, so it's faster to treat everything as single-read data.
if [ $count == "1" ]; then
	echo -e "#|\tSingle end reads." >> $logName;
else
	echo -e "#|\tPaired end reads." >> $logName;
fi;
finalOutput1="$projectDirectory/$outputFile";
finalOutput2="";
echo -e "#|\t$samtools_exec fastq -0 /dev/null $projectDirectory$inputFile -n > $finalOutput1" >> $logName;
$samtools_exec fastq -0 /dev/null "$projectDirectory/$inputFile" -n > $finalOutput1;

echo -e "#|---- sam2fastq.sh ---- end." >> $logName;
