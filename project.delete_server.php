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
	} else if ($_SESSION['logged_on'] == 0) {
		session_destroy();
		header('Location: .');
	}

	// Load user string from session.
	if(isset($_SESSION['user'])) {
		$user = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// Sanitize input strings.
		$project = sanitize_POST("project");
		$dir     = "users/".$user."/projects/".$project;
		$dir2    = "users/".$user."/projects/".$project."/locked.txt";

		// Confirm if requested project exists and is not locked.
		if (is_dir($dir) and !file_exists($dir2))  {
			// Requested project dir does exist for logged in user: Delete installed project.
			queue_end($user,$project,"","","User deleted project.");
			rrmdir($dir);
			echo "COMPLETE";
			log_stuff($user,$project,"","","","project:DELETE success");
		} else {
			if (file_exists($dir2)) {
				// Project is locked.
				echo "ERROR:".$user." project '".$project."' is locked by admin.";
				log_stuff($user,$project,"","","","project:DELETE failure, project is locked by admin.");
			} else {
				// Project doesn't exist, should never happen.
				echo "ERROR:".$user." doesn't own project:'".$project."'\n";
				log_stuff($user,$project,"","","","project:DELETE failure, user doesn't own project.");
			}
		}
	}

	// Function for recursive rmdir, to clean out full project directory.
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
