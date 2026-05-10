#!/bin/bash
set -e;

### define script file locations.
user=$1;
main_dir=$(pwd);

projectDirectory=$main_dir"/users/"$user"/projects/";

cd $projectDirectory;
tail -n 1 */condensed_log.txt | cat
cd ../../../
