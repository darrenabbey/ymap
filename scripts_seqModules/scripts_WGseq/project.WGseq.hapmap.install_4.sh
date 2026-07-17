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

check_octave_crash() {
	local error_file="$projectDirectory/error.txt";
	if [ -f "$error_file" ]; then
		local error_info clean_info failed_message failed_script failed_line;

		error_info=$(cat "$error_file");
		clean_info="${error_info#*Something went wrong. }";

		failed_message="${clean_info#*|}";
		failed_script="${clean_info%%:*}";

		failed_line="${clean_info%%|*}";
		failed_line="${failed_line#*:}";

		echo -e "\n[ERROR] Pipeline halted! Octave crashed in script: $failed_script at line: $failed_line" >> "$logName";
		echo -e "[ERROR] Reason: $failed_message" >> "$logName";
		echo -e "[ERROR] Terminating Bash script execution immediately.\n";

		cd $main_dir"/scripts_seqModules/scripts_WGseq/";
		bash cleaning_WGseq.sh "$user" "$project" "$main_dir" 2>> $logName;
		bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "project.WGseq.install_4.sh completed.";
		cd $main_dur;
		touch $projectDirectory/working.txt;
		rm $projectDirectory/complete.txt;

		exit 1;
	fi
}

log_compiled_script() {
	local source_script="$1";
	local destination_log="$2";

	if [[ -f "$source_script" ]]; then
		# Process the entire file in one go using sed:
		# 's/\\/\\\\/g' -> Doubles up backslashes
		# 's/^/\t|\t/'  -> Prepends your custom log alignment prefix to every line
		sed -e 's/\\/\\\\/g' -e 's/^/\t|\t/' "$source_script" >> "$destination_log";
	else
		echo "Error: Source script $source_script not found to log." >&2;
	fi;
}


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
if [[ -d "$main_dir/users/$user/hapmaps/$hapmap" ]]; then
	hapmapDirectory="$main_dir/users/$user/hapmaps/$hapmap";
	hapmapUser="$user";
	hapmapUsed=1
elif [[ -d "$main_dir/users/default/hapmaps/$hapmap" ]]; then
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

cat << EOF > "$outputName"
function [] = processing1()
	pkg load io;
	pkg load statistics;
	pkg load matgeom;
	diary('$projectDirectory/octave.CNV_and_GCbias.log');
	cd "$main_dir/scripts_seqModules/scripts_WGseq";
	try
		analyze_CNVs_1('$main_dir','$user','$genomeUser','$project','$genome','$ploidyEstimate','$ploidyBase');
	catch err
		fileID = fopen('$projectDirectory/error.txt', 'w');
		if fileID ~= -1
			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\\n', err.stack(1).name, err.stack(1).line, err.message);
			fclose(fileID);
		end;
	end;
end
EOF
log_compiled_script "$outputName" "$logName";

echo -e "\t\tCalling OCTAVE for CNV analysis." >> $logName;
cd "$projectDirectory";
$octave_exec "$outputName";
cd "$script_dir";
check_octave_crash;


##==============================================================================
## Perform ChARM analysis of dataset.
##------------------------------------------------------------------------------
echo -e "#============================#" >> $logName;
echo -e "# ChARM analysis of dataset. #" >> $logName;
echo -e "#============================#" >> $logName;
echo -e "Analyzing CNV edges." >> $condensedLog;

echo -e "\t\tGenerating OCTAVE script to perform ChARM analysis of dataset." >> $logName;
outputName="$projectDirectory/processing2.m";
install /dev/null "$outputName";
install /dev/null "$projectDirectory/octave.ChARM.log";
echo -e "\t\toutputName = "$outputName >> $logName;

cat << EOF > "$outputName"
function [] = processing2()
	pkg load matgeom;
	diary('$projectDirectory/octave.ChARM.log');
	cd "$main_dir/scripts_seqModules/scripts_WGseq";
	try
		ChARM_v4('$project','$user','$genome','$genomeUser','$main_dir');
	catch err
		fileID = fopen('$projectDirectory/error.txt', 'w');
		if fileID ~= -1
			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\\n', err.stack(1).name, err.stack(1).line, err.message);
			fclose(fileID);
		end;
	end;
end
EOF
log_compiled_script "$outputName" "$logName";

echo -e "\t\tCalling OCTAVE for ChARM analysis." >> $logName;
cd "$projectDirectory";
$octave_exec "$outputName";
cd "$script_dir";
check_octave_crash;


##==============================================================================
## Perform SNP/LOH analysis on dataset.
##------------------------------------------------------------------------------
echo -e "#===========================================#" >> $logName;
echo -e "# SNP/LOH analysis of dataset, with hapmap. #" >> $logName;
echo -e "#===========================================#" >> $logName;
echo -e "Preprocessing SNP data, with hapmap." >> $condensedLog;

if [[ -f "$projectDirectory/preprocessed_SNPs.txt" ]]; then
	echo -e "\t\tSNP data already preprocessed with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
else
	echo -e "\tGrabbing hapmap data from: $hapmapDirectory/" >> $logName;
	cp "$hapmapDirectory/SNPdata_parent.txt" "$projectDirectory/SNPdata_parent.txt";

	# prefilter SNP data vs hapmap. (output not yet used.)
	echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/putative_SNPs_from_hapmap_in_child.py" "$genome" "$genomeUser" "$project" "$user" "$hapmap" "$hapmapUser" "$main_dir" > "$projectDirectory/SNPdata_child.temp.txt" 2>> $logName;
	sort -k1,1 -k2,2n "$projectDirectory/SNPdata_child.temp.txt" > "$projectDirectory/SNPdata_child.txt";
	rm "$projectDirectory/SNPdata_child.temp.txt";
	chmod 774 "$projectDirectory/SNPdata_child.txt"; # formerly 'trimmed_SNPs_v5.txt'

	# preprocess SNP data.
	echo -e "\t\tPreprocessing SNP data with python script : 'scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py'" >> $logName;
	$python_exec "$main_dir/scripts_seqModules/scripts_WGseq/dataset_process_for_SNP_analysis.WGseq.py" "$genome" "$genomeUser" "$hapmap" "$hapmapUser" "$project" "$user" "$main_dir" "$logName" hapmap > "$projectDirectory/preprocessed_SNPs.txt" 2>> $logName;
	echo -e "\t\tpre-processing complete." >> $logName;
fi

echo -e "Mapping SNPs." >> $condensedLog;
echo -e "\t\tGenerating OCTAVE script to perform SNP analysis of dataset." >> $logName;
outputName="$projectDirectory/processing3.m";
install /dev/null "$outputName";
install /dev/null "$projectDirectory/octave.SNP_analysis.log";
echo -e "\t\toutputName = $outputName" >> $logName;

cat << EOF > "$outputName"
function [] = processing3()
	pkg load matgeom;
	diary('$projectDirectory/octave.SNP_analysis.log');
	cd "$main_dir/scripts_seqModules/scripts_WGseq";
	try
		analyze_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');
	catch err
		fileID = fopen('$projectDirectory/error.txt', 'w');
		if fileID ~= -1
			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\\n', err.stack(1).name, err.stack(1).line, err.message);
			fclose(fileID);
		end;
	end;
end
EOF
log_compiled_script "$outputName" "$logName";

echo -e "\t\tCalling OCTAVE for SNP/hapmap analysis." >> $logName;
cd "$projectDirectory";
$octave_exec "$outputName";
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

cat << EOF > "$outputName"
function [] = processing4()
	pkg load matgeom;
	diary('$projectDirectory/octave.final_figs.log');
	cd "$main_dir/scripts_seqModules/scripts_WGseq";
	try
		analyze_CNV_SNPs_hapmap('$main_dir','$user','$genomeUser','$project','$hapmap','$genome','$ploidyEstimate','$ploidyBase');
	catch err
		fileID = fopen('$projectDirectory/error.txt', 'w');
		if fileID ~= -1
			fprintf(fileID, 'Something went wrong. %s.m:%d|%s\\n', err.stack(1).name, err.stack(1).line, err.message);
			fclose(fileID);
		end;
	end;
end
EOF
log_compiled_script "$outputName" "$logName";

echo -e "\t\tCalling OCTAVE for CNV/SNP/hapmap analysis." >> $logName;
cd "$projectDirectory";
$octave_exec "$outputName";
cd "$script_dir";
check_octave_crash;

echo -e "finished all processing, moving to Cleaning up intermediate WGseq files" >> $condensedLog;


##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
echo -e "running: " "scripts_seqModules/scripts_WGseq/cleaning_WGseq.sh" "$user" "$project" "$main_dir" >> $logName;
cd $main_dir"/scripts_seqModules/scripts_WGseq/";
bash "cleaning_WGseq.sh" "$user" "$project" "$main_dir" 2>> $logName;
cd $main_dir;

##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
cd $main_dir"/scripts_seqModules/scripts_WGseq/";
bash queue_end.sh "$user" "$project" "$main_dir" "$logName" "project.WGseq.hapmap.install_4.sh completed.";
cd $main_dir;
