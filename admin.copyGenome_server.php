<?php
	session_start();
	error_reporting(E_ALL);
        require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
        ini_set('display_errors', 1);

        // If the user is not logged on, redirect to login page.
        if(!isset($_SESSION['logged_on'])) {
		session_destroy();
                header('Location: .');
        }

	// Ensure admin user is logged in.
	if(isset($_SESSION['user'])) {
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		$super_user_flag_file = "users/".$user."/super.txt";
		if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
			$admin_logged_in = "true";
		} else {
			// not an admin account, redirect to login page.
			$admin_logged_in = "false";
			session_destroy();
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to copy genome to default!");
			header('Location: .');
		}

		// Load user string from session.
		$user_key = sanitizeInt_POST('key');

		// Determine user account associated with key.
		$genomeDir      = "users/".$user."/genomes/";
		$genomeFolders  = array_diff(glob($genomeDir."*\/"), array('..', '.', 'users/default/'));

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
		if (file_exists($dest)) {
			log_stuff($user,"","",$genome_to_copy,"","ADMIN fail: attempted to copy genome to default user, but genome name is already in use.");
		} else {
			log_stuff($user,"","",$genome_to_copy,"","ADMIN success: copied genome to default user.");
			mkdir($dest, 0773, true);
			foreach (scandir($src) as $file) {
				if (!is_readable($src . '/' . $file)) continue;
	                        copy($src . '/' . $file, $dest . '/' . $file);
			}
		}
	}
?>
