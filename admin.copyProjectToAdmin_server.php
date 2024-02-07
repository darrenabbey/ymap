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
		//log_stuff($user,"","",$project_to_copy,"","ADMIN testing.");
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
		$user          = $_SESSION['user'];
		$admin_as_user = sanitize_POST('user');
		$user_key      = sanitizeInt_POST('key');

		// Determine user account associated with key.
		$projectDir      = "users/".$admin_as_user."/projects/";
		$projectFolders  = array_diff(glob($projectDir."*\/"), array('..', '.', 'users/default/'));

		// Sort directories by date, newest first.
		array_multisort($projectFolders, SORT_ASC, $projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {
			$projectFolders[$key] = str_replace($projectDir,"",$folder);
		}

		// Split project list into starting/working/complete lists for sequential display.
		$projectFolders_starting = array();
		$projectFolders_working  = array();
		$projectFolders_complete = array();
		foreach($projectFolders as $key=>$project) {
			if (file_exists("users/".$admin_as_user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$admin_as_user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (is_dir("users/".$admin_as_user."/projects/".$project)) {
				array_push($projectFolders_starting,$project);
			}
		}
		$userProjectCount_starting = count($projectFolders_starting);
		$userProjectCount_working  = count($projectFolders_working);
		$userProjectCount_complete = count($projectFolders_complete);
		// Sort complete and working projects alphabetically.
		array_multisort($projectFolders_starting, SORT_ASC, $projectFolders_starting);
		array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working);
		array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);
		// Build new 'projectFolders' array;
		$projectFolders   = array();
		$projectFolders   = array_merge($projectFolders_starting, $projectFolders_working, $projectFolders_complete);
		$userProjectCount = count($projectFolders);

		// Determine project to copy from provided project key.
		$project_to_copy = $projectFolders[$user_key];

		$src  = $projectDir.$project_to_copy;
		$dest = "users/".$user."/projects/".$admin_as_user."_".$project_to_copy;

		// Copy from source project directory to destination project directory.
		if (file_exists($dest)) {
			log_stuff($user,"","",$project_to_copy,"","ADMIN fail: attempted to copy project to admin user, but project name is already in use.");
		} else {
			log_stuff($user,"","",$project_to_copy,"","ADMIN success: copied project to admin user.");
			mkdir($dest, 0773, true);
			foreach (scandir($src) as $file) {
				if (!is_readable($src.'/'.$file)) continue;
				if (($file != "..") and ($file != ".")) {
		                        copy($src.'/'.$file, $dest.'/'.$file);
				}
			}

			// update name.txt file.
			$projectName  = file_get_contents($dest."/name.txt",'r');
			$handle       = fopen($dest."/name.txt",'w');
			fwrite($handle, "<b>".$admin_as_user."</b> ".$projectName);
			fclose($handle);

			// update parent.txt file
			$parentName  = file_get_contents($dest."/parent.txt",'r');
			$handle      = fopen($dest."/parent.txt",'w');
			fwrite($handle, $admin_as_user."_".$parentName);
			fclose($handle);
		}
	}
?>
