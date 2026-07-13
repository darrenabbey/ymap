#!/bin/bash
#
# project.WGseq.update_2.sh
#
set -e

## All created files will have permission 760
umask 007;

user="$1";
project="$2";
main_dir=$(pwd)"/../..";
projectDirectory="$main_dir/users/$user/projects/$project";
logName="$projectDirectory/process_log.txt";

## Error handling in case something crashes.
trap 'cd $main_dir"/scripts_seqModules/scripts_WGseq/"; bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "Something went wrong. project.WGseq.update_2.sh:$LINENO"; install /dev/null "$projectDirectory/error.txt"; echo -e "Something went wrong. project.WGseq.update_2.sh:$LINENO" > "$projectDirectory/error.txt"; cd $main_dir; exit 1;' ERR;

### define script file locations.
local_dir=$(pwd);
script_dir=$(pwd);

check_octave_crash() {
	local error_file="$projectDirectory/error.txt"
	if [ -f "$error_file" ]; then
		local error_info clean_info failed_message failed_script failed_line

		error_info=$(cat "$error_file")
		clean_info="${error_info#*Something went wrong. }"

		failed_message="${clean_info#*|}"
		failed_script="${clean_info%%:*}"

		failed_line="${clean_info%%|*}"
		failed_line="${failed_line#*:}"

		echo -e "\n[ERROR] Pipeline halted! Octave crashed in script: $failed_script at line: $failed_line" >> "$logName"
		echo -e "[ERROR] Reason: $failed_message" >> "$logName"
		echo -e "[ERROR] Terminating Bash script execution immediately.\n"

		cd $main_dir"/scripts_seqModules/scripts_WGseq/";
		bash cleaning_WGseq.sh "$user" "$project" "$main_dir" 2>> $logName;
		bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "project.WGseq.install_4.sh completed.";
		cd $main_dur;

		exit 1
	fi
}


##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------

# import locations of auxillary software for pipeline analysis.
. $main_dir/local_installed_programs.sh;
. $main_dir/config.sh;

condensedLog="$projectDirectory/condensed_log.txt";

echo -e "#.............................................................................." >> $logName;
echo -e "Running 'scripts_seqModules/scripts_WGseq/project.WGseq.update_2.sh'" >> $logName;
echo -e "Variables passed via command-line from 'scripts_seqModules/scripts_WGseq/project.WGseq.update_2.sh' :" >> $logName;
echo -e "\tuser     = $user" >> $logName;
echo -e "\tproject  = $project" >> $logName;
echo -e "\tmain_dir = $main_dir" >> $logName;
echo -e "#============================================================================== 3" >> $logName;

echo -e "#=====================================#" >> $logName;
echo -e "# Setting up locations and variables. #" >> $logName;
echo -e "#=====================================#" >> $logName;

echo -e "\tprojectDirectory = $projectDirectory" >> $logName;
echo -e "Setting up for processing." >> $condensedLog;

# Get setup information from project files.
# "genome.txt"
#    first line  => genome
#    second line => hapmap
genome=$(head -n 1 "$projectDirectory/genome.txt");
hapmap=$(tail -n 1 "$projectDirectory/genome.txt");
dataFormat=$(head -n 1 "$projectDirectory/dataFormat.txt");
echo -e "\t'genome.txt' file entry." >> $logName;
echo -e "\t\tgenome = $genome" >> $logName;
if [[ "$genome" = "$hapmap" ]]; then
	hapmapInUse=0;
elif [[ "$hapmap" = "none" ]]; then
	hapmapInUse=0;
else
	echo -e "\t\thapmap = $hapmap" >> $logName;
	hapmapInUse=1;
fi
if [[ "$hapmapInUse" = 1 ]]; then
	# Determine location of hapmap being used.
	if [[ -d "$main_dir/users/$user/hapmaps/$hapmap" ]]; then
		hapmapDirectory="$main_dir/users/$user/hapmaps/$hapmap";
		hapmapUser="$user";
	elif [[ -d "$main_dir/users/default/hapmaps/$hapmap" ]]; then
		hapmapDirectory="$main_dir/users/default/hapmaps/$hapmap";
		hapmapUser="default";
	fi
	echo -e "\thapmapDirectory = $hapmapDirectory" >> $logName;
fi

# Determine location of genome being used.
if [[ -d "$main_dir/users/$user/genomes/$genome" ]]; then
	genomeDirectory="$main_dir/users/$user/genomes/$genome";
	genomeUser="$user";
elif [[ -d "$main_dir/users/default/genomes/$genome" ]]; then
	genomeDirectory="$main_dir/users/default/genomes/$genome";
	genomeUser="default";
fi
echo -e "\tgenomeDirectory = $genomeDirectory" >> $logName;

# Get reference FASTA file name from "reference.txt";
genomeFASTA=$(head -n 1 "$genomeDirectory/reference.txt");
echo -e "\tgenomeFASTA = $genomeFASTA" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 "$projectDirectory/ploidy.txt");
echo -e "\tploidyEstimate = $ploidyEstimate" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 "$projectDirectory/ploidy.txt");
echo -e "\tploidyBase = $ploidyBase" >> $logName;

# Get parent name from "parent.txt" in project directory.
projectParent=$(head -n 1 "$projectDirectory/parent.txt");
echo -e "\tprojectParent = $projectParent" >> $logName;

# Determine location of project being used.
if [[ -d "$main_dir/users/$user/projects/$projectParent" ]]; then
	projectParentDirectory="$main_dir/users/$user/projects/$projectParent";
	projectParentUser="$user";
elif [[ -d "$main_dir/users/default/projects/$projectParent" ]]; then
	projectParentDirectory="$main_dir/users/default/projects/$projectParent";
	projectParentUser="default";
fi
echo -e "\tprojectParentDirectory = $projectParentDirectory" >> $logName;

echo -e "#============================================================================== 2" >> $logName;


##==============================================================================
## Unzip SNP archive file: putative_SNPs_v4.zip
##------------------------------------------------------------------------------
if [[ -f "$projectDirectory/putative_SNPs_v4.txt" ]]; then
	echo -e "\tSNP data already decompressed." >> $logName;
else
	echo -e "Decompressing SNP data." >> $condensedLog;
	echo -e "\tDecompressing SNP data." >> $logName;
	echo -e "\t\t$projectDirectory/putative_SNPs_v4.zip" >> $logName;
	cd "$projectDirectory";
	pigz -dc putative_SNPs_v4.zip > putative_SNPs_v4.txt;
	cd "$local_dir";
fi
if [[ -f "$projectDirectory/SNP_CNV_v1.txt" ]]; then
	echo -e "\tSNP data already decompressed." >> $logName;
else
	echo -e "Decompressing CNV/SNP data." >> $condensedLog;
	echo -e "\tDecompressing CNV/SNP data." >> $logName;
	echo -e "\t\t$projectDirectory/SNP_CNV_v1.zip" >> $logName;
	cd "$projectDirectory";
	pigz -dc SNP_CNV_v1.zip > SNP_CNV_v1.txt;
	#unzip -j -o SNP_CNV_v1.zip;
	cd "$local_dir";
fi

##==============================================================================
## Preprocess CNV/SNPs if necessary.
##------------------------------------------------------------------------------
echo -e "#==========================#" >> $logName;
echo -e "# Preprocessing CNV/SNPs.  #" >> $logName;
echo -e "#==========================#" >> $logName;
if [[ -f "$projectDirectory/preprocessed_CNVs.txt" ]]; then
        echo -e "\tCNV data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py'" >> $logName;
else
	install /dev/null "$projectDirectory/preprocessed_CNVs.txt";
	echo -e "Preprocessing CNVs." >> $condensedLog;
	echo -e "\tPreprocessing CNV data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py'" >> $logName;
	$python_exec "$main_dir/scripts_seqModules/scripts_WGseq/dataset_process_for_CNV_analysis.WGseq.py" "$user" "$project" "$genome" "$genomeUser" "$main_dir" "$logName" > "$projectDirectory/preprocessed_CNVs.txt" 2>> $logName;
	echo -e "\tpre-processing complete." >> $logName;
fi
#if [[ -f "$projectDirectory/preprocessed_SNPs.txt" ]]; then
#        echo -e "\tSNP data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
#else
	install /dev/null "$projectDirectory/preprocessed_SNPs.txt";
	echo -e "Preprocessing SNPs." >> $condensedLog;
	if [[ "$hapmapInUse" = 1 ]]; then
		echo -e "\tGrabbing hapmap data from: $hapmapDirectory/" >> $logName;
		cp "$hapmapDirectory/SNPdata_parent.txt" "$projectDirectory/SNPdata_parent.txt";

		# prefilter SNP data vs hapmap. (output not yet used).
		echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
		$python_exec "$main_dir/scripts_seqModules/putative_SNPs_from_hapmap_in_child.py" "$genome" "$genomeUser" "$project" "$user" "$hapmap" "$hapmapUser" "$main_dir" > "$projectDirectory/SNPdata_child.temp.txt" 2>> $logName;
		sort -k1,1 -k2,2n "$projectDirectory/SNPdata_child.temp.txt" > "$projectDirectory/SNPdata_child.txt";
		rm "$projectDirectory/SNPdata_child.temp.txt";
		chmod 774 "$projectDirectory/SNPdata_child.txt"; # formerly 'trimmed_SNPs_v5.txt'

		# preprocess SNP data.
		echo -e "\tPreprocessing SNP data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
		$python_exec "$main_dir/scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py" "$genome" "$genomeUser" "$hapmap" "$hapmapUser" "$project" "$user" "$main_dir" "$logName" hapmap > "$projectDirectory/preprocessed_SNPs.txt" 2>> $logName;
	else
		if [[ -e "$projectParentDirectory/putative_SNPs_v4.txt" ]]; then
			echo -e "\tParent SNP data already decompressed." >> $logName;
			cp "$projectParentDirectory/putative_SNPs_v4.txt" "$projectDirectory/SNPdata_parent.txt";
		else
			echo -e "\tDecompressing parent SNP data." >> $logName;
			echo -e "\t\tpigz -dc '$projectParentDirectory/putative_SNPs_v4.zip' > '$projectDirectory/SNPdata_parent.txt';" >> $logName;
			pigz -dc "$projectParentDirectory/putative_SNPs_v4.zip" > "$projectDirectory/SNPdata_parent.txt";
		fi

		# preprocess parent (or self if no parent) for comparison.
		install /dev/null "$projectDirectory/SNPdata_parent.temp.txt";
		$python_exec "$main_dir/scripts_seqModules/scripts_hapmaps/hapmap.preprocess_parent.py" "$genome" "$genomeUser" "$project" "$user" "$projectParent" "$projectParentUser" "$main_dir" LOH > "$projectDirectory/SNPdata_parent.temp.txt" 2>> $logName;
		mv "$projectDirectory/SNPdata_parent.temp.txt" "$projectDirectory/SNPdata_parent.txt";

		# Preprocess SNP data vs self.
		echo -e "\tPreprocessing SNP data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
	        $python_exec "$main_dir/scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py" "$genome" "$genomeUser" "$project" "$user" "$project" "$user" "$main_dir" "$logName" LOH > "$projectDirectory/preprocessed_SNPs.txt" 2>> $logName;
	fi;
        echo -e "\tpre-processing complete." >> $logName;
#fi


##==============================================================================
## Perform CNV analysis, with GC-correction, on dataset.
##------------------------------------------------------------------------------
echo -e "#==========================#" >> $logName;
echo -e "# CNV analysis of dataset. #" >> $logName;
echo -e "#==========================#" >> $logName;
echo -e "Preprocessing CNV data." >> $condensedLog;
echo -e "Analyzing and mapping CNVs." >> $condensedLog;

echo -e "\tGenerating OCTAVE script to perform CNV analysis of dataset, with GC-correction." >> $logName;
outputName="$projectDirectory/processing1.m";
install /dev/null "$outputName";
install /dev/null "$projectDirectory/octave.CNV_and_GCbias.log";
echo -e "\toutputName = $outputName" >> $logName;

echo -e "function [] = processing1()" > $outputName;
echo -e "\tpkg load io;" >> $outputName;
echo -e "\tpkg load statistics;" >> $outputName;
echo -e "\tpkg load matgeom;" >> $outputName;
echo -e "\tdiary('$projectDirectory/octave.CNV_and_GCbias.log');" >> $outputName;
echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
echo -e "\ttry" >> $outputName;
echo -e "\t\tanalyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
echo -e "\tcatch err" >> $outputName;
echo -e "\t\tfileID = fopen('$projectDirectory/error.txt', 'w');" >> $outputName;
echo -e "\t\tif fileID ~= -1" >> $outputName;
echo -e "\t\t\tfprintf(fileID, 'Something went wrong. %s.m:%d|%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $outputName;
echo -e "\t\t\tfclose(fileID);" >> $outputName;
echo -e "\t\tend;" >> $outputName;
echo -e "\tend;" >> $outputName;
echo -e "endfunction" >> $outputName;

echo -e "\t|\tfunction [] = processing1()" >> $logName;
echo -e "\t|\t    pkg load io;" >> $logName;
echo -e "\t|\t    pkg load statistics;" >> $logName;
echo -e "\t|\t    pkg load matgeom;" >> $logName;
echo -e "\t|\t    diary('$projectDirectory/octave.CNV_and_GCbias.log');" >> $logName;
echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
echo -e "\t|\t    try" >> $logName;
echo -e "\t|\t        analyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
echo -e "\t|\t    catch err" >> $logName;
echo -e "\t|\t        fileID = fopen('$projectDirectory/error.txt', 'w');" >> $logName;
echo -e "\t|\t        if fileID ~= -1" >> $logName;
echo -e "\t|\t            fprintf(fileID, 'Something went wrong. %%s.m:%%d|%%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $logName;
echo -e "\t|\t            fclose(fileID);" >> $logName;
echo -e "\t|\t        end;" >> $logName;
echo -e "\t|\t    end;" >> $logName;
echo -e "\t|\tend" >> $logName;

echo -e "\tCalling OCTAVE." >> $logName;
cd "$projectDirectory";
$octave_exec "$outputName" 2>> $logName;
cd "$script_dir";
check_octave_crash;


if [[ "$hapmapInUse" = 0 ]]; then
	##==============================================================================
	## Perform SNP/LOH analysis on dataset.
	##------------------------------------------------------------------------------
	if [[ "$project" = "$projectParent" ]]; then
		echo -e "#==========================#" >> $logName;
		echo -e "# SNP analysis of dataset. #" >> $logName;
		echo -e "#==========================#" >> $logName;
	else
		echo -e "#==========================#" >> $logName;
		echo -e "# LOH analysis of dataset. #" >> $logName;
		echo -e "#==========================#" >> $logName;
	fi

	echo -e "Mapping SNPs." >> $condensedLog;
	echo -e "\tGenerating OCTAVE script to perform SNP analysis of dataset." >> $logName;
	outputName="$projectDirectory/processing3.m";
	install /dev/null "$outputName";
	install /dev/null "$projectDirectory/octave.SNP_analysis.log";
	echo -e "\toutputName = $outputName" >> $logName;

	echo -e "function [] = processing3()" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('$projectDirectory/octave.SNP_analysis.log');" >> $outputName;
	echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
	echo -e "\ttry" >> $outputName;
	echo -e "\t\tanalyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo -e "\tcatch err" >> $outputName;
	echo -e "\t\tfileID = fopen('$projectDirectory/error.txt', 'w');" >> $outputName;
	echo -e "\t\tif fileID ~= -1" >> $outputName;
	echo -e "\t\t\tfprintf(fileID, 'Something went wrong. %s.m:%d|%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $outputName;
	echo -e "\t\t\tfclose(fileID);" >> $outputName;
	echo -e "\t\tend;" >> $outputName;
	echo -e "\tend;" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing3()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('$projectDirectory/octave.SNP_analysis.log');" >> $logName;
	echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
	echo -e "\t|\t    try" >> $logName;
	echo -e "\t|\t        analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo -e "\t|\t    catch err" >> $logName;
	echo -e "\t|\t        fileID = fopen('$projectDirectory/error.txt', 'w');" >> $logName;
	echo -e "\t|\t        if fileID ~= -1" >> $logName;
	echo -e "\t|\t            fprintf(fileID, 'Something went wrong. %%s.m:%%d|%%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $logName;
	echo -e "\t|\t            fclose(fileID);" >> $logName;
	echo -e "\t|\t        end;" >> $logName;
	echo -e "\t|\t    end;" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\tCalling OCTAVE." >> $logName;
	echo -e "================================================================================================";
	echo -e "== SNP analysis ================================================================================";
	echo -e "================================================================================================";
	cd "$projectDirectory";
	$octave_exec "$outputName" 2>> $logName;
	cd "$script_dir";
	check_octave_crash;


	##==============================================================================
	## Generate final figures for dataset.
	##------------------------------------------------------------------------------
	echo -e "#==================================#" >> $logName;
	echo -e "# Generate final combined figures. #" >> $logName;
	echo -e "#==================================#" >> $logName;
	echo -e "Generating final figures." >> $condensedLog;

	echo -e "\tGenerating OCTAVE script to generate combined CNV and SNP analysis figures from previous calculations." >> $logName;
	outputName="$projectDirectory/processing4.m";
	install /dev/null "$outputName";
	install /dev/null "$projectDirectory/octave.final_figs.log";
	echo -e "\toutputName = $outputName" >> $logName;

	echo -e "function [] = processing4()" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('$projectDirectory/octave.final_figs.log');" >> $outputName;
	echo -e "\tcd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $outputName;
	echo -e "\ttry" >> $outputName;
	echo -e "\t\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo -e "\tcatch err" >> $outputName;
	echo -e "\t\tfileID = fopen('$projectDirectory/error.txt', 'w');" >> $outputName;
	echo -e "\t\tif fileID ~= -1" >> $outputName;
	echo -e "\t\t\tfprintf(fileID, 'Something went wrong. %s.m:%d|%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $outputName;
	echo -e "\t\t\tfclose(fileID);" >> $outputName;
	echo -e "\t\tend;" >> $outputName;
	echo -e "\tend;" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing4()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('$projectDirectory/octave.final_figs.log');" >> $logName;
	echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
	echo -e "\t|\t    try" >> $logName;
	echo -e "\t|\t        analyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$projectParent','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo -e "\t|\t    catch err" >> $logName;
	echo -e "\t|\t        fileID = fopen('$projectDirectory/error.txt', 'w');" >> $logName;
	echo -e "\t|\t        if fileID ~= -1" >> $logName;
	echo -e "\t|\t            fprintf(fileID, 'Something went wrong. %%s.m:%%d|%%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $logName;
	echo -e "\t|\t            fclose(fileID);" >> $logName;
	echo -e "\t|\t        end;" >> $logName;
	echo -e "\t|\t    end;" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\tCalling OCTAVE.   (Log will be appended here after completion.)" >> $logName;
	echo -e "================================================================================================";
	echo -e "== Final figures ===============================================================================";
	echo -e "================================================================================================";
	cd "$projectDirectory";
	$octave_exec "$outputName" 2>> $logName;
	cd "$script_dir";
	check_octave_crash;

	echo -e "finished all processing, moving to Cleaning up intermediate WGseq files" >> $condensedLog;
else
	##==============================================================================
	## Perform SNP/hapmap analysis on dataset.
	##------------------------------------------------------------------------------
	echo -e "#===========================================#" >> $logName;
	echo -e "# SNP/LOH analysis of dataset, with hapmap. #" >> $logName;
	echo -e "#===========================================#" >> $logName;

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
	echo -e "\ttry" >> $outputName;
	echo -e "\t\tanalyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo -e "\tcatch err" >> $outputName;
	echo -e "\t\tfileID = fopen('$projectDirectory/error.txt', 'w');" >> $outputName;
	echo -e "\t\tif fileID ~= -1" >> $outputName;
	echo -e "\t\t\tfprintf(fileID, 'Something went wrong. %s.m:%d|%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $outputName;
	echo -e "\t\t\tfclose(fileID);" >> $outputName;
	echo -e "\t\tend;" >> $outputName;
	echo -e "\tend;" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing3()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('$projectDirectory/octave.SNP_analysis.log');" >> $logName;
	echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
	echo -e "\t|\t    try" >> $logName;
	echo -e "\t|\t        analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo -e "\t|\t    catch err" >> $logName;
	echo -e "\t|\t        fileID = fopen('$projectDirectory/error.txt', 'w');" >> $logName;
	echo -e "\t|\t        if fileID ~= -1" >> $logName;
	echo -e "\t|\t            fprintf(fileID, 'Something went wrong. %%s.m:%%d|%%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $logName;
	echo -e "\t|\t            fclose(fileID);" >> $logName;
	echo -e "\t|\t        end;" >> $logName;
	echo -e "\t|\t    end;" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\t\tCalling OCTAVE." >> $logName;
	echo -e "================================================================================================";
	echo -e "== SNP analysis ================================================================================";
	echo -e "================================================================================================";
	cd "$projectDirectory";
	$octave_exec "$outputName" 2>> $logName;
	cd "$script_dir";
	check_octave_crash;


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
	echo -e "\ttry" >> $outputName;
	echo -e "\t\tanalyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $outputName;
	echo -e "\tcatch err" >> $outputName;
	echo -e "\t\tfileID = fopen('$projectDirectory/error.txt', 'w');" >> $outputName;
	echo -e "\t\tif fileID ~= -1" >> $outputName;
	echo -e "\t\t\tfprintf(fileID, 'Something went wrong. %s.m:%d|%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $outputName;
	echo -e "\t\t\tfclose(fileID);" >> $outputName;
	echo -e "\t\tend;" >> $outputName;
	echo -e "\tend;" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing4()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('$projectDirectory/octave.final_figs.log');" >> $logName;
	echo -e "\t|\t    cd \"$main_dir/scripts_seqModules/scripts_WGseq\";" >> $logName;
	echo -e "\t|\t    try" >> $logName;
	echo -e "\t|\t        analyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');" >> $logName;
	echo -e "\t|\t    catch err" >> $logName;
	echo -e "\t|\t        fileID = fopen('$projectDirectory/error.txt', 'w');" >> $logName;
	echo -e "\t|\t        if fileID ~= -1" >> $logName;
	echo -e "\t|\t            fprintf(fileID, 'Something went wrong. %%s.m:%%d|%%s\\\\n', err.stack(1).name, err.stack(1).line, err.message);" >> $logName;
	echo -e "\t|\t            fclose(fileID);" >> $logName;
	echo -e "\t|\t        end;" >> $logName;
	echo -e "\t|\t    end;" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\t\tCalling OCTAVE.   (Log will be appended here after completion.)" >> $logName;
	echo -e "================================================================================================";
	echo -e "== CNV/SNP/LOH figure generation ===============================================================";
	echo -e "================================================================================================";
	cd "$projectDirectory";
	$octave_exec "$outputName" 2>> $logName;
	cd "$script_dir";
	check_octave_crash;
fi


##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
echo -e "running: " "$main_dir/scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" "$user" "$project" "$main_dir" >> $logName;
cd $main_dir"/scripts_seqModules/scripts_WGseq/";
bash cleaning_WGseq.sh "$user" "$project" "$main_dir" 2>> $logName;
cd $main_dir;


##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
cd $main_dir"/scripts_seqModules/scripts_WGseq/";
bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "project.WGseq.install_4.sh completed.";
cd $main_dur;
