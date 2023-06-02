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
	$user = $_SESSION['user'];
	$super_user_flag_file = "users/".$user."/super.txt";
	if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
		$admin_logged_in = "true";
	} else {
		$admin_logged_in = "false";
		session_destroy();
		log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to lock user!");
		header('Location: .');
	}

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
	array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working);
	array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);

	// grab selected project by it's key
	$project_target = $projectFolders_working[$project_key];

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
?>
