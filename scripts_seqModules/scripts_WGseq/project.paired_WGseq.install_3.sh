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

# Get memory target from "constants.php" file.
MAX_MEMORY_TARGET=$(grep "MAX_MEMORY_TARGET" "$main_dir/constants.php" | tr -dc '0-9');
if [[ "$MAX_MEMORY_TARGET" -gt "0" ]]; then
	# Get FASTQ data total size in bytes.
	FILESIZE1=$(stat -c%s "$main_dir/users/$user/projects/$project/datafile_0.fastq")
	FILESIZE2=$(stat -c%s "$main_dir/users/$user/projects/$project/datafile_1.fastq")
	FILESIZE=$(($FILESIZE1 + $FILESIZE2));

	READS_RAW1=$(wc -l < "$main_dir/users/$user/projects/$project/datafile_0.fastq");
	READS_RAW2=$(wc -l < "$main_dir/users/$user/projects/$project/datafile_1.fastq");
	READS1=$(printf %.0f $( echo "$READS_RAW1/4" | bc -l) );
	READS2=$(printf %.0f $( echo "$READS_RAW2/4" | bc -l) );


	## if file 1 and 2 are different sizes
	if [[ $READS_RAW1 -ne $READS_RAW2 ]]; then
		if [[ $READS_RAW1 -gt $READS_RAW2 ]]; then
			# trim file 1, to length $READS_RAW2.
			head -n $READS_RAW2 "$main_dir/users/$user/projects/$project/datafile_0.fastq" > "$main_dir/users/$user/projects/$project/datafile_0_temp.fastq";
			mv "$main_dir/users/$user/projects/$project/datafile_0_temp.fastq" "$main_dir/users/$user/projects/$project/datafile_0.fastq";
			READS1=$READS2;
		else
			# trim file 2, to length $READS_RAW1.
			head -n $READS_RAW1 "$main_dir/users/$user/projects/$project/datafile_1.fastq" "$main_dir/users/$user/projects/$project/datafile_1_temp.fastq";
			mv "$main_dir/users/$user/projects/$project/datafile_1_remp.fastq" "$main_dir/users/$user/projects/$project/datafile_1.fastq";
			READS2=$READS1;
		fi;
	fi;

	echo -e "#\tFILESIZE1               = $FILESIZE1 (bytes)" >> $logName;
	echo -e "#\tFILESIZE2               = $FILESIZE2 (bytes)" >> $logName;
	echo -e "#\tREADS_RAW1              = $READS_RAW1" >> $logName;
	echo -e "#\tREADS_RAW2              = $READS_RAW2" >> $logName;
	echo -e "#\tREADS1                  = $READS1" >> $logName;
	echo -e "#\tREADS2                  = $READS2" >> $logName;

	# Calculate FASTQ data total size in GB.
	FILESIZE_GB=$(echo "$FILESIZE/1000000000" | bc -l)
	echo -e "#\tFILESIZE_GB             = $FILESIZE_GB (GB)" >> $logName;

	# Fit function relating FASTQ size (GB) to memory utilization (GB).
	#	f(x) = A x + B
	#		f(x) = memory utilization (GB)
	#		x = FASTQ size (GB)
	# To calculate the data that will produce a specific memory utilization, we invert the function.
	#	f(y) = (y - B)/A
	#		f(y) = FASTQ size (GB)
	#		y = memory utilization (GB)
	A="2.4168477588029";
	B="-1.13116709532669";
	# Terms to fit function may need to be characterized at install.

	MAX_PROCESSED_DATA_SIZE=$(echo "($MAX_MEMORY_TARGET - $B)/$A" | bc -l);
	echo -e "#\tMAX_PROCESSED_DATA_SIZE = $MAX_PROCESSED_DATA_SIZE (GB)" >> $logName;

	if [[ $(echo "$FILESIZE_GB > $MAX_PROCESSED_DATA_SIZE" | bc -l) = "1" ]]; then
		echo -e "#\t\tFILESIZE_GB > MAX_PROCESSED_DATA_SIZE => FASTQ subsampling needed." >> $logName;
		# Calculate fraction of target vs original.
		TARGET_FRACTION=$(echo "$MAX_PROCESSED_DATA_SIZE/$FILESIZE_GB" | bc -l);	# Calculate the target number of paired reads.
		TARGET_READS=$(printf %.0f $(echo "$TARGET_FRACTION*$READS1" | bc -l) );	# Round to whole number of reads.
		echo -e "#\tTARGET_FRACTION         = $TARGET_FRACTION (= MAX_PROCESSED_DATA_SIZE/FILESIZE_GB)" >> $logName;
		echo -e "#\tTARGET_READS            = $TARGET_READS" >> $logName;

		echo -e "Downsampling FASTQ data." >> $condensedLog;
		echo -e "#\tDownsampling FASTQ data:" >> $logName;
		echo -e "#\t\tMemory utilization target : $MAX_MEMORY_TARGET (GB)" >> $logName;
		echo -e "#\t\tDownsampling fraction     : $TARGET_FRACTION" >> $logName;

		# Subsample FASTQ files to target fraction.
		cd "$main_dir/users/$user/projects/$project/";
		install /dev/null datafile_0.sample.fastq;
		install /dev/null datafile_1.sample.fastq;

		## Use FADSO to downsample reads.
		#fadso pair -1 datafile_0.fastq -2 datafile_1.fastq -a datafile_0.sample.fastq -b datafile_1.sample.fastq -k $TARGET_READS;

		## Use SEQTK to downsample reads.
		randSeed=$((1 + $RANDOM % 1000));
		seqtk sample -2 -s $randSeed datafile_0.fastq $TARGET_READS > datafile_0.sample.fastq;
		seqtk sample -2 -s $randSeed datafile_1.fastq $TARGET_READS > datafile_1.sample.fastq;

		unlink datafile_0.fastq;
		unlink datafile_1.fastq;
		mv datafile_0.sample.fastq datafile_0.fastq;
		mv datafile_1.sample.fastq datafile_1.fastq;
		echo -e "#\t\tdatafile_0.fastq and datafile_1.fastq downsampled." >> $logName;
		cd "$main_dir";

	else
		TARGET_FRACTION="1";
		echo -e "#\t\tFILESIZE_GB < MAX_PROCESSED_DATA_SIZE => FASTQ subsampling not needed." >> $logName;
	fi;
else
	# Used later to ensure low read mapping warning isn't given because of downsampling.
	TARGET_FRACTION="1";
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

# Get first data file name from "datafiles.txt";
datafile1=$(head -n 1 "$projectDirectory/datafiles.txt");
echo -e "\tdatafile 1 = $datafile1" >> $logName;

# Get second data file name from "datafiles.txt";
datafile2=$(tail -n 1 "$projectDirectory/datafiles.txt");
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
# Not needed becuase FASTQC is not used.
#	##==============================================================================
#	## Trimming/cleanup of FASTQ files.
#	##------------------------------------------------------------------------------
#	echo -e "#=======================================================================================#" >> $logName;
#	echo -e "# Trimming of unbalanced FASTQ entries using 'scripts_seqModules/FASTQ_2_trimming.sh'.  #" >> $logName;
#	echo -e "#=======================================================================================#" >> $logName;
#	echo -e "Resolving FASTQ file errors." >> $condensedLog;
#	currdir=$(pwd);
#	cd "$projectDirectory";
#	bash "$main_dir/scripts_seqModules/FASTQ_2_trimming.sh" "$projectDirectory/$datafile1" "$projectDirectory/$datafile2" >> $logName;
#	cd $currdir;

	##==============================================================================
	## Initial processing of paired-WGseq dataset.
	##------------------------------------------------------------------------------
	echo -e "#=================================================#" >> $logName;
	echo -e "# Initial processing of paired-end WGseq dataset. #" >> $logName;
	echo -e "#=================================================#" >> $logName;

	# Align fastq against genome.
	echo -e "[[=- Align with Bowtie -=]]" >> $logName;
	echo -e "Aligning reads with Bowtie2 => SAM file." >> $condensedLog;

	if [[ -f $projectDirectory/data.bam ]]; then
		echo -e "\tDone: SAM -> BAM, new group headers, sorted." >> $logName;
	else
		echo -e "\tBowtie : paired-end reads aligning into SAM file." >> $logName;

		## Bowtie 2 command for paired reads:
		echo -e "\nRunning bowtie2.\n" >> $logName;
		echo -e "Command used:" >> $logName;
		echo -e "\t$bowtie2Directory\"bowtie2\" --very-sensitive -p '$cores' -x '$genomeDirectory/bowtie_index' -1 '$projectDirectory/$datafile1' -2 '$projectDirectory/$datafile2' -S '$projectDirectory/data.sam'";
		$bowtie2Directory"bowtie2" --very-sensitive -p "$cores" -x "$genomeDirectory/bowtie_index" -1 "$projectDirectory/$datafile1" -2 "$projectDirectory/$datafile2" > "$projectDirectory/data.bam" 2>> $logName;
			# -p : number of threads to use.
			# -1 : dataset.
		    # --very-sensitive : a default set of configurations.
		chmod 774 "$projectDirectory/data.bam";
		echo -e "\tBowtie : paired-end reads aligned into BAM file." >> $logName;

		echo -e "[[=- Sorting/Indexing BAM files -=]]" >> $logName;
		echo -e "\tSamtools : Bowtie-BAM sorting & indexing." >> $logName;
		echo -e "Sorting BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:sort.\n";
		$samtools_exec sort -@ "$cores" "$projectDirectory/data.bam" -o "$projectDirectory/data_sorted.bam" -T "$projectDirectory" 2>> $logName;
		chmod 774 "$projectDirectory/data_sorted.bam";

		echo -e "Indexing BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:index.\n";
		$samtools_exec index "$projectDirectory/data_sorted.bam" 2>> $logName;
		chmod 774 "$projectDirectory/data_sorted.bam.bai";
		echo -e "\tSamtools : Bowtie-BAM sorted & indexed." >> $logName;
	fi;

	if [[ -f $projectDirectory/data.pileup ]]; then
		echo -e "\tSamtools.pileup generated." >> $logName;
	else
		echo -e "#============================================================================== 3" >> $logName;

		echo -e "[[=- In-house SNP/CNV analysis -=]]" >> $logName;
		echo -e "\tSamtools : Generating pileup.   (for SNP/CNV analysis)" >> $logName;
		echo -e "Generating pileup file." >> $condensedLog;
		echo -e "command used:" >> $logName;
		echo -e "\tbash \"$main_dir/scripts_seqModules/parallel_mpileup.sh\" \"$user\" \"$project\" \"$main_dir\" >> $logName;" >> $logName;
		bash "$main_dir/scripts_seqModules/parallel_mpileup.sh" "$user" "$project" "$main_dir" >> $logName;
		chmod 774 "$projectDirectory/data.pileup";
		echo -e "\tSamtools : Pileup generated." >> $logName;
	fi;

	echo -e "Processing pileup for CNVs & SNPs." >> $condensedLog;

	( echo -e "\tPython : Processing pileup for SNPs." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/counts_SNPs_v5.py" "$projectDirectory/data.pileup" > "$projectDirectory/putative_SNPs_v4.txt" 2>> $logName;
	chmod 774 "$projectDirectory/putative_SNPs_v4.txt";
	echo -e "\tPython : Pileup processed for SNPs." >> $logName; ) &

	( echo -e "\tPython : Processing pileup for SNP-CNV." >> $logName;
	$python_exec "$main_dir/scripts_seqModules/counts_CNVs-SNPs_v1.py" "$projectDirectory/data.pileup" > "$projectDirectory/SNP_CNV_v1.txt" 2>> $logName;
	chmod 774 "$projectDirectory/SNP_CNV_v1.txt";
	echo -e "\tPython : Pileup processed for SNP-CNV." >> $logName; ) &

	wait;
fi


# Find genome size and add to readStats.txt file.
sed -n '2~2p' "$genomeDirectory/datafile_g_0.2.fasta" > "$projectDirectory/reference.temp";
referenceSeq="$projectDirectory/reference.temp";
genomeChrCount=$(cat $referenceSeq | wc -l);
genomeLengthInit=$(cat $referenceSeq | wc -c);
genomeLength=$((genomeLengthInit-genomeChrCount));
echo "$genomeLength (genome length)" >> "$projectDirectory/readStats.txt"

## Read in [read count] and [total read length] from readStats.txt file.
readCount=$(head -n 1 "$projectDirectory/readStats.txt" | awk '{print $1}');
readTotalLength=$(head -n 2 "$projectDirectory/readStats.txt" | tail -n 1 | awk '{print $1}');

echo -e "##" >> $logName;
echo -e "## Read depth calculations:" >> $logName;
echo -e "##\t\$readTotalLength          = $readTotalLength" >> $logName;
echo -e "##\t\$TARGET_FRACTION          = $TARGET_FRACTION" >> $logName;
echo -e "##\t\$genomeLength             = $genomeLength" >> $logName;

## Calculate expected average read depth and add to readStats.txt file.
readDepthAverageExpected=$(echo -e "scale=3; $readTotalLength*$TARGET_FRACTION / $genomeLength" | bc -l);
echo "$readDepthAverageExpected (Expected read depth)" >> "$projectDirectory/readStats.txt";

echo -e "##\t\$readDepthAverageExpected = $readDepthAverageExpected" >> $logName;

## Find average read depth and add to readStats.txt file.
readDepthAverageFound=$(awk '{sum += $3; count++} END {if (count > 0) print sum/count}' "$projectDirectory/SNP_CNV_v1.txt");
echo "$readDepthAverageFound (Found read depth)" >> "$projectDirectory/readStats.txt";

echo -e "##\t\$readDepthAverageFound    = $readDepthAverageFound" >> $logName;

## Calculate fraction mapped and add to readStats.txt file.
fractionMapped1=$(echo -e "scale=6; ($readDepthAverageFound / $readDepthAverageExpected)*100" | bc -l);
fractionMapped2=$(echo -e "scale=3; $fractionMapped1 / 1" | bc -l);

echo -e "##\t\$fractionMapped1          = $fractionMapped1" >> $logName;
echo -e "##\t\$fractionMapped2          = $fractionMapped2" >> $logName;

echo "$fractionMapped2 (Mapped read fraction)" >> "$projectDirectory/readStats.txt";
if [[ "$fractionMapped2" < 50 ]]; then
	if [[ "$fractionMapped2" < 1 ]]; then
		echo -e "0$fractionMapped2% reads mapped." >> "$projectDirectory/warning.txt";
	else
		echo -e "$fractionMapped2% reads mapped." >> "$projectDirectory/warning.txt";
	fi
fi

if [[ "$hapmapInUse" = 1 ]]; then
	if [[ -f $projectDirectory/trimmed_SNPs_v5.txt ]]; then
		echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
		echo -e "\t\tDone." >> $logName;
	else
		echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
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
