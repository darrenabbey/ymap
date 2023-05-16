<?php
	session_start();
	error_reporting(E_ALL);
	require_once '../../constants.php';
	require_once '../../sharedFunctions.php';
	require_once '../../POST_validation.php';

	// If the user is not logged on, redirect to login page.
	if(!isset($_SESSION['logged_on'])){
		session_destroy();
		header('Location: .');
	}

	// Load user string from session.
	$user     = $_SESSION['user'];

	// Only information needed by this script sent by "js/ajaxfileupload.js" from form defined in "uploader.1.php".
	// This safe data is used to construct the target file location.

	// Sanitize input strings.
	$genome  = sanitize_POST("target_genome");
	$project = sanitize_POST("target_project");

	// Confirm if requested genome/project exists.
	if ($user == "") {
		log_stuff($user,"","","","","UPLOAD fail: null user during upload attempt!");
		// User not logged in or empty string, should never happen: Force logout.
		session_destroy();
		header('Location: ../');
	}

	if ($genome != "") {
		$genome_dir  = "../../users/".$user."/genomes/".$genome;
		if (!is_dir($genome_dir)) {
			log_stuff($user,"","",$genome,$genome_dir,"UPLOAD fail: user attempted to upload to non-existent genome!");
			// Genome doesn't exist, should never happen: Force logout.
			session_destroy();
			header('Location: ../');
		}
		$target_dir  = "../../users/".$user."/genomes/".$genome."/";
	} else if ($project != "") {
		$project_dir = "../../users/".$user."/projects/".$project;
		if (!is_dir($project_dir)) {
			log_stuff($user,$project,"","",$project_dir,"UPLOAD fail: user attempted to upload to non-existent project!");
			// Project doesn't exist, should never happen: Force logout.
			session_destroy();
			header('Location: ../');
		}
		$target_dir = "../../users/".$user."/projects/".$project."/";
	}

	//==================================
	// Check if user has exceeded quota.
	//----------------------------------
	// getting the current size of the user folder in Gigabytes
	$currentSize = shell_exec("du -scm ../../users/".$user."/ | awk 'END{print $1}'") / (1000);
	// getting user quota in Gigabytes
	$quota_ = getUserQuota($user);
	if ($quota_ > $quota) { $quota = $quota_; }
	// Setting boolean variable that will indicate whether the user has exceeded it's allocated space.
	$exceededSpace = $quota > $currentSize ? FALSE : TRUE;

//	//troubleshooting log output:
//	$myfile = "../../users/".$user."/projects/".$project."/newfile.txt";
//	$txt    = "[currentSize = ".$currentSize."]\n"."[quota = ".$quota."]\n"."[exceededSpace = ".$exceededSpace."]\n";
//	file_put_contents($myfile, $txt);

	// Only allow uploading to proceed if user quota is not exceeded.
	if ($exceededSpace) {
		// Successfully interrupts file upload when quota space is exceeded.
		// Attempts to force reload of user interface, but doesn't work right.
		echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tnparent.parent.update_interface();\n}\n";
		echo "var intervalID = window.setInterval(reload_page, 1000);\n</script>\n";
	} else {
		//============================================================================
		// HTML5Uploader ::  Adam Filkor : http://filkor.org
		// Licensed under the MIT license : http://www.opensource.org/licenses/MIT
		//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		// non-MySQL version.
		//----------------------------------------------------------------------------
		require('UploadHandler.php');
		$upload_handler = new UploadHandler($target_dir);
	}
?>
