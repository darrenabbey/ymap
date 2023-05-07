<?php
	session_start();
	error_reporting(E_ALL);
        require_once 'constants.php';
	require_once 'POST_validation.php';
        ini_set('display_errors', 1);

        // If the user is not logged on, redirect to login page.
        if(!isset($_SESSION['logged_on'])){
		session_destroy();
                header('Location: .');
        }

	// Ensure admin user is logged in.
	$user = $_SESSION['user'];
	$super_user_flag_file = "users/".$user."/super.txt";
	if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
		$admin_logged_in = "true";
	} else {
		$admin_logged_in = "false";
		session_destroy();
		log_stuff("",$user,"","","","","CREDENTIAL fail: user attempted to use admin function to copy genome to default!");
		header('Location: .');
	}

	// Load user string from session.
	$user     = $_SESSION['user'];
	$user_key = sanitizeInt_POST('key');

	// Determine user account associated with key.
	$genomeDir      = "users/".$_SESSION['user']."/genomes/";
	$genomeFolders  = array_diff(glob($genomeDir."*\/"), array('..', '.'));

	// Sort directories by date, newest first.
	array_multisort($genomeFolders, SORT_ASC, $genomeFolders);

	// Trim path from each folder string.
	foreach($genomeFolders as $key=>$folder) {
		$genomeFolders[$key] = str_replace($genomeDir,"",$folder);
	}
	$genome_to_copy = $genomeFolders[$user_key];

	$src  = $genomeDir.$genome_to_copy;
	$dest = "users/default/genomes/".$genome_to_copy;

	// Copy from source genome directory to destination genome directory.
	if (!file_exists($dest)) {
		mkdir($dest, 0777, true);
		foreach (scandir($src) as $file) {
			if (!is_readable($src . '/' . $file)) continue;
                        copy($src . '/' . $file, $dest . '/' . $file);
		}
	}
?>
