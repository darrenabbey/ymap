#!/bin/bash
if [ "$#" -ne 2 ]; then
	echo -e "This script needs two arguments:";
	echo -e "	The folder you want to restore to the original user.";
	echo -e "	The current admin user account to restore from.";
else
	nameString=$(cat "users/$2/projects/$1/name.txt");
	read -a array <<< "$nameString"

	projectName=${array[1]};
	userName=$(echo ${array[0]} | sed -e 's|</b>||g' -e 's|<[^>]*>||g');

	if [ -d "users/$userName/projects/$projectName/" ]; then
		sudo cp "users/$2/projects/$1/"* "users/$userName/projects/$projectName/";
		sudo rm "users/$userName/projects/$projectName/name.txt";
		sudo echo "$projectName" > "users/$userName/projects/$projectName/name.txt";
		sudo chown www-data:www-data "users/$userName/projects/$projectName/name.txt";
		echo "Project '$projectName' restored to user '$userName'.";
	else
		echo "Project '$projectName' or user '$userName' not found.";
	fi;
fi;
