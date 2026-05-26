<?php
//==============================================================================
// The following settings will need to be updated at the time of YMAP installation.
//
// After adjusting, save this file to "constants.php" for use.
//------------------------------------------------------------------------------

// Pipeline componant locations; users_dir variable is not consistently used across YMAP code, so don't change.
$base_dir	= "/var/www/html/ymap";
$users_dir	= $base_dir."/users/";

// Pepper string for password security; so long as this file name starts with a ".", git will ignore it.
include(".pepper.php");


//==============================================================================
// The following settings can be adjusted using the YMAP command line interface.
//------------------------------------------------------------------------------

// Quota (in Gb) for all accounts where no quota.txt exits in user folder.
$quota_global = 15;

// Admin contact email address.
$admin_email = "darrenabbey.ymap@gmail.com";

// The maximum memory utilization has been found to be very predictable from the input size of the sequence reads file:
//	f(x) = 14.07587815x - 1.123882666   (R²= 0.984638424)
//
// Limiting the data size here can be used to keep the memory utilization within expected bounds.
// A zero value here means the check is not performed.
// A non-zero value here is interpreted in Gb; any larger datafiles will be subsampled down to this size before processing.
$MAX_PROCESSED_DATA = o;

// The maximum number of datasets to be analyzed in parallel by the processing queue.
// More than one can be processed at once, but the memory utilization becomes less predictable so should not be done on memory limited servers.
$MAX_QUEUE_PARALLEL = 1;

// The maximum size of a dataset to be anaalyzed. Larger datasets will be subsampled down to this level.
$MAX_READ_COUNT_PER_PROJECT = 100000;


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
?>
