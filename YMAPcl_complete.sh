#!/bin/bash
set -e;

user=$1;
main_dir=$(pwd);
projectDirectory=$main_dir"/users/"$user"/projects/";

clear;
echo -e "#====================================================#";
echo -e "# YMAP commandline : User project completed figures. #";
echo -e "#----------------------------------------------------#";
echo -e "# user: "$user;
echo -e "#";
echo -e "# Projects completed:";
cd $projectDirectory;
for dir in */; do
	line=$( tail -n 1 $dir"condensed_log.txt" )
	if [[ "$line" == "Cleaning and archiving." ]]; then
		echo -e "#\t"$dir;
		for file in $projectDirectory$dir*.png; do
			filename=${file##*/};
			if [[ $filename != *"Rsquared"* ]]; then
				if [[ $filename != *"ChARM_test"* ]]; then
					if [[ $filename != *"SNP-histogram"* ]]; then
						echo -e "#\t\tusers/"$user"/projects/"$dir${filename##*/};
					fi;
				fi;
			fi;
		done;
	fi;
done;
cd ../../../;
echo -e "#====================================================#";
