#!/bin/bash
set -e

#============================================================================
# User installed executables not in PATH variable.
#----------------------------------------------------------------------------

# bowtie2 executable directories (if not installed to path):
bowtie2Directory="";


#============================================================================
# System installed executables or name in PATH variable.
#----------------------------------------------------------------------------
wigToBigWig_exec="wigToBigWig";
octave_exec="octave -qf --no-gui";
samtools_exec="samtools";

# Can be used to run PyPy (or any other Python implementation) instead of
# CPython for sripts that support it (for example, scripts may require numpy,
# which PyPy doesn't necessarily have):
python_exec="python3";

# Python 3 executable that also has numpy installed. If not available, set to same as python_exec.
python_numpy_exec="python3";
