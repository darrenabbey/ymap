user=$1;
hapmap=$2;
main_dir=$3;
logName=$4;
message=$5;

projectDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";

##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
echo -e "\tEnding queue processing." >> $logName;
outputName=$projectDirectory"finalize.php";
echo -e "<?php" > $outputName;
echo -e "chdir('"$main_dir"');" >> $outputName;
echo -e "require_once 'constants.php';" >> $outputName;
echo -e "require_once 'sharedFunctions.php';" >> $outputName;
echo -e "queue_end('"$user"','','','"$hapmap"','"$message"');" >> $outputName;
echo -e "?>" >> $outputName;
php $outputName;
rm $outputName;
