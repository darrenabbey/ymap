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
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to copy project to default!");
			header('Location: .');
		}

		// Load user string from session.
		$user     = $_SESSION['user'];
		$user_key = sanitizeInt_POST('key');

		// Determine user account associated with key.
		$projectDir      = "users/".$user."/projects/";
		$projectFolders  = array_diff(glob($projectDir."*\/"), array('..', '.', 'users/default/'));

		// Sort directories by date, newest first.
		array_multisort($projectFolders, SORT_ASC, $projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {
			$projectFolders[$key] = str_replace($projectDir,"",$folder);
		}
		$project_to_copy = $projectFolders[$user_key];

		$src  = $projectDir.$project_to_copy;
		$dest = "users/default/projects/".$project_to_copy;

		// Copy from source project directory to destination project directory.
		if (file_exists($dest)) {
			log_stuff($user,"","",$project_to_copy,"","ADMIN fail: attempted to copy project to default user, but project name is already in use.");
		} else {
			log_stuff($user,"","",$project_to_copy,"","ADMIN success: copied project to default user.");
			mkdir($dest, 0777, true);
			foreach (scandir($src) as $file) {
				if (!is_readable($src . '/' . $file)) continue;
	                        copy($src . '/' . $file, $dest . '/' . $file);
			}
		}
	}
?>
