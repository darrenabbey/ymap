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
		$admin_user_flag_file = "users/".$user."/admin.txt";
		if (file_exists($admin_user_flag_file)) {  // Admin-user privilidges.
			$admin_logged_in = "true";
		} else {
			// not an admin account, redirect to login page.
			$admin_logged_in = "false";
			session_destroy();
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to delete genome!");
			header('Location: .');
		}

		// Load user string from session.
		$genome_key = sanitizeInt_POST('key');

		// Determine genome associated with key.
		$genomeDir      = "users/default/genomes/";
		$genomeFolders  = glob($genomeDir."*\/");

		// Sort directories by date, newest first.
		array_multisort($genomeFolders, SORT_ASC, $genomeFolders);

		// Trim path from each folder string.
		foreach($genomeFolders as $key=>$folder) { $genomeFolders[$key] = str_replace($genomeDir,"",$folder); }
		$genome_target = $genomeFolders[$genome_key];

		// Confirm if requested genome exists.
		$dir     = "users/default/genomes/".$genome_target;
		if (is_dir($dir)) {
			// Requested genome does exist: Delete genome.
			rrmdir($dir);
			echo "COMPLETE\n";
			log_stuff($user,$genome_target,"","","","ADMIN genome:DELETE success.");
		} else {
			// genome doesn't exist, should never happen.
			echo "ERROR:".$genome_target." doesn't exist.";
			log_stuff($user,$genome_target,"","","","ADMIN genome:DELETE FAIL: can't delete default user genome that doesn't exist.");
		}
	}

	//==========================
	// recursive rmdir function.
	//--------------------------
	// Function for recursive rmdir, to clean out full genome directory.
	function rrmdir($dir) {
		if (is_dir($dir)) {
			$objects = scandir($dir);
			foreach ($objects as $object) {
				if ($object != "." && $object != "..") {
					if (filetype($dir."/".$object) == "dir") rrmdir($dir."/".$object); else unlink($dir."/".$object);
				}
			}
			reset($objects);
			rmdir($dir);
		}
	}
?>
