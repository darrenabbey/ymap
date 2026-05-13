#!/bin/bash
set -e;

main_dir=$(pwd);
userDirectory=$main_dir"/users/";

clear;
echo -e "#=========================================#";
echo -e "# YMAP commandline : List users.          #";
echo -e "#-----------------------------------------#";
if [ -d $userDirectory ]; then
		echo -e "#";
		echo -e "# Registered user accounts:";
		cd $userDirectory;
		for dir in */; do
			echo -e "#\t"$dir;
		done;
		cd ../../../;
else
	echo -e "#\t\e[41mError: User directory not found.!\e[0m";
fi;
echo -e "#";
echo -e "#=========================================#";
