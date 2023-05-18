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
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to clean project!");
			header('Location: .');
		}

		// Load user string from session.
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
		$project_to_clean = $projectFolders[$user_key];
		$src  = $projectDir.$project_to_clean;

		// Make a temp directory.
		$temp_dir = $projectDir.$project_to_clean."temp/";
		mkdir($temp_dir);

		// Move all project files to temp directory.
		// Get array of all source files
		$files = scandir($projectDir.$project_to_clean);
		// Identify directories
		$source = $projectDir.$project_to_clean;
		$destination = $temp_dir;
		// Cycle through all source files
		foreach ($files as $file) {
			if (in_array($file, array(".","..","temp"))) continue;
			// If we copied this successfully, mark it for deletion
			if (copy($source.$file, $destination.$file)) {
				$delete[] = $source.$file;
			}
		}
		// Delete all successfully-copied files
		foreach ($delete as $file) {
			unlink($file);
		}

		// Move only needed files back to project directory.
		// Get array of target source files
		$files = scandir($temp_dir);
		// Identify directories
		$source = $temp_dir;
		$destination = $projectDir.$project_to_clean;
		// Cycle through all source files
		foreach ($files as $file) {
			if (in_array($file, array("complete.txt","dataFormat.txt","genome.txt","index.php","name.txt","parent.txt","totalSize.txt"))) {
				copy($source.$file, $destination.$file);
			}
			$file_ext = substr(strrchr($file, '.'), 1);
			// mv [png|eps|bed|gff3] files.
			if (($file_ext == "png") or ($file_ext == "eps") or ($file_ext == "bed") or ($file_ext == "gff3")) {
				copy($source.$file, $destination.$file);
			}
		}

		// Cycle through all files remaining in temp directory and delete.
		$files = scandir($temp_dir);
		foreach ($files as $file) {
			if (in_array($file, array(".",".."))) continue;
			$delete[] = $temp_dir.$file;
		}

		// Delete temp directory.
		rmdir($temp_dir);

		log_stuff($user,$project_to_clean,"","","","project:MINIMIZE success.");
	}
?>
