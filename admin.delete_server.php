<?php
	session_start();
	error_reporting(E_ALL);
        require_once 'constants.php';
	require_once 'POST_validation.php';
        ini_set('display_errors', 1);

        // If the user is not logged on, redirect to login page.
        if(!isset($_SESSION['logged_on'])){
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
		header('Location: .');
	}

	// Load user string from session.
	$user     = $_SESSION['user'];
	$user_key = sanitizeInt_POST('key');

	// Determine user account associated with key.
	$userDir      = "users/";
	$userFolders  = array_diff(glob($userDir."*\/"), array('..', '.'));
	// Sort directories by date, newest first.
	array_multisort($userFolders, SORT_ASC, $userFolders);
	// Trim path from each folder string.
	foreach($userFolders as $key=>$folder) { $userFolders[$key] = str_replace($userDir,"",$folder); }
	$user_target = $userFolders[$user_key];

	// Confirm if requested user exists.
	$dir     = "users/".$user_target;
	if (is_dir($dir)) {
		// Requested user does exist: Delete user.
		rrmdir($dir);
		echo "COMPLETE\n";
	} else {
		// User doesn't exist, should never happen.
		echo "ERROR:".$user_target." doesn't exist.";
	}

	//==========================
	// recursive rmdir function.
	//--------------------------
	function rrmdir($dir) {
		if (is_dir($dir)) {
			$objects = scandir($dir);
			foreach ($objects as $object) {
				if ($object != "." && $object != "..") {
					if (filetype($dir."/".$object) == "dir") {
						rrmdir($dir."/".$object);
					} else {
						unlink($dir."/".$object);
					}
				}
			}
			reset($objects);
			rmdir($dir);
		}
	}
?>
