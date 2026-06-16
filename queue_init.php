<?php
	session_start();
	require_once 'constants.php';
	require_once 'sharedFunctions.php';

	$userName    = $argv[1];
	$projectName = $argv[2];
	$genomeName  = "";
	$hapmapName  = "";
	$message     = "from: admin manual intervention.";

	make_salt($userName,$projectName,$genomeName,$hapmapName);
	queue_init($userName,$projectName,$genomeName,$hapmapName,$message);
?>
