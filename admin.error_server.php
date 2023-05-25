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
		log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to add error to project!");
		header('Location: .');
	}

	// Load user string from session.
	$admin_as_user = sanitize_POST('user');
	$key_          = sanitizeInt_POST('key');
	$errorText     = stripHTML_POST('errorText');

	log_stuff($user,"","","","","troubleshooting: [".$admin_as_user."]");
	log_stuff($user,"","","","","troubleshooting: [".$key_."]");


	// Confirm admin_as_user exists.
	if (!is_dir("users/".$admin_as_user)) {
		session_destroy();
		log_stuff($user,"","","","","CREDENTIAL fail: admin attempted to add error to project belonging to a user that doesn't exist! [".$admin_as_user."]");
		header('Location: .');
	}

	// Determine user account project associated with key.
	$userProjectCount = 0;
	$projectsDir      = "users/".$admin_as_user."/projects/";
	$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.', 'index.php'));
	// Sort directories by date, newest first.
	array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);
	// Trim path from each folder string.
	foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectsDir,"",$folder);   }
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
	// Build new 'projectFolders' array;
	$projectFolders   = array();
	$projectFolders   = array_merge($projectFolders_starting, $projectFolders_working, $projectFolders_complete);
	$userProjectCount = count($projectFolders);

	// lookup project folder from key.
	if ((intval($key_) > -1) and (intval($key_) < $userProjectCount)) {
		$project_ = $projectFolders[intval($key_)];
	} else {
		session_destroy();
		log_stuff($user,"","","","","CREDENTIAL fail: admin attempted to use erroneous key to find user project! [user=".$admin_as_user."][key=".$key_."]");
		header('Location: .');
	}

	// Confirm if requested user project exists.
	$dir     = "users/".$admin_as_user."/projects/".$project_."/";
	if (is_dir($dir)) {
		// Requested user project does exist: Generate new error.txt file for user project
		$errorFile = $dir."error.txt";
		$error = fopen($errorFile, "w");
		fwrite($error, $errorText);
		fclose($error);
	}
?>
