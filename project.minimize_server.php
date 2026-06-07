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

	// Function for reducing project files to only necessary for display.
	function minimizeProject($dir) {
		$dir = $dir."/";
		// Make a temp directory.
		$temp_dir = $dir."/temp/";
		mkdir($temp_dir);

		// Get array of all project files
                $files = scandir($dir);

		// Move files we want to keep into temp folder.
		foreach ($files as $file) {
			if (in_array($file, array("complete.txt","dataFormat.txt","genome.txt","index.php","name.txt","parent.txt","process_log.txt"."figVer.txt","working_done.txt"))) {
				rename($dir.$file, $temp_dir.$file);
			}
			$file_ext = substr(strrchr($file, '.'), 1);
			// mv [png|eps|bed|gff3] files.
			if (($file_ext == "png") or ($file_ext == "eps") or ($file_ext == "bed") or ($file_ext == "gff3")) {
				rename($dir.$file, $temp_dir.$file);
			}
		}

		// Refresh array of all project files
		$files = scandir($dir);

		// Delete remaining project files.
		foreach ($files as $file) {
			if (in_array($file, array(".","..","temp"))) continue;
			unlink($dir.$file);
		}

		//=============================================
		// Move needed files back to project directory.
		//---------------------------------------------

		// Get array of remaining files
		$files = scandir($temp_dir);

		// Move the saved files back to the project directory.
		foreach ($files as $file) {
			rename($temp_dir.$file,$dir.$file);
		}

		// Delete temp directory.
		rmdir($temp_dir);

		// Make minimized.txt file in project dir to mark project as minimized.
		$minimizedFile = $dir."/minimized.txt";
		$minimized     = fopen($minimizedFile, 'w');
		fclose($minimized);
	}
?>
