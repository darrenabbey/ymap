#!/bin/bash -e
#
# Script to call project.WGseq.install_4.sh from commandline.
#
# Following zip files in each project directory need to be unzipped.
#	putative_SNPs_v4.zip
#	SNP_CNV_v1.zip
# Use this command.
#	unzip -j [fiel.zip]

user="darren";
project="ID5115";
main_dir=$(pwd)"/../../";
local_dir=$(pwd);
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";
condensedLog=$projectDirectory"condensed_log.txt";


##==============================================================================
## Unzip SNP archive file: putative_SNPs_v4.zip
##------------------------------------------------------------------------------
if [ -f $projectDirectory"putative_SNPs_v4.txt" ]
then
        echo "\tSNP data already decompressed." >> $logName;
else
        echo "\tDecompressing SNP data." >> $logName;
	cd $projectDirectory;
        unzip -j -o putative_SNPs_v4.zip;
	cd $local_dir;
fi


sh project.WGseq.install_4.sh $user $project;
