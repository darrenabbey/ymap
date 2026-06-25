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
			$projectFolders = [];
			$objects = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($projectsDir), RecursiveIteratorIterator::SELF_FIRST);
			foreach($objects as $name => $object){
				if (is_dir($name)) {
					$name_ = str_replace($projectsDir,"",$name);
					if (str_contains($name_,"..") or str_contains($name_,".")) {
					} else {
						$projectFolders[] = $name_;
					}
				}
			}

			// Sort directories by date, newest first.
			sort($projectFolders);

			// Trim path from each folder string.
			foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectDir,"",$folder);   }

			// grab selected project by it's key
			$project_target = $projectFolders[$project_key];

			// Confirm if requested user and project exists.
			$dir     = "users/".$project_user."/projects/".$project_target;

			if (is_dir($dir)) {
				// Requested user project does exist: Generate new locked.txt file for user project.
				$lockFile = $dir."locked.txt";
				$lock = fopen($lockFile, "w");
				fwrite($lock, "locked");
				fclose($lock);
				echo "COMPLETE\n";
			} else {
				// User project doesn't exist, should never happen.
				echo "ERROR: ".$dir." doesn't exist.\n";
			}
		}
	}
?>
