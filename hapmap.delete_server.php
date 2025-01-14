<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	ini_set('display_errors', 1);

        // If the user is not logged on, redirect to login page.
        if(!isset($_SESSION['logged_on'])){
		session_destroy();
                header('Location: .');
        }

	// Load user string from session.
	if(isset($_SESSION['user'])) {
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// Sanitize input string.
		$hapmap  = sanitize_POST("hapmap");
		$dir     = "users/".$user."/hapmaps/".$hapmap;

		// Confirm if requested project exists.
		if (is_dir($dir)) {
			// Requested project dir does exist for logged in user: Delete installed project.
			rrmdir($dir);
			echo "COMPLETE";
			log_stuff($user,"",$hapmap,"","","H:DELETE success");
		} else {
			// Project doesn't exist, should never happen.
			echo "ERROR:".$user." doesn't own project.";
			log_stuff($user,"",$hapmap,"","","H:DELETE failure");
		}
	}

	// Function for recursive rmdir, to clean out full hapmap directory.
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
