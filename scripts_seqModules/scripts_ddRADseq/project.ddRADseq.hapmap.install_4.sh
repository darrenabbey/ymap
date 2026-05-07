#!/bin/bash -e
#
# project.ddRADseq.hapmap.install_4.sh
#
set -e;
## All created files will have permission 760
umask 007;

### define script file locations.
user=$1;
project=$2;
hapmap=$3;
main_dir=$(pwd)"/../../";

# load local installed program location variables.
. $main_dir/local_installed_programs.sh;


##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";
condensedLog=$projectDirectory"condensed_log.txt";


## Error handling in case something crashes.
trap 'bash queue_end.sh $user $project $main_dir $logName "Something went wrong. project.ddRADseq.hapmap.install_4.sh:$LINENO"; echo -e "Something went wrong. project.ddRADseq.hapmap.install_4.sh:$LINENO" > $projectDirectory"error.txt"; exit 1;' ERR;


# Get parent name used from project's "parent.txt" file.
parent=$(head -n 1 $projectDirectory"parent.txt");
echo -e "\tparent = '"$parent"'" >> $logName;
# Determine location of parent.
if [ -d $main_dir"users/"$user"/projects/"$parent"/" ]
then
	parentDirectory=$main_dir"users/"$user"/projects/"$parent"/";
	parentUser=$user;
elif [ -d $main_dir"users/default/projects/"$parent"/" ]
then
	parentDirectory=$main_dir"users/default/projects/"$parent"/";
	parentUser="default";
fi
echo -e "\tparentDirectory = '"$parentDirectory"'" >> $logName;


# Get genome name used from project's "genome.txt" file.
genome=$(head -n 1 $projectDirectory"genome.txt");
echo -e "\tgenome = '"$genome"'" >> $logName;
# Determine location of genome being used.
if [ -d $main_dir"users/"$user"/genomes/"$genome"/" ]
then
	genomeDirectory=$main_dir"users/"$user"/genomes/"$genome"/";
	genomeUser=$user;
elif [ -d $main_dir"users/default/genomes/"$genome"/" ]
then
	genomeDirectory=$main_dir"users/default/genomes/"$genome"/";
	genomeUser="default";
fi
echo -e "\tgenomeDirectory = '"$genomeDirectory"'" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyEstimate = '"$ploidyEstimate"'" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyBase = '"$ploidyBase"'" >> $logName;

# Determine location of hapmap being used.
if [ -d $main_dir"users/"$user"/hapmaps/"$hapmap"/" ]
then
	hapmapDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";
	hapmapUser=$user;
	hapmapUsed=1
elif [ -d $main_dir"users/default/hapmaps/"$hapmap"/" ]
then
	hapmapDirectory=$main_dir"users/default/hapmaps/"$hapmap"/";
	hapmapUser="default";
	hapmapUsed=1;
else
	hapmapUsed=0;
fi
echo -e "\thapmapDirectory = '"$hapmapDirectory"'" >> $logName;

cp $hapmapDirectory"colors.txt" $projectDirectory"colors.txt";


reflocation=$main_dir"users/"$genomeUser"/genomes/"$genome"/";                 # Directory where FASTA file is kept.
FASTA=`sed -n 1,1'p' $reflocation"reference.txt"`;                             # Name of FASTA file.
FASTAname=$(echo $FASTA | sed 's/.fasta//g');                                  # name of genome file, without file type.
RestrctionEnzymes=`sed -n 1,1'p' $projectDirectory"restrictionEnzymes.txt"`;   # Name of restriction enxyme list file.
ddRADseq_FASTA=$FASTAname"."$RestrctionEnzymes".fasta";                        # Name of digested reference for ddRADseq analysis, using chosen restriction enzymes.


##==============================================================================
## Preprocess ddRADseq CNV information.
##------------------------------------------------------------------------------
if [ -f $projectDirectory"preprocessed_CNVs.ddRADseq.txt" ]
then
	echo -e "\tCNV data already preprocessed with python script : 'py/dataset_process_for_CNV_analysis.ddRADseq.py'" >> $logName;
else
	echo -e "\tPreprocessing CNV data with python script : 'py/dataset_process_for_CNV_analysis.ddRADseq.py'" >> $logName;
	$python_exec $main_dir"scripts_seqModules/scripts_ddRADseq/dataset_process_for_CNV_analysis.ddRADseq.py" $user $project $genome $genomeUser $main_dir $RestrctionEnzymes $logName  > $projectDirectory"preprocessed_CNVs.ddRADseq.txt" 2>> $logName;
	echo -e "\tpre-processing complete." >> $logName;
fi


##==============================================================================
## Preprocess ddRADseq SNP information.
##------------------------------------------------------------------------------
if [ -f $projectDirectory"preprocessed_SNPs.ddRADseq.txt" ]
then
	echo -e "\tParent or hapmap data already preprocessed with python script: 'scripts_seqModules/scripts_hapmaps/hapmap.preprocess_parent.py'" >> $logName;
	echo -e "\tSNP data already preprocessed with python script: 'scripts_seqModules/scripts_ddRADseq/dataset_process_for_SNP_analysis.ddRADseq.py'" >> $logName;
else
	if [ -f $parentDirectory"putative_SNPs_v4.txt" ]
	then
		echo -e "\tParent SNP data already decompressed." >> $logName;
		cp $parentDirectory"putative_SNPs_v4.txt" $projectDirectory"SNPdata_parent.txt";
	else
		echo -e "\tDecompressing parent SNP data." >> $logName;
		parentSnpDataTempDir=$projectDirectory"/SNPdata_parent_temp/";
		mkdir $parentSnpDataTempDir;
		unzip -j $parentDirectory"putative_SNPs_v4.zip" -d $parentSnpDataTempDir;
		mv $parentSnpDataTempDir"putative_SNPs_v4.txt" $projectDirectory"SNPdata_parent.txt";
		rmdir $parentSnpDataTempDir;
	fi

	# preprocess hapmap/parent SNP data.
	echo -e "\tProcessing SNP data from parent or hapmap with python script : 'scripts_seqModules/scripts_hapmaps/hapmap.preprocess_parent.py'" >> $logName;
	$python_exec $main_dir"scripts_seqModules/scripts_hapmaps/hapmap.preprocess_parent.py" $genome $genomeUser $project $user $parent $parentUser $main_dir LOH > $projectDirectory"SNPdata_parent.temp.txt" 2>> $logName;
	rm $projectDirectory"SNPdata_parent.txt";
	mv $projectDirectory"SNPdata_parent.temp.txt" $projectDirectory"SNPdata_parent.txt";

	# preprocess dataset SNP data.
	echo -e "\tProcessing SNP data with python script: 'scripts_seqModules/scripts_ddRADseq/dataset_process_for_SNP_analysis.ddRADseq.py'" >> $logName;
	$python_exec $main_dir"scripts_seqModules/scripts_ddRADseq/dataset_process_for_SNP_analysis.ddRADseq.py" $genome $genomeUser $parent $parentUser $project $user $main_dir $RestrctionEnzymes $logName LOH > $projectDirectory"preprocessed_SNPs.ddRADseq.txt" 2>> $logName;
	chmod 0666 $projectDirectory"preprocessed_SNPs.ddRADseq.txt";
	echo -e "\tpre-processing complete." >> $logName;
fi


##==============================================================================
## Perform CGH analysis, with GC-correction, on dataset.
##------------------------------------------------------------------------------
echo -e "#==========================#" >> $logName;
echo -e "# CGH analysis of dataset. #" >> $logName;
echo -e "#==========================#" >> $logName;
echo -e "Preprocessing CNV data.   (~10 min for 1.6 Gbase genome dataset.)" >> $condensedLog;

if [ -f $projectDirectory"corrected_CNV.project.mat" ]
then
	echo -e "\tCNV analysis already complete." >> $logName;
else
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
fi


##==============================================================================
## Perform ChARM analysis of dataset.
##------------------------------------------------------------------------------
echo -e "#============================#" >> $logName;
echo -e "# ChARM analysis of dataset. #" >> $logName;
echo -e "#============================#" >> $logName;
echo -e "Analyzing CNV edges." >> $condensedLog;

if [ -f $projectDirectory"Common_ChARM.mat" ]
then
	echo -e "\tChARM analysis already complete." >> $logName;
else
	echo -e "\tGenerating octave script to perform ChARM analysis of dataset." >> $logName;
	outputName=$projectDirectory"processing2.m";
	echo -e "\toutputName = "$outputName >> $logName;

	echo -e "function [] = processing2()" > $outputName;
	echo -e "\tdiary('"$projectDirectory"octave.ChARM.log');" >> $outputName;
	echo -e "\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $outputName;
	echo -e "\tChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing2()" >> $logName;
	echo -e "\t|\t\tdiary('"$projectDirectory"octave.ChARM.log');" >> $logName;
	echo -e "\t|\t\tcd "$main_dir"scripts_seqModules/scripts_ddRADseq;" >> $logName;
	echo -e "\t|\t\tChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\tCalling octave." >> $logName;
	echo -e "================================================================================================";
	echo -e "== ChARM analysis ==============================================================================";
	echo -e "================================================================================================";
	$octave_exec $outputName 2>> $logName;
	echo -e "\toctave log from ChARM analysis." >> $logName;
	sed 's/^/\t\t|/;' $projectDirectory"octave.ChARM.log" >> $logName;
fi


##==============================================================================
## Perform SNP/LOH analysis on dataset.   ...must be redone for ddRADseq, specificially.
##------------------------------------------------------------------------------
if [ "$project" = "$parent" ]
then
    echo -e "#==========================#" >> $logName;
    echo -e "# LOH analysis of dataset. #" >> $logName;
    echo -e "#==========================#" >> $logName;
    echo -e "Preprocessing SNP data.   (~4 hrs for LOH analysis of 1.6 Gbase genome dataset.)" >> $condensedLog;
else
    echo -e "#==========================#" >> $logName;
    echo -e "# SNP analysis of dataset. #" >> $logName;
    echo -e "#==========================#" >> $logName;
    echo -e "Preprocessing SNP data.   (~20 min for SNP analysis of 1.6 Gbase genome dataset.)" >> $condensedLog;
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


##==============================================================================
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
bash queue_end.sh $user $project $main_dir $logName "project.ddRADseq.hapmap.install_4.sh completed.";
