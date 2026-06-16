<?php
	session_start();
	require_once 'constants.php';
	require_once 'sharedFunctions.php';

	$user    = $ARGV[1];
	$project = $ARGV[2];
	$genome  = "";
	$hapmap  = "";
	$message = "from: admin manual intervention.";

	make_salt($user,$project,$genome,$hapmap);
	queue_init($user,$project,$genome,$hapmap,$message);
?>
