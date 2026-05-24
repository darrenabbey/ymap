<?php
// Pipeline componant locations.
$base_dir	= "/var/www/html/ymap";
$users_dir	= $base_dir."/users/";

// User interface details.
$ui_tabArea_height = "275px";
$ui_tab_height     = "40px";
$ui_tab_width      = "80px";
$ui_iframe_height  = "255px";  // $ui_tabArea_height - $ui_tab_height.

// Quota for all accounts where no quota.txt exits in user folder.
$quota_global = 15;

// The maximum number of chromosomes that can be chosen for drawing
$MAX_CHROM_SELECTION = 50;

// Pepper string for password security.
include(".pepper.php");


//==============================================================================
// The following settings can be adjusted using the YMAP command line interface.
//------------------------------------------------------------------------------

// Admin contact email address.
$admin_email = "darrenabbey.ymap@gmail.com";

// The maximum number of chromosomes that will be displayed to the user to choose from the 50 to draw.
// Too high a maximum leads to scripts_genomes/genome.install_2.php failing to run when a reference with many contigs is loaded.
$MAX_CHROM_POOL = 200;

// The maximum number of datasets to be analyzed in parallel by the processing queue.
$MAX_QUEUE_PARALLEL = 1;

// The maximum size of a dataset to be anaalyzed. Larger datasets will be subsampled down to this level.
$MAX_READ_COUNT_PER_PROJECT = 100000;
?>
