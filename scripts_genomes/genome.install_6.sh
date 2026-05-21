#!/bin/bash
#
# genome.install_6.sh
#
set -e;

## All created files will have permission 760
umask 007;

## define script file locations.
user=$1;
genome=$2;
main_dir=$(pwd)"/../";
script_dir=$(pwd);

genomeDirectory=$main_dir"users/"$user"/genomes/"$genome"/";
FASTA=`sed -n 1,1'p' $genomeDirectory"reference.txt"`;					# Name of FASTA file.
FASTAname=$(echo $FASTA | sed 's/\.fasta//g');						# Name of genome file, without file type.
FASTA2=$(echo $FASTA | sed 's/\.fasta/\.2\.fasta/g');					# Name of reformatted genome file, to single-line entries.

if [ -e $genomeDirectory"repeat_kmer_length.txt" ]; then
	file=$genomeDirectory"repeat_kmer_length.txt";
	repet_kmerLength=$(cat "$file")
else
	repet_kmerLength=23;								# 23 bp is long enough for most sequences to be unique in a yeast genome.
fi

skew_kmerLength=25001; # needs to be an odd number.					# https://berthub.eu/articles/skewdb/ uses a 4096 bp kmer; not clear ideal length.
skew_kmerStep=100;
	# 50 is way too small kmer length.
	# 50000 seems right for yeast genomes.
genomeRepetWIG=$genomeDirectory"datafile_g_0.2.wig";	# File containing repetitiveness data for genome.
standard_bin_FASTA=$genomeDirectory$FASTAname".standard_bins.fasta";			# Name of reference genome broken up into standard bins.
standard_bin_SNPs_FASTA=$genomeDirectory$FASTAname".standard_bins.SNPs.fasta";		# Name of reference genome broken up into standard bins for SNPs.
ddRADseq_FASTA=$genomeDirectory$FASTAname".MfeI_MboI.fasta";				# Name of digested reference for ddRADseq analysis.
logName=$genomeDirectory"process_log.txt";
condensedLog=$genomeDirectory"condensed_log.txt";


## Error handling in case something crashes.
trap 'bash queue_end.sh $user $genome $main_dir $logName "Something went wrong. genome.install_6.sh:$LINENO"; echo -e "Something went wrong. genome.install_6.sh:$LINENO" > $genomeDirectory"error.txt"; exit 1;' ERR;


echo -e "\n\nRunning 'scripts_genomes/genome.install_6.sh'" >> $logName;
echo -e "\tInput to shell script:" >> $logName;
echo -e "\t\t\$1 (user)          = $1" >> $logName;
echo -e "\t\t\$2 (genome)        = $2" >> $logName;
echo -e "" >> $logName;
echo -e "\tImportant location variables in script:" >> $logName;
echo -e "\t\t\$logName           = "$logName >> $logName;
echo -e "\t\t\$genomeDirectory   = "$genomeDirectory >> $logName;
echo -e "\t\t\$FASTA             = "$FASTA >> $logName;
echo -e "\t\t\$FASTAname         = "$FASTAname >> $logName;
echo -e "\t\t\$ddRADseq_FASTA    = "$ddRADseq_FASTA >> $logName;
echo -e "\t\t\$repet_kmerLenghth = "$repet_kmerLength >> $logName;
echo -e "" >> $logName;
echo -e "Setting up for processing." >> $condensedLog;

# load local installed program location variables.
. $main_dir"local_installed_programs.sh";

##============================================#
# Initialization of various programs below.   #
#============================================##

echo -e "\n\t============================================================================================== 1" >> $logName;

## Check is genome and index files for Bowtie are available: Exit if genome files not found; Generate index files if needed.
if [ ! -e $genomeDirectory"bowtie_index.4.bt2" ]
then
	echo -e "Generating Bowtie2 index for genome." >> $condensedLog;
	echo -e "\tBowtie index for genome '$genome' not found: Reindexing genome." >> $logName;
	## Bowtie 2 commands:
	echo -e "\t"$bowtie2Directory"bowtie2-build "$genomeDirectory$FASTA" " $genomeDirectory"bowtie_index" >> $logName;
	$bowtie2Directory"bowtie2-build" $genomeDirectory$FASTA $genomeDirectory"bowtie_index";
else
	echo -e "\tBowtie index for genome '$genome' found" >> $logName;
fi

echo -e "\n\t============================================================================================== 4" >> $logName;

## Check if Samtools FASTA index file is found.
if [ -e $genomeDirectory$FASTA".fai" ]
then
	echo -e "\tFASTA index file for genome '$genome' found." >> $logName;
else
	echo -e "Generatiing FASTA dictionary file for genome, step2." >> $condensedLog;
	echo -e "\tFASTA index file not found for genome '$genome': Regenerating using SamTools." >> $logName;
	$samtools_exec faidx $genomeDirectory$FASTA;
fi

echo -e "\n\t============================================================================================== 5" >> $logName;

## Generate version of FASTA genome file to have single-line entries.
if [ -e $genomeDirectory$FASTA2 ]; then
	echo -e "\tFASTA already reformated to single-line entries." >> $logName;
else
	echo -e "\tReformating FASTA into single-line entries." >> $logName;
	bash $main_dir"scripts_seqModules/FASTA_reformat_1.sh" $genomeDirectory$FASTA > $genomeDirectory$FASTA2;
fi;

echo -e "\n\t============================================================================================== 5a" >> $logName;

## Check which figures are to be generated for genome.
repetBool=$(head -n 2 $genomeDirectory"figure_options.txt" | tail -n 1);
skewBool=$(head -n 3 $genomeDirectory"figure_options.txt" | tail -n 1);
cartoonBool=$(head -n 4 $genomeDirectory"figure_options.txt" | tail -n 1);

if [ "$repetBool" = "False" ]
then
	echo -e "\t###" >> $logName;
	echo -e "\t### Genome is not being processed for repetitiveness." >> $logName;
	echo -e "\t###" >> $logName;
else
	echo -e "\t###" >> $logName;
	echo -e "\t### Genome is being processed for repetitiveness." >> $logName;
	echo -e "\t###" >> $logName;
	echo -e "Processing genome for repetitiveness." >> $condensedLog;

	if [ ! -e $genomeDirectory"datafile_g_0.repetitiveness_"$repet_kmerLength".txt" ]
	then
		echo -e "\tGenerating repetitiveness dictionary." >> $logName;
		echo -e "\t\t bash "$main_dir"scripts_genomes/FASTA_repetitiveness_dictionary.sh "$user" "$genome" "$main_dir" "$logName" "$repet_kmerlength" >> "$logName" 2>> "$logName";" >> $logName;
		bash $main_dir"scripts_genomes/FASTA_repetitiveness_dictionary.sh"       $user $genome $main_dir $logName $repet_kmerLength >> $logName 2>> $logName;

		echo -e "\tCleaning up repetitiveness dictionary." >> $logName;
		echo -e "\t\t bash "$main_dir"scripts_genomes/FASTA_repetitiveness_dictionary_clean.sh "$user" "$genome" "$main_dir" "$logName" "$repet_kmerlength" >> "$logName" 2>> "$logName";" >> $logName;
		bash $main_dir"scripts_genomes/FASTA_repetitiveness_dictionary_clean.sh" $user $genome $main_dir $logName $repet_kmerLength >> $logName 2>> $logName;
	else
		echo -e "\tRepetitiveness dictionary for genome '$genome' found" >> $logName;
	fi
	if [ ! -e $genomeDirectory"datafile_g_0.repetitiveness_"$repet_kmerLength".wig" ]
	then
		echo -e "\tMaking repetitiveness profile (*.wig)." >> $logName;
		echo -e "\t\t bash "$main_dir"scripts_genomes/FASTA_repetitiveness-to-WIG.sh "$user" "$genome" "$main_dir" "$logName" "$repet_kmerlength" >> "$logName" 2>> "$logName";" >> $logName;
		bash $main_dir"scripts_genomes/FASTA_repetitiveness-to-WIG.sh"           $user $genome $main_dir $logName $repet_kmerLength >> $logName 2>> $logName;
	else
		echo -e "\tRepetitiveness profile (*.wig) for genome '$genome' found" >> $logName;
	fi

	echo -e "#==================================#" >> $logName;
	echo -e "# Generate repetitiveness figure.  #" >> $logName;
	echo -e "#==================================#" >> $logName;
	echo -e "Generating repetitiveness figure." >> $condensedLog;

	echo -e "\tGenerating OCTAVE script to generate repetitiveness figure." >> $logName;
	outputName=$genomeDirectory"processing1.m";
	echo -e "\toutputName = "$outputName >> $logName;

	echo -e "function [] = processing1()" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('"$genomeDirectory"octave.repet.log');" >> $outputName;
	echo -e "\tcd "$main_dir"scripts_genomes/;" >> $outputName;
	echo -e "\trepetitiveness_plot('"$main_dir"','"$user"','"$genome"','"$repet_kmerLength"');" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing1()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('"$genomeDirectory"octave.repet.log');" >> $logName;
	echo -e "\t|\t    cd "$main_dir"scripts_genomes/;" >> $logName;
	echo -e "\t|\t    repetitiveness_plot('"$main_dir"','"$user"','"$genome"','"$repet_kmerLength"');" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\tCalling OCTAVE." >> $logName;
	echo -e "================================================================================================";
	echo -e "== Repetitiveness figure =======================================================================";
	echo -e "================================================================================================";
	cd $genomeDirectory;
	$octave_exec $outputName;
	cd $script_dir;
	##echo -e "\tOCTAVE log from repetitiveness figure generation." >> $logName;
	##sed 's/^/\t|/;' $genomeDirectory"octave.repet.log" >> $logName;
fi

echo -e "\n\t============================================================================================== 5b" >> $logName;

if [ "$skewBool" = "False" ]
then
	echo -e "\t###" >> $logName;
        echo -e "\t### Genome is not being processed for GC-skew and AT-skew." >> $logName;
	echo -e "\t###" >> $logName;
else
	echo -e "\t###" >> $logName;
	echo -e "\t### Genome is being processed for GC-skew and AT-skew." >> $logName;
	echo -e "\t###" >> $logName;

	echo -e "Processing genome for GC-skew." >> $condensedLog;
	echo -e "\tGenerating GC-skew dictionary." >> $logName;
	echo -e "\t\t bash "$main_dir"scripts_genomes/FASTA_GCskew_dictionary.sh "$user" "$genome" "$main_dir" "$logName" "$skew_kmerLength" "$skew_kmerStep" >> "$logName" 2>> "$logName >> $logName;
        bash $main_dir"scripts_genomes/FASTA_GCskew_dictionary.sh" $user $genome $main_dir $logName $skew_kmerLength $skew_kmerStep >> $logName 2>> $logName;

	echo -e "Processing genome for AT-skew." >> $condensedLog;
	echo -e "\tGenerating AT-skew dictionary." >> $logName;
	echo -e "\t\t bash "$main_dir"scripts_genomes/FASTA_ATskew_dictionary.sh "$user" "$genome" "$main_dir" "$logName" "$skew_kmerLength" "$skew_kmerStep" >> "$logName" 2>> "$logName >> $logName;
	bash $main_dir"scripts_genomes/FASTA_ATskew_dictionary.sh" $user $genome $main_dir $logName $skew_kmerLength $skew_kmerStep >> $logName 2>> $logName;

	echo -e "#==============================#" >> $logName;
	echo -e "# Generate GC/AT-skew figure.  #" >> $logName;
	echo -e "#==============================#" >> $logName;
	echo -e "Generating GC-skew figure." >> $condensedLog;

	echo -e "\tGenerating OCTAVE script to generate GC/AT-skew figure." >> $logName;
	outputName=$genomeDirectory"processing2.m";
	echo -e "\toutputName = "$outputName >> $logName;

	echo -e "function [] = processing2()" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('"$genomeDirectory"octave.skew.log');" >> $outputName;
	echo -e "\tcd "$main_dir"scripts_genomes/;" >> $outputName;
	echo -e "\tGCskew_plot('"$main_dir"','"$user"','"$genome"','"$skew_kmerLength"','"$skew_kmerStep"');" >> $outputName;
	echo -e "end" >> $outputName;

	echo -e "\t|\tfunction [] = processing2()" >> $logName;
	echo -e "\t|\t    pkg load matgeom;" >> $logName;
	echo -e "\t|\t    diary('"$genomeDirectory"octave.skew.log');" >> $logName;
	echo -e "\t|\t    cd "$main_dir"scripts_genomes/;" >> $logName;
	echo -e "\t|\t    GCskew_plot('"$main_dir"','"$user"','"$genome"','"$skew_kmerLength"','"$skew_kmerStep"');" >> $logName;
	echo -e "\t|\tend" >> $logName;

	echo -e "\tCalling OCTAVE." >> $logName;
	echo -e "================================================================================================";
	echo -e "== GC/AT-skew figure ===========================================================================";
	echo -e "================================================================================================";
	cd $genomeDirectory;
	$octave_exec $outputName;
	cd $script_dir;
	##echo -e "\tOCTAVE log from GC/AT-skew figure generation." >> $logName;
	##sed 's/^/\t|/;' $genomeDirectory"octave.skew.log" >> $logName;
fi

echo -e "\n\t============================================================================================== 5b" >> $logName;

if [ "$cartoonBool" = "False" ]
then
	echo -e "\t###" >> $logName;
	echo -e "\t### Cartoon figure is not bening made." >> $logName;
	echo -e "\t###" >> $logName;
else
	echo -e "\t###" >> $logName;
	echo -e "\t### Cartoon figure is being made.." >> $logName;
	echo -e "\t###" >> $logName;

	echo -e "#===========================#" >> $logName;
	echo -e "# Generate Cartoon figure.  #" >> $logName;
	echo -e "#===========================#" >> $logName;
	echo -e "Generating cartoon figure." >> $condensedLog;

	echo -e "\tGenerating OCTAVE script to generate cartoon figure." >> $logName;
	outputName=$genomeDirectory"processing3.m";
	echo -e "\toutputName = "$outputName >> $logName;

	echo -e "function [] = processing3()" > $outputName;
	echo -e "\tpkg load matgeom;" >> $outputName;
	echo -e "\tdiary('"$genomeDirectory"octave.cartoon.log');" >> $outputName;
	echo -e "\tcd "$main_dir"scripts_genomes/;" >> $outputName;
	echo -e "\tcartoon_plot('"$main_dir"','"$user"','"$genome"','"$skew_kmerLength"','"$skew_kmerStep"');" >> $outputName;
	echo -e "end" >> $outputName;

	scriptText=$(printf "%s " $(sed 's/^/\n\t|\t/' "$outputName"))
	echo $scriptText >> $logName;

	echo -e "\tCalling OCTAVE." >> $logName;
	echo -e "========================================================================================";
	echo -e "== Cartoon figure ======================================================================";
	echo -e "========================================================================================";
	cd $genomeDirectory;
	$octave_exec $outputName;
	cd $script_dir;
	##echo -e "\tOCTAVE log from cartoon figure generation." >> $logName;
	##sed 's/^/\t|/;' $genomeDirectory"octave.cartoon.log" >> $logName;
fi

echo -e "\n\t============================================================================================== 6" >> $logName;

if [ -e $standard_bin_FASTA ]
then
	echo -e "\tGenome already fragmented into standard bins." >> $logName;
else
	echo -e "Performing standard-bin fragmentation of genome." >> $condensedLog;
	echo -e "\tGenome being fragmentated into standard bins." >> $logName;

	## Perform reference genome fragmentation.
	$python_exec $main_dir"scripts_genomes/genome_process_for_standard_bins_1.py" $user $genome $main_dir $logName >> $standard_bin_FASTA 2>> $logName;
fi

echo -e "\n\t----------------------------------------------------------------------------------------------" >> $logName;

if [ -e $standard_bin_SNPs_FASTA ]
then
	echo -e "\tGenome already fragmented into standard bins for SNPs." >> $logName;
else
	echo -e "Performing standard-bin fragmentation of genome for SNPs." >> $condensedLog;
	echo -e "\tGenome being fragmentated into standard bins for SNPs." >> $logName;

	## Perform reference genome fragmentation.
	$python_exec $main_dir"scripts_genomes/genome_process_for_standard_bins_1.SNPs.py" $user $genome $main_dir $logName >> $standard_bin_SNPs_FASTA 2>> $logName;
fi

echo -e "\n\t----------------------------------------------------------------------------------------------" >> $logName;


if [ -e $ddRADseq_FASTA ]
then
	echo -e "\tSimulated restriction digest (MfeI & MboI) of genome already complete." >> $logName;
else
	echo -e "Performing simulated restriction digest (MfeI & MboI) of genome." >> $condensedLog;
	echo -e "\tSimulated restriction digest of genome being performed." >> $logName;

	## Perform simulated digest of genome.
	echo -e "" > $ddRADseq_FASTA;
	$python_exec $main_dir"scripts_genomes/genome_process_for_RADseq_1.py" $user $genome $main_dir $logName >> $ddRADseq_FASTA 2>> $logName;
fi

echo -e "\n\t============================================================================================== 7" >> $logName;

inputFile=$genomeDirectory"chromosome_features.txt";
outputFile=$genomeDirectory"chromosome_features_2.txt";
if [ -e $inputFile ]
then
	echo -e "Simplifying and sorting chromosome_features file." >> $condensedLog;
	## Simplifying and sorting chromosome_features file.
	echo -e "\n\tSimplifying and sorting chromosome features file." >> $logName;
	echo -e "\n\t\tfeatures file = "$genomeDirectory"chromosome_features.txt" >> $logName;
	echo -e "" > $outputFile;
	$python_exec $main_dir"scripts_genomes/chromosome_features.simplify.py" $user $genome $main_dir $logName >> $outputFile 2>> $logName;
else
	echo -e "\n\tChromosome features file not available." >> $logName;
fi

echo -e "\n\t============================================================================================== 7" >> $logName;

## Reformat standard-bin fragmented FASTA file to have single-line entries for each sequence fragment.
echo -e "Reformatting standard genome fragments FASTA file." >> $condensedLog;
echo -e "\tReformatting digested FASTA file => single-line per sequence fragment." >> $logName;
bash $main_dir"scripts_seqModules/FASTA_reformat_1.sh" $standard_bin_FASTA > $standard_bin_FASTA.2;
bash $main_dir"scripts_seqModules/FASTA_reformat_1.sh" $standard_bin_SNPs_FASTA > $standard_bin_SNPs_FASTA.2;
mv $standard_bin_FASTA.2 $standard_bin_FASTA;
mv $standard_bin_SNPs_FASTA.2 $standard_bin_SNPs_FASTA;

outputFile=$genomeDirectory$FASTAname".GC_ratios.standard_bins.txt";
if [ -e $outputFile ]
then
	echo -e "\n\tGC-ratios per standard-bin fragment has been calculated." >> $logName
else
	echo -e "Calculating GC ratios for genome standard-bin fragments." >> $condensedLog;
	## Calculating GC_ratio of standard bin fragments.
	echo -e "\n\tCalculating GC-ratios per each standard bin fragment." >> $logName;
	echo -e "\n\t\treflocation = "$genomeDirectory >> $logName;
	echo -e "" > $outputFile;
	$python_exec $main_dir"scripts_genomes/genome_process_for_standard_bins.GC_bias_1.py" $user $genome $main_dir $logName >> $outputFile 2>> $logName;
fi

echo -e "\n\t----------------------------------------------------------------------------------------------" >> $logName;

## Reformat digested FASTA file to have single-line entries for each sequence fragment.
echo -e "Reformatting digested genome fragments FASTA file." >> $condensedLog;
echo -e "\tReformatting digested FASTA file => single-line per sequence fragment." >> $logName;
bash $main_dir"scripts_seqModules/FASTA_reformat_1.sh" $ddRADseq_FASTA > $ddRADseq_FASTA.2;
mv $ddRADseq_FASTA.2 $ddRADseq_FASTA;

outputFile=$genomeDirectory$FASTAname".GC_ratios.MfeI_MboI.txt";
if [ -e $outputFile ]
then
	echo -e "\n\tGC-ratios per digestion fragment has been calculated." >> $logName
else
	echo -e "Calculating GC ratios for digested genome fragments." >> $condensedLog;
	## Calculating GC_ratio  of ddRADseq (MfeI & MboI) fragments.
	echo -e "\n\tCalculating GC-ratios per each restriction digestion fragment." >> $logName;
	echo -e "\n\t\treflocation = "$genomeDirectory >> $logName;
	echo -e "" > $outputFile;
	$python_exec $main_dir"scripts_genomes/genome_process_for_RADseq.GC_bias_1.py" $user $genome $main_dir $logName >> $outputFile 2>> $logName;
fi

echo -e "\n\t============================================================================================== 8" >> $logName;

##==============================================================================
## Cleanup intermediate processing files.
##------------------------------------------------------------------------------
bash $main_dir"scripts_genomes/cleaning_genome.sh" $user $genome $main_dir 2>> $logName;

echo -e "\n\t============================================================================================== 9" >> $logName;


##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
bash queue_end.sh $user $genome $main_dir $logName "genome.install_6.sh completed.";
