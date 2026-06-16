<?php
	session_start();
	require_once 'constants.php';
	require_once 'sharedFunctions.php';

	if ($argc  == 3) {
		$userName    = $argv[1];
		$projectName = $argv[2];
		$genomeName  = "";
		$hapmapName  = "";
		$message     = "from: admin manual intervention.";
		if (is_dir($base_dir."/users/".$userName) and is_dir($base_dir."/users/".$userName."/projects/".$projectName)) {
			make_salt($userName,$projectName,$genomeName,$hapmapName);
			queue_init($userName,$projectName,$genomeName,$hapmapName,$message);
		} else {
			print_r("User and/or project name not found.\nUse: php queue_init.php [userName] [projectName]\n");
		}
	} else {
		print_r("Use: php queue_init.php [userName] [projectName]\n");
	}
?>
