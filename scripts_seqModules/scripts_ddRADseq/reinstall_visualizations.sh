#!/bin/bash
#
# project.ddRADseq.hapmap.install_4.sh
#
set -e;

## All created files will have permission 760
umask 007;

user=$1;
#user='darren1';

project=$2;
#project='SC5314_ddRADseq';
#project='9442_ddRADseq';
#project='11461_ddRADseq';
#project='11461_ddRADseq_hapmap';

main_dir=$(pwd)"/../../";

##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";
condensedLog=$projectDirectory"condensed_log.txt";

# load local installed program location variables.
. $main_dir/local_installed_programs.sh;

# Get parent name used, from project's "parent.txt" file.
parent=$(head -n 1 $projectDirectory"parent.txt");
echo -e "\tparent = '"$parent"'" >> $logName;
# Determine location of parent.
if [[ -d $main_dir"users/"$user"/projects/"$parent"/" ]]
then
	parentDirectory=$main_dir"users/"$user"/projects/"$parent"/";
	parentUser=$user;
elif [[ -d $main_dir"users/default/projects/"$parent"/" ]]
then
	parentDirectory=$main_dir"users/default/projects/"$parent"/";
	parentUser="default";
fi
echo -e "\tparentDirectory = '"$parentDirectory"'" >> $logName;

# Get genome and hapmap names used, from project's "genome.txt" file.
genome=$(head -n 1 $projectDirectory"genome.txt");
hapmap=$(tail -n 1 $projectDirectory"genome.txt");
if [[ "$genome" = "$hapmap" ]]
then
	hapmapInUse=0;
else
	# Determine location of hapmap being used.
	if [[ -d $main_dir"users/"$user"/hapmaps/"$hapmap"/" ]]
	then
		hapmapDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";
		cp $hapmapDirectory"colors.txt" $projectDirectory"colors.txt";
		echo -e "\thapmap          = '"$hapmap"'" >> $logName;
		echo -e "\thapmapDirectory = '"$hapmapDirectory"'" >> $logName;
		hapmapUser=$user;
		hapmapInUse=1;
	elif [[ -d $main_dir"users/default/hapmaps/"$hapmap"/" ]]
	then
		hapmapDirectory=$main_dir"users/default/hapmaps/"$hapmap"/";
		cp $hapmapDirectory"colors.txt" $projectDirectory"colors.txt";
		echo -e "\thapmap          = '"$hapmap"'" >> $logName;
		echo -e "\thapmapDirectory = '"$hapmapDirectory"'" >> $logName;
		hapmapUser="default";
		hapmapInUse=1;
	else
		hapmapInUse=0;
	fi
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
echo -e "\tgenome          = '"$genome"'" >> $logName;
echo -e "\tgenomeDirectory = '"$genomeDirectory"'" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyEstimate = '"$ploidyEstimate"'" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyBase = '"$ploidyBase"'" >> $logName;

reflocation=$main_dir"users/"$genomeUser"/genomes/"$genome"/";                 # Directory where FASTA file is kept.
FASTA=`sed -n 1,1'p' $reflocation"reference.txt"`;                             # Name of FASTA file.
FASTAname=$(echo $FASTA | sed 's/.fasta//g');                                  # name of genome file, without file type.
RestrctionEnzymes=`sed -n 1,1'p' $projectDirectory"restrictionEnzymes.txt"`;   # Name of restriction enxyme list file.
ddRADseq_FASTA=$FASTAname"."$RestrctionEnzymes".fasta";                        # Name of digested reference for ddRADseq analysis, using chosen restriction enzymes.


##==============================================================================
## Generate script to re-run terminal visualization octave code.
##------------------------------------------------------------------------------
echo -e "#======================================#" >> $logName;
echo -e "# Re-perform visualization of dataset. #" >> $logName;
echo -e "#======================================#" >> $logName;

echo -e "\tGenerating octave script to perform CNV analysis of dataset, with GC-correction." >> $logName;
outputName=$projectDirectory"processing_Rerun.m";
echo -e "\toutputName = "$outputName >> $logName;

echo -e "function [] = processing_Rerun()" > $outputName;
echo -e "\tdiary('"$projectDirectory"octave.rerun_visualization.log');" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $outputName;


echo -e "\tanalyze_CNVs_RADseq_3(  '$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;

echo -e "\tanalyze_SNPs_RADseq(    '$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;

echo -e "\tanalyze_CNV_SNPs_RADseq('$main_dir','$user','$genomeUser','$project','$parent','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;


echo -e "end" >> $outputName;

echo -e "\tCalling octave." >> $logName;
$octave_exec $outputName  2>> $logName;
echo -e "\toctave log from redo of visualization.." >> $logName;
sed 's/^/\t\t|/;' $projectDirectory"octave.rerun_visualization.log" >> $logName;
