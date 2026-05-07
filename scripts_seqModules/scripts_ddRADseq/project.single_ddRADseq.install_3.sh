#!/bin/bash
#
# project.single_ddRADseq.install_3.sh
#
set -e;

## All created files will have permission 760
umask 007;

### define script file locations.
user=$1;
project=$2;
main_dir=$(pwd)"/../../";


##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------

# Setup process_log.txt file.
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";
condensedLog=$projectDirectory"condensed_log.txt";


## Error handling in case something crashes.
trap 'bash queue_end.sh $user $project $main_dir $logName "Something went wrong. project.single_ddRADseq.install_3.sh:$LINENO"; echo -e "Something went wrong. project.single_ddRADseq.install_3.sh:$LINENO" > $projectDirectory"error.txt"; exit 1;' ERR;


echo -e "#.............................................................................." >> $logName;
echo -e "" >> $logName;
echo -e "Input to : project.single_ddRADseq.install_3.sh" >> $logName;
echo -e "\tuser     = "$user >> $logName;
echo -e "\tproject  = "$project >> $logName;
echo -e "\tmain_dir = "$main_dir >> $logName;
echo -e "" >> $logName;

# import locations of auxillary software for pipeline analysis.
. $main_dir"local_installed_programs.sh";
. $main_dir"config.sh";

# Define project directory.
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";

echo -e "Running 'scripts_seqModules/scripts_ddRADseq/project.paired_ddRADseq.install_3.sh'" >> $logName;
echo -e "Variables passed via command-line from 'scripts_seqModules/scripts_ddRADseq/project.paired_ddRADseq.install_2.php' :" >> $logName;
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
# "dataFormat.txt"
genome=$(head -n 1 $projectDirectory"genome.txt");
hapmap=$(tail -n 1 $projectDirectory"genome.txt");
dataFormat=$(head -n 1 $projectDirectory"dataFormat.txt");
echo -e "\tLocation variables from 'genome.txt' file entry." >> $logName;
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

# Get data file name from "datafiles.txt";
datafile=$(head -n 1 $projectDirectory"datafiles.txt");
echo -e "\tdatafile = '"$datafile"'" >> $logName;

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

echo -e "#============================================================================== 2" >> $logName;


reflocation=$main_dir"users/"$genomeUser"/genomes/"$genome"/";                 # Directory where FASTA file is kept.
FASTA=`sed -n 1,1'p' $reflocation"reference.txt"`;                             # Name of FASTA file.
FASTAname=$(echo $FASTA | sed 's/.fasta//g');                                  # name of genome file, without file type.
RestrctionEnzymes=`sed -n 1,1'p' $projectDirectory"restrictionEnzymes.txt"`;   # Name of restriction enxyme list file.
ddRADseq_FASTA=$FASTAname"."$RestrctionEnzymes".fasta";                        # Name of digested reference for ddRADseq analysis, using chosen restriction enzymes.


if [[ -f $projectDirectory"SNP_CNV_v1.txt" ]]
then
	echo -e "\tDone: SAM -> BAM, new group headers, sorted." >> $logName;
	echo -e "\tDone: Samtools.pileup." >> $logName;
else
	##==============================================================================
	## Trimming/cleanup of FASTQ files.
	##------------------------------------------------------------------------------
	echo -e "#=================================================#" >> $logName;
	echo -e "# Trimming of unbalanced FASTQ entries.           #" >> $logName;
	echo -e "#=================================================#" >> $logName;
	echo -e "Resolving FASTQ file errors." >> $condensedLog;
	currdir=$(pwd);
	cd $projectDirectory;
	bash $main_dir"scripts_seqModules/FASTQ_1_trimming.sh" $projectDirectory$datafile >> $logName;
	cd $currdir;
	echo -e "\tFASTQ files trimmed using : 'FASTQ_trimming.sh'" >> $logName;


	##==============================================================================
	## Initial processing of paired-ddRADseq dataset.
	##------------------------------------------------------------------------------
	echo -e "#====================================================#" >> $logName;
	echo -e "# Initial processing of paired-end ddRADseq dataset. #" >> $logName;
	echo -e "#====================================================#" >> $logName;

	# Align fastq against genome.
	echo -e "[[=- Align with Bowtie -=]]" >> $logName;
	echo -e "Aligning reads with Bowtie2 => SAM file." >> $condensedLog;

	if [[ -f $projectDirectory"data.bam" ]]
	then
		echo -e "\tDone: SAM -> BAM, new group headers, sorted." >> $logName;
	else
		echo -e "\tBowtie : paired-end reads aligning into SAM file." >> $logName;
		## Bowtie 2 command for paired reads:
		echo -e "\nRunning bowtie2.\n";
		$bowtie2Directory"bowtie2" --very-sensitive -p $cores $genomeDirectory"bowtie_index" -U $projectDirectory$datafile -S $projectDirectory"data.sam";
			# -S : SAM output mode.
			# -p : number of threads to use.
			# -1 : dataset.
		    # --very-sensitive : a default set of configurations.
		echo -e "\tBowtie : paired-end reads aligned into SAM file." >> $logName;

		echo -e "\tSamtools : converting Bowtie-SAM into compressed format (BAM) file." >> $logName;
		echo -e "Compressing SAM file => BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:view.\n";
		$samtools_exec view -@ $cores -bT $genomeDirectory$genomeFASTA $projectDirectory"data.sam" > $projectDirectory"data.temp.bam";
		rm $projectDirectory"data.sam";
		echo -e "\tSamtools : Bowtie-SAM converted into compressed format (BAM) file." >> $logName;

		echo -e "\tPicard : Adding headers to Bowtie-BAM file." >> $logName;
		echo -e "Standardizing BAM read group headers." >> $condensedLog;
		echo -e "\nRunning picard:AddOrReplaceReadGroups.\n";
		java -Xmx2g -jar $picardDirectory"AddOrReplaceReadGroups.jar" INPUT=$projectDirectory"data.temp.bam" OUTPUT=$projectDirectory"data.bam" RGID=1 RGLB=1 RGPL=ILLUMINA RGPU=1 RGSM=SM VALIDATION_STRINGENCY=SILENT;
		rm $projectDirectory"data.temp.bam";
		echo -e "\tPicard : Headers added to Bowtie-BAM file." >> $logName;

		echo -e "[[=- Sorting/Indexing BAM files -=]]" >> $logName;
		echo -e "\tSamtools : Bowtie-BAM sorting & indexing." >> $logName;
		echo -e "Sorting BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:sort.\n";
		$samtools_exec sort -@ $cores $projectDirectory"data.bam" -o $projectDirectory"data_sorted.bam" -T $projectDirectory;
		echo -e "Indexing BAM file." >> $condensedLog;
		echo -e "\nRunning samtools:index.\n";
		$samtools_exec index $projectDirectory"data_sorted.bam";
		echo -e "\tSamtools : Bowtie-BAM sorted & indexed." >> $logName;
	fi

	if [[ -f $projectDirectory"data.pileup" ]]
	then
		echo -e "\tSamtools.pileup generated." >> $logName;
	else
		echo -e "#============================================================================== 3" >> $logName;

		echo -e "[[=- In-house SNP/CNV analysis -=]]" >> $logName;
		usedFile=$projectDirectory"data_sorted.bam";
		echo -e "\tSamtools : Generating pileup.   (for SNP/CNV analysis)" >> $logName;
		echo -e "Generating pileup file." >> $condensedLog;
		echo -e "\nRunning samtools:mpileup.\n";
		$python_exec $main_dir"scripts_seqModules/parallel_mpileup.py" $samtools_exec $genomeDirectory$genomeFASTA $usedFile $logName $cores $genomeDirectory data.pileup 2>> $logName;
		echo -e "\tSamtools : Pileup generated." >> $logName;
	fi

	echo -e "Processing pileup for CNVs & SNPs." >> $condensedLog;

	( echo -e "\tPython : Processing pileup for SNPs." >> $logName;
	$python_exec $main_dir"scripts_seqModules/counts_SNPs_v5.py" $projectDirectory"data.pileup" > $projectDirectory"putative_SNPs_v4.txt" 2>> $logName;
	echo -e "\tPython : Pileup processed for SNPs." >> $logName; ) &

	( echo -e "\tPython : Processing pileup for SNP-CNV." >> $logName;
	$python_exec $main_dir"scripts_seqModules/counts_CNVs-SNPs_v1.py" $projectDirectory"data.pileup" > $projectDirectory"SNP_CNV_v1.txt" 2>> $logName;
	echo -e "\tPython : Pileup processed for SNP-CNV." >> $logName; ) &

	wait;
fi
if [[ -f $projectDirectory"trimmed_SNPs_v4.txt" ]]
then
	echo -e "\tPython : Simplify parental putative_SNP list to contain only those loci with an allelic ratio on range [0.25 .. 0.75]." >> $logName;
	echo -e "\t\tDone." >> $logName;
	echo -e "\tPython : Simplify child putative_SNP list to contain only those loci with an allelic ratio on range [0.25 .. 0.75] in the parent dataset." >> $logName;
	echo -e "\t\tDone." >> $logName;
else
	echo -e "\tPython : Simplify parental putative_SNP list to contain only those loci with an allelic ratio on range [0.25 .. 0.75]." >> $logName;
	$python_exec $main_dir"scripts_seqModules/scripts_ddRADseq/putative_SNPs_from_parent.py"            $genome $genomeUser $project $user $projectParent $projectParentUser $main_dir > $projectDirectory"trimmed_SNPs_v4.parent.txt" 2>> $logName;
	echo -e "\t\tDone." >> $logName;

	echo -e "\tPython : Simplify child putative_SNP list to contain only those loci with an allelic ratio on range [0.25 .. 0.75] in the parent dataset." >> $logName;
	$python_exec $main_dir"scripts_seqModules/scripts_ddRADseq/putative_SNPs_from_parent_in_child.3.py" $genome $genomeUser $project $user $main_dir > $projectDirectory"trimmed_SNPs_v4.txt" 2>> $logName;
	echo -e "\t\tDone." >> $logName;
fi
if [[ $hapmapInUse = 1 ]]
then
	if [[ -f $projectDirectory"trimmed_SNPs_v5.txt" ]]
	then
		echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
		echo -e "\t\tDone." >> $logName;
	else
		echo -e "\tPython : Simplify child putative_SNP list to contain only those loci found in the haplotype map." >> $logName;
		$python_exec $main_dir"scripts_seqModules/putative_SNPs_from_hapmap_in_child.py"   $genome $genomeUser $project $user $hapmap $hapmapUser $main_dir > $projectDirectory"trimmed_SNPs_v5.txt" 2>> $logName;
		echo -e "\t\tDone." >> $logName;
	fi
fi


echo -e "Pileup processing is complete." >> $condensedLog;
echo -e "\n\tPileup processing complete.\n" >> $logName;

if [[ $hapmapInUse = 0 ]]
then
	echo -e "\nPassing processing on to 'scripts_seqModules/scripts_ddRADseq/project.ddRADseq.install_4.sh' for final analysis.\n" >> $logName;
	echo   "============================================================================\n" >> $logName;
	bash $main_dir"scripts_seqModules/scripts_ddRADseq/project.ddRADseq.install_4.sh" $user $project 2>> $logName;
else
	echo -e "\nPassing processing on to 'scripts_seqModules/scripts_ddRADseq/project.ddRADseq.hapmap.install_4.sh' for final analysis.\n" >> $logName;
	echo   "===================================================================================\n" >> $logName;
	bash $main_dir"scripts_seqModules/scripts_ddRADseq/project.ddRADseq.hapmap.install_4.sh" $user $project $hapmap 2>> $logName;
fi
