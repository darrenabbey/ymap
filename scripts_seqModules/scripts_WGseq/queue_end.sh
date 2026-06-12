#!/bin/bash
set -e

user="$1";
project="$2";
genome="";
hapmap="";
main_dir="$3";
logName="$4";
message="$5";

Directory="$main_dir/users/$user/projects/$project";

##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
echo -e "\tEnding queue processing." >> $logName;
outputName="$Directory/finalize.php";
echo -e "<?php" > $outputName;
echo -e "chdir('$main_dir');" >> $outputName;
echo -e "require_once 'constants.php';" >> $outputName;
echo -e "require_once 'sharedFunctions.php';" >> $outputName;
echo -e "queue_end('$user','$project','','','$message');" >> $outputName;
echo -e "\$salt_string = get_salt('$user','$project','$genome','$hapmap');" >> $outputName;
echo -e "log_stuff('$user','$project','','',\$salt_string,'YMAP_daemon: $message');" >> $outputName;
echo -e "SYSTEM_force_minimize('$user','$project');" >> $outputName;
echo -e "?>" >> $outputName;
php $outputName;
rm $outputName;
echo -e "\tConclusion of processing data: $message" >> $logName;
