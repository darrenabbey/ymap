#!/bin/bash
set -e;

if [ -z $1 ]
then
	echo -e "# Command syntax is : 'bash YMAPcl_complete.sh [user]'";
	echo -e "# ";
	echo -e "#        [user]  : The name of a registered user.";
	echo -e "# ";
	echo -e "# This script will display the completed projects and the final PNG format figure file paths.";
	echo -e "# The file paths can be used to copy the figure to a chosen final location.";
	echo -e "# ";
else
	user=$1;
	main_dir=$(pwd);
	projectDirectory=$main_dir"/users/"$user"/projects/";

	clear;
	echo -e "#====================================================#";
	echo -e "# YMAP commandline : User project completed figures. #";
	echo -e "#----------------------------------------------------#";
	echo -e "# user: "$user;
	if [ -d $projectDirectory ]; then
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
	else
		echo -e "#\t\e[41mError: User name not registered.\e[0m";
	fi;
	echo -e "#";
	echo -e "#====================================================#";
fi;
