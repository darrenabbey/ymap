#!/bin/bash -e
#
# project.WGseq.update_2.sh
#
set -e;
## All created files will have permission 760
umask 007;

### define script file locations.
user=$1;
project=$2;
main_dir=$(pwd)"/../../";
script_dir=$(pwd);

echo "";
echo "Input to : project.WGseq.update_2.sh";
echo "\tuser     = "$user;
echo "\tproject  = "$project;
echo "\tmain_dir = "$main_dir;
echo "";

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

echo "#.............................................................................." >> $logName;
echo "Running 'scripts_seqModules/scripts_WGseq/project.WGseq.update_2.sh'" >> $logName;
echo "Variables passed via command-line from 'scripts_seqModules/scripts_WGseq/project.WGseq.update_2.sh' :" >> $logName;
echo "\tuser     = '"$user"'" >> $logName;
echo "\tproject  = '"$project"'" >> $logName;
echo "\tmain_dir = '"$main_dir"'" >> $logName;
echo "#============================================================================== 3" >> $logName;

echo "#=====================================#" >> $logName;
echo "# Setting up locations and variables. #" >> $logName;
echo "#=====================================#" >> $logName;

echo "\tprojectDirectory = '$projectDirectory'" >> $logName;
echo "Setting up for processing." >> $condensedLog;

# Get setup information from project files.
# "genome.txt"
#    first line  => genome
#    second line => hapmap
genome=$(head -n 1 $projectDirectory"genome.txt");
hapmap=$(tail -n 1 $projectDirectory"genome.txt");
dataFormat=$(head -n 1 $projectDirectory"dataFormat.txt");
echo "\t'genome.txt' file entry." >> $logName;
echo "\t\tgenome = '"$genome"'" >> $logName;
if [ "$genome" = "$hapmap" ]
then
	hapmapInUse=0;
else
	echo "\t\thapmap = '"$hapmap"'" >> $logName;
	hapmapInUse=1;
fi
if [ $hapmapInUse = 1 ]
then
	# Determine location of hapmap being used.
	if [ -d $main_dir"users/"$user"/hapmaps/"$hapmap"/" ]
	then
		hapmapDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";
		hapmapUser=$user;
	elif [ -d $main_dir"users/default/hapmaps/"$hapmap"/" ]
	then
		hapmapDirectory=$main_dir"users/default/hapmaps/"$hapmap"/";
		hapmapUser="default";
	fi
	echo "\thapmapDirectory = '"$hapmapDirectory"'" >> $logName;
fi

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
echo "\tgenomeDirectory = '"$genomeDirectory"'" >> $logName;

# Get reference FASTA file name from "reference.txt";
genomeFASTA=$(head -n 1 $genomeDirectory"reference.txt");
echo "\tgenomeFASTA = '"$genomeFASTA"'" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 $projectDirectory"ploidy.txt");
echo "\tploidyEstimate = '"$ploidyEstimate"'" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 $projectDirectory"ploidy.txt");
echo "\tploidyBase = '"$ploidyBase"'" >> $logName;

# Get parent name from "parent.txt" in project directory.
projectParent=$(head -n 1 $projectDirectory"parent.txt");
echo "\tparentProject = '"$projectParent"'" >> $logName;

echo "#============================================================================== 2" >> $logName;

##==============================================================================
## Perform CGH analysis, with GC-correction, on dataset.
##------------------------------------------------------------------------------
echo "#==========================#" >> $logName;
echo "# CGH analysis of dataset. #" >> $logName;
echo "#==========================#" >> $logName;
echo "Preprocessing CNV data.   (~10 min for 1.6 Gbase genome dataset.)" >> $condensedLog;
echo "Analyzing and mapping CNVs." >> $condensedLog;

echo "\tGenerating OCTAVE script to perform CNV analysis of dataset, with GC-correction." >> $logName;
outputName=$projectDirectory"processing1.m";
echo "\toutputName = "$outputName >> $logName;

echo "function [] = processing1()" > $outputName;
echo "\tpkg load statistics;" >> $outputName;
echo "\tdiary('"$projectDirectory"matlab.CNV_and_GCbias.log');" >> $outputName;
echo "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
echo "\tanalyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo "end" >> $outputName;

echo "\t|\tfunction [] = processing1()" >> $logName;
echo "\t|\t    pkg load statistics;" >> $logName;
echo "\t|\t    diary('"$projectDirectory"matlab.CNV_and_GCbias.log');" >> $logName;
echo "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
echo "\t|\t    analyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo "\t|\tend" >> $logName;

echo "\tCalling OCTAVE." >> $logName;
#$matlab_exec -nosplash -r "run "$outputName"; exit;" 2>> $logName;
cd $projectDirectory;
$matlab_exec $outputName;
cd $script_dir;
echo "\tOCTAVE log from CNV analysis." >> $logName;
sed 's/^/\t|/;' $projectDirectory"matlab.CNV_and_GCbias.log" >> $logName;


if [ $hapmapInUse = 0 ]
then
	##==============================================================================
	## Perform SNP/LOH analysis on dataset.
	##------------------------------------------------------------------------------
	if [ "$project" = "$projectParent" ]
	then
		echo "#==========================#" >> $logName;
		echo "# SNP analysis of dataset. #" >> $logName;
		echo "#==========================#" >> $logName;
	else
		echo "#==========================#" >> $logName;
		echo "# LOH analysis of dataset. #" >> $logName;
		echo "#==========================#" >> $logName;
	fi

	echo "Mapping SNPs." >> $condensedLog;
	echo "\tGenerating OCTAVE script to perform SNP analysis of dataset." >> $logName;
	outputName=$projectDirectory"processing3.m";
	echo "\toutputName = "$outputName >> $logName;

	echo "function [] = processing3()" > $outputName;
	echo "    diary('"$projectDirectory"matlab.SNP_analysis.log');" >> $outputName;
	echo "    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
	echo "    analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo "end" >> $outputName;

	echo "\t|\tfunction [] = processing3()" >> $logName;
	echo "\t|\t    diary('"$projectDirectory"matlab.SNP_analysis.log');" >> $logName;
	echo "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
	echo "\t|\t    analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo "\t|\tend" >> $logName;

	echo "\tCalling OCTAVE." >> $logName;
	echo "================================================================================================";
	echo "== SNP analysis ================================================================================";
	echo "================================================================================================";
	#$matlab_exec -nosplash -r "run "$outputName"; exit;" 2>> $logName;
	cd $projectDirectory;
	$matlab_exec $outputName;
	cd $script_dir;
	echo "\tOCTAVE log from SNP analysis." >> $logName;
	sed 's/^/\t|/;' $projectDirectory"matlab.SNP_analysis.log" >> $logName;


	##==============================================================================
	## Generate final figures for dataset.
	##------------------------------------------------------------------------------
	echo "#==================================#" >> $logName;
	echo "# Generate final combined figures. #" >> $logName;
	echo "#==================================#" >> $logName;
	echo "Generating final figures." >> $condensedLog;

	echo "\tGenerating OCTAVE script to generate combined CNV and SNP analysis figures from previous calculations." >> $logName;
	outputName=$projectDirectory"processing4.m";
	echo "\toutputName = "$outputName >> $logName;

	echo "function [] = processing4()" > $outputName;
	echo "\tdiary('"$projectDirectory"matlab.final_figs.log');" >> $outputName;
	echo "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
	echo "\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo "end" >> $outputName;

	echo "\t|\tfunction [] = processing4()" >> $logName;
	echo "\t|\t    diary('"$projectDirectory"matlab.final_figs.log');" >> $logName;
	echo "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
	echo "\t|\t    analyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo "\t|\tend" >> $logName;

	echo "\tCalling OCTAVE.   (Log will be appended here after completion.)" >> $logName;
	echo "================================================================================================";
	echo "== Final figures ===============================================================================";
	echo "================================================================================================";
	#$matlab_exec -nosplash -r "run "$outputName"; exit;" 2>> $logName;
	cd $projectDirectory;
	$matlab_exec $outputName;
	cd $script_dir;
	echo "\tOCTAVE log from final figure generation." >> $logName;
	sed 's/^/\t|/;' $projectDirectory"matlab.final_figs.log" >> $logName;
	echo "finished all processing, moving to Cleaning up intermediate WGseq files" >> $condensedLog;
else
	##==============================================================================
	## Perform SNP/LOH analysis on dataset.
	##------------------------------------------------------------------------------
	if [ hapmapUsed = 1 ]
	then
		echo "#===========================================#" >> $logName;
		echo "# SNP/LOH analysis of dataset, with hapmap. #" >> $logName;
		echo "#===========================================#" >> $logName;
	else
		echo "#==============================================#" >> $logName;
		echo "# SNP/LOH analysis of dataset, with reference. #" >> $logName;
		echo "#==============================================#" >> $logName;
	fi;

	echo "Mapping SNPs." >> $condensedLog;
	echo "\t\tGenerating OCTAVE script to perform SNP analysis of dataset." >> $logName;
	outputName=$projectDirectory"processing3.m";
	echo "\t\toutputName = "$outputName >> $logName;

	echo "function [] = processing3()" > $outputName;
	echo "    diary('"$projectDirectory"matlab.SNP_analysis.log');" >> $outputName;
	echo "    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
	echo "    analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo "end" >> $outputName;

	echo "\t|\tfunction [] = processing3()" >> $logName;
	echo "\t|\t    diary('"$projectDirectory"matlab.SNP_analysis.log');" >> $logName;
	echo "\t|\t    cd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
	echo "\t|\t    analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo "\t|\tend" >> $logName;

	echo "\t\tCalling OCTAVE." >> $logName;
	echo "================================================================================================";
	echo "== SNP analysis ================================================================================";
	echo "================================================================================================";
	#$matlab_exec -nosplash -r "run "$outputName"; exit;" 2>> $logName;
	cd $projectDirectory;
	$matlab_exec $outputName;
	cd $script_dir;
	echo "\t\tOCTAVE log from SNP analysis." >> $logName;
	sed 's/^/\t\t\t|/;' $projectDirectory"matlab.SNP_analysis.log" >> $logName;


	##==============================================================================
	## Generate final figures for dataset.
	##------------------------------------------------------------------------------
	echo "#==================================#" >> $logName;
	echo "# Generate final combined figures. #" >> $logName;
	echo "#==================================#" >> $logName;
	echo "Generating final figures." >> $condensedLog;

	echo "\t\tGenerating OCTAVE script to generate combined CNV and SNP analysis figures from previous calculations." >> $logName;
	outputName=$projectDirectory"processing4.m";
	echo "\t\toutputName = "$outputName >> $logName;

	echo "function [] = processing4()" > $outputName;
	echo "\tdiary('"$projectDirectory"matlab.final_figs.log');" >> $outputName;
	echo "\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $outputName;
	echo "\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo "end" >> $outputName;

	echo "\t|\tfunction [] = processing4()" >> $logName;
	echo "\t|\t\tdiary('"$projectDirectory"matlab.final_figs.log');" >> $logName;
	echo "\t|\t\tcd "$main_dir"scripts_seqModules/scripts_WGseq;" >> $logName;
	echo "\t|\t\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo "\t|\tend" >> $logName;

	echo "\t\tCalling OCTAVE.   (Log will be appended here after completion.)" >> $logName;
	echo "================================================================================================";
	echo "== CNV/SNP/LOH figure generation ===============================================================";
	echo "================================================================================================";
	#$matlab_exec -nosplash -r "run "$outputName"; exit;" 2>> $logName;
	cd $projectDirectory;
	$matlab_exec $outputName;
	cd $script_dir;
	echo "\t\tOCTAVE log from final figure generation." >> $logName;
	sed 's/^/\t\t|/;' $projectDirectory"matlab.final_figs.log" >> $logName;
fi

##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
echo "running: " $main_dir"scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" $user $project $main_dir >> $logName;
sh $main_dir"scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" $user $project $main_dir 2>> $logName;
