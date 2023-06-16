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
		// Sanitize input strings.
		$project = sanitize_POST("project");
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

	// Function for reducing project files to only necessary for display.
	function minimizeProject($dir) {
		$dir = $dir."/";
		// Make a temp directory.
		$temp_dir = $dir."/temp/";
		mkdir($temp_dir);

		// Move all project files to temp directory.
		// Get array of all source files
		$files = scandir($dir);

		// Identify directories
		$source = $dir;
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

		//==================================================
		// Move only needed files back to project directory.
		//--------------------------------------------------

		// Get array of target source files
		$files = scandir($temp_dir);

		// Identify directories
		$source = $temp_dir;
		$destination = $dir;

		// Cycle through all source files
		foreach ($files as $file) {
			if (in_array($file, array("complete.txt","dataFormat.txt","genome.txt","index.php","name.txt","parent.txt","process_log.txt"))) {
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

		// Make minimized.txt file in project dir to mark project as minimized.
		$minimizedFile = $dir."/minimized.txt";
		$minimized     = fopen($minimizedFile, 'w');
		fclose($minimized);
	}
?>
