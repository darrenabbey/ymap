#!/bin/bash
set -e

#============================================================================
# User installed executables not in PATH variable.
#----------------------------------------------------------------------------
# Location where bioinformatics tools are installed:
userProgramsLocation="";

# Dependency executable directories:
bowtie2Directory=$userProgramsLocation"bowtie2-2.1.0/";

# Dependency executables:
octave_exec=$userProgramsLocation"octave -qf --no-gui";

# the wigToBigWig executable:
wigToBigWig_exec=$userProgramsLocation"wigToBigWig";



#============================================================================
# System installed executables or name in PATH variable.
#----------------------------------------------------------------------------
samtools_exec="samtools";

# Can be used to run PyPy (or any other Python implementation) instead of
# CPython for sripts that support it (for example, scripts may require numpy,
# which PyPy doesn't necessarily have):
python_exec="python3";

# Python 3 executable that also has numpy installed. If not available, set to same as python_exec.
python_numpy_exec="python3";
