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
		// not an admin account, redirect to login page.
		$admin_logged_in = "false";
		session_destroy();
		log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to copy hapmap to default!");
		header('Location: .');
	}

	// Load user string from session.
	$user     = $_SESSION['user'];
	$user_key = sanitizeInt_POST('key');

	// Determine user account associated with key.
	$hapmapDir      = "users/".$user."/hapmaps/";
	$hapmapFolders  = array_diff(glob($hapmapDir."*\/"), array('..', '.', 'users/default/'));

	// Sort directories by date, newest first.
	array_multisort($hapmapFolders, SORT_ASC, $hapmapFolders);

	// Trim path from each folder string.
	foreach($hapmapFolders as $key=>$folder) {
		$hapmapFolders[$key] = str_replace($hapmapDir,"",$folder);
	}
	$hapmap_to_copy = $hapmapFolders[$user_key];

	$src  = $hapmapDir.$hapmap_to_copy;
	$dest = "users/default/hapmaps/".$hapmap_to_copy;

	// Copy from source hapmap directory to destination hapmap directory.
	if (file_exists($dest)) {
		log_stuff($user,"","",$hapmap_to_copy,"","ADMIN fail: attempted to copy hapmap to default user, but hapmap name is already in use.");
	} else {
		log_stuff($user,"","",$hapmap_to_copy,"","ADMIN success: copied hapmap to default user.");
		mkdir($dest, 0773, true);
		foreach (scandir($src) as $file) {
			if (!is_readable($src . '/' . $file)) continue;
                        copy($src . '/' . $file, $dest . '/' . $file);
		}
	}
?>
