#!/bin/bash
set -e

#----------------------------------------------------------------------------------------------
# Generate reverse-complement versions of the sequence input.
#----------------------------------------------------------------------------------------------
echo $1 | tr "[ATGCYRSWKMBVDHNatgcyrswkmbvdhnEeFfIiJjLlOoPpQqXxZz]" "[TACGRYSWMKVBHDNtacgryswmkvbhdn********************]" | rev
