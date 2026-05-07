#!/bin/bash
#
# project.ddRADseq.install_4.sh
#
set -e;

## All created files will have permission 760
umask 007;

### define script file locations.
user=$1;
project=$2;
main_dir=$(pwd)"/../../";

echo -e "";
echo -e "Input to : project.ddRADseq.update_2.sh";
echo -e "\tuser     = "$user;
echo -e "\tproject  = "$project;
echo -e "\tmain_dir = "$main_dir;
echo -e "";


##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------

# import locations of auxillary software for pipeline analysis.
. $main_dir"local_installed_programs.sh";
. $main_dir"config.sh";

# Define project directory.
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";

# Setup process_log.txt file.
logName=$projectDirectory"process_log.txt";
condensedLog=$projectDirectory"condensed_log.txt";


## Error handling in case something crashes.
trap 'bash queue_end.sh $user $project $main_dir $logName "Something went wrong. project.ddRADseq.install_2.sh:$LINENO"; echo -e "Something went wrong. project.ddRADseq.install_2.sh:$LINENO" > $projectDirectory"error.txt"; exit 1;' ERR;


chmod 0666 $logName;
echo -e "#.............................................................................." >> $logName;
echo -e "Running 'scripts_seqModules/scripts_ddRADseq/project.ddRADseq.update_2.sh'" >> $logName;
echo -e "Variables passed via command-line from 'scripts_seqModules/scripts_ddRADseq/project.ddRADseq.update_1.php' :" >> $logName;
echo -e "\tuser     = '"$user"'" >> $logName;
echo -e "\tproject  = '"$project"'" >> $logName;
echo -e "\tmain_dir = '"$main_dir"'" >> $logName;
echo -e "#============================================================================== 3" >> $logName;

echo -e "#=====================================#" >> $logName;
echo -e "# Setting up locations and variables. #" >> $logName;
echo -e "#=====================================#" >> $logName;

echo -e "\tprojectDirectory = '$projectDirectory'" >> $logName;
echo -e "Setting up for processing." >> $condensedLog;

# Get setup information from project files.
# "genome.txt"
#    first line  => genome
#    second line => hapmap
genome=$(head -n 1 $projectDirectory"genome.txt");
hapmap=$(tail -n 1 $projectDirectory"genome.txt");
dataFormat=$(head -n 1 $projectDirectory"dataFormat.txt");
echo -e "\t'genome.txt' file entry." >> $logName;
echo -e "\t\tgenome = '"$genome"'" >> $logName;
if [[ "$genome" = "$hapmap" ]]
then
	hapmapInUse=0;
else
	echo -e "\t\thapmap = '"$hapmap"'" >> $logName;
	hapmapInUse=1;
	# Determine location of hapmap being used.
	if [[ -d $main_dir"users/"$user"/hapmaps/"$hapmap"/" ]]
	then
		hapmapDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";
		hapmapUser=$user;
		hapmapUsed=1
	elif [[ -d $main_dir"users/default/hapmaps/"$hapmap"/" ]]
	then
		hapmapDirectory=$main_dir"users/default/hapmaps/"$hapmap"/";
		hapmapUser="default";
		hapmapUsed=1;
	else
		hapmapUsed=0;
	fi
	echo -e "\thapmapDirectory = '"$hapmapDirectory"'" >> $logName;
fi

# Determine location of genome being used.
if [[ -d $main_dir"users/"$user"/genomes/"$genome"/" ]]
then
	genomeDirectory=$main_dir"users/"$user"/genomes/"$genome"/";
	genomeUser=$user;
elif [[ -d $main_dir"users/default/genomes/"$genome"/" ]]
then
	genomeDirectory=$main_dir"users/default/genomes/"$genome"/";
	genomeUser="default";
fi
echo -e "\tgenomeDirectory = '"$genomeDirectory"'" >> $logName;

# Get reference FASTA file name from "reference.txt";
genomeFASTA=$(head -n 1 $genomeDirectory"reference.txt");
echo -e "\tgenomeFASTA = '"$genomeFASTA"'" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyEstimate = '"$ploidyEstimate"'" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyBase = '"$ploidyBase"'" >> $logName;

# Get parent name from "parent.txt" in project directory.
projectParent=$(head -n 1 $projectDirectory"parent.txt");
echo -e "\tparentProject = '"$projectParent"'" >> $logName;

# Determine location of parent being used.
if [[ -d $main_dir"users/"$user"/projects/"$projectParent"/" ]]
then
	projectParentDirectory=$main_dir"users/"$user"/genomes/"$projectParent"/";
	projectParentUser=$user;
elif [[ -d $main_dir"users/default/projects/"$projectParent"/" ]]
then
	projectParentDirectory=$main_dir"users/default/genomes/"$projectParent"/";
	projectParentUser="default";
fi

reflocation=$main_dir"users/"$genomeUser"/genomes/"$genome"/";                 # Directory where FASTA file is kept.
FASTA=`sed -n 1,1'p' $reflocation"reference.txt"`;                             # Name of FASTA file.
FASTAname=$(echo $FASTA | sed 's/.fasta//g');                                  # name of genome file, without file type.
RestrctionEnzymes=`sed -n 1,1'p' $projectDirectory"restrictionEnzymes.txt"`;   # Name of restriction enxyme list file.
ddRADseq_FASTA=$FASTAname"."$RestrctionEnzymes".fasta";                        # Name of digested reference for ddRADseq analysis, using chosen restriction enzymes.

echo -e "#============================================================================== 2" >> $logName;


##==============================================================================
## Perform CGH analysis, with GC-correction, on dataset.
##------------------------------------------------------------------------------
echo -e "#==========================#" >> $logName;
echo -e "# CGH analysis of dataset. #" >> $logName;
echo -e "#==========================#" >> $logName;
echo -e "Performing CGH analysis." >> $condensedLog;
echo -e "Analyzing and mapping CNVs." >> $condensedLog;

echo -e "\tGenerating octave script to perform CNV analysis of dataset, with GC-correction." >> $logName;
outputName=$projectDirectory"processing1.m";
echo -e "\toutputName = "$outputName >> $logName;

echo -e "function [] = processing1()" > $outputName;
echo -e "\tdiary('"$projectDirectory"octave.CNV_and_GCbias.log');" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $outputName;
echo -e "\tanalyze_CNVs_RADseq_3('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing1()" >> $logName;
echo -e "\t|\t\tdiary('"$projectDirectory"octave.CNV_and_GCbias.log');" >> $logName;
echo -e "\t|\t\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $logName;
echo -e "\t|\t\tanalyze_CNVs_RADseq_3('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling octave." >> $logName;
$octave_exec $outputName 2>> $logName;
echo -e "\toctave log from CNV analysis." >> $logName;
sed 's/^/\t\t|/;' $projectDirectory"octave.CNV_and_GCbias.log" >> $logName;


##==============================================================================
## Perform SNP/LOH analysis on dataset.   ...must be redone for ddRADseq, specificially.
##------------------------------------------------------------------------------
if [[ "$project" = "$parent" ]]
then
	echo -e "#============================#" >> $logName;
	echo -e "#= LOH analysis of dataset. =#" >> $logName;
	echo -e "#============================#" >> $logName;
else
	echo -e "#============================#" >> $logName;
	echo -e "#= SNP analysis of dataset. =#" >> $logName;
	echo -e "#============================#" >> $logName;
fi

echo -e "Mapping SNPs." >> $condensedLog;
echo -e "\tGenerating octave script to perform SNP analysis of dataset." >> $logName;
outputName=$projectDirectory"processing3.m";
echo -e "\toutputName = "$outputName >> $logName;

echo -e "function [] = processing3()" > $outputName;
echo -e "\tdiary('"$projectDirectory"octave.SNP_analysis.log');" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $outputName;
echo -e "\tanalyze_SNPs_RADseq('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing3()" >> $logName;
echo -e "\t|\t\tdiary('"$projectDirectory"octave.SNP_analysis.log');" >> $logName;
echo -e "\t|\t\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $logName;
echo -e "\t|\t\tanalyze_SNPs_RADseq('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling octave." >> $logName;
echo -e "================================================================================================";
echo -e "== SNP analysis ================================================================================";
echo -e "================================================================================================";
$octave_exec $outputName 2>> $logName;
echo -e "\toctave log from SNP analysis." >> $logName;
sed 's/^/\t\t|/;' $projectDirectory"octave.SNP_analysis.log" >> $logName;


#===============================================================================
## Generate final figures for dataset.
##------------------------------------------------------------------------------
echo -e "#==================================#" >> $logName;
echo -e "# Generate final combined figures. #" >> $logName;
echo -e "#==================================#" >> $logName;
echo -e "Generating final figures." >> $condensedLog;

echo -e "\tGenerating octave script to generate combined CNV and SNP analysis figures from previous calculations." >> $logName;
outputName=$projectDirectory"processing4.m";
echo -e "\toutputName = "$outputName >> $logName;

echo -e "function [] = processing4()" > $outputName;
echo -e "\tdiary('"$projectDirectory"octave.final_figs.log');" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $outputName;
echo -e "\tanalyze_CNV_SNPs_RADseq('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing4()" >> $logName;
echo -e "\t|\t\tdiary('"$projectDirectory"octave.final_figs.log');" >> $logName;
echo -e "\t|\t\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $logName;
echo -e "\t|\t\tanalyze_CNV_SNPs_RADseq('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling octave.   (Log will be appended here after completion.)" >> $logName;
$octave_exec $outputName 2>> $logName;
sed 's/^/\t\t|/;' $projectDirectory"octave.final_figs.log" >> $logName;


##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
echo -e "running: " $main_dir"scripts_seqModules/scripts_ddRADseq/cleaning_ddRADseq.sh" $user $project >> $logName;
bash $main_dir"scripts_seqModules/scripts_ddRADseq/cleaning_ddRADseq.sh" $user $project 2>> $logName;


##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
bash queue_end.sh $user $project $main_dir $logName "project.ddRADseq.update_2.sh completed.";
