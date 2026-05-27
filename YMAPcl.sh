#!/bin/bash
set -e;

main_dir=$(pwd);
userDirectory=$main_dir"/users/";
if [ -e $main_dir"/YMAPcl.dat" ]; then
	user=$(head -n 1 $main_dir"/YMAPcl.dat");
else
	user="";
fi;
function logged_in_status() {
	if [[ "$user" = "" ]]; then
		echo -e "#\tNot logged in.";
	else
		echo -e "#\tLogged in as '$user'.";
	fi;
}

lineThick="#================================================================================#";
lineThin="#--------------------------------------------------------------------------------#";

arguments_count=$#;

if [ -z $1 ]; then
	echo -e $lineThick;
	echo -e "# YMAP2 commandline";
	logged_in_status;
	echo -e $lineThin;
	echo -e "#";
	echo -e "# Command syntax is : 'bash YMAPcl.sh [command] (option1) (option2) (...)'";
	echo -e "# ";
	echo -e "#   Commands:";
	echo -e "#	log_in		: Log the admin interface to a specific user account.";
	echo -e "#	log_out		: Log the admin interface out of a user account.";
	echo -e "#	daemon		: Show status of ymap_daemon service.";
	echo -e "#	queue_limit	: Show the max number of datasets to be processed in parallel.";
	echo -e "#	data_limit	: Show the max user data to be processed.";
	echo -e "#	admin_email	: Show admin email, displayed in user interface for issues.";
	echo -e "#	quota		: Show per account disk quota.";
	echo -e "#	info		: Show user account information.";
	echo -e "#	status		: Show data processing status.";
	echo -e "#	genomes		: List installed genomes.";
	echo -e "#	hapmaps		: List installed hapmaps.";
	echo -e "#	complete	: List file paths & names of images for completed projects.";
	echo -e "#	delete		: Delete a project/genome/hapmap/user.";
	echo -e "#	install		: install data for a new project/genome.";
	echo -e "#";
	echo -e "#   Commands not implemented:"
	echo -e "#	queue		: Shows the status of the YMAP processing queue.";
	echo -e "#	queue delete	: Force ends an item from the processing queue. To be used in case";
	echo -e "#				there is ever an improperly terminated process that somehow doesn't";
	echo -e "#				lead to an end entry in the queue log, leading to the queue being";
	echo -e "#				hung/stuck."
	echo -e "#	queue flush	: Cleans up resolved entries from the queue log. Should not be needed,";
	echo -e "#				but may be useful for managing the queue.";
	echo -e "#	combine_figures";
	echo -e "#";
	echo -e "#   Commands not implemented, require uer interface:";
	echo -e "#	build_hapmap";
	echo -e "#	minimize (dataset)";
	echo -e "# ";
	echo -e $lineThick;
else
	##
	## Functions for use in commandline interface.
	##
	function queue_init_project() {
		main_dir=$1;
		user=$2;
		project=$3;
		message=$4;
		projectDirectory=$main_dir"/users/"$user"/projects/";

		# Define salt string.
		salt=$(mktemp -u XXXXXXXXXXXXXXXX);
		echo $salt > $projectDirectory$project"/salt.txt";

		# Add entry to queue log.
		printf -v queueLogFile '%(%Y-%m-%d)T' -1;
		queueLogFile=$queueLogFile"_queue.log";
		printf -v dateTime '%(%Y-%m-%d %H:%M:%S)T' -1;
		queueString=$dateTime" - user:"$user" - project:"$project" - "$salt" - init - "$message;
		echo "$queueString" >> $main_dir"/queue/"$queueLogFile;
	}
	function queue_reinit_project() {
		main_dir=$1;
		user=$2;
		project=$3;
		message=$4;
		projectDirectory=$main_dir"/users/"$user"/projects/";

		# Make "update.txt" file in project.
		printf -v dateString '%(%Y-%m-%d)T' -1;
		echo $dateString > $projectDirectory$project"/update.txt";

		# Define salt string.
		salt=$(mktemp -u XXXXXXXXXXXXXXXX);
		echo $salt > $projectDirectory$project"/salt.txt";

		# Add entry to queue log.
		printf -v queueLogFile '%(%Y-%m-%d)T' -1;
		queueLogFile=$queueLogFile"_queue.log";
		printf -v dateTime '%(%Y-%m-%d %H:%M:%S)T' -1;
		salt=$(head -n 1 $projectDirectory$project"/salt.txt");
		queueString=$dateTime" - user:"$user" - project:"$project" - "$salt" - init - "$message;
		echo "$queueString" >> $main_dir"/queue/"$queueLogFile;
	}
	function queue_start_project() {
		main_dir=$1;
		user=$2;
		project=$3;
		message=$4;
		projectDirectory=$main_dir"/users/"$user"/projects/";

		# Get salt string.
		salt=$(head -n 1 $projectDirectory$project"/salt.txt");

		# Add entry to queue log.
		printf -v queueLogFile '%(%Y-%m-%d)T' -1;
		queueLogFile=$queueLogFile"_queue.log";
		printf -v dateTime '%(%Y-%m-%d %H:%M:%S)T' -1;
		queueString=$dateTime" - user:"$user" - project:"$project" - "$salt" - start - "$message;
		echo "$queueString" >> $main_dir"/queue/"$queueLogFile;
	}
	function queue_end_project() {
		main_dir=$1;
		user=$2;
		project=$3;
		message=$4;
		projectDirectory=$main_dir"/users/"$user"/projects/";

		# Get salt string.
		if [[ -e $projectDirectory$project"/salt.txt" ]]; then
			salt=$(head -n 1 $projectDirectory$project"/salt.txt");
		else
			salt=$(mktemp -u XXXXXXXXXXXXXXXX);
		fi;

		# Add entry to queue log.
		printf -v queueLogFile '%(%Y-%m-%d)T' -1;
		queueLogFile=$queueLogFile"_queue.log";
		printf -v dateTime '%(%Y-%m-%d %H:%M:%S)T' -1;
		queueString=$dateTime" - user:"$user" - project:"$project" - "$salt" - end - "$message;
		echo "$queueString" >> $main_dir"/queue/"$queueLogFile;
	}
	function userInterface_delete() {
		main_dir=$1;
		userAccount=$2;
		whatisit=$3;

		tempfile=$(mktemp --suffix ".ymap");
		tempfile2=$(mktemp --suffix ".ymap");

		## Build string of projects.
		if [[ "$whatisit" = "project" ]]; then
			workingDirectory=$main_dir"/users/"$userAccount"/projects/";
		elif [[ "$whatisit" = "genome" ]]; then
			workingDirectory=$main_dir"/users/"$userAccount"/genomes/";
		elif [[ "$whatisit" = "hapmap" ]]; then
			workingDirectory=$main_dir"/users/"$userAccount"/hapmaps/";
		elif [[ "$whatisit" = "user" ]]; then
			if [[ "$userAccount" = "default" ]]; then
				echo -e "#\t\e[41mInvalid selection: You can't delete the 'default' user.\e[0m";
				echo -e "#";
				echo -e $lineThick;
				return 1;
			else
				workingDirectory=$main_dir"/users/";
			fi;
		else
			echo -e "#\t\e[41mInvalid selection: Code error.\e[0m";
			echo -e "#";
			echo -e $lineThick;
			return 1;
		fi;

		if [[ ! -e $workingDirectory ]]; then
			echo -e "#\t\e[41mInvalid selection: User not found.\e[0m";
			echo -e "#";
			echo -e $lineThick;
			return 1;
		fi;

		cd $workingDirectory;
		if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
			nameString="";
			counter=1;
			for dir in */; do
				name=$( echo ${dir::-1} );
				nameString=$nameString" "$counter" "$name;
				counter=$(($counter+1));
			done;
		else
			nameString="";
		fi;
		cd ../../../;

		if [[ ! "$nameString" = "" ]]; then
			### https://www.geeksforgeeks.org/linux-unix/shell-scripting-dialog-boxes/
			(dialog --nocancel --menu "Select $whatisit to delete.\n        (You can cancel later.)" 25 45 25 $nameString) 2> $tempfile
			selectedKey=$(head -n 1 $tempfile);

			## Get chosen project/genome/hapmap/user name.
			cd $workingDirectory;
			counter=1;
			for dir in */; do
				name=$( echo ${dir::-1} );
				if [[ $selectedKey -eq $counter ]]; then
					selectedName=$name;
				fi;
				counter=$(($counter+1));
			done;
			cd ../../../;

			## Confirming user choice before deleting.
			clear;
			if [[ "$whatisit" = "user" ]] && [[ "$selectedName" = "default" ]]; then
				echo -e $lineThick;
				echo -e "# YMAP2 commandline : Delete user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\t\e[41mInvalid selection: You can't delete the 'default' user.\e[0m";
				echo -e "#";
				echo -e $lineThick;
				return 1;
			else
				echo -e $lineThick;
				echo -e "# YMAP2 commandline : Delete $whatisit.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				if [[ "$whatisit" = "user" ]]; then
					echo -e "#\t\e[41mAre you certain you want to delete the $whatisit '$selectedName'?\e[0m";
				else
					echo -e "#\t\e[41mAre you certain you want to delete the $whatisit '$selectedName' belonging to user '$userAccount'?\e[0m";
				fi;
				echo -e -n "#\n#\t[yes/no]: ";
				read -r response;
				if [ "$response" = "yes" ]; then
					echo -e "#";
					echo -e "#\tDeleting $whatisit.";

					if [[ "$whatisit" = "project" ]]; then
						## Adding 'end' entry to queue log.
						queue_end_project $main_dir $userAccount $selectedName "YMAPcl.sh deleted.";
					fi;

					## Actually deleting entry.
					rm -rf $workingDirectory$selectedName;
					echo -e "#\t$whatisit deleted.";
				elif [ "$response" = "no" ]; then
					echo -e "#";
					echo -e "#\tOperation canceled.";
				else
					echo -e "#";
					echo -e "#\tValue of 'yes' or 'no' was not entered, operation canceled.";
				fi;
			fi;
		else
			echo -e "#\tNo "$whatisit"s found, operation canceled.";
		fi;
	}
	function userInterface_install() {
		main_dir=$1;
		user=$2;
		whatisit=$3;

		tempfile=$(mktemp --suffix ".ymap");
		tempfile2=$(mktemp --suffix ".ymap");

		if [[ "$whatisit" = "project" ]]; then
			echo -e "#\t Installing a new project.";
		elif [[ "$whatisit" = "genome" ]]; then
			echo -e "#\tInstalling a new genome.";
		elif [[ "$whatisit" = "user" ]]; then
			echo -e "#\tInstalling a new user.";
		else
			echo -e "#\t\e[41mInvalid selection: Code error.\e[0m";
			echo -e $lineThick;
			return 1;
		fi;
	}

	##
	## Main part of commandline interface code.
	##

	echo -e $lineThick;
	case $1 in
	    "log_in")
		echo -e "# YMAP2 commandline :";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
			echo -e "#";
			echo -e "#\t\e[41mAs this is an admin interface, there is no user account password check.\e[0m";
			echo -e "#";

			## List user directories.
			if [ -d $userDirectory ]; then
				echo -e "#	Registered user accounts:";
				dirs=$(find $userDirectory* -maxdepth 0 -type d);
				if [ -z "$dirs" ]; then
					echo -e "#\t\tNo registered users."
				else
					for dir in $dirs; do
						echo -e "#\t\t"${dir##*/};
					done;
				fi;
			else
				echo -e "#\t\e[41mError: User directory not found!\e[0m";
			fi;

			## Show currently logged in account, if logged in.
			if [ "$user" != "" ]; then
				echo -e "#";
				echo -e "#\tUser '$user' is currently logged in." ;
			fi;
		else
			## Show currently logged in account, if logged in.
			if [[ "$user" = "$2" ]]; then
				echo -e "#\tUser '$2' was already logged in.";
			else
				if [[ ! "$user" = "" ]]; then
					echo -e "#\tUser '$user' has been logged out.";
					echo -e "#";
				fi;
				echo -e "#\tUser '$2' has been logged in.";
				echo $2 > $main_dir"/YMAPcl.dat";
			fi;
		fi;
	    ;;
	    "log_out")
		echo -e "# YMAP2 commandline :";
		echo -e $lineThin
		echo -e "#";
		if [[ ! "$user" = "" ]]; then
			echo "" > $main_dir"/YMAPcl.dat";
			echo -e "#\tUser '$user' has been logged out.";
		else
			echo -e "#\tNo user was logged in.";
		fi;
	    ;;
	    "info")
		echo -e "# YMAP2 commandline : User information.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		if [ "$user" == "" ]; then
			## If not logged in, allow user passed as argument.
			if [ -z $2 ]; then
				echo -e "#\tUsage: bash YMAPcl.sh user \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
			else
				user=$2;
			fi;
		fi;
		if [ "$user" != "" ]; then
			## If logged in.
			echo -e "#\tuser : "$user;
			echo -e "#";
			main_dir=$(pwd);
			userInfoFile=$main_dir"/users/"$user"/info.txt";
			while IFS= read -r line; do
				echo -e "#\t\t"$line;
			done < $userInfoFile;
		fi;
	    ;;
	    "users")
		echo -e "# YMAP2 commandline : List users.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		if [ -d $userDirectory ]; then
			echo -e "#\tRegistered user accounts:";
			dirs=$(find $userDirectory* -maxdepth 0 -type d);
			if [ -z "$dirs" ]; then
				echo -e "#\t\tNo registered users."
			else
				for dir in $dirs; do
					echo -e "#\t\t"${dir##*/};
				done;
			fi;
		else
			echo -e "#\t\t\e[41mError: User directory not found!\e[0m";
		fi;
	    ;;
	    "daemon")
		echo -e "# YMAP2 commandline : ymap_daemon service status.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		tempfile=$(mktemp --suffix ".ymap");
		service ymap_daemon status > $tempfile;

		## If line contains "└" character, print long line broken into new lines without the "│" character.
		## If line doesn't contain "└" character, print long line broken into new lines with "│" character to maintain formatting.
		awk '{
			if ($0 ~ "└") {
				while (length > 160) {
					print substr($0, 1, 160); $0 = "\t      \t\t" substr($0, 161);
				} print $0;
			} else {
				while (length > 160) {
					print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161);
				} print $0;
			}
		}' $tempfile | sed 's/^/#\t/' | cat;
	    ;;
	    "status")
		if [ "$user" == "" ]; then
			##
			## If not logged in.
			##
			echo -e "# YMAP2 commandline : User project status.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
                        if [ -z $2 ]; then
                                echo -e "#\tUsage: bash YMAPcl.sh status \e[31m(user)\e[0m";
                                echo -e "#";
                                echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
                        else
				user=$2
			fi;
		fi;
		if [ "$user" != "" ]; then
			##
			## Logged in.
			##
			echo -e "# YMAP2 commandline : User '$user' project status.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			projectDirectory=$main_dir"/users/"$user"/projects/";
			if [ -d $projectDirectory ]; then
				cd $projectDirectory;

				## Projects not started: missing "complete.txt" and "working.txt" files.
				echo -e "#\tProjects initialized:";
				tempfile=$(mktemp --suffix ".ymap");
				find * -type d "!" -exec sh -c 'ls -A "{}" | grep --quiet -e "working.txt" -e "complete.txt"' \; -print > $tempfile;
				cat $tempfile | xargs -n 7 | column -t | sed 's/^/#\t\t/' | cat;
				echo -e "#";

				## Projects not started: missing "complete.txt" and "working.txt" files.
				echo -e "#\tProjects processing:";
				for dir in */; do
					if [ -e $dir"working.txt" ]; then
						if [ ! -e $dir"complete.txt" ]; then
							line=$( tail -n 1 $dir"condensed_log.txt" )
							if [[ "$line" != "Cleaning and archiving." ]]; then
								echo -e "#\t\t"$dir"\t: "$line;
								if [ -e $dir"error.txt" ]; then
									error=$( cat $dir"error.txt"; )
									echo -e "#\t\t\t\e[41mError: $error\e[0m";
								fi;
							fi;
						fi;
					fi;
				done;
				echo -e "#";

				## Projects done: include "complete.txt" file.
				echo -e "#\tProjects completed:";
				tempfile=$(mktemp --suffix ".ymap");
				find * -type d -exec sh -c 'ls -A "{}" | grep --quiet "complete.txt"' \; -print > $tempfile;
				# Convert one column into multiple columns in interface format.
				cat $tempfile | xargs -n 7 | column -t | sed 's/^/#\t\t/' | cat;

				cd ../../../;
			else
				echo -e "#\t\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;
	    ;;
	    "genomes")
		echo -e "# YMAP2 commandline : List user genomes.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		if [ "$user" == "" ]; then
			## If not logged in, allow user passed as argument.
			if [ -z $2 ]; then
				echo -e "#\tUsage: bash YMAPcl.sh genomes \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
			else
				user=$2;
			fi;
		fi;
		if [ "$user" != "" ]; then
			echo -e "#\tuser : "$user;
			echo -e "#";
			main_dir=$(pwd);
			genomeDirectory=$main_dir"/users/"$user"/genomes/";
			if [ -d $genomeDirectory ]; then
				echo -e "#\tUser installed genomes:";
				dirs=$(find $genomeDirectory* -type d);
				if [ -z "$dirs" ]; then
					echo -e "#\t\tNo user installed genomes."
				else
					for dir in $dirs; do
						echo -e "#\t\t"${dir##*/};
					done;
				fi;
			else
				echo -e "#\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;
		echo -e "#";
		main_dir=$(pwd);
		genomeDirectory=$main_dir"/users/default/genomes/";
		echo -e "#\tSystem installed genomes:";
		dirs=$(find $genomeDirectory* -type d);
		if [ -z "$dirs" ]; then
			echo -e "#\t\tNo system installed genomes."
		else
			for dir in $dirs; do
				echo -e "#\t\t"${dir##*/};
			done;
		fi;
	    ;;
	    "hapmaps")
		echo -e "# YMAP2 commandline : List user hapmaps.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		if [ "$user" == "" ]; then
			## If not logged in, allow user passed as argument.
			if [ -z $2 ]; then
				echo -e "#\tUsage: bash YMAPcl.sh hapmaps \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
			else
				user=$2;
			fi;
		fi;
		if [ "$user" != "" ]; then
			echo -e "#\tuser : "$user;
			echo -e "#";
			main_dir=$(pwd);
			hapmapDirectory=$main_dir"/users/"$user"/hapmaps/";
			if [ -d $hapmapDirectory ]; then
				echo -e "#\tUser installed hapmaps:";
				dirs=$(find $hapmapDirectory* -type d);
				if [ -z "$dirs" ]; then
					echo -e "#\t\tNo user installed hapmaps."
				else
					for dir in $dirs; do
						genome=$(head -n 1 $hapmapDirectory${dir##*/}"/genome.txt");
						echo -e "#\t\t"${dir##*/}" ["$genome"]";
					done;
				fi;
			else
				echo -e "#\t\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;

		echo -e "#";
		main_dir=$(pwd);
		hapmapDirectory=$main_dir"/users/default/hapmaps/";
		echo -e "#\tSystem installed hapmaps:";
		dirs=$(find $hapmapDirectory* -type d);
		if [ -z "$dirs" ]; then
			echo -e "#\t\tNo system installed hapmaps."
		else
			for dir in $dirs; do
				genome=$(head -n 1 $hapmapDirectory${dir##*/}"/genome.txt");
				echo -e "#\t\t"${dir##*/}" ["$genome"]";
			done;
		fi;
	    ;;
	    "complete")
		echo -e "# YMAP2 commandline : List user figures.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		if [ "$user" == "" ]; then
			## If not logged in, allow user passed as argument.
			if [ -z $2 ]; then
				echo -e "#\tUsage: bash YMAPcl.sh complete \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
			else
				user=$2;
			fi;
		fi;
		if [ "$user" != "" ]; then
			echo -e "#\tuser: "$user;
			projectDirectory=$main_dir"/users/"$user"/projects/";
			if [ -d $projectDirectory ]; then
				echo -e "#";
				echo -e "#\tProjects completed:";
					cd $projectDirectory;
					for dir in */; do
						line=$( tail -n 1 $dir"condensed_log.txt" )
						if [[ "$line" == "Cleaning and archiving." ]]; then
							echo -e "#\t\t"$dir;
							for file in $projectDirectory$dir*.png; do
								filename=${file##*/};
								if [[ $filename != *"Rsquared"* ]]; then
									if [[ $filename != *"ChARM_test"* ]]; then
										if [[ $filename != *"SNP-histogram"* ]]; then
											echo -e "#\t\t\tusers/"$user"/projects/"$dir${filename##*/};
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
		fi;
	    ;;
	    "queue_limit")
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Limit of YMAP processes to run concurrently in queue.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap");
			grep "\$MAX_QUEUE_PARALLEL" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "#\tUsage: bash YMAPcl.sh queue_limit \e[31m(value)\e[0m";
			echo -e "#";
			echo -e "#\t\e[41mChanging this option will prompt you for your credentials to\e[0m";
			echo -e "#\t\e[41mrestart the yamp_daemon service that manages the queue.\e[0m";
		else
			if ! [[ "$2" =~ ^[0-9]+$ ]]; then
				echo -e "# YMAP2 commandline : Limit of YMAP processes to run concurrently in queue.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$MAX_QUEUE_PARALLEL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
				echo -e "#";
				echo -e "#\t\e[41mChanging this option will prompt you for your credentials to\e[0m";
				echo -e "#\t\e[41mrestart the yamp_daemon service that manages the queue.\e[0m";
			else
				echo -e "# YMAP2 commandline : New limit of YMAP processes to run concurrently in queue.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$MAX_QUEUE_PARALLEL/c\\\$MAX_QUEUE_PARALLEL = ${2};" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$MAX_QUEUE_PARALLEL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#      \e[41mChanging this option will prompt you for your credentials to\e[0m";
				echo -e "#      \e[41mrestart the yamp_daemon service that manages the queue.\e[0m";
				service ymap_daemon restart;
			fi;
		fi;
	    ;;
	    "data_limit")
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Per project data limit in Gb.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap");
			grep "\$MAX_PROCESSED_DATA_SIZE" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "#\tUsage: bash YMAPcl.sh data_limit \e[31m(value)\e[0m";
			echo -e "#";
			echo -e "#\t\e[41mA value of '0' means there is no data size limit defined.\e[0m";
		else
			if ! [[ "$2" =~ ^[0-9]+$ ]]; then
				echo -e "# YMAP2 commandline : Per project data limit in Gb.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$MAX_PROCESSED_DATA_SIZE" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New per project data limit in Gb.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$MAX_PROCESSED_DATA_SIZE/c\\\$MAX_PROCESSED_DATA_SIZE = ${2};" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$MAX_PROCESSED_DATA_SIZE" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			fi;
		fi;
	    ;;
	    "admin_email")
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Admin email address.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap");
			grep "\$ADMIN_EMAIL" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "#\tUsage: bash YMAPcl.sh admin_email \e[31m(address)\e[0m";
		else
			email_pattern='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
			if [[ ! "$2" =~ $email_pattern ]]; then
				echo -e "# YMAP2 commandline : Admin email address.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$ADMIN_EMAIL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New admin email address.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$ADMIN_EMAIL/c\\\$ADMIN_EMAIL = \"${2}\";" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$ADMIN_EMAIL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			fi;
		fi;
	    ;;
	    "quota")
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : User account disk utilization quota.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap");
			grep "\$QUOTA_GLOBAL" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "#\tUsage: bash YMAPcl.sh quota \e[31m(value)\e[0m";
		else
			if ! [[ "$2" =~ ^[0-9]+$ ]]; then
				echo -e "# YMAP2 commandline : User account disk utilization quota.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$QUOTA_GLOBAL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New user account disk utilization quota.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$QUOTA_GLOBAL/c\\\$QUOTA_GLOBAL = ${2};" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$QUOTA_GLOBAL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			fi;
		fi;
	    ;;
	    "delete")
		fail=0;
		if [ "$user" = "" ]; then
			if [[ "$arguments_count" = 3 ]]; then
				userAccount=$3;
			elif [[ "$arguments_count" = 2 ]]; then
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				case $2 in
				    "project")
					echo -e "#\tUsage: bash YMAPcl.sh delete project \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "genome")
					echo -e "#\tUsage: bash YMAPcl.sh delete genome \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "hapmap")
					echo -e "#\tUsage: bash YMAPcl.sh delete hapmap \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "user")
					fail=0;
				    ;;
				    *)
					echo -e "#\tUsage: bash YMAPcl.sh delete project \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcl.sh delete genome \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcl.sh delete hapmap \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcl.sh delete user";
					echo -e "#";
					echo -e "#\t\t\e[41mError: Wrong 2nd arguement!\e[0m";
					fail=1;
				    ;;
				esac;
			elif [[ "$arguments_count" = 1 ]]; then
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\tUsage: bash YMAPcl.sh delete project \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh delete genome \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh delete hapmap \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh delete user";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
				fail=1;
			else
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong number of arguments!\e[0m";
				fail=1;
			fi;
		else
			if [[ "$arguments_count" = 2 ]]; then
				userAccount=$user;
			elif [[ "$arguments_count" = 1 ]]; then
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\tUsage: bash YMAPcl.sh delete project";
				echo -e "#\tUsage: bash YMAPcl.sh delete genome";
				echo -e "#\tUsage: bash YMAPcl.sh delete hapmap";
				echo -e "#\tUsage: bash YMAPcl.sh delete user";
				fail=1;
			else
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong number of arguments!\e[0m";
				fail=1;
			fi;
		fi;
		if [[ "$fail" -eq 0 ]]; then
			case $2 in
			    "project")
				userInterface_delete $main_dir $userAccount "project";
			    ;;
			    "genome")
				userInterface_delete $main_dir $userAccount "genome";
			    ;;
			    "hapmap")
				userInterface_delete $main_dir $userAccount "hapmap";
			    ;;
			    "user")
				userInterface_delete $main_dir "null" "user";
			    ;;
			    *)
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#\tUsage: bash YMAPcl.sh install project \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh install genome \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh install hapmap \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh install user";
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong 2nd arguement!\e[0m";
			    ;;
			esac;
		fi;
	    ;;
##
## DRAGON : not updated below.
##
	    "install")
		fail=0;
		if [ "$user" = "" ]; then
			if [[ "$arguments_count" = 3 ]]; then
				echo -e "# YMAP2 commandline : Install project/genome/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				userAccount=$3;
			elif [[ "$arguments_count" = 2 ]]; then
				echo -e "# YMAP2 commandline : Install project/genome/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				case $2 in
				    "project")
					echo -e "#\tUsage: bash YMAPcl.sh install project \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "genome")
					echo -e "#\tUsage: bash YMAPcl.sh install genome \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "user")
					fail=0;
				    ;;
				    *)
					echo -e "#\tUsage: bash YMAPcl.sh install project \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcl.sh install genome \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcl.sh install user";
					echo -e "#";
					echo -e "#\t\t\e[41mError: incorrect 2nd arguement!\e[0m";
					fail=1;
				    ;;
				esac;
			elif [[ "$arguments_count" = 1 ]]; then
				echo -e "# YMAP2 commandline : Install project/genome/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\tUsage: bash YMAPcl.sh install project \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh install genome \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcl.sh install user";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
				fail=1;
			else
				echo -e "# YMAP2 commandline : Install project/genome/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong number of arguments!\e[0m";
				fail=1;
			fi;
		else
			if [[ "$arguments_count" = 2 ]]; then
				echo -e "# YMAP2 commandline : Install project/genome/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				userAccount=$user;
			elif [[ "$arguments_count" = 1 ]]; then
				echo -e "# YMAP2 commandline : Install project/genome/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\tUsage: bash YMAPcl.sh install project";
				echo -e "#\tUsage: bash YMAPcl.sh install genome";
				echo -e "#\tUsage: bash YMAPcl.sh install user";
				fail=1;
			else
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong number of arguments!\e[0m";
				fail=1;
			fi;
		fi;

		if [[ "$fail" -eq 0 ]]; then
			case $2 in
			    "project")
				userInterface_install $main_dir $userAccount "project";
			    ;;
			    "genome")
				userInterface_install $main_dir $userAccount "genome";
			    ;;
			    "user")
				userInterface_install $main_dir "null" "user";
			    ;;
			    *)
				echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong arguement!\e[0m";
			    ;;

			esac;
		fi;
	    ;;
	esac;
	echo -e "#";
	echo -e $lineThick
fi;


