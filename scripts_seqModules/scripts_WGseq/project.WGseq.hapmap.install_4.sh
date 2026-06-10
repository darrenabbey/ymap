#!/bin/bash
#
# project.WGseq.hapmap.install_4.sh
#
set -e;

## All created files will have permission 760
umask 007;

user="$1";
project="$2";
hapmap="$3";
main_dir="$4";
projectDirectory="$main_dir/users/$user/projects/$project";
logName="$projectDirectory/process_log.txt";

## Error handling in case something crashes.
trap 'cd $main_dir"/scripts_seqModules/scripts_WGseq/"; bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "Something went wrong. project.WGseq.hapmap.install_4.sh:$LINENO"; install /dev/null "$projectDirectory/error.txt"; echo -e "Something went wrong. project.WGseq.hapmap.install_4.sh:$LINENO" > "$projectDirectory/error.txt"; cd $main_dir; exit 1;' ERR;

script_dir=$(pwd);

# load local installed program location variables.
. $main_dir/local_installed_programs.sh;

echo -e "";
echo -e "Input to : project.WGseq.hapmap.install_4.sh";
echo -e "\tuser     = $user";
echo -e "\tproject  = $project";
echo -e "\thapmap   = $hapmap";
echo -e "\tmain_dir = $main_dir";
echo -e "";


##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------

condensedLog="$projectDirectory/condensed_log.txt";

# Get genome name used from project's "genome.txt" file.
genome=$(head -n 1 "$projectDirectory/genome.txt");
echo -e "\tgenome = $genome" >> $logName;

# Determine location of genome being used.
if [[ -d "$main_dir/users/$user/genomes/$genome" ]]
then
    genomeDirectory="$main_dir/users/$user/genomes/$genome";
    genomeUser="$user";
elif [[ -d "$main_dir/users/default/genomes/$genome" ]]
then
    genomeDirectory="$main_dir/users/default/genomes/$genome";
    genomeUser="default";
fi
echo -e "\tgenomeDirectory = $genomeDirectory" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 "$projectDirectory/ploidy.txt");
echo -e "\tploidyEstimate = $ploidyEstimate" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 "$projectDirectory/ploidy.txt");
echo -e "\tploidyBase = $ploidyBase" >> $logName;

# Determine location of hapmap being used.
if [[ -d "$main_dir/users/$user/hapmaps/$hapmap" ]]
then
	hapmapDirectory="$main_dir/users/$user/hapmaps/$hapmap";
	hapmapUser="$user";
	hapmapUsed=1
elif [[ -d "$main_dir/users/default/hapmaps/$hapmap" ]]
then
	hapmapDirectory="$main_dir/users/default/hapmaps/$hapmap";
	hapmapUser="default";
	hapmapUsed=1;
else
	hapmapUsed=0;
fi
echo -e "\thapmapDirectory = $hapmapDirectory" >> $logName;

cp "$hapmapDirectory/colors.txt" "$projectDirectory/colors.txt";
chmod 774 "$projectDirectory/colors.txt";


##==============================================================================
## Perform CNV analysis, with GC-correction, on dataset.
##------------------------------------------------------------------------------
echo -e "#==========================#" >> $logName;
echo -e "# CNV analysis of dataset. #" >> $logName;
echo -e "#==========================#" >> $logName;
echo -e "Preprocessing CNV data." >> $condensedLog;

if [[ -f "$projectDirectory/preprocessed_CNVs.txt" ]]
then
	echo -e "\t\tCNV data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py'" >> $logName;
else
	#install /dev/null "$projectDirectory/preprocessed_CNVs.txt";
	echo -e "\t\tPreprocessing CNV data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py'" >> $logName;
	$python_exec "$main_dir/scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py" "$user" "$project" "$genome" "$genomeUser" "$main_dir" "$logName"  > "$projectDirectory/preprocessed_CNVs.txt" 2>> $logName;
	echo -e "\t\tpre-processing complete." >> $logName;
fi

echo -e "Analyzing and mapping CNVs." >> $condensedLog;

echo -e "\t\tGenerating OCTAVE script to perform CNV analysis of dataset, with GC-correction." >> $logName;
outputName="$projectDirectory/processing1.m";
install /dev/null "$outputName";
install /dev/null "$projectDirectory/octave.CNV_and_GCbias.log";
echo -e "\t\toutputName = $outputName" >> $logName;

echo -e "function [] = processing1()" > $outputName;
echo -e "\tpkg load io;" >> $outputName;
echo -e "\tpkg load statistics;" >> $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary('$projectDirectory/octave.CNV_and_GCbias.log');" >> $outputName;
echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
echo -e "\tanalyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing1()" >> $logName;
echo -e "\t|\t    pkg load io;" >> $logName;
echo -e "\t|\t    pkg load statistics;" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('$projectDirectory/octave.CNV_and_GCbias.log');" >> $logName;
echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
echo -e "\t|\t    analyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\t\tCalling OCTAVE." >> $logName;
cd "$projectDirectory";
$octave_exec "$outputName";
cd "$script_dir";
echo -e "\t\tOCTAVE log from CNV analysis." >> $logName;
sed 's/^/\t\t\t|/;' "$projectDirectory/octave.CNV_and_GCbias.log" >> $logName;


##==============================================================================
## Perform ChARM analysis of dataset.
##------------------------------------------------------------------------------
echo -e "#============================#" >> $logName;
echo -e "# ChARM analysis of dataset. #" >> $logName;
echo -e "#============================#" >> $logName;
echo -e "Analyzing CNV edges." >> $condensedLog;

if [[ -f "$projectDirectory/Common_ChARM.mat" ]]
then
	echo -e "\t\tChARM analysis already completed." >> $logName;
else
	echo -e "\t\tGenerating OCTAVE script to perform ChARM analysis of dataset." >> $logName;
	outputName="$projectDirectory/processing2.m";
	install /dev/null "$outputName";
	install /dev/null "$projectDirectory/octave.ChARM.log";
	echo -e "\t\toutputName = "$outputName >> $logName;

	echo -e "function [] = processing2()" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('$projectDirectory/octave.ChARM.log');" >> $outputName;
	echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
	echo -e "\tChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing2()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('$projectDirectory/octave.ChARM.log');" >> $logName;
	echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
	echo -e "\t|\t    ChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\t\tCalling OCTAVE." >> $logName;
	echo -e "================================================================================================";
	echo -e "== ChARM analysis ==============================================================================";
	echo -e "================================================================================================";
	cd "$projectDirectory";
	$octave_exec "$outputName";
	cd "$script_dir";
	echo -e "\t\tOCTAVE log from ChARM analysis." >> $logName;
	sed 's/^/\t\t\t|/;' "$projectDirectory/octave.ChARM.log" >> $logName;
fi


##==============================================================================
## Perform SNP/LOH analysis on dataset.
##------------------------------------------------------------------------------
if [[ hapmapUsed = 1 ]]
then
	echo -e "#===========================================#" >> $logName;
	echo -e "# SNP/LOH analysis of dataset, with hapmap. #" >> $logName;
	echo -e "#===========================================#" >> $logName;
	echo -e "Preprocessing SNP data, with hapmap." >> $condensedLog;
else
	echo -e "#==============================================#" >> $logName;
	echo -e "# SNP/LOH analysis of dataset, with reference. #" >> $logName;
	echo -e "#==============================================#" >> $logName;
	echo -e "Preprocessing SNP data, with reference." >> $condensedLog;
fi;


if [[ -f "$projectDirectory/preprocessed_SNPs.txt" ]]
then
	echo -e "\t\tSNP data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
else
	#install /dev/null "$projectDirectory/preprocessed_SNPs.txt";
	echo -e "\t\tPreprocessing SNP data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;

	$python_exec "$main_dir/scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py" "$genome" "$genomeUser" "$hapmap" "$hapmapUser" "$project" "$user" "$main_dir" "$logName" hapmap  > "$projectDirectory/preprocessed_SNPs.txt" 2>> $logName;
	echo -e "\t\tpre-processing complete." >> $logName;
fi

echo -e "Mapping SNPs." >> $condensedLog;
echo -e "\t\tGenerating OCTAVE script to perform SNP analysis of dataset." >> $logName;
outputName="$projectDirectory/processing3.m";
install /dev/null "$outputName";
install /dev/null "$projectDirectory/octave.SNP_analysis.log";
echo -e "\t\toutputName = $outputName" >> $logName;

echo -e "function [] = processing3()" > $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary('$projectDirectory/octave.SNP_analysis.log');" >> $outputName;
echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
echo -e "\tanalyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing3()" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('$projectDirectory/octave.SNP_analysis.log');" >> $logName;
echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
echo -e "\t|\t    analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\t\tCalling OCTAVE." >> $logName;
echo -e "================================================================================================";
echo -e "== SNP analysis ================================================================================";
echo -e "================================================================================================";
cd "$projectDirectory";
$octave_exec "$outputName";
cd "$script_dir";
echo -e "\t\tOCTAVE log from SNP analysis." >> $logName;
sed 's/^/\t\t\t|/;' "$projectDirectory/octave.SNP_analysis.log" >> $logName;


##==============================================================================
## Generate final figures for dataset.
##------------------------------------------------------------------------------
echo -e "#==================================#" >> $logName;
echo -e "# Generate final combined figures. #" >> $logName;
echo -e "#==================================#" >> $logName;
echo -e "Generating final figures." >> $condensedLog;

echo -e "\t\tGenerating OCTAVE script to generate combined CNV and SNP analysis figures from previous calculations." >> $logName;
outputName="$projectDirectory/processing4.m";
install /dev/null "$outputName";
install /dev/null "$projectDirectory/octave.final_figs.log";
echo -e "\t\toutputName = $outputName" >> $logName;

echo -e "function [] = processing4()" > $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary('$projectDirectory/octave.final_figs.log');" >> $outputName;
echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
echo -e "\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "end" >> $outputName;

echo -e "\t|\tfunction [] = processing4()" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('$projectDirectory/octave.final_figs.log');" >> $logName;
echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
echo -e "\t|\t    analyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\t\tCalling OCTAVE.   (Log will be appended here after completion.)" >> $logName;
echo -e "================================================================================================";
echo -e "== CNV/SNP/LOH figure generation ===============================================================";
echo -e "================================================================================================";
cd "$projectDirectory";
$octave_exec "$outputName";
cd "$script_dir";
echo -e "\t\tOCTAVE log from final figure generation." >> $logName;
sed 's/^/\t\t|/;' "$projectDirectory/octave.final_figs.log" >> $logName;


##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
echo -e "running: " "$main_dir/scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" "$user" "$project" "$main_dir" >> $logName;
bash "$main_dir/scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" "$user" "$project" "$main_dir" 2>> $logName;


##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "project.WGseq.hapmap.install_4.sh completed.";
