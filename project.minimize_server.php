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
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// Sanitize input strings.
		$project = sanitize_POST("project");
		if ($project == "") {
			echo "ERROR:".$project." doesn't exist.";
			log_stuff($user,$project,"","","","project:MINIMIZE failure, project name error.");
		} else {
			$dir     = "users/".$user."/projects/".$project;

			// Confirm if requested project exists.
			if (is_dir($dir)) {
				// Requested project dir does exist for logged in user: Delete installed project.
				minimizeProject($dir);
				echo "COMPLETE";
				log_stuff($user,$project,"","","","project:MINIMIZE success");
			} else {
				// Project doesn't exist, should never happen.
				echo "ERROR:".$user." doesn't own project.";
				log_stuff($user,$project,"","","","project:MINIMIZE failure, user doesn't own project.");
			}
			log_stuff($user,$project,"","","","project:MINIMIZE success.");
		}
	}
?>
