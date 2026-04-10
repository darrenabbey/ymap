#!/bin/bash -e

## All created files will have permission 760
umask 007;

##
## $system_call_string = "sh hapmap.trim_1.sh ".$user." ".$hapmap." ".$hapmapParent." ".$derived." > /dev/null &";
##

### define script file locations.
user=$1;
hapmap=$2; # new hapmap name.
hapmapParent=$3; # existing hapmap name.
project=$4; # project that is derived strain of hapmap background.

main_dir=$(pwd)"/../../";

# load local installed program location variables.
. $main_dir/local_installed_programs.sh;


##==============================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------
hapmapNewDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";
mkdir $hapmapNewDirectory;
# Determine location of hapmapParent.
if [ -d $main_dir"users/"$user"/hapmaps/"$hapmapParent"/" ]
then
	hapmapParentDirectory=$main_dir"users/"$user"/hapmaps/"$hapmapParent"/";
	hapmapParentUser=$user;
elif [ -d $main_dir"users/default/hapmaps/"$hapmapParent"/" ]
then
	hapmapParentDirectory=$main_dir"users/default/hapmaps/"$hapmapParent"/";
	hapmapParentUser="default";
fi


logName=$hapmapNewDirectory"process_log.txt";
condensedLog=$hapmapNewDirectory"condensed_log.txt";
echo "" >> $logName;
echo "Running 'scripts_seqModules/scripts_hapmaps/hapmap.trim_1.sh'" >> $logName;
echo "Variables passed via command-line from 'scripts_seqModules/scripts_hapmaps/hapmap.install_1.php' :" >> $logName;
echo "    user                        = "$user >> $logName;
echo "    hapmap (new)                = "$hapmap >> $logName;
echo "    parentHapmap (existing)     = "$parentHapmap >> $logName;
echo "    derived project             = "$project >> $logName;
echo "    main_dir                    = "$main_dir >> $logName;
echo "#.............................................................................." >> $logName;
echo "" >> $logName;
echo "#=====================================#" >> $logName;
echo "# Setting up locations and variables. #" >> $logName;
echo "#=====================================#" >> $logName;
echo "Setting up for processing." >> $condensedLog;
echo "Important variables :" >> $logName;
echo "    hapmapParent user           = '"$hapmapParentUser"'" >> $logName;
echo "    hapmapParent directory      = '"$hapmapParentDirectory"'" >> $logName;

# Determine location of derived project.  Is it in user or default account?
if [ -d $main_dir"users/"$user"/projects/"$project"/" ]
then
	projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
	projectUser=$user;
elif [ -d $main_dir"users/default/projects/"$project"/" ]
then
	projectDirectory=$main_dir"users/default/projects/"$project"/";
	projectUser="default";
fi
echo "    derived project directory    = '"$projectDirectory"'" >> $logName;


# Get genome name from derived project's "genome.txt" file.
genome=$(head -n 1 $projectDirectory"genome.txt");
echo "    genome                      = '"$genome"'" >> $logName;

# Determine location of derived project genome.
if [ -d $main_dir"users/"$user"/genomes/"$genome"/" ]
then
	genomeDirectory=$main_dir"users/"$user"/genomes/"$genome"/";
	genomeUser=$user;
elif [ -d $main_dir"users/default/genomes/"$genome"/" ]
then
	genomeDirectory=$main_dir"users/default/genomes/"$genome"/";
	genomeUser="default";
fi
echo "    genome directory            = '"$genomeDirectory"'" >> $logName;

# Get reference FASTA file name from "reference.txt";
genomeFASTA=$(head -n 1 $genomeDirectory"reference.txt");
echo "    genome FASTA file           = '"$genomeFASTA"'" >> $logName;

##==============================================================================================

echo "Move derived project SNP data file to new hapmap directory." >> $logName;
if [ ! -f $hapmapNewDirectory"SNPdata_derived.txt" ]
then
	# Move derived project SNP data to hapmapNewDirectory.
	echo "\tCopy derived : 'SNP_CNV_v1.txt'" >> $logName;
	echo "\t\t to : '"$hapmapNewDirectory"SNPdata_derived.txt'" >> $logName;
	cp $projectDirectory"SNP_CNV_v1.zip" $hapmapNewDirectory"SNPdata_derived.zip";
	echo "\tDecompressing derived data." >> $logName;
	cd $hapmapNewDirectory;
	unzip -j SNPdata_derived.zip;
	rm SNPdata_derived.zip;
	mv SNP_CNV_v1.txt SNPdata_parent.txt;
	cd $main_dir;

	# Move derived project allelic-ratio cutoff data to hapmapNewDirectory.
	cp $projectDirectory"allelic_ratios.txt" $hapmapNewDirectory"allelic_ratios.txt";

	# Process derived project SNP file 'SNPdata_derived.txt' into condensed het SNP information.
	$python_exec $main_dir"scripts_seqModules/scripts_hapmaps/hapmap.preprocess_derived.py" $genome $genomeUser $project $projectUser $hapmap $user $main_dir > $hapmapNewDirectory"SNPdata_derived.temp.txt" 2>> $logName;
	rm $hapmapNewDirectory"SNPdata_parent.txt";
else
	echo "\tDerived project data already prepared for use with new hapmap." >> $logName;
fi

echo "Move old hapmap data file to new hapmap directory." >> $logName;
if [ ! -f $hapmapNewDirectory"SNPdata_hapmap.txt" ]
then
	cp $hapmapParentDirectory"SNPdata_parent.txt" $hapmapNewDirectory"SNPdata_hapmap.txt";
else
	echo "\tOld hapmap data already prepared for use with new hapmap." >> $logName;
fi

# migrate phasing from SNPdata_hapmap.txt to SNPdata_derived.txt
echo "Migrate phasing data from old hapmap to new." >> $logName;
$python_exec $main_dir"scripts_seqModules/scripts_hapmaps/hapmap.migrate.py" $user $hapmap  $main_dir > $hapmapNewDirectory"SNPdata_derived.txt" 2>> $logName;
rm $hapmapNewDirectory"SNPdata_derived.temp.txt";

# make new hapmap functional.
cp $hapmapNewDirectory"SNPdata_derived.txt" $hapmapNewDirectory"SNPdata_parent.txt"


## Generate "complete.txt" to indicate processing has completed normally.
completeFile=$hapmapNewDirectory"complete.txt";
timestamp=$(date +%T);
echo $timestamp > $completeFile;
echo "\tGenerated 'complete.txt' file." >> $logName;
chmod 0666 $completeFile;

echo "Concluding analysis." >> $condensedLog;

## Delete 'working.txt' file to let pipeline know that processing has completed, but hapmap is available for additional entries.
rm $main_dir"users/"$user"/hapmaps/"$hapmap"/working.txt";
