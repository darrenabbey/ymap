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
	if ($genome != "") {
		$genome_dir  = "../../users/".$user."/genomes/".$genome;
		if (!is_dir($genome_dir)) {
			log_stuff("../../",$user,"","",$genome,$genome_dir,"UPLOAD fail: user attempted to upload to non-existent genome!");
			// Genome doesn't exist, should never happen: Force logout.
			session_destroy();
			header('Location: ../');
		}
		$target_dir  = "../../users/".$user."/genomes/".$genome."/";
	} else if ($project != "") {
		$project_dir = "../../users/".$user."/projects/".$project;
		if (!is_dir($project_dir)) {
			log_stuff("../../",$user,$project,"","",$project_dir,"UPLOAD fail: user attempted to upload to non-existent project!");
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
	$currentSize = getUserUsageSize($user);
	// getting user quota in Gigabytes
	$quota_ = getUserQuota($user);
	if ($quota_ > $quota) {   $quota = $quota_;   }
	// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
	$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
	if ($exceededSpace) {
		echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tnparent.update_interface();\n}\n";
		echo "var intervalID = window.setInterval(reload_page, 1000);\n</script>\n";
	}


	//============================================================================
	// HTML5Uploader ::  Adam Filkor : http://filkor.org
	// Licensed under the MIT license : http://www.opensource.org/licenses/MIT
	//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	// non-MySQL version.
	//----------------------------------------------------------------------------
	// Only allow uploading to proceed if user quota is not exceeded.
	if (!$exceededSpace) {
		require('UploadHandler.php');
		$upload_handler = new UploadHandler($target_dir);
	}
?>
