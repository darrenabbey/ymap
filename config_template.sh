#!/bin/bash
set -e

#=============================================================
# Adjust number of cores to your server environment.
#	Fewer cores will lead to less memory utilization.
#	Fewer cores will lead to longer processing times.
#
# After making adjustments, save this file to: "config.sh"
#-------------------------------------------------------------

# How many cores is Ymap allowed to use (relevant to 3-rd party tools):
cores=6

# If debug mode is turned on, intermediate files in analysis will be kept:
debug=0
