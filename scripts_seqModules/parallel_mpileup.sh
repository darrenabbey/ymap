#!/bin/bash
set -e

user=$1;	#user="darren2";
project=$2;	#project="test";
main_dir=$(pwd)"/../../";

# import locations of auxillary software for pipeline analysis.
. $main_dir"local_installed_programs.sh";
. $main_dir"config.sh";

# Define project directory.
projectDirectory=$main_dir"users/"$user"/projects/"$project;
BAMfile=$projectDirectory/data_sorted.bam;

# Get setup information from project files : "genome.txt" : first line  => genome
genome=$(head -n 1 $projectDirectory/genome.txt);
if [[ -d $main_dir"users/"$user"/genomes/"$genome"/" ]]
then
	genomeDirectory=$main_dir"users/"$user"/genomes/"$genome"/";
else
	genomeDirectory=$main_dir"users/default/genomes/"$genome"/";
fi

### Load used contig names from $genomeDirectory"figure_definitions.txt" file.
echo -e "identifying which contigs are used.";
figureDefinitions=$genomeDirectory"figure_definitions.txt";
contigNames=();
i=0;
{
	read -r null;
	while read line; do
		useContig=$(echo -e "$line" | awk '{print $2}');		# if 2nd field is 1, indicates contig is used.
		if [[ $useContig -eq 1 ]]
		then
			contigName=$(echo -e "$line" | awk '{print $4}');	# extract 4th field from each line for contig name.
			echo $contigName;
			contigNames[i]+=$contigName;
			i=$((i+1));
		fi
	done
} < $figureDefinitions;

### Fire off samtools mpileup processes for quick parallel operation.
echo -e "generating temporary '*.pileup_' files for each contig that is used, in parallel with low memory footprint.";
arraylength=${#contigNames[@]}
for ((i=0; i<${arraylength}; i++));
do
	$samtools_exec mpileup -a -f $genomeDirectory/datafile_g_0.fasta -r ${contigNames[i]} $BAMfile | awk '{print $1 " " $2 " " $3 " " $4 " " $5}' > $projectDirectory/${contigNames[i]}.pileup_ &
done;
wait;

# Cleanup intermediate files.
echo -e "concatenating temporary '*.pileup_' files to 'data.pileup'.";
cat $projectDirectory/*.pileup_ > $projectDirectory/data.pileup;

echo -e "removing temporary '*.pileup_' files.";
rm $projectDirectory/*.pileup_;
