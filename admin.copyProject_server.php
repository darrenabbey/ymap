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
			// not an admin account, redirect to login page.
			$admin_logged_in = "false";
			session_destroy();
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to copy project to default!");
			header('Location: .');
		} else {
			$admin_logged_in = "true";

			// Load user string from session.
			$user        = $_SESSION['user'];

			$project_key = sanitizeInt_POST('key');

			// Determine user account associated with key.
			$projectsDir    = "users/".$user."/projects/";
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
			foreach($projectFolders as $key=>$folder) {
				$projectFolders[$key] = str_replace($projectDir,"",$folder);
			}

			// Determine project to copy from provided project key.
			$project_to_copy = $projectFolders[$project_key];

			$src  = "users/".$user."/projects/".$project_to_copy;
			$dest = "users/default/projects/".$project_to_copy;

			// Copy from source project directory to destination project directory.
			if (file_exists($dest)) {
				log_stuff($user,"","",$project_to_copy,"","ADMIN fail: attempted to copy project to default user, but project name is already in use.");
			} else {
				log_stuff($user,"","",$project_to_copy,"","ADMIN success: copied project to default user.");
				mkdir($dest, 0776, true);
				recurseCopy($src, $dest);
			}
		}
	}
	function recurseCopy(string $sourceDirectory, string $destinationDirectory): void {
		$directory = opendir($sourceDirectory);
		if (is_dir($destinationDirectory) === false) {
			mkdir($destinationDirectory);
		}
		while (($file = readdir($directory)) !== false) {
			if ($file === '.' || $file === '..') {  continue;   }
			if (is_dir("$sourceDirectory/$file") === true) {
				recurseCopy("$sourceDirectory/$file", "$destinationDirectory/$file");
			} else {
				copy("$sourceDirectory/$file", "$destinationDirectory/$file");
			}
		}
		closedir($directory);
	}
?>
