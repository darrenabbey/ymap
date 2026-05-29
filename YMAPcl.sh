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
	echo -e "#";
	if [[ ! -e "/etc/init.d/ymap_daemon" ]]; then
		echo -e "#       \e[42minstall_YMAP  : Install the ymap_daemon into '/etc/init.d/' then start it up.\e[0m";
		echo -e "#                         \e[42mMake localized copies of template files.\e[0m";
		echo -e "#                         \e[42mThis command will prompt for admin credentials.\e[0m";
		echo -e "#                         \e[42mThis command option will go away after it is used.\e[0m";
		echo -e "#                         \e[41mExamine code starting with '\"install_YMAP\")' to see what\e[0m";
		echo -e "#                         \e[41madmin credentials are used for.\e[0m";
	fi
	echo -e "#	log_in		: Log the admin interface to a specific user account.";
	echo -e "#	log_out		: Log the admin interface out of a user account.";
	echo -e "#	daemon		: Show status of ymap_daemon service.";
	echo -e "#	queue_limit	: Show the max number of datasets to be processed in parallel.";
	echo -e "#	data_limit	: Show the target max memory utilization.";
	echo -e "#	admin_email	: Show admin email, displayed in user interface for issues.";
	echo -e "#	quota		: Show per account disk quota.";
	echo -e "#	info		: Show user account information.";
	echo -e "#	status		: Show data processing status.";
	echo -e "#	genomes		: List installed genomes.";
	echo -e "#	hapmaps		: List installed hapmaps.";
	echo -e "#	complete	: List file paths & names of images for completed projects.";
	echo -e "#	delete		: Delete a project/genome/hapmap/user.";
	echo -e "#	install		: Install a new project/genome/user.";
	echo -e "#				\e[32mGenome and user install are not implemented yet.\e[0m";
	echo -e "#	run		: Configure and run installed project datasets.";
	echo -e "#";
	echo -e "#   Commands not implemented:"
	echo -e "#	queue		: Shows the status of the YMAP processing queue.";
	echo -e "#	queue flush	: Clean up corrupted queue log. May be needed if queue refuses to run";
	echo -e "E				 installed data files.";
	echo -e "#	combine_figures	: ";
	echo -e "#	build_hapmap	: complicated user interface required, may not be possible in commandline.";
	echo -e "#	minimize	: ";
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
		nameString="";
		if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
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
				echo -e -n "#\t[yes/no]: ";
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
					echo -e "#\tUnclear entry, operation canceled.";
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

		if [[ "$whatisit" = "project" ]]; then
			workingDirectory=$main_dir"/users/"$user"/projects/"
			bulkDirectory=$main_dir"/users/"$user"/bulkdata/";

			if [[ ! -e $workingDirectory ]]; then
				echo -e "#\t\e[41mInvalid selection: User not found.\e[0m";
				echo -e "#";
				echo -e $lineThick;
				return 1;
			fi;

			echo -e "#\tInstalling a new project.";
			echo -e "#\t\tAfter installing a datafile (or multiple datafiles to be run";
			echo -e "#\t\twith the same settings), use command 'run' to add the data";
			echo -e "#\t\tto the processing queue.";

			## Accept input path;
			echo -e "#";
			echo -e "#\tEnter the path to your data files.";
			echo -e -n "#\t\t[path/]: ";
			read -r selectedDirectory;

			startingDirectory=$(pwd);
			cd $selectedDirectory;
			if [ "$(find . -maxdepth 1 -type f | wc -l)" -gt 1 ]; then
				nameString="";
				counter=1;
				options=();
				for file in *; do
					if [ -f "$file" ]; then
						name=$(echo -n "$file");
						options+=($counter $name off);
						counter=$(($counter+1));
					fi
				done;
			else
				nameString="";
			fi;
			cd $startingDirectory;
			cmd=(dialog --output-fd 1 --separate-output --checklist 'Choose the files to install:' 0 0 0)
			choices=$("${cmd[@]}" "${options[@]}")
			clear;

			## Rebuild interface.
			echo -e $lineThick;
			echo -e "# YMAP2 commandline : Install project/genome/user.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tInstalling a new project.";
			echo -e "#\t\tAfter installing a datafile (or multiple datafiles to be run"; 
			echo -e "#\t\twith the same settings), run a separate command to add the";
			echo -e "#\t\tdata to the processing queue.";
			echo -e "#";
			echo -e "#\tEnter the path to your data files.";
			echo -e "#\t\t[path/]: "$selectedDirectory;
			echo -e "#";
			echo -e "#\tData file selected:";
			cd $selectedDirectory;
			if [ "$(find . -maxdepth 1 -type f | wc -l)" -gt 1 ]; then
				counter=1;
				for file in *; do
					if [ -f "$file" ]; then
						name=$(echo -n "$file");
						if [[ $choices == *"$counter"* ]]; then
							if [ ! -f $bulkDirectory$file ]; then
								echo -e "#\t\t$name";
							else
								echo -e "#\t\t$name (already in bulk directory)";
							fi;
						fi
						counter=$(($counter+1));
					fi
				done;
			fi;
			cd $startingDirectory;
			echo -e "#";
			echo -e "#\tCopying data file into user 'bulkdata' directory.";
			cd $selectedDirectory;
			if [ "$(find . -maxdepth 1 -type f | wc -l)" -gt 1 ]; then
				counter=1;
				for file in *; do
					if [ -f "$file" ]; then
						name=$(echo -n "$file");
						if [[ $choices == *"$counter"* ]]; then
							if [ ! -f $bulkDirectory$file ]; then
								cp $file $bulkDirectory;
							fi;
						fi;
						counter=$(($counter+1));
					fi
				done;
			fi;
			cd $startingDirectory;
		elif [[ "$whatisit" = "genome" ]]; then
			echo -e "#\tInstalling a new genome [not yet implemented].";
		elif [[ "$whatisit" = "user" ]]; then
			echo -e "#\tInstalling a new user [not yet implemented].";
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
	    "install_YMAP")
		if [[ !  -e "/etc/init.d/ymap_daemon" ]]; then
			# Copy 'ymap_daemon_template.sh' to /etc/init.d/ymap_daemon
			TargetFile="/etc/init.d/ymap_daemon";
			sudo cp ymap_daemon_template.sh $TargetFile;

			# Update file setting.
			sudo sed -i "/DAEMON_OPTS_temp/c\\\DAEMON_OPTS=\"$main_dir/ymap_daemon.php\";" $TargetFile;

			# Make it executable.
			sudo chmod +x $TargetFile;

			# reload services.
			sudo systemctl daemon-reload

			# Start the service.
			sudo service ymap_daemon start;
		fi;
		if [[ ! -e "constants.php" ]]; then
			# Copy 'constants_template.php' to 'constants.php'.
			TargetFile1="constants.php";
			cp constants_template.php $TargetFile1;
			sudo sed -i "/BASE_DIR_temp/c\\\$base_dir=\"$main_dir/\";" $TargetFile1;

			# Copy 'ymap_daemon_template.php' to 'ymap_daemon.php'.
			TargetFile2="ymap_daemon.php";
			cp ymap_daemon_template.php $TargetFile2;
			sudo sed -i "/BASE_DIR_temp/c\\\$script_directory=\"$main_dir/\";" $TargetFile2;

			# Copy 'config_template.sh' to 'config.sh',
			TargetFile3="config.sh"
			cp config_template.sh $TargetFile3;

			echo -e "#";
			echo -e "#\tSettings files localized.";
		fi;
	    ;;
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
			main_dir=$(pwd);
			userInfoFile=$main_dir"/users/"$user"/info.txt";
			while IFS= read -r line; do
				echo -e "#\t"$line;
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

				## Project files installed, but not run: count files in bulkdata directory.
				installedCount=$(ls $main_dir"/users/"$user"/bulkdata/" | wc -l);
				if [[ "$installedCount" = "0" ]]; then
					echo -e "#\tNo datasets have been installed and not yet initialized/run into queue.";
				else
					echo -e "#\t$installedCount data files have been installed and not yet initialized/run into queue.";
				fi;
				echo -e "#";

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
			grep "\$MAX_MEMORY_TARGET" constants.php > $tempfile;
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
				grep "\$MAX_MEMORY_TARGET" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New per project data limit in Gb.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$MAX_MEMORY_TARGET/c\\\$MAX_MEMORY_TARGET = ${2};" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$MAX_MEMORY_TARGET" constants.php > $tempfile;
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
## DRAGON : not finalized below.
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
	    "run")
		fail=0;
		if [ "$user" = "" ]; then
			if [[ "$arguments_count" = 2 ]]; then
				echo -e "# YMAP2 commandline : Run project queue.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				userAccount=$2;
			else
				echo -e "# YMAP2 commandline : Run project queue.";
				logged_in_status;
				echo -e $lineThin;
				echo -e "#";
				echo -e "#\tUsage: bash YMAPcl.sh run \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcl.sh log_in \e[31m(user)\e[0m";
                                fail=1;
			fi;
		else
			echo -e "# YMAP2 commandline : Run project queue.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			userAccount=$user;
		fi;
		if [[ $(ls $main_dir"/users/"$user"/bulkdata/" | wc -l) = "0" ]]; then
			echo -e "#\t\e[41mNo datasets have been installed and not yet run for this user.\e[0m";
			fail=1;
		fi;

		if [[ "$fail" -eq 0 ]]; then
			# Clear *.txt files from bulksettings directory of active user, to ensure there's no crossover from earlier runs.
			bulkDir=$main_dir"/users/"$user"/bulksettings/";
			rm $bulkDir *.txt;

			#// Main selections needed.
			#$ploidy          = sanitizeFloat_ARGV(2);
			#$ploidyBase      = sanitizeFloat_ARGV(3);
			#$dataFormat      = sanitizeIntChar_ARGV(4);
			#$showAnnotations = sanitizeIntChar_ARGV(5);
			#$manualLOH       = sanitizeTabbed_ARGV(6);
			#$genome          = sanitize_ARGV(7);
			#$hapmap          = sanitize_ARGV(8);
			#$bias_GC         = sanitizeBoolean_ARGV(9);
			#$bias_end        = sanitizeBoolean_ARGV(10);

			# Ask the user which genome to use.
			genomeDir1=$main_dir"/users/"$user"/genomes/";
			genomeDir2=$main_dir"/users/default/genomes/";
			nameString=""
			maxNameLength=0;
			counter=1;
			genomes=();
			cd $genomeDir1;
			if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
				for dir in */; do
					name=$( echo ${dir::-1} );
					if [[ ${#String} -gt "$maxNameLength" ]]; then
						maxNameLength=${#name};
					fi;
					genomes+=($name);
					nameString=$nameString" "$counter" "$name;
					counter=$(($counter+1));
				done;
			else
				nameString="";
			fi;
			cd ../../../;
			cd $genomeDir2;
			if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
				for dir in */; do
					name=$( echo ${dir::-1} );
					if [[ ${#String} -gt "$maxNameLength" ]]; then
						maxNameLength=${#name};
					fi;
					genomes+=($name);
					nameString=$nameString" "$counter" "$name;
					counter=$(($counter+1));
				done;
			else
				nameString="";
			fi;
			cd ../../../;
			tempfile=$(mktemp --suffix ".ymap");
			(dialog --nocancel --menu "Select genome to use." 25 $maxNameLength 25 $nameString) 2> $tempfile
			selectedKey=$(head -n 1 $tempfile);
			genome=${genomes[$selectedKey-1]};

			# Get default ploidy from installed genome.
			genomeDir1=$main_dir"/users/"$user"/genomes/"$genome;
			genomeDir2=$main_dir"/users/default/genomes/"$genome;
			if [[ -e "$genomeDir1" ]]; then
				ploidy=$(cat $genomeDir1"/ploidy.txt");
			elif [[ -e "$genomeDir2" ]]; then
				ploidy=$(cat $genomeDir2"/ploidy.txt" );
			fi;

			# Ask user what ploidy to use for figure, using default ploidy from genome.
			(dialog --form "Ploidy settings can be updated later." 12 40 4 "Ploidy of experiment:" 1 1 "$ploidy" 1 23 5 0 "Baseline ploidy:" 2 1 "$ploidy" 2 23 5 0) 2> $tempfile;
			results=$(cat $tempfile);
			ploidy=$(echo "${results#* ' '}" | head -n 1);
			ploidyBase=$(echo "${results#* ' '}" | tail -n 1);

			# dataformat default to 1 for short- or long-read sequence data.
			dataFormat=1;

			# showAnnotations
			#	<option value="1">Yes</option>
			#	<option value="0">No</option>
			## Confirming user choice before deleting.
			clear;
			echo -e $lineThick;
			echo -e "# YMAP2 commandline : Run processing queue.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tSelected genome.";
			echo -e "#\t\t$genome";
			echo -e "#";
			echo -e "#\tPloidy estimate = "$ploidy;
			echo -e "#\t\tThis value is an estimate for the experimental sample and can be later adjusted for individual datasets.";
			echo -e "#";
			echo -e "#\tBaseline ploidy - "$ploidyBase;
			echo -e "#\t\tThis value is used to define the midline of chromosome cartoons in generated figures, can be later adjusted.";
			echo -e "#";
			echo -e "#\tWould you like to generate figures using any annotations defind for this genome?";
			echo -e -n "#\t\t[yes/no]: ";
			read -r response;
			if [ "$response" = "yes" ]; then
				echo -e "#";
				showAnnotations=1;
			elif [ "$response" = "no" ]; then
				echo -e "#";
				showAnnotations=0;
			else
				echo -e "#\t\tUnclear entry, defaulting to 'yes'.";
				echo -e "#";
				showAnnotations=1;
			fi;

			# manualLOH is not yet used, default to "";
			manualLOH="none";

			# Look to see if there are any haplotype maps defined for the chosen genome.
			hapmapDir1=$main_dir"/users/"$user"/hapmaps/";
			hapmapDir2=$main_dir"/users/default/hapmaps/";
			nameString=""
			maxNameLength=0;
			counter=1;
			hapmaps=();
			cd $hapmapDir1;
			if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
				for dir in */; do
					name=$( echo ${dir::-1} );
					if [[ ${#String} -gt "$maxNameLength" ]]; then
						maxNameLength=${#name};
					fi;
					genomeName=$(head -n 1 $hapmapDir1$name"/genome.txt");
					if [[ "$genome" = "$genomeName" ]]; then
						hapmaps+=($name);
						nameString=$nameString" "$counter" "$name;
						counter=$(($counter+1));
					fi;
				done;
			else
				nameString="";
			fi;
			cd ../../../;
			cd $hapmapDir2;
			if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
				for dir in */; do
					name=$( echo ${dir::-1} );
					if [[ ${#String} -gt "$maxNameLength" ]]; then
						maxNameLength=${#name};
					fi;
					genomeName=$(head -n 1 $hapmapDir2$name"/genome.txt");
					if [[ "$genome" = "$genomeName" ]]; then
						hapmaps+=($name);
						nameString=$nameString" "$counter" "$name;
						counter=$(($counter+1));
					fi;
				done;
			else
				nameString="";
			fi;
			cd ../../../;
			if [[ ${#a[@]} -gt 0 ]]; then
				(dialog --nocancel --menu "Select haplotype map to use." 25 $maxNameLength 25 $nameString) 2> $tempfile
				selectedKey=$(head -n 1 $tempfile);
				hapmap=${hapmaps[$selectedKey-1]};
			else
				hapmap="none";
			fi;

			# Get bias correction selections.
			clear;
			echo -e $lineThick;
			echo -e "# YMAP2 commandline : Run processing queue.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tSelected genome.";
			echo -e "#\t\t$genome";
			echo -e "#";
			echo -e "#\tPloidy estimate = "$ploidy;
			echo -e "#\t\tThis value is an estimate for the experimental sample and can be later adjusted for individual datasets.";
			echo -e "#";
			echo -e "#\tBaseline ploidy - "$ploidyBase;
			echo -e "#\t\tThis value is used to define the midline of chromosome cartoons in generated figures, can be later adjusted.";
			echo -e "#";
			echo -e "#\tWould you like to generate figures using any annotations defind for this genome?";
			if [[ "$showAnnotations" = 0 ]]; then
				echo -e "#\t\t[yes/no]: no";
			else # if [[ "$showAnnotations" = 1 ]]; then
				echo -e "#\t\t[yes/no]: yes";
			fi;
			echo -e "#"
			echo -e "#\tWould you like to apply GC% bias correction to the data before display?"
			echo -e -n "#\t\t[yes/no]: "
			read -r response;
			if [ "$response" = "yes" ]; then
				bias_GC=true;
			elif [ "$response" = "no" ]; then
				bias_GC=false;
			else
				echo -e "#\t\tUnclear entry, defaulting to 'yes'.";
				bias_GC=true;
			fi;
			echo -e "#"
			echo -e "#\tWould you like to apply GC% bias correction to the data before display?"
			echo -e -n "#\t\t[yes/no]: "
			read -r response;
			if [ "$response" = "yes" ]; then
				bias_end=true;
			elif [ "$response" = "no" ]; then
				bias_end=false;
			else
				echo -e "#\t\tUnclear entry, defaulting to 'no'.";
				bias_end=false;
			fi;

			#       // Figure selection booleans.
			#       $fig_A1          = sanitizeBoolean_ARGV(11);
			#       $fig_A2          = sanitizeBoolean_ARGV(12);
			#       $fig_B1          = sanitizeBoolean_ARGV(13);
			#       $fig_B2          = sanitizeBoolean_ARGV(14);
			#       $fig_C           = sanitizeBoolean_ARGV(15);
			#       $fig_D1          = sanitizeBoolean_ARGV(16);
			#       $fig_D2          = sanitizeBoolean_ARGV(17);
			#       $fig_E           = sanitizeBoolean_ARGV(18);
			#       $fig_F1          = sanitizeBoolean_ARGV(19);
			#       $fig_F2          = sanitizeBoolean_ARGV(20);
			#       $fig_G1          = sanitizeBoolean_ARGV(21);
			#       $fig_G2          = sanitizeBoolean_ARGV(22);

			options=();
			if [[ "$bias_GC" = "true" ]]; then
				options+=(0 "GC-content bias figure" on);
			fi
			if [[ "$bias_end" = "true" ]]; then
				options+=(1 "Chromosome-end bias figure" on);
			fi;
			options+=(2 "Linear CNV map figure" off);
			options+=(3 "Full CNV map figure" off);
			options+=(4 "Linear high-top CNV figure" off);
			options+=(5 "Linear SNP/LOH map figure" off);
			options+=(6 "Full SNP/LOH map figure" off);
			options+=(7 "Linear allelic ratio (fire-plot) map figure" off);
			options+=(8 "Linear CNV/SNP/LOH map figure" on);
			options+=(9 "Full CNV/SNP/LOH map figure" on);
			options+=(10 "Linear CNV/SNP/LOH map figure with alternate color scheme." off);
			options+=(11 "Full CNV/SNP/LOH map figure with alternate color scheme." off);
			cmd=(dialog --output-fd 1 --separate-output --checklist 'Choose the figures to generate.\nThese choices can be adjusted later.' 0 0 0)
			choices=$("${cmd[@]}" "${options[@]}")
			clear;
			contains() {
				value=0;
				for word in $choices; do
					if [[ "$word" = "$1" ]]; then
						value=1;
					fi;
				done
				return $value;
			}
			if contains "0";  then fig_A1=false; else fig_A1=true; fi;
			if contains "1";  then fig_A2=false; else fig_A2=true; fi;
			if contains "2";  then fig_B1=false; else fig_B1=true; fi;
			if contains "3";  then fig_B2=false; else fig_B2=true; fi;
			if contains "4";  then fig_C=false;  else fig_C=true;  fi;
			if contains "5";  then fig_D1=false; else fig_D1=true; fi;
			if contains "6";  then fig_D2=false; else fig_D2=true; fi;
			if contains "7";  then fig_E=false;  else fig_E=true;  fi;
			if contains "8";  then fig_F1=false; else fig_F1=true; fi;
			if contains "9";  then fig_F2=false; else fig_F2=true; fi;
			if contains "10"; then fig_G1=false; else fig_G1=true; fi;
			if contains "11"; then fig_G2=false; else fig_G2=true; fi;

			echo -e $lineThick;
			echo -e "# YMAP2 commandline : Run processing queue.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tSelected genome.";
			echo -e "#\t\t$genome";
			echo -e "#";
			echo -e "#\tPloidy estimate = "$ploidy;
			echo -e "#\t\tThis value is an estimate for the experimental sample and can be later adjusted for individual datasets.";
			echo -e "#";
			echo -e "#\tBaseline ploidy - "$ploidyBase;
			echo -e "#\t\tThis value is used to define the midline of chromosome cartoons in generated figures, can be later adjusted.";
			echo -e "#";
			echo -e "#\tWould you like to generate figures using any annotations defind for this genome?";
			if [[ "$showAnnotations" = 0 ]]; then
				echo -e "#\t\t[yes/no]: no";
			else # if [[ "$showAnnotations" = 1 ]]; then
				echo -e "#\t\t[yes/no]: yes";
			fi;
			echo -e "#"
			echo -e "#\tWould you like to apply GC% bias correction to the data before display?"
			if [[ "$bias_GC" = "true" ]]; then
				echo -e "#\t\t[yes/no]: yes";
			else
				echo -e "#\t\t[yes/no]: no"
			fi;
			echo -e "#"
			echo -e "#\tWould you like to apply GC% bias correction to the data before display?"
			if [[ "$bias_end" = "true" ]]; then
				echo -e "#\t\t[yes/no]: yes";
			else
				echo -e "#\t\t[yes/no]: no"
			fi;
			echo -e "#"
			echo -e "#\tFigure types selected:"
			for i in $choices; do
				echo -e "#\t\t"${options[$i*3+1]};
			done;
			echo -e "#"

			#echo "user            : "$user;
			#echo "ploidy          : "$ploidy;
			#echo "ploidyBase      : "$ploidyBase;
			#echo "dataFormat      : "$dataFormat;		# '1' for seq data.
			#echo "showAnnotations : "$showAnnotations;	# '0' or '1' for no/yes
			#echo "manualLOH       : "$manualLOH;
			#echo "genome          : "$genome;
			#echo "hapmap          : "$hapmap;
			#echo "bias_GC         : "$bias_GC;		# ''/'False' => false; other => true.
			#echo "bias_end        : "$bias_end;		# ''/'False' => false; other => true.
			#echo "fig_A1          : "$fig_A1;
			#echo "fig_A2          : "$fig_A2;
			#echo "fig_B1          : "$fig_B1;
			#echo "fig_B2          : "$fig_B2;
			#echo "fig_C           : "$fig_C;
			#echo "fig_D1          : "$fig_D1;		# all fig settings are "true"/"false";
			#echo "fig_D2          : "$fig_D2;
			#echo "fig_E           : "$fig_E;
			#echo "fig_F1          : "$fig_F1;
			#echo "fig_F2          : "$fig_F2;
			#echo "fig_G1          : "$fig_G1;
			#echo "fig_G2          : "$fig_G2;

			php project_bulk.create_server.php $user $ploidy $ploidyBase $dataFormat $showAnnotations $manualLOH $genome $hapmap $bias_GC $bias_end $fig_A1 $fig_A2 $fig_B1 $fig_B2 $fig_C $fig_D1 $fig_D2 $fig_E $fig_F1 $fig_F2 $fig_G1 $fig_G2 >/dev/null 2>&1 &
		fi;
	    ;;
	    *)
		echo -e "# YMAP2 commandline : Unknown command.";
		logged_in_status;
		echo -e $lineThin;
	    ;;
	esac;
	echo -e "#";
	echo -e $lineThick
fi;


