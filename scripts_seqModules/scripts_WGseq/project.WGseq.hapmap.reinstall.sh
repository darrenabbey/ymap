#!/bin/bash -e
#
# project.WGseq.hapmap.install_4.sh
#
user="darren1";
project="12353_WGseq_hapmap";
hapmap="test";

main_dir=$(pwd)"/../../";
local_dir=$(pwd);
projectDirectory=$main_dir"users/"$user"/projects/"$project"/";
logName=$projectDirectory"process_log.txt";
condensedLog=$projectDirectory"condensed_log.txt";


chmod 774 $projectDirectory*;
sh project.WGseq.hapmap.install_4.sh $user $project $hapmap;
