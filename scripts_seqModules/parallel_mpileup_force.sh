#!/bin/bash
set -e

user="$1";        #user="darren2";
project="$2";     #project="test";
main_dir="$3";    #main_dir="/var/www/html/ymap/";
projectDirectory="$main_dir/users/$user/projects/$project";
logNAme="$projectDirectory/process_log";

## Error handling in case something crashes.
trap 'cd $main_dir"/scripts_seqModules/scripts_WGseq/"; bash queue_end.sh $user $project $main_dir $logName "Something went wrong. parallel_mpileup_force.sh:$LINENO"; install /dev/null $projectDirectory"error.txt"; echo -e "Something went wrong. parallel_mpileup_force.sh:$LINENO" > $projectDirectory"/error.txt"; cd $main_dir; exit 1;' ERR;

# import locations of auxillary software for pipeline analysis.
. $main_dir/local_installed_programs.sh;
. $main_dir/config.sh;

# Define project directory.
BAMfile="$projectDirectory/data_sorted.bam";

# Get setup information from project files : "genome.txt" : first line  => genome
genome=$(head -n 1 "$projectDirectory/genome.txt");
if [ -d "$main_dir/users/$user/genomes/$genome" ]
then
	genomeDirectory="$main_dir/users/$user/genomes/$genome";
else
	genomeDirectory="$main_dir/users/default/genomes/$genome";
fi

### Load used contig names from $genomeDirectory"figure_definitions.txt" file.
echo -e "identifying which contigs are used.";
figureDefinitions="$genomeDirectory/figure_definitions.txt";
contigNames=();
i=0;
{
	read -r null;
	while read line; do
		useContig=$(echo -e "$line" | awk '{print $2}');		# if 2nd field is 1, indicates contig is used.
		if [ "$useContig" -eq 1 ]
		then
			contigName=$(echo -e "$line" | awk '{print $4}');	# extract 4th field from each line for contig name.
			echo "$contigName";
			contigNames[i]+="$contigName";
			i=$((i+1));
		fi
	done
} < "$figureDefinitions";

### Fire off samtools mpileup processes for quick parallel operation.
echo -e "generating temporary '*.pileup2_' files for each contig that is used, in parallel with low memory footprint.";
arraylength=${#contigNames[@]}
for ((i=0; i<${arraylength}; i++));
do
	$samtools_exec mpileup -a -A -B -q 0 -Q 0 --ff 0 -f "$genomeDirectory/datafile_g_0.fasta" -r ${contigNames[i]} "$BAMfile" | awk '{print $1 " " $2 " " $3 " " $4 " " $5}' > "$projectDirectory/${contigNames[i]}.pileup2_" &
done;
wait;

# Cleanup intermediate files.
echo -e "concatenating temporary '*.pileup2_' files to 'data.pileup2'.";
cd $projectDirectory
cat *.pileup2_ > data.pileup2;

echo -e "removing temporary '*.pileup_' files.";
rm *.pileup2_;
cd $main_dir;
