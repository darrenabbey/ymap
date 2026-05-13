#!/bin/bash
set -e;

user=$1;
main_dir=$(pwd);
projectDirectory=$main_dir"/users/"$user"/projects/";

clear;
echo -e "#=========================================#";
echo -e "# YMAP commandline : User project status. #";
echo -e "#-----------------------------------------#";
echo -e "# user: "$user;
echo -e "#";
echo -e "# Projects initialized or processing:";
cd $projectDirectory;
for dir in */; do
	line=$( tail -n 1 $dir"condensed_log.txt" )
	if [[ "$line" != "Cleaning and archiving." ]]; then
		echo -e "#\t"$dir"\t: "$line;
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
echo -e "#=========================================#";
