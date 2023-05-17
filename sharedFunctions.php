<?php
// return the current size in GB of the user folder
function getUserUsageSize($userName) {
	// Just looks at total volume of user directory.
	return shell_exec("du -scm users/".$userName."/ | awk 'END{print $1}'") / (1000);
}

// return the size of the user quota in GB
function getUserQuota($userName) {
	// load hardcoded quota from constants
	require('constants.php');
	// check if user has a personal quota if so overriding quota
	if (file_exists("users/".$userName."/quota.txt")) {
		$quota_ = trim(file_get_contents("users/".$userName."/quota.txt"));
	} else {
		$quota_ = $quota;
	}
	return $quota_;
}

// YMAP logging function.
function log_stuff($user,$project,$hapmap,$genome,$filename,$message) {
	// define log file.
	$log_file = "logs/".date('Y-m-d')."_activity.log";

	echo getcwd();

	// check if log file exists, create if not.
	if (!file_exists($log_file)) {
		$myfile = fopen($log_file, "w");
		fwrite($myfile, "Initiate log file: ".date('Y-m-d H:i:s')."\n");
		fclose($myfile);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s').' - IP:'.$_SERVER["REMOTE_ADDR"].' - SessionID:'.session_id();
	if (!empty($user)) {            $line = $line.' - user:'.$user;         }
	if (!empty($project)) {         $line = $line.' - project:'.$project;   }
	if (!empty($hapmap)) {          $line = $line.' - hapmap:'.$hapmap;     }
	if (!empty($genome)) {          $line = $line.' - genome:'.$genome;     }
	if (!empty($filename)) {        $line = $line.' - '.$filename;          }
	if (!empty($message)) {         $line = $line.' - "'.$message.'"';      }
	file_put_contents($log_file, $line . PHP_EOL, FILE_APPEND);
}
?>
