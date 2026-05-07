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
	if (file_exists($base_dir."/users/".$userName."/quota.txt")) {
		$quota = trim(file_get_contents($base_dir."/users/".$userName."/quota.txt"));
	} else {
		$quota = $quota_global;
	}
	return $quota;
}

// YMAP logging function.
function log_stuff($user,$project,$hapmap,$genome,$filename,$message) {
	// find main Ymap directory, by removing possible ymap subdirectories from path of calling script.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	// define log file.
	$log_file = $filePath."/logs/".date('Y-m-d')."_activity.log";

	// check if log file exists, create if not.
	if (!file_exists($log_file)) {
		$myfile = fopen($log_file, "w");
		fwrite($myfile, "Initiate log file: ".date('Y-m-d H:i:s')."\n");
		fclose($myfile);
		chmod($log_file, 0774);
	}

	// add comment to log file.
	if ( isset($_SERVER["REMOTE_ADDR"]) && (null !== session_id()) ) {
		$line = date('Y-m-d H:i:s').' - IP:'.$_SERVER["REMOTE_ADDR"].' - SessionID:'.session_id();
		if (!empty($user)) {       $line = $line.' - user:'.$user;         }
		if (!empty($project)) {    $line = $line.' - project:'.$project;   }
		if (!empty($hapmap)) {     $line = $line.' - hapmap:'.$hapmap;     }
		if (!empty($genome)) {     $line = $line.' - genome:'.$genome;     }
		if (!empty($filename)) {   $line = $line.' - '.$filename;          }
		if (!empty($message)) {    $line = $line.' - "'.$message.'"';      }
		file_put_contents($log_file, $line . PHP_EOL, FILE_APPEND);
	} else {
		$line = date('Y-m-d H:i:s').' - IP:[null] - SessionID:[null]';
		if (!empty($user)) {       $line = $line.' - user:'.$user;         }
		if (!empty($project)) {    $line = $line.' - project:'.$project;   }
		if (!empty($hapmap)) {     $line = $line.' - hapmap:'.$hapmap;     }
		if (!empty($genome)) {     $line = $line.' - genome:'.$genome;     }
		if (!empty($filename)) {   $line = $line.' - '.$filename;          }
		if (!empty($message)) {    $line = $line.' - "'.$message.'"';      }
		file_put_contents($log_file, $line . PHP_EOL, FILE_APPEND);
	}
}


//========================================================================================
// YMAP Queue functions.
//----------------------------------------------------------------------------------------
function queue_init($user,$project,$genome,$hapmap,$message) {
	// find main Ymap directory, by removing possible ymap subdirectories from path of calling script.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	// define log file.
	$log_file = $filePath."/queue/".date('Y-m-d')."_queue.log";

	// check if log file exists, create if not.
	if (!file_exists($log_file)) {
		$myfile = fopen($log_file, "w");
		fwrite($myfile, "");
		fclose($myfile);
		chmod($log_file, 0774);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s');
	$line = $line.' - user:'.$user;
	if (!empty($project)) {   $line = $line.' - project:'.$project;   }
	if (!empty($genome)) {    $line = $line.' - genome:'.$genome;     }
	if (!empty($hapmap)) {    $line = $line.' - hapmap:'.$hapmap;     }
	$line = $line.' - init';
	if (!empty($message)) {   $line = $line.' - '.$message;           }
	file_put_contents($log_file, $line . PHP_EOL, FILE_APPEND);
}

function queue_start($user,$project,$genome,$hapmap,$message) {
	// find main Ymap directory, by removing possible ymap subdirectories from path of calling script.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	// define log file.
	$log_file = $filePath."/queue/".date('Y-m-d')."_queue.log";

	// check if log file exists, create if not.
	if (!file_exists($log_file)) {
		$myfile = fopen($log_file, "w");
		fwrite($myfile, "");
		fclose($myfile);
		chmod($log_file, 0774);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s');
	$line = $line.' - user:'.$user;
	if (!empty($project)) {   $line = $line.' - project:'.$project;   }
	if (!empty($genome)) {    $line = $line.' - genome:'.$genome;     }
	if (!empty($hapmap)) {    $line = $line.' - hapmap:'.$hapmap;     }
	$line = $line.' - start';
	if (!empty($message)) {   $line = $line.' - '.$message;           }
	file_put_contents($log_file, $line . PHP_EOL, FILE_APPEND);
}
function queue_end($user,$project,$genome,$hapmap,$message) {
	// find main Ymap directory, by removing possible ymap subdirectories from path of calling script.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	$queue_dir   = $filePath."/queue/";
	$queue_files = array_slice(scandir($queue_dir), 2);
	foreach ($queue_files as $key1 => $queue_file) {
		if (str_contains($queue_file,".log")) {
			$queue_contents = trim(file_get_contents($queue_dir.$queue_file));
			if ($queue_contents) {
				// Queue contents example:
				//	Initiate queue file: 2026-05-05 19:06:21
				//	2026-05-05 19:06:21 - user:darrenFY - project:TJ4771_R1_clean - start - message 1.
				//	2026-05-05 19:06:21 - user:darrenFY - project:TJ4772_R1_clean - start - message 2.
				//	2026-05-05 19:06:21 - user:darrenFY - project:TJ4773_R1_clean - start
				$outline = "";
				$queue_lines = preg_split("/\R/", $queue_contents);
				foreach($queue_lines as $key2 => $line){
					$line_parts = explode(" - ",$line);
					if (sizeof($line_parts) > 0) {
						if ($line_parts[1] == "user:".$user) {
							if ($line_parts[2] == "project:".$project) {
								$outline = date('Y-m-d H:i:s');
								$outline = $outline.' - user:'.$user;
								$outline = $outline.' - project:'.$project;
							} else if ($line_parts[2] == "genome:".$genome) {
								$outline = date('Y-m-d H:i:s');
								$outline = $outline.' - user:'.$user;
								$outline = $outline.' - genome:'.$genome;
							} else if ($line_parts[2] == "hapmap:".$hapmap) {
								$outline = date('Y-m-d H:i:s');
								$outline = $outline.' - user:'.$user;
								$outline = $outline.' - hapmap:'.$hapmap;
							}
						}
					}
				}
				if ($outline <> "") {
					$outline = $outline.' - end';
					if (!empty($message)) {   $outline = $outline.' - '.$message;           }
					file_put_contents($queue_dir.$queue_file, $outline.PHP_EOL, FILE_APPEND);
				}
			}
		}
	}
}

function getColors($user,$project) {
	//[$colorString1, $colorString2] = getColors($user,$project);
	$colors_file  = $base_dir."/users/".$user."/projects/".$project."/colors.txt";
	if (file_exists($colors_file)) {
		$handle       = fopen($colors_file,'r');
		$colorString1 = trim(fgets($handle));
		$colorString2 = trim(fgets($handle));
		fclose($handle);
	} else {
		$colorString1 = 'null';
		$colorString2 = 'null';
	}
	return [$colorString1,$colorString2];
}

?>
