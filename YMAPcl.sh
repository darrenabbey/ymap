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
	echo -e "#        users               : List registered users.";
	echo -e "#        user (user)         : Show user account information.";
	echo -e "#        status              : Shows status of ymap_daemon service.";
	echo -e "#        status (user)       : Shows data processing status.";
	echo -e "#        projects (user)     : Lists installed projects.";
	echo -e "#        genomes (user)      : Lists installed genomes.";
	echo -e "#        hapmaps (user)      : Lists installed hapmaps.";
	echo -e "#        complete (user)     : Lists figure images for completed projects.";
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
	echo -e "#        queue_limit         : Shows the max number of datasets to be processed in parallel.";
	echo -e "#        queue_limit (value) : Sets the max number of datasets to be processed in parallel.";
	echo -e "#                              \e[31mChanging this option will prompt you for your credentials to\e[0m";
	echo -e "#                              \e[31mrestart the yamp_daemon service that manages the queue.\e[0m";
	echo -e "#        data_limit          : Shows the max number of sequence reads to be processed at a time.";
	echo -e "#        data_limit (value)  : Sets the max number of sequence reads to be processed at a time.";
	echo -e "#        admin_email         : Show admin email, displayed in user interface for issues.";
	echo -e "#        admin_email (value) : Set admin email, displayed in user interface for issues.";
	echo -e "#        quota               : Show per account disk quota.";
	echo -e "#        quota (value)       : Set per account disk quota.";
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
	echo -e $lineThick;
	case $1 in
	    "users")
		echo -e "# YMAP2 commandline : List users.";
		echo -e $lineThin;
		echo -e "#";
		if [ -d $userDirectory ]; then
			echo -e "# Registered user accounts:";
			dirs=$(find $userDirectory* -maxdepth 0 -type d);
			if [ -z "$dirs" ]; then
				echo -e "#\tNo registered users."
			else
				for dir in $dirs; do
					echo -e "#\t"${dir##*/};
				done;
			fi;
		else
			echo -e "#\t\e[41mError: User directory not found!\e[0m";
		fi;
	    ;;
	    "user")
		echo -e "# YMAP2 commandline : User information.";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcl.sh user \e[31m(user)\e[0m";
		else
			echo -e "# user : "$2;
			echo -e "#";
			main_dir=$(pwd);
			userInfoFile=$main_dir"/users/"$2"/info.txt";
			#cat $userInfoFile;
			while IFS= read -r line; do
				echo -e "#\t"$line;
			done < $userInfoFile;
		fi;
	    ;;
	    "status")
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : ymap_daemon service status.";
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap_daemon_status");
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
		else
			echo -e "# YMAP2 commandline : User project status.";
			echo -e $lineThin;
			echo -e "#";
			projectDirectory=$main_dir"/users/"$2"/projects/";
			if [ -d $projectDirectory ]; then
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
				echo -e "#\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;
	    ;;
	    "projects")
		echo -e "# YMAP2 commandline : List user projects.";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcl.sh projects \e[31m(user)\e[0m";
		else
			echo -e "# user : "$2;
			echo -e "#";
			main_dir=$(pwd);
			projectDirectory=$main_dir"/users/"$2"/projects/";
			if [ -d $projectDirectory ]; then
				echo -e "# User installed projects:";
				dirs=$(find $projectDirectory* -type d);
				if [ -z "$dirs" ]; then
					echo -e "#\tNo user installed projects."
				else
					for dir in $dirs; do
						echo -e "#\t"${dir##*/};
					done;
				fi;

			else
				echo -e "#\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;
	    ;;
	    "genomes")
		echo -e "# YMAP2 commandline : List user genomes.";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcl.sh genomes \e[31m(user)\e[0m";
		else
			echo -e "# user : "$2;
			echo -e "#";
			main_dir=$(pwd);
			genomeDirectory=$main_dir"/users/"$2"/genomes/";
			if [ -d $genomeDirectory ]; then
				echo -e "# User installed genomes:";
				dirs=$(find $genomeDirectory* -type d);
				if [ -z "$dirs" ]; then
					echo -e "#\tNo user installed genomes."
				else
					for dir in $dirs; do
						echo -e "#\t"${dir##*/};
					done;
				fi;
			else
				echo -e "#\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;
		echo -e "#";
		main_dir=$(pwd);
		genomeDirectory=$main_dir"/users/default/genomes/";
		echo -e "# System installed genomes:";
		dirs=$(find $genomeDirectory* -type d);
		if [ -z "$dirs" ]; then
			echo -e "#\tNo system installed genomes."
		else
			for dir in $dirs; do
				echo -e "#\t"${dir##*/};
			done;
		fi;
	    ;;
	    "hapmaps")
		echo -e "# YMAP2 commandline : List user hapmaps.";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcl.sh hapmaps \e[31m(user)\e[0m";
		else
			echo -e "# user : "$2;
			echo -e "#";
			main_dir=$(pwd);
			hapmapDirectory=$main_dir"/users/"$2"/hapmaps/";
			if [ -d $hapmapDirectory ]; then
				echo -e "# User installed hapmaps:";
				dirs=$(find $hapmapDirectory* -type d);
				if [ -z "$dirs" ]; then
					echo -e "#\tNo user installed hapmaps."
				else
					for dir in $dirs; do
						echo -e "#\t"${dir##*/};
					done;
				fi;
			else
				echo -e "#\t\e[41mError: User not registered!\e[0m";
			fi;
		fi;
		echo -e "#";
		main_dir=$(pwd);
		hapmapDirectory=$main_dir"/users/default/hapmaps/";
		echo -e "# System installed hapmaps:";
		dirs=$(find $hapmapDirectory* -type d);
		if [ -z "$dirs" ]; then
			echo -e "#\tNo system installed hapmaps."
		else
			for dir in $dirs; do
				echo -e "#\t"${dir##*/};
			done;
		fi;
	    ;;
	    "complete")
		echo -e "# YMAP2 commandline : List user figures.";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcl.sh complete \e[31m(user)\e[0m";
		else
			echo -e "# user: "$2;
			projectDirectory=$main_dir"/users/"$2"/projects/";
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
		fi;
	    ;;
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
	    queue_limit)
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Limit of YMAP processes to run concurrently in queue.";
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap_setting");
			grep "\$MAX_QUEUE_PARALLEL" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "#	\e[31mChanging this option will prompt you for your credentials to\e[0m";
			echo -e "#	\e[31mrestart the yamp_daemon service that manages the queue.\e[0m";
		else
			echo -e "# YMAP2 commandline : New limit of YMAP processes to run concurrently in queue.";
			echo -e $lineThin;
			echo -e "#";
			sed -i "/\$MAX_QUEUE_PARALLEL/c\\\$MAX_QUEUE_PARALLEL = ${2};" constants.php
			tempfile=$(mktemp --suffix ".ymap_setting");
			grep "\$MAX_QUEUE_PARALLEL" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "#	\e[31mChanging this option will prompt you for your credentials to\e[0m";
			echo -e "#	\e[31mrestart the yamp_daemon service that manages the queue.\e[0m";
			service ymap_daemon restart;
		fi;
	    ;;
	    data_limit)
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Data limit in reads.";
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap_setting");
			grep "\$MAX_READ_COUNT_PER_PROJECT" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "# This is not yet defind or implemented.";
		else
			echo -e "# YMAP2 commandline : New data limit in reads.";
			echo -e $lineThin;
			echo -e "#";
			sed -i "/\$MAX_READ_COUNT_PER_PROJECT/c\\\$MAX_READ_COUNT_PER_PROJECT = ${2};" constants.php
			tempfile=$(mktemp --suffix ".ymap_setting");
			grep "\$MAX_READ_COUNT_PER_PROJECT" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
			echo -e "#";
			echo -e "# This is not yet defind or implemented.";
		fi;
	    ;;
	    admin_email)
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : Admin email address.";
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap_setting");
			grep "\$admin_email" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
		else
			echo -e "# YMAP2 commandline : New admin email address.";
			echo -e $lineThin;
			echo -e "#";
			sed -i "/\$admin_email/c\\\$MAX_READ_COUNT_PER_PROJECT = ${2};" constants.php
			tempfile=$(mktemp --suffix ".ymap_settin");
			grep "\$admin_email" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
		fi;
	    ;;
	    quota)
		if [ -z $2 ]; then
			echo -e "# YMAP2 commandline : User account disk utilization quota.";
			echo -e $lineThin;
			echo -e "#";
			tempfile=$(mktemp --suffix ".ymap_setting");
			grep "\$quota_global" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
		else
			echo -e "# YMAP2 commandline : New user account disk utilization quota.";
			echo -e $lineThin;
			echo -e "#";
			sed -i "/\$quota_global/c\\\$MAX_READ_COUNT_PER_PROJECT = ${2};" constants.php
			tempfile=$(mktemp --suffix ".ymap_settin");
			grep "\$quota_global" constants.php > $tempfile;
			awk '{ while (length > 160) { print substr($0, 1, 160); $0 = "\t     │\t\t" substr($0, 161); } print $0; }' $tempfile | sed 's/^/#\t/' | cat;
		fi;
	    ;;
	esac;
	echo -e "#";
	echo -e $lineThick
fi;

