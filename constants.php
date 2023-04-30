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
	$quota = 25;

	// The following constants stem from the fact that Ymap display up to 50 chromosomes and that php supports up to around 1000 variables that can be passed
	// between forms and in $_SESSION variables which limits the genome form to up to 300 entries
	$MAX_CHROM_SELECTION = 50;  // the maximum number of chromosomes that can be chosen for drawing
	$MAX_CHROM_POOL      = 300; // the maximum number of chromosomes that will be displayed to the user to choose from the 50 to draw

	// Pepper string for password security.
	include(".pepper.php");

	// YMAP logging function.
	function log_stuff($user,$project,$hapmap,$genome,$filename,$message) {
		// define log file.
		$log_file = "logs/activity.log";

		// check if log file exists, create if not.
		if (!file_exists($log_file)) {
			$myfile = fopen($log_file, "w");
			fwrite($myfile, "Initiate log file: ".date('Y-m-d H:i:s')."\n");
			fclose($myfile);
		}

		// add comment to log file.
		$line = date('Y-m-d H:i:s').' - '.session_id();
		if (!empty($user)) {		$line = $line.' - u:'.$user;		}
		if (!empty($project)) {		$line = $line.' - p:'.$project;		}
		if (!empty($hapmap)) {		$line = $line.' - h:'.$hapmap;		}
		if (!empty($genome)) {		$line = $line.' - g:'.$genome;		}
		if (!empty($filename)) {	$line = $line.' - '.$filename;		}
		if (!empty($message)) {		$line = $line.' - "'.$message.'"';	}
		file_put_contents($log_file, $line . PHP_EOL, FILE_APPEND);
	}
?>
