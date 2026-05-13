#!/bin/bash
set -e;

if [ -z $1 ]
then
	echo -e "#";
	echo -e "# Command syntax is : 'bash YMAPcl_status.sh [user]'";
	echo -e "# ";
	echo -e "#        [user]  : The name of a registered user.";
	echo -e "# ";
	echo -e "# This script will display the status of all installed projects for the user.";
	echo -e "# ";
else
	user=$1;
	main_dir=$(pwd);
	projectDirectory=$main_dir"/users/"$user"/projects/";

	clear;
	echo -e "#=========================================#";
	echo -e "# YMAP commandline : User project status. #";
	echo -e "#-----------------------------------------#";
	echo -e "# user: "$user;
	if [ -d $projectDirectory ]; then
		echo -e "#";
		echo -e "# Projects initialized or processing:";
		cd $projectDirectory;
		for dir in */; do
			line=$( tail -n 1 $dir"condensed_log.txt" )
			if [[ "$line" != "Cleaning and archiving." ]]; then
				echo -e "#\t"$dir"\t: "$line;
				if [ -e $dir"error.txt" ]; then
					error=$( cat $dir"error.txt"; )
					echo -e "#\t\t\e[41mError: $error\e[0m";
				fi;
			fi;
		done;
		echo -e "#";
		echo -e "# Projects completed:";
		for dir in */; do
			line=$( tail -n 1 $dir"condensed_log.txt" )
			if [[ "$line" == "Cleaning and archiving." ]]; then
				echo -e "#\t"$dir;
			fi;
		done;
		cd ../../../;
	else
		echo -e "#\t\e[41mError: User name not registered.\e[0m";
	fi;
	echo -e "#";
	echo -e "#=========================================#";
fi;
