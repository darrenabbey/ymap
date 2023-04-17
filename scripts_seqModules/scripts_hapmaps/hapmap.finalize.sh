#!/bin/bash -e
#
# Initialization of genome into pipeline
#   $1 : user
#   $2 : hapmap

## All created files will have permission 760
umask 007;

### define script file locations.
user=$1;
hapmap=$2;
main_dir=$(pwd)"/../../";

# import locations of auxillary software for pipeline analysis.
. $main_dir"local_installed_programs.sh";

##============================================================================================================
## Define locations and names to be used later.
##------------------------------------------------------------------------------------------------------------
# Determine location of hapmap.
if [ -d $main_dir"users/"$user"/hapmaps/"$hapmap"/" ]
then
	hapmapDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";
	hapmapUser=$user;
elif [ -d $main_dir"users/default/hapmaps/"$hapmap"/" ]
then
	hapmapDirectory=$main_dir"users/default/hapmaps/"$hapmap"/";
	hapmapUser="default";
fi
logName=$hapmapDirectory"process_log.txt";
condensedLog=$hapmapDirectory"condensed_log.txt";
echo "" >> $logName;
echo "Running 'scripts_seqModules/scripts_hapmaps/hapmap.finalize.sh'" >> $logName;
echo "    user              = "$user >> $logName;
echo "    hapmap            = "$hapmap >> $logName;
echo "    hapmapUser        = '"$hapmapUser"'" >> $logName;
echo "    hapmapDirectory   = '"$hapmapDirectory"'" >> $logName;

##============================================================================================================
## Read in 'SNPdata_parent.txt' file from Ymap-internal representation and output hapmap definition files.
##------------------------------------------------------------------------------------------------------------
$python_exec $main_dir"/scripts_seqModules/scripts_hapmaps/process_hapmap.output_cleaned.py" $hapmapDirectory"SNPdata_parent.txt" > $hapmapDirectory"hapmap_final.txt" 2>> $logName;
$python_exec $main_dir"/scripts_seqModules/scripts_hapmaps/process_hapmap.output_errors.py"  $hapmapDirectory"SNPdata_parent.txt" > $hapmapDirectory"hapmap_errors.txt" 2>> $logName;
