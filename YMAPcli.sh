#!/bin/bash
set -e;

main_dir=$(pwd);
userDirectory=$main_dir"/users/";
if [ -e $main_dir"/YMAPcli.dat" ]; then
	user=$(head -n 1 $main_dir"/YMAPcli.dat");
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
	cat images/YMAP2_Logo_1.txt | sed 's/^/# /';
	echo -e "$";
	logged_in_status;
	echo -e $lineThin;

	echo -e "#";
	echo -e "# Command syntax is : 'bash YMAPcli.sh [command] (option1) (option2) (...)'";
	echo -e "# ";
	echo -e "#   Commands:";
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
	echo -e "#	daemon_log      : Show last 40 lines of the event log for the ymap_daemon service.";
	echo -e "#	queue_limit	: Show the max number of datasets to be processed in parallel.";
	echo -e "#	data_limit	: Show the target max memory utilization.";
	echo -e "#	admin_email	: Show admin email, displayed in user interface for issues.";
	echo -e "#	quota		: Show per account disk quota.";
	echo -e "#	info		: Show user account information.";
	echo -e "#	status		: Show data processing status.";
	echo -e "#	status_daemon   : Combined 'status' and 'daemon' functions.";
	echo -e "#	genomes		: List installed genomes.";
	echo -e "#	hapmaps		: List installed hapmaps.";
	echo -e "#	complete	: List file paths & names of images for completed projects.";
	echo -e "#	preview         : Preview an image in the shell.";
	echo -e "#	delete		: Delete a project/genome/hapmap/user.";
	echo -e "#	install		: Install a new project/genome/user.";
	echo -e "#				\e[32mNew user installation is not implemented.\e[0m";
	echo -e "#	run		: Configure and run installed project datasets.";
	echo -e "#";
	echo -e "#   Commands not implemented:"
	echo -e "#	queue		: Shows the status of the YMAP processing queue.";
	echo -e "#	queue flush	: Clean up corrupted queue log. May be needed if queue refuses to run";
	echo -e "E				 installed data files.";
	echo -e "#	combine_figures	: ";
	echo -e "#	build_hapmap	: complicated user interface required, may not be possible in commandline.";
	echo -e "#	minimize	: ";
	echo -e "#";
	echo -e "#   How to cite:";
	echo -e "#	Abbey DA, Funt J, Lurie-Weinberger MN, Thompson DA, Regev A, Myers CL, Berman J.";
	echo -e "#	YMAP: a pipeline for visualization of copy number variation and loss of heterozygosity";
	echo -e "#	in eukaryotic pathogens. Genome Med. 2014 Nov 20;6(11):100. doi: 10.1186/s13073-014-0100-8.";
	echo -e "#	PMID: 25505934; PMCID: PMC4263066.";
	echo -e "#";
	echo -e "#   If you're interested in a collaboration to use this tool or for processing data from organisms with";
	echo -e "#	much larger genomes than the yeast described in the publication, please reach out to me by email at";
	echo -e "#	\e[33mabbey007@umn.edu\e[0m or \e[33mdarrenabbey.ymap@gmail.com\e[0m or on various social medias as \e[33mthebiologistisn\e[0m.";
	echo -e "#";
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
	function secureNewDirectory() {
		dir=$1;
		# Run PHP secureNewDirectory function.
		tempfile=$(mktemp --suffix ".ymap.php");
		echo -e "<?php" > $tempfile;
		echo -e "chdir('$main_dir');" >> $tempfile;
		echo -e "require_once 'constants.php';" >> $tempfile;
		echo -e "require_once 'sharedFunctions.php';" >> $tempfile;
		echo -e "secureNewDirectory('$dir');" >> $tempfile;
		echo -e "?>" >> $tempfile;
		php $tempfile;
	}
	function log_stuff() {
		user=$1;
		project=$2;
		hapmap=$3;
		genome=$4;
		filename=$5;
		message=$6;
		# Run PHP log_stuff function.
		tempfile=$(mktemp --suffix ".ymap.php");
		echo -e "<?php" > $tempfile;
		echo -e "chdir('$main_dir');" >> $tempfile;
		echo -e "require_once 'constants.php';" >> $tempfile;
		echo -e "require_once 'sharedFunctions.php';" >> $tempfile;
		echo -e "log_stuff('$user','$project','$hapmap','$genome','$filename','$message');" >> $tempfile;
		echo -e "?>" >> $tempfile;
		php $tempfile;
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
		cd $main_dir;

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
			cd $main_dir;

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
						queue_end_project $main_dir $userAccount $selectedName "YMAPcli.sh deleted.";
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

		case $whatisit in
		    "project")
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
			echo -e "#";

			## Accept input path;
			echo -e "#\tEnter the path to your data files.";
			echo -e -n "#\t\t[path/]: ";
			read -r selectedDirectory;
			if [[ -z "$selectedDirectory" ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid path:";
				echo -e "E\t\tPath can't be empty.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			elif [[ ! -e "$selectedDirectory" ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid path:";
				echo -e "E\t\tPath must exist.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			fi;

			## Dialog to accept user file(s).
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
			echo -e "# YMAP2 commandline : Install project.";
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
		    ;;
		    "genome")
			workingDirectory=$main_dir"/users/"$user"/genomes/";
			if [[ ! -e $workingDirectory ]]; then
				echo -e "#\t\e[41mInvalid selection: User not found.\e[0m";
				echo -e "#";
				echo -e $lineThick;
				return 1;
			fi;

			echo -e "#\tInstalling a new genome.";
			echo -e "#\t\tAfter installing a *.FASTA to be processed, some information";
			echo -e "#\t\twill be requested, and then the genome will be add to the";
			echo -e "#\t\tprocessing queue.";
			echo -e "#";

			## Accept input path;
			echo -e "#\tEnter the path to your data files.";
			echo -e -n "#\t\t[path/]: ";
			read -r selectedDirectory;
			if [[ -z "$selectedDirectory" ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid path:";
				echo -e "E\t\tPath can't be empty.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			elif [[ ! -e "$selectedDirectory" ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid path:";
				echo -e "E\t\tPath must exist.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			fi;

			## Dialog to grab specific file.
			startingDirectory=$(pwd);
			cd $selectedDirectory;
			if [ "$(find . -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
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
			cmd=(dialog --output-fd 1 --radiolist 'Choose the file to install:' 0 0 0)
			choices=$("${cmd[@]}" "${options[@]}")
			clear;

			cd $selectedDirectory;
			selectedFile="";
			if [ "$(find . -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
				counter=1;
				for file in *; do
					if [ -f "$file" ]; then
						name=$(echo -n "$file");
						if [[ $choices == *"$counter"* ]]; then
							selectedFile=$name;
						fi
						counter=$(($counter+1));
					fi
				done;
			fi;
			cd $startingDirectory;
			if [[ -z "$selectedFile" ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid file:";
				echo -e "E\t\tFile can't be empty.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			fi;

			## Rebuild interface.
			echo -e $lineThick;
			echo -e "# YMAP2 commandline : Install genome.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tInstalling a new genome.";
			echo -e "#\t\tAfter installing a *.FASTA to be processed, some information";
			echo -e "#\t\will be requested, and then the genome will be add to the";
			echo -e "#\t\tprocessing queue.";
			echo -e "#";
			echo -e "#\tEnter the path to your data files.";
			echo -e "#\t\t[path/]: "$selectedDirectory;
			echo -e "#";
			echo -e "#\tFASTA file selected:";
			echo -e "#\t\t"$selectedFile;
			echo -e "#";

			## Accept name string.
			echo -e "#\tEnter the name for your new genome.";
			echo -e -n "#\t\t[name]: ";
			read -r genome;
			echo -e "#";
			genomeDir_user="$main_dir/users/$user/genomes/$genome";
			genomeDir_sys="$main_dir/users/default/genomes/$genome";
			if [[ -z "$genome" ]]; then
				echo -e "#\tThat is not a valid name:";
				echo -e "E\t\tName can't be empty.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			elif ! [[ "$genome" =~ ^[a-zA-Z0-9._]*$ ]]; then
				echo -e "#\tThat is not a valid name:";
				echo -e "#\t\tUse only a-z, A-Z, 0-9, '.', or '_' characters.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			elif [[ -e $genomeDir_user ]] || [[ -e $genomeDir_sys ]]; then
				echo -e "#\tGenome '$genome' directory already exists.";
				echo -e "#";
				echo -e $lineThick;
				log_stuff "$user" "" "" "$genome" "" "genome:CREATE failure";
				exit;
			fi;

			## Make genomes directory if not found.
			genomesDir="$main_dir/users/$user/genomes";
			if [[ -z "$genomesDir=" ]]; then
				# User genome directory accidentally not present.
				mkdir $genomesDir;
				chmod 0773 $genomesDir;
				secureNewDirectory $genomesDir;
			fi;

			mkdir $genomeDir_user;
			chmod 0773 $genomeDir_user
			secureNewDirectory $genomeDir_user;

			# Process selected FASTA file into user directory.
			cp $selectedDirectory$selectedFile $genomeDir_user;

			# PHP: scripts_genomes/genome.install_1.php
			cd $main_dir"/scripts_genomes";
			php genome.install_1.php $user $selectedFile $genome "g_0" 2> $main_dir/users/$user/genomes/$genome/process_log.txt;
			cd $main_dir;

			# Log it.
			log_stuff "$user" "" "" "$genome" "" "genome:CLI-CREATE success";
			fail=false;

			# Ask user for default ploidy for genome.
			tempfile=$(mktemp --suffix ".ymap");
			(dialog --form "What is the default ploidy for this genome?" 12 40 4 "Ploidy (#.#) = " 1 1 "" 1 15 4 0) 2> $tempfile;
			results=$(cat $tempfile);
			ploidy=$(echo "${results#* ' '}" | head -n 1);
			if ! [[ "$ploidy" =~ ^[0-9]\.[0-9]$ ]]; then
				echo -e "#";
                                echo -e "#\tThat is not a valid ploidy value:";
                                echo -e "#\t\tUse something like '1.0', '2.0', etc.";
                                echo -e "#";
                                echo -e $lineThick;
                                exit;
			fi;

			# Grab chromosome sizes from json.
			chrLengths_json=$(cat "$main_dir/users/$user/genomes/$genome/chr_lengths.json");
			chrLengths_json=$(echo ${chrLengths_json//[\[\]]});
			IFS=',' read -r -a chrLengths <<< "$chrLengths_json";

			# Grab chromosome names from json.
			chrNames_json=$(cat "$main_dir/users/$user/genomes/$genome/chr_names.json");
			chrNames_json=$(echo ${chrNames_json//[\[\]\"]});
			IFS=',' read -r -a chrNames <<< "$chrNames_json";

			# Ask user what chromosomes to use for genome.
			counter=1;
			options=();
			for chrName in "${chrNames[@]}"; do
				#echo $name;
				options+=($counter $chrName on);
				counter=$(($counter+1));
			done;
			cmd=(dialog --output-fd 1 --separate-output --checklist 'Which chromosomes would you like to use?' 0 0 0)
			selectedChrs=$("${cmd[@]}" "${options[@]}")
			selectedChrs=$(echo ${selectedChrs[@]});
			IFS=' ' read -r -a selectedChrs <<< $selectedChrs;

			# Ask user what labels to use for selected chromosomes.
			tempfile=$(mktemp --suffix ".ymap");
			maxNameLength=0;
			for chr in ${selectedChrs[@]}; do
				name=${chrNames[$chr-1]};
				if [[ ${#name} -gt "$maxNameLength" ]]; then
					maxNameLength=${#name};
				fi;
			done;
			options=();
			counter=1;
			for chr in ${selectedChrs[@]}; do
				name=${chrNames[$chr-1]};
				# (label y x item y x fieldLength inputLength)
				options+=($name $counter "1" "chr"$chr $counter $(($maxNameLength+3)) "6" "6");
				counter=$(($counter+1));
			done;
			tempfile=$(mktemp --suffix ".ymap");
			# --form text height width formheight [ label y x item y x fieldLength itemLength ] ...
			(dialog --form 'Define labels for chromosomes.' 20 $(($maxNameLength+15)) 12 ${options[@]}) 2> $tempfile;
			chrLabels_init=$(cat $tempfile);
			chrLabels=();
			for element in $chrLabels_init; do
				chrLabels+=($element);
			done;

			# Ask for centromere start coordinates.
			options=();
			counter=1;
			for chr in ${selectedChrs[@]}; do
				name=${chrNames[$chr-1]}"("${chrLabels[$counter-1]}")";
				# (label y x item y x fieldLength inputLength)
				options+=($name $counter "1" "0" $counter $(($maxNameLength+10)) "6" "6");
				counter=$(($counter+1));
			done;
			tempfile=$(mktemp --suffix ".ymap");
			(dialog --form 'Define CEN start coordinates.\n    (Leave as 0 if unknown.)' 20 $(($maxNameLength+15+10)) 12 ${options[@]}) 2> $tempfile;
			cenStarts_init=$(cat $tempfile);
			cenStarts=();
			for element in $cenStarts_init; do
				cenStarts+=($element);
			done;

			# Ask for centromere end coordinates.
			tempfile=$(mktemp --suffix ".ymap");
			(dialog --form 'Define CEN end coordinates.\n    (Leave as 0 if unknown.)' 20 $(($maxNameLength+15+10)) 12 ${options[@]}) 2> $tempfile;
			cenEnds_init=$(cat $tempfile);
			cenEnds=();
			for element in $cenEnds_init; do
				cenEnds+=($element);
			done;

			# Ask if rDNA is present on this chromosome.
			options=();
			counter=1;
			for chr in ${selectedChrs[@]}; do
				name=${chrNames[$chr-1]}"("${chrLabels[$counter-1]}")";
				options+=($counter $name off);
				counter=$(($counter+1));
			done;
			cmd=(dialog --output-fd 1 --checklist 'Is rDNA on this chromosome?\n    (Leave unselected if unknown.)' 0 0 0);
			rdnaChromosomes=$("${cmd[@]}" "${options[@]}")
			rdnaChromosomes=$(echo ${rdnaChromosomes[@]});
			IFS=' ' read -r -a rdhaChromosomes <<< $rdnaChromosomes;

			if [[ ! -z "$rdnaChromosomes" ]]; then
				# Ask for rDNA start and end coordinates.
				options=();
				counter=1;
				for chr in ${rdnaChromosomes[@]}; do
					name=${chrNames[$chr-1]}"("${chrLabels[$counter-1]}")";
					# (label y x item y x fieldLength inputLength)
					options+=($name'[rDNA_start]' $(($counter  )) "1" "0" $(($counter  )) $(($maxNameLength+15+10)) "20" "20");
					options+=($name'[rDNA_end]'   $(($counter+1)) "1" "0" $(($counter+1)) $(($maxNameLength+15+10)) "20" "20");
					counter=$(($counter+2));
				done;
				tempfile=$(mktemp --suffix ".ymap");
				(dialog --form 'Define rDNA coordinates.\n    (Leave as 0 if unknown.)' 20 $(($maxNameLength+43+10)) 12 ${options[@]}) 2> $tempfile;
				rdnaCoords_init=$(cat $tempfile);
				rdnaCoords=();
				for element in $rdnaCoords_init; do
					rdnaCoords+=($element);
				done;
			else
				rdnaCoords=();
			fi;

			# Ask for order of chromosomes in figure.
			options=();
			counter=1;
			for chr in ${selectedChrs[@]}; do
				name=${chrNames[$chr-1]}"("${chrLabels[$counter-1]}")";
				# (label y x item y x fieldLength inputLength)
				options+=($name $counter "1" $counter $counter $(($maxNameLength+3+10)) "6" "6");
				counter=$(($counter+1));
			done;
			tempfile=$(mktemp --suffix ".ymap");
			(dialog --form 'Define figure chromosome order' 20 $(($maxNameLength+15+10)) 12 ${options[@]}) 2> $tempfile;
			chrOrder=$(cat $tempfile);
			chrOrder=$(echo ${chrOrder[@]});
			IFS=' ' read -r -a chrOrder <<< $chrOrder;

			# Ask if chromosome is reversed.
			options=();
			counter=1;
			for chr in ${selectedChrs[@]}; do
				name=${chrNames[$chr-1]}"("${chrLabels[$counter-1]}")";
				options+=($counter $name off);
				counter=$(($counter+1));
			done;
			cmd=(dialog --output-fd 1 --checklist 'Is this chromosome reversed?\n    (Leave unselected if unknown.)' 0 0 0);
			chrReversed=$("${cmd[@]}" "${options[@]}")
			chrReversed=$(echo ${chrReversed[@]});
			IFS=' ' read -r -a chrReversed <<< $chrReversed;

			# Ask if figures to be generated. (chromosome cartoons; repetititveness; GC-skew map)
			options=();
			options+=(1 "Chromosome cartoons" on);
			options+=(2 "Repetitiveness map" on);
			options+=(3 "GC-skew map" on);
			# --checklist text height width list-height [ tag item status ] ...
			cmd=(dialog --output-fd 1 --checklist 'Select reference genome figures to generate?\n    (These are separate from figures prepared from your data.)' 12 70 3);
			selectedFigures=$("${cmd[@]}" "${options[@]}")
			selectedFigures=$(echo ${selectedFigures[@]});
			IFS=' ' read -r -a selectedFigures <<< $selectedFigures;

			# Ask if further annotations will be defined for genome.
			options=();
			options+=('Annotations' "1" "1" "0" "1" "13" "6" "6");
			tempfile=$(mktemp --suffix ".ymap");
			# --form text height width formheight [ label y x item y x flen ilen ] ...
			(dialog --form 'Do you have any additional genome annotations?\n    (Leave as 0 if no/unknown.)' 10 50 2 ${options[@]}) 2> $tempfile;
			annotation_count=$(cat $tempfile);
			clear;

			## Annotation input user interface
			annotation_chr="";
			annotation_shape="";
			annotation_start="";
			annotation_end="";
			annotation_name="";
			annotation_fillColor="";
			annotation_edgeColor="";
			annotation_size="";
			if [[ "$annotation_count" -gt "0" ]]; then
				for ((i = 0 ; i < $annotation_count; i++)); do
					echo -e "#\tAnnotation $i";

					# dialog: select chr [chr_labels]
					#	--radiolist text height width list-height [ tag item status ] ...
					nameString="";
					counter=1;
					options=();
					for chr in ${selectedChrs[@]}; do
						name=${chrNames[$chr-1]}"("${chrLabels[$counter-1]}")";
						options+=($counter $name off);
						counter=$(($counter+1));
					done;
					cd $startingDirectory;
					cmd=(dialog --output-fd 1 --radiolist 'Annotation '$(($i+1))'\n    Choose which chromosome.' 0 0 0)
					choice=$("${cmd[@]}" "${options[@]}")
					selectedOption=${options[$(( (choice-1)*3+1 ))]}
					counter=1;
					for chr in ${chrNames[@]}; do
						name=${chrNames[$counter-1]}
						if [[ "$selectedOption" == *"$name"* ]]; then
							annotation_chr=$annotation_chr","$counter;
							break;
						fi
						counter=$(($counter+1));
					done;

					#echo "annotation_chr = "$annotation_chr;
					#read -p "Press any key to resume ..."

					## dialog: select type [dot, block].
					nameString="";
					options=();
					options+=(1 "dot" on);
					options+=(2 "block" off);
					cmd=(dialog --output-fd 1 --radiolist 'Annotation '$(($i+1))'\n    Choose which chromosome.' 0 0 0)
					choice=$("${cmd[@]}" "${options[@]}")
					selectedOption=${options[$(( (choice-1)*3+1 ))]}
					annotation_shape=$annotation_shape","$selectedOption;

					#echo "annotation_shape = "$annotation_shape;
					#read -p "Press any key to resume ..."

					# dialog: enter start bp.
					# dialog: enter end bp.
					# dialog: enter name.
					# dialog: enter size.
					options=();
					options+=("Starting_bp:" 1 1 0 1 23 5 0);
					options+=("Ending_bp:"   2 1 0 2 23 5 0);
					options+=("Name"         3 1 "name" 3 23 5 0);
					options+=("Size"         4 1 3 4 23 5 0);
					tempfile=$(mktemp --suffix ".ymap");
					(dialog --form "Annotation $(($i+1)) settings." 12 40 4 ${options[@]}) 2> $tempfile;
					results=$(cat $tempfile);
					results_=();
					for element in $results; do
						results_+=($element);
					done;
					startBp=$(echo ${results_[0]});
					endBp=$(echo ${results_[1]});
					name=$(echo ${results_[2]});
					size=$(echo ${results_[3]});
					annotation_start=$annotation_start","$startBp;
					annotation_end=$annotation_end","$endBp;
					annotation_name=$annotation_name","$name;
					annotation_size=$annotation_size","$size;

					#echo "annotation_start = "$annotation_start;
					#echo "annotation_end   = "$annotation_end;
					#echo "annotation_name  = "$annotation_name;
					#echo "annotation_size  = "$annotation_size;
					#read -p "Press any key to resume ..."

					# dialog: select fill color [black, yellow, magenta, cyan, red, green, blue white].
					options=();
					options+=(1 "black_(k)"   on);
					options+=(2 "yellow_(y)"  off);
					options+=(3 "magenta_(m)" off);
					options+=(4 "cyan_ (c)"   off);
					options+=(5 "red_(r)"     off);
					options+=(6 "green_(g)"   off);
					options+=(7 "blue_(b)"    off);
					options+=(8 "white_(w)"   off);
					cmd=(dialog --output-fd 1 --radiolist 'Annotation '$(($i+1))'\n    Choose fill color.' 0 0 0)
					choice=$("${cmd[@]}" "${options[@]}")
					selectedOption=${options[$(( (choice-1)*3 ))]}
					case $selectedOption in
					    1)	fillColor="k";  ;;
					    2)	fillColor="y";  ;;
					    3)  fillColor="m";  ;;
					    4)  fillColor="c";  ;;
					    5)  fillColor="r";  ;;
					    6)  fillColor="g";  ;;
					    7)  fillColor="b";  ;;
					    8)  fillColor="w";  ;;
					esac;
					annotation_fillColor=$annotation_fillColor","$fillColor;

					#echo "annotation_fillColor  = "$annotation_fillColor;
					#read -p "Press any key to resume ..."

					# dialog: select edge color [black, yellow, magenta, cyan, red, green, blue white].
					options=();
					options+=(1 "black_(k)"   on);
					options+=(2 "yellow_(y)"  off);
					options+=(3 "magenta_(m)" off);
					options+=(4 "cyan_ (c)"   off);
					options+=(5 "red_(r)"     off);
					options+=(6 "green_(g)"   off);
					options+=(7 "blue_(b)"    off);
					options+=(8 "white_(w)"   off);
					cmd=(dialog --output-fd 1 --radiolist 'Annotation '$(($i+1))'\n    Choose edge color.' 0 0 0)
					choice=$("${cmd[@]}" "${options[@]}")
					selectedOption=${options[$(( (choice-1)*3 ))]}
					case $selectedOption in
					    1)  edgeColor="k";  ;;
					    2)  edgeColor="y";  ;;
					    3)  edgeColor="m";  ;;
					    4)  edgeColor="c";  ;;
					    5)  edgeColor="r";  ;;
					    6)  edgeColor="g";  ;;
					    7)  edgeColor="b";  ;;
					    8)  edgeColor="w";  ;;
					esac;
					annotation_edgeColor=$annotation_edgeColor","$edgeColor;

					#echo "annotation_edgeColor  = "$annotation_edgeColor;
					#read -p "Press any key to resume ..."
				done;
				annotation_chr="${annotation_chr:1}";
				annotation_shape="${annotation_shape:1}";
				annotation_start="${annotation_start:1}";
				annotation_end="${annotation_end:1}";
				annotation_name="${annotation_name:1}";
				annotation_size="${annotation_size:1}";
				annotation_fillColor="${annotation_fillColor:1}";
				annotation_edgeColor="${annotation_edgeColor:1}";
			fi;

			## Rebuild user interface.
			clear;
			echo -e $lineThick;
			echo -e "# YMAP2 commandline : Install genome.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tInstalling a new genome.";
			echo -e "#\t\tAfter installing a *.FASTA to be processed, some information";
			echo -e "#\t\will be requested, and then the genome will be add to the";
			echo -e "#\t\tprocessing queue.";
			echo -e "#";
			echo -e "#\tEnter the path to your data files.";
			echo -e "#\t\t[path/]: "$selectedDirectory;
			echo -e "#";
			echo -e "#\tFASTA file selected:";
			echo -e "#\t\t"$selectedFile;
			echo -e "#\tGenome name: "$genome;
			echo -e "#";
			echo -e "#\tGenome ploidy: "$ploidy;
			echo -e "#";
			echo -e "#\tSelected chromosomes:";
			counter=1;
			for chr in ${selectedChrs[@]}; do
				echo -e -n '#\t\t';
				echo -e -n ${chrNames[$chr-1]};
				echo -e -n ' (';
				echo -e -n ${chrLabels[$chr-1]};
				echo -e -n ') ';
				counter=$(($counter+1));
				echo -e "";
			done;
			echo -e "#";
			echo -e "#\tGenome figures to generate:";
			if [[ "${selectedFigures[@]}" =~ "1" ]]; then
				echo -e "#\t\tChromosome cartoons.";
			fi;
			if [[ "${selectedFigures[@]}" =~ "2" ]]; then
				echo -e "#\t\tRepetitiveness map.";
			fi;
			if [[ "${selectedFigures[@]}" =~ "3" ]]; then
				echo -e "#\t\tGC-skew map.";
			fi;
			echo -e "#";


			##=========================================================
			##
			## Reformat data for input into pipeline components.
			##
			##---------------------------------------------------------
			rDNA_chr="";
			for chr in ${rdnaChromosomes[@]}; do
				rDNA_chr=$rDNA_chr","$chr;
			done;
			rDNA_chr="${rDNA_chr:1}"
			if [[ "$rDNA_chr" = "" ]]; then
				rDNA_chr="null";
			fi;
			if [[ "$rDNA_chr" != "null" ]]; then
				rDNA_start="";
				rDNA_end="";
				counter=1;
				for coord in ${rdnaCoords[@]}; do
					if [[ ! "((counter % 2))" -eq "0" ]]; then
						rDNA_start=$rDNA_start","$coord;
					else
						rDNA_end=$rDNA_end","$coord;
					fi;
					counter=$(($counter+1));
				done;
				rDNA_start="${rDNA_start:1}"
				rDNA_end="${rDNA_end:1}"
			else
				rDNA_start="null";
				rDNA_end="null";
			fi;
			chr_count=${#chrNames[@]};
			ploidy_default=$ploidy;
			expression_regions="null";
			counter=1;
			chr_draw="";
			chr_order="";
			chr_reversed="";
			chr_labels="";
			cen_start="";
			cen_end="";
			function get_index() {
				local array=$1;
				local value=$2;
				for i in "${!array[@]}"; do
					if [[ "${array[$i]}" = "$value" ]]; then
						echo "${i}";
					fi
				done
			}
			for chrName in "${chrNames[@]}"; do
				if [[ "${selectedChrs[@]}" =~ "$counter" ]]; then
					for i in "${!selectedChrs[@]}"; do
						if [[ "${selectedChrs[$i]}" = "$counter" ]]; then
							counterKey="$((${i}+1))";
						fi
					done;
					chr_draw=$chr_draw",1";
					chr_order=$chr_order","${chrOrder[$counterKey-1]};
					chr_labels=$chr_labels","${chrLabels[$counterKey-1]};
					cen_start=$cen_start","${cenStarts[$counterKey-1]}
					cen_end=$cen_end","${cenEnds[$counterKey-1]}
					if [[ "${chrReversed[@]}" =~ "${chrOrder[$counterKey-1]}" ]]; then
						chr_reversed=$chr_reversed",1";
					else
						chr_reversed=$chr_reversed",0";
					fi;
				else
					chr_draw=$chr_draw",0";
					chr_order=$chr_order",0";
					chr_labels=$chr_labels",null";
					cen_start=$cen_start",0";
					cen_end=$cen_end",0";
					chr_reversed=$chr_reversed",0"
				fi;
				counter=$(($counter+1));
			done;
			chr_draw="${chr_draw:1}";
			chr_order="${chr_order:1}";
			chr_reversed="${chr_reversed:1}";
			chr_labels="${chr_labels:1}";
			cen_start="${cen_start:1}";
			cen_end="${cen_end:1}";
			if [[ "${selectedFigures[@]}" =~ "1" ]]; then
				fig1_bool="true";
			else
				fig1_bool="false";
			fi;
			if [[ "${selectedFigures[@]}" =~ "2" ]]; then
				fig2_bool="true";
			else
				fig2_bool="false";
			fi;
			if [[ "${selectedFigures[@]}" =~ "3" ]]; then
				fig3_bool="true";
			else
				fig3_bool="false";
			fi;

			echo -e "#\tAdditional information:";
			echo -e "#";
			echo -e "#\t\tchr count               = "$chr_count;
			echo -e "#\t\tchr drawn               = "$chr_draw" (1=drawn, 0=not drawn)";
			echo -e "#\t\tchr labels              = "$chr_labels" (null=unused)";
			echo -e "#\t\tcen starts              = "$cen_start" (bp coordinates)";
			echo -e "#\t\tcen ends                = "$cen_end" (bp coordinates)";
			echo -e "#\t\tchr order               = "$chr_order" (0=unused)";
			echo -e "#\t\tchr reversed            = "$chr_reversed" (1=reversed, 0=normal/unused)";
			echo -e "#\t\trDNA chr(s)             = "$rDNA_chr;
			echo -e "#\t\trDNA start(s)           = "$rDNA_start;
			echo -e "#\t\trDNA end(s)             = "$rDNA_end;
			echo -e "#\t\tannotation_chr(s)       = "$annotation_chr;
			echo -e "#\t\tannotation_shape(s)     = "$annotation_shape;
			echo -e "#\t\tannotation_start(s)     = "$annotation_start;
			echo -e "#\t\tannotation_end(s)       = "$annotation_end;
			echo -e "#\t\tannotation_name(s)      = "$annotation_name;
			echo -e "#\t\tannotation_fillColor(s) = "$annotation_fillColor;
			echo -e "#\t\tannotation_edgeColor(s) = "$annotation_edgeColor;
			echo -e "#\t\tannotation_size(s)      = "$annotation_size;

			##=========================================================
			## Generates settings files in genome directory.
			##---------------------------------------------------------
			cd $main_dir"/scripts_genomes";
			php genome.install_2.php $user $genome $chr_count $rDNA_start $rDNA_end $ploidy_default $annotation_count $expression_regions $chr_draw $chr_labels $cen_start $cen_end $chr_order $chr_reversed $fig1_bool $fig2_bool $fig3_bool 2> $main_dir/users/$user/genomes/$genome/process_log.txt;
			cd $main_dir;
			##=========================================================


			##=========================================================
			## Generates annotations file in genome directory; initiates queue entry.
			##---------------------------------------------------------
			cd $main_dir"/scripts_genomes";
			php genome.install_3.php $user $genome $rDNA_chr $rDNA_start $rDNA_end $annotation_count $annotation_chr $annotation_shape $annotation_start $annotation_end $annotation_name $annotation_fillColor $annotation_edgeColor $annotation_size 2> $main_dir/users/$user/genomes/$genome/process_log.txt;
			cd $main_dir;
			##=========================================================


			##=========================================================
			## Information about genome processing scripts not called directly.
			##---------------------------------------------------------
			## php genome.install_4.php			# For dealing with expression_region annotations; not used.
			## php genome.install_5.php $user $genome	# final pre-processing; this is where ymap_daemon starts.
			## bash genome.install_6.sh $user $genome	# final figure generating and related pre-processing.
			##=========================================================
			echo -e "#";
			echo -e "#\t\e[42mGenome has been added to the processing queue.\e[0m";
		    ;;
		    "user")
			echo -e "#\tInstalling a new user is not yet implemented.";
		    ;;
		    "*")
			echo -e "#\t\e[41mInvalid selection: Code error.\e[0m";
			echo -e $lineThick;
			return 1;
		    ;;
		esac;
	}
	ymap_display_daemon() {
		tempfile=$(mktemp --suffix ".ymap");
		if [[ "$1" = "status" ]]; then
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
			}' $tempfile | sed 's/^/#\t/';
		elif [[ "$1" = "log" ]]; then
			journalctl -u ymap_daemon.service | tail -n 40 > $tempfile;

			# No complicated graphics to show.
			cat $tempfile | sed 's/^/#\t/';
		fi;
	}

	##
	## Main part of commandline interface code.
	##

	echo -e $lineThick;
	noTail=false;
	case $1 in
	    "install_YMAP")
		if [[ !  -e "/etc/init.d/ymap_daemon" ]]; then
			##
			## YMAP daemon installation.
			##

			## Copy 'ymap_daemon_template.sh' to /etc/init.d/ymap_daemon
			TargetFile="/etc/init.d/ymap_daemon";
			sudo cp ymap_daemon_template.sh $TargetFile;

			## Update file setting.
			sudo sed -i "/DAEMON_OPTS_temp/c\\\DAEMON_OPTS=\"$main_dir/ymap_daemon.php\";" $TargetFile;

			## Make it executable.
			sudo chmod +x $TargetFile;

			# To reload services.
			sudo systemctl daemon-reload;

			# Enable service to start at boot.
			sudo systemctl enable ymap_daemon;

			# Enable start at crash.
			echo -e "#";
			echo -e "#	To ensure the ymap_daemon restarts after a crash, manual stesp are needed.";
			echo -e "#		(https://www.tecmint.com/automatically-restart-service-linux/)";
			echo -e "#";
			echo -e "#	1) sudo systemctl edit ymap_daemon.service";
			echo -e "#";
			echo -e "#	2) Add these lines after third line.";
			echo -e "#		[Service]";
			echo -e "#		Restart=always";
			echo -e "#		RestartSec=5s";
			echo -e "#";
			echo -e "#	3) sudo systemctl daemon-reload";
			echo -e "#";
			echo -e "#	4) sudo systemctl restart ymap_daemon";
			echo -e "#";
			echo -e "#	To confirm status:";
			echo -e "#		sudo systemctl show ymap_daemon | grep Restart";
			echo -e "#	Should look like:";
			echo -e "#		Restart=always";
			echo -e "#		RestartUSec=5s";
			echo -e "#		NRestarts=0";
			echo -e "#		RestartKillSignal=15"
			echo -e "#";
			echo -e $lineThin;



			##
			## Localize settings files.
			##

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
			sudo sed -i "/BASE_DIR_temp/c\\\base_dir=\"$main_dir\";" $TargetFile3;

			echo -e "#";
			echo -e "#\tSettings files localized.";
		fi;
	    ;;
	    "log_in")
		echo -e "# YMAP2 commandline :";
		echo -e $lineThin;
		echo -e "#";
		if [ -z $2 ]; then
			echo -e "#\tUsage: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
				echo $2 > $main_dir"/YMAPcli.dat";
			fi;
		fi;
	    ;;
	    "log_out")
		echo -e "# YMAP2 commandline :";
		echo -e $lineThin
		echo -e "#";
		if [[ ! "$user" = "" ]]; then
			echo "" > $main_dir"/YMAPcli.dat";
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
				echo -e "#\tUsage: bash YMAPcli.sh user \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
		ymap_display_daemon status;
	    ;;
	    "daemon_log")
		echo -e "# YMAP2 commandline : ymap_daemon service event log.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		ymap_display_daemon log;
	    ;;
	    "status")
		echo -e "# YMAP2 commandline : Status of projects/genomes in queue.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		php queue_status.php
	    ;;
	    "status_daemon")
		bash YMAPcli.sh status;
		bash YMAPcli.sh daemon;
		noTail=true;
	    ;;
	    "genomes")
		echo -e "# YMAP2 commandline : List user genomes.";
		logged_in_status;
		echo -e $lineThin;
		echo -e "#";
		if [ "$user" == "" ]; then
			## If not logged in, allow user passed as argument.
			if [ -z $2 ]; then
				echo -e "#\tUsage: bash YMAPcli.sh genomes \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
				echo -e "#\tUsage: bash YMAPcli.sh hapmaps \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
				echo -e "#\tUsage: bash YMAPcli.sh complete \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
				cd $main_dir;
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
			echo -e "#\tUsage: bash YMAPcli.sh queue_limit \e[31m(value)\e[0m";
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
			echo -e "#\tUsage: bash YMAPcli.sh data_limit \e[31m(value)\e[0m";
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
			echo -e "#\tUsage: bash YMAPcli.sh admin_email \e[31m(address)\e[0m";
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
			echo -e "#\tUsage: bash YMAPcli.sh quota \e[31m(value)\e[0m";
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
					echo -e "#\tUsage: bash YMAPcli.sh delete project \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "genome")
					echo -e "#\tUsage: bash YMAPcli.sh delete genome \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "hapmap")
					echo -e "#\tUsage: bash YMAPcli.sh delete hapmap \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "user")
					fail=0;
				    ;;
				    *)
					echo -e "#\tUsage: bash YMAPcli.sh delete project \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcli.sh delete genome \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcli.sh delete hapmap \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcli.sh delete user";
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
				echo -e "#\tUsage: bash YMAPcli.sh delete project \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh delete genome \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh delete hapmap \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh delete user";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
				echo -e "#\tUsage: bash YMAPcli.sh delete project";
				echo -e "#\tUsage: bash YMAPcli.sh delete genome";
				echo -e "#\tUsage: bash YMAPcli.sh delete hapmap";
				echo -e "#\tUsage: bash YMAPcli.sh delete user";
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
				echo -e "#\tUsage: bash YMAPcli.sh install project \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh install genome \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh install hapmap \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh install user";
				echo -e "#";
				echo -e "#\t\t\e[41mError: Wrong 2nd arguement!\e[0m";
			    ;;
			esac;
		fi;
	    ;;
	    "preview")
		# if "tiv" installed, show graphics.
		if [[ -x "$(command -v tiv)" ]]; then
			echo -e "# YMAP2 commandline : Preview figure.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			if [ "$user" == "" ]; then
				## If not logged in, allow user passed as argument.
				if [ -z $2 ]; then
					echo -e "#\tUsage: bash YMAPcli.sh preview \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
				else
					user=$2;
				fi;
			fi;
			if [ "$user" != "" ]; then
				## Validate user account.
				if [[ -e "$main_dir/users/$user" ]]; then
					## Ask which project.
					projectDir="$main_dir/users/$user/projects/";
					nameString=""
					maxNameLength=0;
					counter=1;
					projects=();
					cd $projectDir;
					if [ "$(find . -maxdepth 1 -type d | wc -l)" -gt 1 ]; then
						for dir in */; do
							name=$( echo ${dir::-1} );
							if [[ ${#String} -gt "$maxNameLength" ]]; then
								maxNameLength=${#name};
							fi;
							if [[ -e "$projectDir$name/complete.txt" ]]; then
								projects+=($name);
								nameString=$nameString" "$counter" "$name;
								counter=$(($counter+1));
							fi;
						done;
					else
						nameString="";
					fi;
					cd $main_dir;
					if [[ "$counter" -eq 1 ]]; then
						echo -e "#\tNo projects are complete for user '$user'.";
					else
						tempfile=$(mktemp --suffix ".ymap");
						(dialog --nocancel --menu "Select project to examine." 25 $maxNameLength 25 $nameString) 2> $tempfile
						selectedKey=$(head -n 1 $tempfile);
						project=${projects[$selectedKey-1]};

						## Ask which figure.
						projectDirectory="$main_dir/users/$user/projects/$project/";
						nameString=""
						maxNameLength=0;
						counter=1;
						for path in "$projectDirectory"*.png; do
							name=${path##*/}
							if [[ ${#String} -gt "$maxNameLength" ]]; then
								maxNameLength=${#name};
							fi;
							images+=($name);
							nameString=$nameString" "$counter" "$name;
							counter=$(($counter+1));
						done;
						tempfile=$(mktemp --suffix ".ymap");
						(dialog --nocancel --menu "Select project to examine." 25 $maxNameLength 25 $nameString) 2> $tempfile
						selectedKey=$(head -n 1 $tempfile);
						imageFile=${images[$selectedKey-1]};

 						## Display figure.
						clear;
						echo -e $lineThick;
						echo -e "# YMAP2 commandline : Show graphics.";
						logged_in_status;
						echo -e $lineThin;
						echo -e "#";
						tiv "$projectDirectory$imageFile";
					fi;
				else
					echo -e "#\tUser '$user' doesn't seem to exist.";
				fi;
			fi;
		else
			echo -e "# YMAP2 commandline : Show graphics.";
			logged_in_status;
			echo -e $lineThin;
			echo -e "#";
			echo -e "#\tCommandline tool 'tiv' is not installed, so no graphical output is not enabled.";
			echo -e "#";
			echo -e "#\ttiv can be installed from 'https://github.com/stefanhaustein/TerminalImageViewer'.";
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
					echo -e "#\tUsage: bash YMAPcli.sh install project \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "genome")
					echo -e "#\tUsage: bash YMAPcli.sh install genome \e[31m(user)\e[0m";
					echo -e "#";
					echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
					fail=1;
				    ;;
				    "user")
					fail=0;
				    ;;
				    *)
					echo -e "#\tUsage: bash YMAPcli.sh install project \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcli.sh install genome \e[31m(user)\e[0m";
					echo -e "#\tUsage: bash YMAPcli.sh install user";
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
				echo -e "#\tUsage: bash YMAPcli.sh install project \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh install genome \e[31m(user)\e[0m";
				echo -e "#\tUsage: bash YMAPcli.sh install user";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
				echo -e "#\tUsage: bash YMAPcli.sh install project";
				echo -e "#\tUsage: bash YMAPcli.sh install genome";
				echo -e "#\tUsage: bash YMAPcli.sh install user";
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
				echo -e "#\tUsage: bash YMAPcli.sh run \e[31m(user)\e[0m";
				echo -e "#";
				echo -e "#\tOr first log in using the command: bash YMAPcli.sh log_in \e[31m(user)\e[0m";
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
			cd $main_dir"/users/"$user"/bulksettings/";
			rm *.txt;
			cd $main_dir;

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
			cd $main_dir;
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
			cd $main_dir;
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
			if ! [[ "$ploidy" =~ ^[0-9]\.[0-9]$ ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid ploidy value:";
				echo -e "#\t\tUse something like '1.0', '2.4', etc.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			elif ! [[ "$ploidyBase" =~ ^[0-9]\.[0-9]$ ]]; then
				echo -e "#";
				echo -e "#\tThat is not a valid baseline ploidy value:";
				echo -e "#\t\tUse something like '1.0', '2.0', etc.";
				echo -e "#";
				echo -e $lineThick;
				exit;
			fi;

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
			cd $main_dir;
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
			cd $main_dir;
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
		echo -e "#"
		echo -e "#\t'$1' is not a defined command in the YMAP commandline interface."
		echo -e "#"
		echo -e "#\tRun 'bash YMAPcli.sh' to see available commands."
	    ;;
	esac;
	if [[ "$noTail" = "false" ]]; then
		echo -e "#";
		echo -e $lineThick
	fi;
fi;


