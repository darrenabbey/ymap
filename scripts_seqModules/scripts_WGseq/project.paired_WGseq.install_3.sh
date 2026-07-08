#!/bin/bash
#
# project.paired_WGseq.install_3.sh
#
set -e;

## All created files will have permission 760
umask 007;

user=$1;
project=$2;
main_dir=$(pwd)"/../..";
projectDirectory="$main_dir/users/$user/projects/$project";
logName="$projectDirectory/process_log.txt";

## Error handling in case something crashes.
trap 'cd $main_dir"/scripts_seqModules/scripts_WGseq/"; bash queue_end.sh "$user" "$project" "$main_dir" $logName "Something went wrong. project.paired_WGseq.install_3.sh:$LINENO"; install /dev/null "$projectDirectory/error.txt"; echo -e "Something went wrong. project.paired_WGseq.install_3.sh:$LINENO" > "$projectDirectory/error.txt";cd $main_dir; exit 1;' ERR;

##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------

# import locations of auxillary software for pipeline analysis.
. $main_dir/local_installed_programs.sh;
. $main_dir/config.sh;
main_dir=$base_dir;
projectDirectory="$main_dir/users/$user/projects/$project";

#logName="$projectDirectory/process_log.txt"
#install /dev/null $logName;
echo "% $main_dir/local_installed_programs.sh" >> $logName;
echo "% $main_dir/config.sh" >> $logName;
echo "% $projectDirectory" >> $logName;

# Setup process_log.txt file.
condensedLog="$projectDirectory/condensed_log.txt";
#install /dev/null $condensedLog;

echo -e "#.............................................................................." >> $logName;
echo -e "Running 'scripts_seqModules/scripts_WGseq/project.paired_WGseq.install_3.sh'" >> $logName;
echo -e "Variables passed via command-line from 'scripts_seqModules/scripts_WGseq/project.paired_WGseq.install_2.php' :" >> $logName;
echo -e "\tuser     = $user" >> $logName;
echo -e "\tproject  = $project" >> $logName;
echo -e "\tmain_dir = $main_dir" >> $logName;
echo -e "#============================================================================== 3" >> $logName;

echo -e "#=====================================#" >> $logName;
echo -e "# Setting up locations and variables. #" >> $logName;
echo -e "#=====================================#" >> $logName;

echo -e "\tprojectDirectory = $projectDirectory" >> $logName;
echo -e "Setting up for processing." >> $condensedLog;

chmod 0774 $logName;
chmod 0774 $condensedLog;


echo -e "#==============================================================================" >> $logName;
echo -e "#\tChecking to see if FASTQ data needs to be downsampled to be processed within memory limitations." >> $logName;
echo -e "#------------------------------------------------------------------------------" >> $logName;

# Get first data file name from "datafiles.txt";
datafile1=$(head -n 1 "$projectDirectory/datafiles.txt");
# Get second data file name from "datafiles.txt";
datafile2=$(tail -n 1 "$projectDirectory/datafiles.txt");

# Get memory target from "constants.php" file.
MAX_FASTQ_TARGET_string1=$(grep -e "MAX_FASTQ_TARGET" "$main_dir/constants.php");
MAX_FASTQ_TARGET_string2=$(echo -e "${MAX_FASTQ_TARGET_string1/'$MAX_FASTQ_TARGET = '/''}");
MAX_FASTQ_TARGET=${MAX_FASTQ_TARGET_string2%;*};

if [[ "$MAX_FASTQ_TARGET" > "0" ]]; then
	# Get FASTQ data total size in bytes.
	FILESIZE1=$(stat -c%s "$main_dir/users/$user/projects/$project/$datafile1");
	FILESIZE2=$(stat -c%s "$main_dir/users/$user/projects/$project/$datafile2");
	FILESIZE=$(($FILESIZE1 + $FILESIZE2));
	READS_RAW1=$(wc -l < "$main_dir/users/$user/projects/$project/$datafile1");
	READS_RAW2=$(wc -l < "$main_dir/users/$user/projects/$project/$datafile2");
	READS1=$(printf %.0f $( echo "$READS_RAW1/4" | bc -l) );
	READS2=$(printf %.0f $( echo "$READS_RAW2/4" | bc -l) );
	FILESIZE_GB=$(echo "$FILESIZE/1000000000" | bc -l);
	MAX_PROCESSED_DATA_SIZE=$MAX_FASTQ_TARGET;
	echo -e "#\tFILESIZE1 (bytes)            = $FILESIZE1" >> $logName;
	echo -e "#\tFILESIZE2 (bytes)            = $FILESIZE2" >> $logName;
	echo -e "#\tREADS1                       = $READS1" >> $logName;
	echo -e "#\tREADS2                       = $READS2" >> $logName;
	echo -e "#\tFILESIZE_GB (total, GB)      = $FILESIZE_GB" >> $logName;
	echo -e "#\tMAX_PROCESSED_DATA_SIZE (GB) = $MAX_PROCESSED_DATA_SIZE (GB)" >> $logName;

	if [[ $(echo "$FILESIZE_GB > $MAX_PROCESSED_DATA_SIZE" | bc -l) = 1 ]]; then
		echo -e "#\t\tFILESIZE_GB > MAX_PROCESSED_DATA_SIZE : FASTQ subsampling needed." >> $logName;
		echo -e "#------------------------------------------------------------------------------" >> $logName;
		# Calculate fraction of target vs original.
		TARGET_FRACTION=$(echo "$MAX_PROCESSED_DATA_SIZE/$FILESIZE_GB" | bc -l);	# Calculate the target number of paired reads.
		TARGET_READS=$(printf %.0f $(echo "$TARGET_FRACTION*$READS1" | bc -l) );	# Round to whole number of reads.
		echo -e "#\tTARGET_FRACTION              = $TARGET_FRACTION (= MAX_PROCESSED_DATA_SIZE/FILESIZE_GB)" >> $logName;
		echo -e "#\tTARGET_READS                 = $TARGET_READS" >> $logName;

		echo -e "Downsampling FASTQ data." >> $condensedLog;
		echo -e "#\tDownsampling FASTQ data..." >> $logName;
		echo -e "#" >> $logName;

		# Subsample FASTQ files to target fraction.
		cd "$main_dir/users/$user/projects/$project/";
		install /dev/null $datafile1.sample;
		install /dev/null $datafile2.sample;

		## Use SEQTK to downsample reads.
		randSeed=$((1 + $RANDOM % 1000));
		seqtk sample -2 -s $randSeed $datafile1 $TARGET_READS > $datafile1.sample;
		seqtk sample -2 -s $randSeed $datafile2 $TARGET_READS > $datafile2.sample;

		unlink $datafile1;
		unlink $datafile2;
		mv $datafile1.sample $datafile1;
		mv $datafile2.sample $datafile2;

		FILESIZE1=$(stat -c%s "$main_dir/users/$user/projects/$project/$datafile1");
		FILESIZE2=$(stat -c%s "$main_dir/users/$user/projects/$project/$datafile2");
		FILESIZE=$(($FILESIZE1 + $FILESIZE2));
		READS_RAW1=$(wc -l < "$main_dir/users/$user/projects/$project/$datafile1");
		READS_RAW2=$(wc -l < "$main_dir/users/$user/projects/$project/$datafile2");
		READS1=$(printf %.0f $( echo "$READS_RAW1/4" | bc -l) );
		READS2=$(printf %.0f $( echo "$READS_RAW2/4" | bc -l) );
		FILESIZE_GB=$(echo "$FILESIZE/1000000000" | bc -l);
		echo -e "#\tFILESIZE1 (bytes, after)     = $FILESIZE1" >> $logName;
		echo -e "#\tFILESIZE2 (bytes, after)     = $FILESIZE2" >> $logName;
		echo -e "#\tREADS1 (after)               = $READS1" >> $logName;
		echo -e "#\tREADS2 (after)               = $READS2" >> $logName;
		echo -e "#\tFILESIZE_GB (GB, after)      = $FILESIZE_GB" >> $logName;

		echo -e "#\t\t$datafile1 and $datafile2 downsampled." >> $logName;
		cd "$main_dir";

	else
		echo -e "#" >> $logName;
		echo -e "#\tFILESIZE_GB <= MAX_PROCESSED_DATA_SIZE : FASTQ subsampling not needed." >> $logName;
		echo -e "#" >> $logName;
	fi;
else
	echo -e "#" >> $logName;
	echo -e "#\tFASTQ subsampling disabled in constants.php file." >> $logName;
	echo -e "#" >> $logName;
fi;
echo -e "#==============================================================================" >> $logName;


# Get setup information from project files.
# "genome.txt"
#    first line  => genome
#    second line => hapmap
# "dataFormat.txt"
#    5th character, 0=no indel-realignment, 1= indel-realignment.
genome=$(head -n 1 "$projectDirectory/genome.txt");
hapmap=$(tail -n 1 "$projectDirectory/genome.txt");
dataFormat=$(head -n 1 "$projectDirectory/dataFormat.txt");
echo -e "\t'genome.txt' file entry." >> $logName;
echo -e "\tgenome = $genome" >> $logName;
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

# Show data file names";
echo -e "\tdatafile 1 = $datafile1" >> $logName;
echo -e "\tdatafile 2 = $datafile2" >> $logName;

# Get ploidy estimate from "ploidy.txt" in project directory.
ploidyEstimate=$(head -n 1 "$projectDirectory/ploidy.txt");
echo -e "\tploidyEstimate = $ploidyEstimate" >> $logName;

# Get ploidy baseline from "ploidy.txt" in project directory.
ploidyBase=$(tail -n 1 "$projectDirectory/ploidy.txt");
echo -e "\tploidyBase = $ploidyBase" >> $logName;

# Get parent name from "parent.txt" in project directory.
projectParent=$(head -n 1 "$projectDirectory/parent.txt");
echo -e "\tparentProject = $projectParent" >> $logName;

echo -e "#============================================================================== 2" >> $logName;

if [[ -f $projectDirectory/SNP_CNV_v1.txt ]]; then
	echo -e "\tDone: SAM -> BAM, new group headers, sorted." >> $logName;
	echo -e "\tSamtools.pileup generated." >> $logName;
else
	##==============================================================================
	## Trimming/cleanup of FASTQ files.
	##------------------------------------------------------------------------------
	echo -e "#=======================================================================================#" >> $logName;
	echo -e "# Trimming of unbalanced FASTQ entries using 'scripts_seqModules/FASTQ_2_trimming.sh'.  #" >> $logName;
	echo -e "#=======================================================================================#" >> $logName;
	echo -e "Resolving FASTQ file errors." >> $condensedLog;
	currdir=$(pwd);
	cd "$projectDirectory";
	bash "$main_dir/scripts_seqModules/FASTQ_2_trimming.sh" "$projectDirectory/$datafile1" "$projectDirectory/$datafile2" $user $project $main_dir >> $logName;
	cd $currdir;

	##==============================================================================
	## Initial processing of paired-WGseq dataset.
	##------------------------------------------------------------------------------
	echo -e "#=================================================#" >> $logName;
	echo -e "# Initial processing of paired-end WGseq dataset. #" >> $logName;
	echo -e "#=================================================#" >> $logName;

	# Align fastq against genome.
	echo -e "[[=- Align with Bowtie -=]]" >> $logName;
	echo -e "Aligning reads with Bowtie2." >> $condensedLog;

	if [[ -f $projectDirectory/data.bam ]]; then
		echo -e "\tDone: FASTQ -> BAM, new group headers, sorted." >> $logName;
	else
		echo -e "\tBowtie : paired-end reads aligning into BAM file." >> $logName;

		## Bowtie 2 command for paired reads:
		echo -e "\nRunning bowtie2.\n" >> $logName;
		echo -e "Command used:" >> $logName;
		echo -e "\t$bowtie2Directory\"bowtie2\" --very-sensitive -p '$cores' -x '$genomeDirectory/bowtie_index' -1 '$projectDirectory/$datafile1' -2 '$projectDirectory/$datafile2' -S '$projectDirectory/data.sam'" >> $logName;
		$bowtie2Directory"bowtie2" --very-sensitive -p "$cores" -x "$genomeDirectory/bowtie_index" -1 "$projectDirectory/$datafile1" -2 "$projectDirectory/$datafile2" | $samtools_exec view -b > "$projectDirectory/data.bam" 2>> $logName;
			# -p : number of threads to use.
			# -1 : dataset.
			# --very-sensitive : a default set of configurations.
		chmod 774 "$projectDirectory/data.bam";
		echo -e "\tBowtie : paired-end reads aligned into BAM file." >> $logName;

		echo -e "[[=- Sorting/Indexing BAM files -=]]" >> $logName;
		echo -e "\tSamtools : Bowtie-BAM sorting & indexing." >> $logName;
		echo -e "Sorting BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:sort.\n";
		$samtools_exec sort -@ "$cores" "$projectDirectory/data.bam" -o "$projectDirectory/data_sorted.bam" -T "$projectDirectory" 2>> $logName >> $logName;
		chmod 774 "$projectDirectory/data_sorted.bam";

		echo -e "Indexing BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:index.\n";
		$samtools_exec index "$projectDirectory/data_sorted.bam" 2>> $logName >> $logName;
		chmod 774 "$projectDirectory/data_sorted.bam.bai";
		echo -e "\tSamtools : Bowtie-BAM sorted & indexed." >> $logName;
	fi;

	if [[ -f $projectDirectory/data.pileup ]]; then
		echo -e "\tSamtools.pileup generated." >> $logName;
	else
		echo -e "#============================================================================== 3" >> $logName;

		echo -e "[[=- In-house SNP/CNV analysis -=]]" >> $logName;
		echo -e "\tSamtools : Generating pileup.   (for SNP/CNV analysis)" >> $logName;
		echo -e "Generating pileup files." >> $condensedLog;

		echo -e "command used for normal pileup output:" >> $logName;
		echo -e "\tbash \"$main_dir/scripts_seqModules/parallel_mpileup.sh\" \"$user\" \"$project\" \"$main_dir\" >> $logName;" >> $logName;
		bash "$main_dir/scripts_seqModules/parallel_mpileup.sh" "$user" "$project" "$main_dir" >> $logName;
		chmod 774 "$projectDirectory/data.pileup";

		echo -e "command used to force all reads to be output in pileup:" >> $logName;
		echo -e "\tbash \"$main_dir/scripts_seqModules/parallel_mpileup.sh\" \"$user\" \"$project\" \"$main_dir\" >> $logName;" >> $logName;
		bash "$main_dir/scripts_seqModules/parallel_mpileup_force.sh" "$user" "$project" "$main_dir" >> $logName;
		chmod 774 "$projectDirectory/data.pileup2";

		echo -e "\tSamtools : Pileups generated." >> $logName;
	fi;

	echo -e "Processing pileup for CNVs & SNPs." >> $condensedLog;

	( echo -e "\tPython : Processing pileup for SNPs." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/counts_SNPs_v5.py" "$projectDirectory/data.pileup" > "$projectDirectory/putative_SNPs_v4.txt" 2>> $logName;
	chmod 774 "$projectDirectory/putative_SNPs_v4.txt";
	echo -e "\tPython : Pileup processed for SNPs." >> $logName; ) &

	( echo -e "\tPython : Processing pileup(forced) for SNPs." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/counts_SNPs_v5.py" "$projectDirectory/data.pileup2" > "$projectDirectory/putative_SNPs_v4.txt2" 2>> $logName;
	chmod 774 "$projectDirectory/putative_SNPs_v4.txt2";
	echo -e "\tPython : Pileup processed for SNPs." >> $logName; ) &

	( echo -e "\tPython : Processing pileup for SNP-CNV." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/counts_CNVs-SNPs_v1.py" "$projectDirectory/data.pileup" > "$projectDirectory/SNP_CNV_v1.txt" 2>> $logName;
	chmod 774 "$projectDirectory/SNP_CNV_v1.txt";
	echo -e "\tPython : Pileup processed for SNP-CNV." >> $logName; ) &

	( echo -e "\tPython : Processing pileup(forced) for SNP-CNV." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/counts_CNVs-SNPs_v1.py" "$projectDirectory/data.pileup2" > "$projectDirectory/SNP_CNV_v1.txt2" 2>> $logName;
	chmod 774 "$projectDirectory/SNP_CNV_v1.txt2";
	echo -e "\tPython : Pileup processed for SNP-CNV." >> $logName; ) &

	wait;
fi

#=================================
# Build 'readStats.txt' file.
#---------------------------------
build_readstats_file(){
	fileOut=$1;
	fileIn=$2;

	sed -n '2~4p' "$projectDirectory/$datafile1" > "$projectDirectory/$datafile1.temp";	# Discared FASTQ lines except for sequence.
	sed -n '2~4p' "$projectDirectory/$datafile2" > "$projectDirectory/$datafile2.temp";
	readCount1=$(wc -l < "$projectDirectory/$datafile1.temp");				# Get number of reads.
	readCount2=$(wc -l < "$projectDirectory/$datafile2.temp");
	readTotalLength1=$(wc -c < "$projectDirectory/$datafile1.temp");				# Get total sequence length.
	readTotalLength2=$(wc -c < "$projectDirectory/$datafile2.temp");
	readCount=$((readCount1 + readCount2));
	readTotalLength=$((readTotalLength1 + readTotalLength2));
	echo "$readCount (reads count)" > "$projectDirectory/$fileOut";
	echo "$readTotalLength (reads total length)" >> "$projectDirectory/$fileOut";
	chmod 0777 "$projectDirectory/$fileOut";
	rm "$projectDirectory/$datafile1.temp";
	rm "$projectDirectory/$datafile2.temp";

	# Find genome size and add to $fileOut.txt file.
	sed -n '2~2p' "$genomeDirectory/datafile_g_0.2.fasta" > "$projectDirectory/reference.temp";
	referenceSeq="$projectDirectory/reference.temp";
	genomeChrCount=$(wc -l < $referenceSeq);
	genomeLengthInit=$(wc -c < $referenceSeq);
	genomeLength=$((genomeLengthInit-genomeChrCount));
	echo "$genomeLength (genome length)" >> "$projectDirectory/$fileOut";
	echo -e "##" >> $logName;
	echo -e "## Read depth calculations:" >> $logName;
	echo -e "##\t\$readTotalLength          = $readTotalLength" >> $logName;
	echo -e "##\t\$genomeLength             = $genomeLength" >> $logName;

	## Calculate expected average read depth and add to $fileOut.txt file.
	readDepthAverageExpected=$(echo -e "scale=3; $readTotalLength / $genomeLength" | bc -l);
	echo "$readDepthAverageExpected (Expected read depth)" >> "$projectDirectory/$fileOut";
	echo -e "##\t\$readDepthAverageExpected = $readDepthAverageExpected" >> $logName;

	## Find average read depth and add to $fileOut.txt file.
	readDepthAverageFound=$(awk '{sum += $3; count++} END {if (count > 0) print sum/count}' "$projectDirectory/$fileIn");
	echo "$readDepthAverageFound (Found read depth)" >> "$projectDirectory/$fileOut";
	echo -e "##\t\$readDepthAverageFound    = $readDepthAverageFound" >> $logName;

	## Calculate fraction mapped and add to $fileOut.txt file.
	fractionMapped1=$(echo -e "scale=6; ($readDepthAverageFound / $readDepthAverageExpected)*100" | bc -l);
	fractionMapped2=$(echo -e "scale=3; $fractionMapped1 / 1" | bc -l);
	echo -e "##\t\$fractionMapped1          = $fractionMapped1" >> $logName;
	echo -e "##\t\$fractionMapped2          = $fractionMapped2" >> $logName;
	echo "$fractionMapped2 (Mapped read fraction)" >> "$projectDirectory/$fileOut";
}
build_readstats_file "readStats.txt"  "SNP_CNV_v1.txt";
mappedReads1=$fractionMapped2;
build_readstats_file "readStats.txt2" "SNP_CNV_v1.txt2";
mappedReads2=$fractionMapped2;

#if [[ "$mappedReads1" < 10 ]]; then
#	if [[ "$mappedReads2" > 10 ]]; then
#		## Poor mapping quality, switch to no quality filters.

		## swap files around.
		mv "$projectDirectory/putative_SNPs_v4.txt"	"$projectDirectory/putative_SNPs_v4.txt3";
		mv "$projectDirectory/SNP_CNV_v1.txt"		"$projectDirectory/SNP_CNV_v1.txt3";

		mv "$projectDirectory/putative_SNPs_v4.txt2"	"$projectDirectory/putative_SNPs_v4.txt";
		mv "$projectDirectory/SNP_CNV_v1.txt2"		"$projectDirectory/SNP_CNV_v1.txt";

		mv "$projectDirectory/putative_SNPs_v4.txt3"    "$projectDirectory/putative_SNPs_v4.txt2";
		mv "$projectDirectory/SNP_CNV_v1.txt3"          "$projectDirectory/SNP_CNV_v1.txt2";
#		echo -e "Low read-mapping quality." > "$projectDirectory/warning.txt";
#	else
#		## Reads from wrong species mapped?
#		if [[ "$mappedReads1" < 1 ]]; then
#			echo -e "0$mappedReads1% reads mapped." > "$projectDirectory/warning.txt";
#		else
#			echo -e "$mappedReads1% reads mapped." > "$projectDirectory/warning.txt";
#		fi
#	fi
#fi
#---------------------------------
# End of 'readStats.txt' section.
#=================================


if [[ "$hapmapInUse" = 1 ]]; then
	echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
	if [[ -f $projectDirectory/trimmed_SNPs_v5.txt ]]; then
		echo -e "\t\tAlready done." >> $logName;
	else
		echo -e "\t\t| Inputs to python script:" >> $logName;
		echo -e "\t\t|\tgenome     = $genome"     >> $logName;
		echo -e "\t\t|\tgenomeUser = $genomeUser" >> $logName;
		echo -e "\t\t|\tproject    = $project"    >> $logName;
		echo -e "\t\t|\tuser       = $user"       >> $logName;
		echo -e "\t\t|\thapmap     = $hapmap"     >> $logName;
		echo -e "\t\t|\thapmapUser = $hapmapUser" >> $logName;
		echo -e "\t\t|\tmain_dir   = $main_dir"   >> $logName;
		$python_exec "$main_dir/scripts_seqModules/putative_SNPs_from_hapmap_in_child.py" "$genome" "$genomeUser" "$project" "$user" "$hapmap" "$hapmapUser" "$main_dir" > "$projectDirectory/trimmed_SNPs_v5.txt" 2>> $logName;
		echo -e "\t\tDone." >> $logName;

		chmod 774 "$projectDirectory/trimmed_SNPs_v5.txt";
	fi
fi

echo -e "Pileup processing is complete." >> $condensedLog;
echo -e "\nPileup processing complete.\n" >> $logName;
echo -e "-------------------------------------------------------------------------" >> $logName;
echo -e "Variables passed to next script." >> $logName;
echo -e "\t\$user     = "$user >> $logName;
echo -e "\t\$project  = "$project >> $logName;
echo -e "\t\$main_dir = "$main_dir >> $logName;
echo -e "-------------------------------------------------------------------------" >> $logName;

if [[ "$hapmapInUse" = 0 ]]; then
	echo -e "\nPassing processing on to 'project.WGseq.install_4.sh' for final analysis.\n" >> $logName;
	echo -e "\tCurrent directory = "$(pwd) >> $logName;
	echo -e "=========================================================================\n" >> $logName;
	bash "$main_dir/scripts_seqModules/scripts_WGseq/project.WGseq.install_4.sh" "$user" "$project" "$main_dir" 2>> $logName;
else
	echo -e "\nPassing processing on to 'project.WGseq.hapmap.install_4.sh' for final analysis.\n" >> $logName;
	echo -e "================================================================================\n" >> $logName;
	bash "$main_dir/scripts_seqModules/scripts_WGseq/project.WGseq.hapmap.install_4.sh" "$user" "$project" "$hapmap" "$main_dir" 2>> $logName;
fi
