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
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to delete project!");
			header('Location: .');
		}

		// Load user string from session.
		$project_key = sanitizeInt_POST('key');

		// Determine project account associated with key.
		$projectDir      = "users/default/projects/";
		$projectFolders  = glob($projectDir."*\/");

		// Sort directories by date, newest first.
		array_multisort($projectFolders, SORT_ASC, $projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) { $projectFolders[$key] = str_replace($projectDir,"",$folder); }
		$project_target = $projectFolders[$project_key];

		// Confirm if requested project exists.
		$dir     = "users/default/projects/".$project_target;
		if (is_dir($dir)) {
			// Requested project does exist: Delete project.
			rrmdir($dir);
			echo "COMPLETE\n";
			log_stuff($user,$project_target,"","","","ADMIN project:DELETE success.");
		} else {
			// project doesn't exist, should never happen.
			echo "ERROR:".$project_target." doesn't exist.";
			log_stuff($user,$project_target,"","","","ADMIN project:DELETE FAIL: can't delete default user project that doesn't exist.");
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
