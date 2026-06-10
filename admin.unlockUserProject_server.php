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
	} else if ($_SESSION['logged_on'] == 0) {
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
		if (!(file_exists($admin_user_flag_file))) {  // admin-user privilidges not found.
			$admin_logged_in = "false";
			session_destroy();
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to lock user!");
			header('Location: .');
		} else {
			$admin_logged_in = "true";

			// Load user string from session.
			$user         = $_SESSION['user'];
			$project_user = sanitize_POST('user');
			$project_key  = sanitizeInt_POST('key');

			// Determine user account associated with key.
			$projectDir      = "users/".$project_user."/projects/";
			$projectFolders  = array_diff(glob($projectDir."*\/"), array('..', '.', 'users/default/'));

			// Sort directories by date, newest first.
			array_multisort($projectFolders, SORT_ASC, $projectFolders);

			// Trim path from each folder string.
			foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectDir,"",$folder);   }

			// Split project list into ready/working/starting lists for sequential display.
			$projectFolders_complete = array();
			$projectFolders_working  = array();
			$projectFolders_starting = array();
			foreach($projectFolders as $key=>$project) {
				if (file_exists("users/".$project_user."/projects/".$project."/complete.txt")) {
					array_push($projectFolders_complete,$project);
				} else if (file_exists("users/".$project_user."/projects/".$project."/working.txt")) {
					array_push($projectFolders_working, $project);
				} else if (is_dir("users/".$project_user."/projects/".$project)) {
					array_push($projectFolders_starting,$project);
				}
			}
			$userProjectCount_starting = count($projectFolders_starting);
			$userProjectCount_working  = count($projectFolders_working);
			$userProjectCount_complete = count($projectFolders_complete);
			// Sort complete and working projects alphabetically.
			array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working);
			array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);

			// grab selected project by it's key
			$project_target = $projectFolders_working[$project_key-$userProjectCount_starting];

			// Confirm if requested user and project exists.
			$dir     = "users/".$project_user."/projects/".$project_target;
			if (is_dir($dir)) {
				// Requested user project does exist: Delete locked.txt file for user project.
				$lockFile = $dir."locked.txt";
				unlink($lockFile);
				echo "COMPLETE\n";
			} else {
				// User project doesn't exist, should never happen.
				echo "ERROR: ".$dir." doesn't exist.";
			}
		}
	}
?>
