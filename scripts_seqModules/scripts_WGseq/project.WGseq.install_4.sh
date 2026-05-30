#!/bin/bash
#
# project.WGseq.install_4.sh
#
set -e;

## All created files will have permission 760
umask 007;

user=$1;
project=$2;
main_dir=$(pwd)"/../../";
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";

## Error handling in case something crashes.
trap 'bash queue_end.sh $user $project $main_dir $logName "Something went wrong. project.WGseq.install_4.sh:$LINENO"; install /dev/null $projectDirectory"error.txt"; echo -e "Something went wrong. project.WGseq.install_4.sh:$LINENO" > $projectDirectory"error.txt"; exit 1;' ERR;

script_dir=$(pwd);

echo -e "";
echo -e "Input to : project.WGseq.install_4.sh";
echo -e "\tuser     = "$user;
echo -e "\tproject  = "$project;
echo -e "\tmain_dir = "$main_dir;
echo -e "";

# load local installed program location variables.
. $main_dir"local_installed_programs.sh";

##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------

condensedLog=$projectDirectory"condensed_log.txt";

# Get genome name used from project's "genome.txt" file.
genome=$(head -n 1 $projectDirectory"genome.txt");
echo -e "\tgenome = '"$genome"'" >> $logName;

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

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyEstimate = '"$ploidyEstimate"'" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 $projectDirectory"ploidy.txt");
echo -e "\tploidyBase = '"$ploidyBase"'" >> $logName;

# Get parent name from "parent.txt" in project directory.
projectParent=$(head -n 1 $projectDirectory"parent.txt");
echo -e "\tparentProject = '"$projectParent"'" >> $logName;

# Determine location of project being used.
if [[ -d $main_dir"users/"$user"/projects/"$projectParent"/" ]]
then
    projectParentDirectory=$main_dir"users/"$user"/projects/"$projectParent"/";
    projectParentUser=$user;
elif [[ -d $main_dir"users/default/projects/"$projectParent"/" ]]
then
    projectParentDirectory=$main_dir"users/default/projects/"$projectParent"/";
    projectParentUser="default";
fi
echo -e "\tprojectParentDirectory = '"$projectParentDirectory"'" >> $logName;



##==============================================================================
## Perform CNV analysis, with GC-correction, on dataset.
##------------------------------------------------------------------------------
echo -e "#==========================#" >> $logName;
echo -e "# CNV analysis of dataset. #" >> $logName;
echo -e "#==========================#" >> $logName;
echo -e "Preprocessing CNV data." >> $condensedLog;

if [[ -f $projectDirectory"preprocessed_CNVs.txt" ]]
then
	echo -e "\tCNV data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py'" >> $logName;
else
	install /dev/null $projectDirectory"preprocessed_CNVs.txt";
	echo -e "\tPreprocessing CNV data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py'" >> $logName;
	$python_exec $main_dir"scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py" $user $project $genome $genomeUser $main_dir $logName  > $projectDirectory"preprocessed_CNVs.txt" 2>> $logName;
	echo -e "\tpre-processing complete." >> $logName;
fi

echo -e "Analyzing and mapping CNVs." >> $condensedLog;

echo -e "\tGenerating OCTAVE script to perform CNV analysis of dataset, with GC-correction." >> $logName;
outputName=$projectDirectory"processing1.m";
install /dev/null $outputName;
install /dev/null $projectDirectory"octave.CNV_and_GCbias.log";
echo -e "\toutputName = "$outputName >> $logName;
echo -e "function [] = processing1()" > $outputName;
echo -e "\tpkg load statistics;" >> $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary '"$projectDirectory"octave.CNV_and_GCbias.log';" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
echo -e "\tanalyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing1()" >> $logName;
echo -e "\t|\t    pkg load statistics;" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('"$projectDirectory"octave.CNV_and_GCbias.log');" >> $logName;
echo -e "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
echo -e "\t|\t    analyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling OCTAVE." >> $logName;
cd $projectDirectory;
$octave_exec $outputName;
cd $script_dir;


echo -e "\tOCTAVE log from CNV analysis." >> $logName;
#sed 's/^/\t|/;' $projectDirectory"octave.CNV_and_GCbias.log" >> $logName;
cat $projectDirectory"octave.CNV_and_GCbias.log" >> $logName;


##==============================================================================
## Perform ChARM analysis of dataset.
##------------------------------------------------------------------------------
echo -e "#============================#" >> $logName;
echo -e "# ChARM analysis of dataset. #" >> $logName;
echo -e "#============================#" >> $logName;
echo -e "Analyzing CNV edges." >> $condensedLog;

if [[ -f $projectDirectory"Common_ChARM.mat" ]]
then
	echo -e "\tChARM analysis already completed." >> $logName;
else
	echo -e "\tGenerating OCTAVE script to perform ChARM analysis of dataset." >> $logName;
	outputName=$projectDirectory"processing2.m";
	install /dev/null $outputName;
	install /dev/null $projectDirectory"octave.ChARM.log";
	echo -e "\toutputName = "$outputName >> $logName;

	##echo -e "function [] = processing2()" > $outputName;
	echo -e "function processing2" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('"$projectDirectory"octave.ChARM.log');" >> $outputName;
	echo -e "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
	echo -e "\tChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');" >> $outputName;
	echo -e "end" >> $outputName;

	##echo -e "\t|\tfunction [] = processing2()" >> $logName;
	echo -e "\t|\tfunction processing2" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('"$projectDirectory"octave.ChARM.log');" >> $logName;
	echo -e "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
	echo -e "\t|\t    ChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\tCalling OCTAVE." >> $logName;
	echo -e "================================================================================================";
	echo -e "== ChARM analysis ==============================================================================";
	echo -e "================================================================================================";
	cd $projectDirectory;
	$octave_exec $outputName;
	cd $script_dir;
	echo -e "\tOCTAVE log from ChARM analysis." >> $logName;
	sed 's/^/\t|/;' $projectDirectory"octave.ChARM.log" >> $logName;
fi

##==============================================================================
## Perform SNP/LOH analysis on dataset.
##------------------------------------------------------------------------------
if [[ "$project" = "$projectParent" ]]
then
	echo -e "#==========================#" >> $logName;
	echo -e "# SNP analysis of dataset. #" >> $logName;
	echo -e "#==========================#" >> $logName;
	echo -e "Preprocessing SNP data." >> $condensedLog;
else
	echo -e "#==========================#" >> $logName;
	echo -e "# LOH analysis of dataset. #" >> $logName;
	echo -e "#==========================#" >> $logName;
	echo -e "Preprocessing SNP data, with reference." >> $condensedLog;
fi

if [[ -f $projectDirectory"preprocessed_SNPs.txt" ]]
then
	echo -e "\tSNP data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
else
	install /dev/null $projectDirectory"preprocessed_SNPs.txt";
	echo -e "\tPreprocessing SNP data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
	if [[ -f $projectParentDirectory"putative_SNPs_v4.txt" ]]
	then
		echo -e "\tParent SNP data already decompressed." >> $logName;
		cp $projectParentDirectory"putative_SNPs_v4.txt" $projectDirectory"SNPdata_parent.txt";
	else
		echo -e "\tDecompressing parent SNP data." >> $logName;
		pigz -dc $projectParentDirectory"putative_SNPs_v4.zip" > $projectDirectory"SNPdata_parent.txt";
		#parentSnpDataTempDir=$projectDirectory"/SNPdata_parent_temp/";
		#mkdir $parentSnpDataTempDir;
		#unzip -j $projectParentDirectory"putative_SNPs_v4.zip" -d $parentSnpDataTempDir;
		#mv $parentSnpDataTempDir"putative_SNPs_v4.txt" $projectDirectory"SNPdata_parent.txt";
		#rmdir $parentSnpDataTempDir;
	fi

	# preprocess parent for comparison.
	$python_exec $main_dir"scripts_seqModules/scripts_hapmaps/hapmap.preprocess_parent.py" $genome $genomeUser $project $user $projectParent $projectParentUser $main_dir LOH > $projectDirectory"SNPdata_parent.temp.txt" 2>> $logName;

	rm $projectDirectory"SNPdata_parent.txt";
	mv $projectDirectory"SNPdata_parent.temp.txt" $projectDirectory"SNPdata_parent.txt";

	$python_exec $main_dir"scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py" $genome $genomeUser $projectParent $projectParentUser $project $user $main_dir $logName LOH > $projectDirectory"preprocessed_SNPs.txt" 2>> $logName;
	echo -e "\tpre-processing complete." >> $logName;
fi

echo -e "Mapping SNPs." >> $condensedLog;
echo -e "\tGenerating OCTAVE script to perform SNP analysis of dataset." >> $logName;
outputName=$projectDirectory"processing3.m";
install /dev/null $outputName;
install /dev/null $projectDirectory"octave.SNP_analysis.log";
echo -e "\toutputName = "$outputName >> $logName;

echo -e "function processing3" > $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary('"$projectDirectory"octave.SNP_analysis.log');" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
echo -e "\tanalyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction processing3" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('"$projectDirectory"octave.SNP_analysis.log');" >> $logName;
echo -e "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
echo -e "\t|\t    analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling OCTAVE." >> $logName;
echo -e "================================================================================================";
echo -e "== SNP analysis ================================================================================";
echo -e "================================================================================================";
cd $projectDirectory;
$octave_exec $outputName;
cd $script_dir;
echo -e "\tOCTAVE log from SNP analysis." >> $logName;
sed 's/^/\t|/;' $projectDirectory"octave.SNP_analysis.log" >> $logName;


##==============================================================================
## Generate final figures for dataset.
##------------------------------------------------------------------------------
echo -e "#==================================#" >> $logName;
echo -e "# Generate final combined figures. #" >> $logName;
echo -e "#==================================#" >> $logName;
echo -e "Generating final figures." >> $condensedLog;

echo -e "\tGenerating OCTAVE script to generate combined CNV and SNP analysis figures from previous calculations." >> $logName;
outputName=$projectDirectory"processing4.m";
install /dev/null $outputName;
install /dev/null $projectDirectory"octave.final_figs.log";
echo -e "\toutputName = "$outputName >> $logName;

echo -e "function processing4" > $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary('"$projectDirectory"octave.final_figs.log');" >> $outputName;
echo -e "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
echo -e "\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction processing4" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('"$projectDirectory"octave.final_figs.log');" >> $logName;
echo -e "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
echo -e "\t|\t    analyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling OCTAVE.   (Log will be appended here after completion.)" >> $logName;
echo -e "================================================================================================";
echo -e "== Final figures ===============================================================================";
echo -e "================================================================================================";
cd $projectDirectory;
$octave_exec $outputName;
cd $script_dir;
echo -e "\tOCTAVE log from final figure generation." >> $logName;
sed 's/^/\t|/;' $projectDirectory"octave.final_figs.log" >> $logName;
echo -e "finished all processing, moving to Cleaning up intermediate WGseq files" >> $condensedLog;


##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
chmod 774 $projectDirectory* || true;
echo -e "running: " $main_dir"scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" $user $project $main_dir >> $logName;
bash $main_dir"scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" $user $project $main_dir 2>> $logName;


##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
bash queue_end.sh $user $project $main_dir $logName "project.WGseq.install_4.sh completed.";
