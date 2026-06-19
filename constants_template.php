<?php
//==============================================================================
// The following settings may need to be updated at the time of YMAP installation.
//
// After adjusting, save this file to "constants.php" for use.
//------------------------------------------------------------------------------

BASE_DIR_temp

// Pepper string for password security; so long as this file name starts with a ".", git will ignore it.
include(".pepper.php");


//==============================================================================
// The following settings can be adjusted using the YMAP command line interface (YMAPcl.sh).
//------------------------------------------------------------------------------

// Quota (in Gb) for all accounts where no quota.txt exits in user folder.
$QUOTA_GLOBAL = 5;

// Admin contact email address.
$ADMIN_EMAIL = "admin@email.address";

// The maximum memory utilization has been found to be very predictable from the input size of the sequence reads file:
//	x = Gb of *.fastq data; f(x) = Gb memory utilized.
//	f(x) = 2.59507052086734x - 1.13116709532669   (R²= 0.984272095936311)
//
// Limiting the data size here can be used to keep the memory utilization within expected bounds.
// A zero value here means the check is not performed.
// A non-zero value here is interpreted in Gb; any larger datafiles will be subsampled down to this size before processing.
$MAX_FASTQ_TARGET = 1.7;

// The maximum number of datasets to be analyzed in parallel by the processing queue.
// More than one can be processed at once, but the memory utilization becomes less predictable so should not be done on memory limited servers without testing.
$MAX_QUEUE_PARALLEL = 1;

// The time estimate for completing a dataset (in minutes), used in calculating expected time for queue completion in user interface.
// This will need to be empirically determined for each new install.
$QUEUE_TIME_ESTIMATE = 40;

// On space-liminted systems, this option tells YMAP to automatically minimize each project when complete.
$MINIMIZE_WHEN_DONE = True;

//==============================================================================
// The following settings should never need to be updated.
//------------------------------------------------------------------------------

// User interface details.
$ui_tabArea_height = "275px";
$ui_tab_height     = "40px";
$ui_tab_width      = "80px";
$ui_iframe_height  = "255px";  // $ui_tabArea_height - $ui_tab_height.

// The maximum number of chromosomes that can be chosen for drawing
$MAX_CHROM_SELECTION = 50;

// The maximum number of chromosomes that will be displayed to the user to choose from the 50 to draw.
// Too high a maximum leads to scripts_genomes/genome.install_2.php failing to run when a reference with many contigs is loaded.
$MAX_CHROM_POOL = 200;

// Pipeline componant locations; users_dir variable is not consistently used across YMAP code, so don't change.
$users_dir = $base_dir."users/";
?>
