#===================================================================================================================================
# Decompose Sam files into FASTQ files for introduction into the sequence analysis pipeline.
#-----------------------------------------------------------------------------------------------------------------------------------
user=$1;
project=$2;
inputFile=$3;
main_dir=$(pwd)"/";

projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logFile=$projectDirectory"process_log.txt";
echo "#|---- sam2fastq.sh ---- begin." >> $logFile;

# import locations of auxillary software for pipeline analysis.
. $main_dir"local_installed_programs.sh";

finalOutput1=$projectDirectory"data_r1.fastq";
finalOutput2=$projectDirectory"data_r2.fastq";

#===================================================================================================================================
# Use SAMtools to convert Bam to Sam.
#-----------------------------------------------------------------------------------------------------------------------------------

echo "#| $samtools_exec collate -u -O $projectDirectory$inputFile | $samtools_exec fastq -1 $finalOutput1 -2 $finalOutput2 -0 /dev/null -s /dev/null -n" >> $logFile;

$samtools_exec collate -u -O $projectDirectory$inputFile | $samtools_exec fastq -1 $finalOutput1 -2 $finalOutput2 -0 /dev/null -s /dev/null -n;

echo "#|---- sam2fastq.sh ---- end." >> $logFile;
