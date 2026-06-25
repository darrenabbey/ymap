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
		$super_user_flag_file = "users/".$user."/super.txt";
		if (!(file_exists($super_user_flag_file))) {  // Super-user privilidges.
			// not an admin account, redirect to login page.
			$admin_logged_in = "false";
			session_destroy();
			log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to copy project to default!");
			header('Location: .');
		} else {
			$super_logged_in = "true";

			// Load user string from session.
			$admin_as_user = sanitize_POST('user');
			$project_key   = sanitizeInt_POST('key');
			log_stuff($user,"","","","","TESTING: ".$admin_as_user." ".$project_key);

			// Determine user account associated with key.
			$projectsDir    = "users/".$admin_as_user."/projects/";
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

			$src  = "users/".$admin_as_user."/projects/".$project_to_copy;
			$dest = "users/".$user."/projects/".$admin_as_user."_".$project_to_copy;

			// Copy from source project directory to destination project directory.
			if (file_exists($dest)) {
				log_stuff($user,$project_to_copy,"","","","ADMIN fail: attempted to copy project to admin user, but project name is already in use.");
			} else {
				log_stuff($user,$project_to_copy,"","","","ADMIN success: copied project to admin user.");
				mkdir($dest, 0773, true);
				recurseCopy($src, $dest);

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
