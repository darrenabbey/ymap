#!/bin/bash
set -e;

lineThick="#================================================================================#";
lineThin="#--------------------------------------------------------------------------------#";

if [ -z $1 ]; then
	echo -e $lineThick;
	echo -e "# YMAP2 commandline";
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
	echo -e "#	complete	: Lists figure images for completed projects.";

	echo -e "#        queue               : Shows the status of the YMAP processing queue.";
	echo -e "#                              \e[31mNot yet implemented!\e[0m";
	echo -e "#        queue delete        : Force ends an item from the processing queue. To be used in case";
	echo -e "#                              there is ever an improperly terminated process that somehow doesn't";
	echo -e "#                              lead to an end entry in the queue log, leading to the queue being";
	echo -e "#                              hung/stuck."
	echo -e "#                              \e[31mNot yet implemented!\e[0m";
	echo -e "#        queue flush         : Cleans up resolved entries from the queue log. Should not be needed,";
	echo -e "#                              but may be useful for managing the queue.";
	echo -e "#                              \e[31mNot yet implemented!\e[0m";
	echo -e "#";
	echo -e "#   Other commands not yet implemented:";
	echo -e "#        install dataset (user)   => user interface?";
	echo -e "#        install bulk_data (user) => user interface?";
	echo -e "#        install genome (user)    => user interface?";
	echo -e "#        build hapmap (user)      => user interface?";
	echo -e "#        minimize dataset (user)  => user interface?";
	echo -e "#        delete dataset (user)    => user interface?";
	echo -e "#        delete genome (user)     => user interface?";
	echo -e "#        delete hapmap (user)     => user interface?";
	echo -e "#        combine figures (user)   ???";
	echo -e "# ";
	echo -e $lineThick;
else
	main_dir=$(pwd);
	userDirectory=$main_dir"/users/";

	##
	## Check to see if a user account is logged in.
	##
	if [ -e $main_dir"/YMAPcl.dat" ]; then
		user=$(head -n 1 $main_dir"/YMAPcl.dat");
	else
		user="";
	fi;


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

			if [ "$user" != "" ]; then
				## Show currently logged in account, if logged in.
				echo -e "#";
				echo -e "#\tUser '$user' is currently logged in." ;
			fi;
		else
			echo -e "#      User $2 has been logged in.";
			echo $2 > $main_dir"/YMAPcl.dat";
			#dialog --menu "Select user account." 12 45 25 1 "apple" 2 "banana" 3 "grapes" 4 "oranges";
		fi;
	    ;;
	    "log_out")
		echo -e "# YMAP2 commandline :";
		echo -e $lineThin;
		echo -e "#";
		echo -e "#\tUser $user has been logged out.";
		echo "" > $main_dir"/YMAPcl.dat";
	    ;;
	    "info")
		echo -e "# YMAP2 commandline : User information.";
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
	    data_limit)
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Per project data limit in Gb.";
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
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$MAX_PROCESSED_DATA_SIZE" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New per project data limit in Gb.";
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
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$ADMIN_EMAIL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New admin email address.";
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$ADMIN_EMAIL/c\\\$ADMIN_EMAIL = \"${2}\";" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$ADMIN_EMAIL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			fi;
		fi;
	    ;;
	    quota)
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : User account disk utilization quota.";
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
				echo -e $lineThin;
				echo -e "#";
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$QUOTA_GLOBAL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
				echo -e "#";
				echo -e "#\t\e[41mInvalid input.\e[0m";
			else
				echo -e "# YMAP2 commandline : New user account disk utilization quota.";
				echo -e $lineThin;
				echo -e "#";
				sed -i "/\$QUOTA_GLOBAL/c\\\$QUOTA_GLOBAL = ${2};" constants.php
				tempfile=$(mktemp --suffix ".ymap");
				grep "\$QUOTA_GLOBAL" constants.php > $tempfile;
				awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			fi;
		fi;
	    ;;


##
## DRAGON : not updated below.
##

	    "delete")
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Delete project/genome/hapmap/user.";
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tUsage1: bash YMAPcl.sh delete \e[31m(project) (user)\e[0m";
			echo -e "#\tUsage2: bash YMAPcl.sh delete \e[31m(genome) (user)\e[0m";
			echo -e "#\tUsage3: bash YMAPcl.sh delete \e[31m(hapmap) (user)\e[0m";
			echo -e "#\tUsage4: bash YMAPcl.sh delete \e[31m(user)\e[0m";
		else
			case $2 in
			    "project")
				if [ -z $3 ]; then
					echo -e "# YMAP2 commandline : Delete project.";
					echo -e $lineThin;
					echo -e "#";
					echo -e "#\tUsage1: bash YMAPcl.sh delete project \e[31m(user)\e[0m";
				else
					### https://www.geeksforgeeks.org/linux-unix/shell-scripting-dialog-boxes/
					function DialogGen() {
						# dialog --title "Delete Project" --msgbox 'Start of user interface to delete an installed project.' 10 40;
						# dialog --checklist 'checklist' 15 10 10 'potato'  5 'on'  'carrot' 2 'off' 'grape' 3 'on' 'cabbage' 4 'off';
						dialog --menu "Select project to delete." 12 45 25 1 "apple" 2 "banana" 3 "grapes" 4 "oranges";
					}
					DialogGen
					clear;
				fi;
			    ;;
			    "genome")
				if [ -z $3 ]; then
					echo -e "# YMAP2 commandline : Delete genome.";
					echo -e $lineThin;
					echo -e "#";
					echo -e "#\tUsage1: bash YMAPcl.sh delete genome \e[31m(user)\e[0m";
				else
					# comment.
					echo -e " DD";
				fi;
			    ;;
			    "hapmap")
				if [ -z $3 ]; then
					echo -e "# YMAP2 commandline : Delete hapmap.";
					echo -e $lineThin;
					echo -e "#";
					echo -e "#\tUsage1: bash YMAPcl.sh delete hapmap \e[31m(user)\e[0m";
				else
					# comment.
					echo -e " DD";
				fi;
			    ;;
			    *)
				# comment.
				echo -e " DD";
			    ;;
			esac;
		fi;
	    ;;
	esac;
	echo -e "#";
	echo -e $lineThick
fi;

