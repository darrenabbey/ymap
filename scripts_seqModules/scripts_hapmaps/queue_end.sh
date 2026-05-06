user=$1;
hapmap=$2;
main_dir=$3;
logName=$4;
message=$5;

projectDirectory=$main_dir"users/"$user"/hapmaps/"$hapmap"/";

##==============================================================================
## Add project end to queue log file.
##------------------------------------------------------------------------------
echo "\tEnding queue processing." >> $logName;
outputName=$projectDirectory"finalize.php";
echo "<?php" > $outputName;
echo "chdir('"$main_dir"');" >> $outputName;
echo "require_once 'constants.php';" >> $outputName;
echo "require_once 'sharedFunctions.php';" >> $outputName;
echo "queue_end('"$user"','','','"$hapmap"','"$message"');" >> $outputName;
echo "?>" >> $outputName;
php $outputName;
rm $outputName;
