#===================================================================================================================================
# Convert Bam file to Sam file for introduction into the sequence analysis pipeline.
#-----------------------------------------------------------------------------------------------------------------------------------
user=$1;
project=$2;
inputFile=$3;
main_dir=$(pwd)"/";

# load local installed program location variables.
. $main_dir"local_installed_programs.sh";

projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logFile=$projectDirectory"process_log.txt";
echo -e "#|---- bam2sam.sh ---- begin." >> $logFile;

outputFile="data.sam"
echo -e "#| input file  : "$inputFile >> $logFile;
echo -e "#| output file : "$outputFile >> $logFile;

#===================================================================================================================================
# Use SAMtools to convert Bam to Sam.
#-----------------------------------------------------------------------------------------------------------------------------------

cd $projectDirectory;

echo -e "#| indexing BAM file." >> $logFile;
$samtools_exec index $inputFile;
echo -e "#| converting to SAM file." >> $logFile;
$samtools_exec view -h $inputFile > $outputFile;
echo -e "#|---- bam2sam.sh ---- end." >> $logFile;
