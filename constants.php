<?php
	// Pipeline componant location constants.
	$users_dir    = "users/";
	$hapmapGenome = "C_albicans_SC5314_version_A21-s02-m03-r03";

	// User interface details.
	$ui_tabArea_height = "275px";
	$ui_tab_height     = "40px";
	$ui_tab_width      = "80px";
	$ui_iframe_height  = "255px";  // $ui_tabArea_height - $ui_tab_height.

	// uncertain.
	$directory = ".";

	// hardcoded quota (used in case no globalquota.txt in users folder or no quota.txt exits in user folder)
	$quota = 10;

	// The following constants stem from the fact that Ymap display up to 50 chromosomes and that php supports up to around 1000 variables that can be passed
	// between forms and in $_SESSION variables which limits the genome form to up to 300 entries
	$MAX_CHROM_SELECTION = 50;  // the maximum number of chromosomes that can be chosen for drawing
	$MAX_CHROM_POOL      = 300; // the maximum number of chromosomes that will be displayed to the user to choose from the 50 to draw

	// Pepper string for password security.
	include(".pepper.php");
?>
