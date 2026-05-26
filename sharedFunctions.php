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
		$quota = $QUOTA_GLOBAL;
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
		file_put_contents($log_file, $line.PHP_EOL, FILE_APPEND);
	} else {
		$line = date('Y-m-d H:i:s').' - IP:[null] - SessionID:[null]';
		if (!empty($user)) {       $line = $line.' - user:'.$user;         }
		if (!empty($project)) {    $line = $line.' - project:'.$project;   }
		if (!empty($hapmap)) {     $line = $line.' - hapmap:'.$hapmap;     }
		if (!empty($genome)) {     $line = $line.' - genome:'.$genome;     }
		if (!empty($filename)) {   $line = $line.' - '.$filename;          }
		if (!empty($message)) {    $line = $line.' - "'.$message.'"';      }
		file_put_contents($log_file, $line.PHP_EOL, FILE_APPEND);
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

	// Make a unique string to place in project/genome/hapmap directory.
	$salt_string = bin2hex(random_bytes(16 / 2));
	if (!empty($project)) {
		file_put_contents($filePath."/users/".$user."/projects/".$project."/salt.txt", $salt_string);
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		file_put_contents($filePath."/users/".$user."/genomes/".$genome."/salt.txt", $salt_string);
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
		file_put_contents($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt", $salt_string);
		$line = $line.' - hapmap:'.$hapmap.' - '.$salt_string;
	}
	$line = $line.' - init';
	if (!empty($message)) {   $line = $line.' - '.$message;           }
	file_put_contents($log_file, $line.PHP_EOL, FILE_APPEND);
}
function queue_reinit($user,$project,$genome,$hapmap,$message) {
	// find main Ymap directory, by removing possible ymap subdirectories from path of calling script.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	if (!empty($project)) {
		// Add an update.txt file into project to let queue know it is an update process.
		$update_file = $filePath."/users/".$user."/projects/".$project."/update.txt";
		$myfile = fopen($update_file, "w");
		fwrite($myfile, date('Y-m-d'));
		fclose($myfile);
		chmod($log_file, 0774);
	}

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

	// Make a unique string to place in project/genome/hapmap directory.
	$salt_string = bin2hex(random_bytes(16 / 2));
	if (!empty($project)) {
		if (file_exists($filePath."/users/".$user."/projects/".$project."/salt.txt")) {
			unlink($filePath."/users/".$user."/projects/".$project."/salt.txt");
		}
		file_put_contents($filePath."/users/".$user."/projects/".$project."/salt.txt", $salt_string);
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		if (file_exists($filePath."/users/".$user."/genomes/".$genome."/salt.txt")) {
			unlink($filePath."/users/".$user."/genomes/".$genome."/salt.txt");
		}
		file_put_contents($filePath."/users/".$user."/genomes/".$genome."/salt.txt", $salt_string);
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
		if (file_exists($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt")) {
			unlink($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt");
		}
		file_put_contents($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt", $salt_string);
		$line = $line.' - hapmap:'.$hapmap.' - '.$salt_string;
	}
	$line = $line.' - init';
	if (!empty($message)) {   $line = $line.' - '.$message;           }
	file_put_contents($log_file, $line.PHP_EOL, FILE_APPEND);
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
	if (!empty($project)) {
		$salt_string = trim(file_get_contents($filePath."/users/".$user."/projects/".$project."/salt.txt"));
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		$salt_string = trim(file_get_contents($filePath."/users/".$user."/genomes/".$genome."/salt.txt"));
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
		$salt_string = trim(file_get_contents($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt"));
		$line = $line.' - hapmap:'.$hapmap.' - '.$salt_string;
	}
	$line = $line.' - start';
	if (!empty($message)) {   $line = $line.' - '.$message;           }
	file_put_contents($log_file, $line.PHP_EOL, FILE_APPEND);
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
	if (!empty($project)) {
		if (file_exists($filePath."/users/".$user."/projects/".$project."/salt.txt")) {
			$salt_string = trim(file_get_contents($filePath."/users/".$user."/projects/".$project."/salt.txt"));
			$line = $line.' - project:'.$project.' - '.$salt_string;
		}
	} elseif (!empty($genome)) {
		if (file_exists($filePath."/users/".$user."/genomes/".$genome."/salt.txt")) {
			$salt_string = trim(file_get_contents($filePath."/users/".$user."/genomes/".$genome."/salt.txt"));
			$line = $line.' - genome:'.$genome.' - '.$salt_string;
		}
	} elseif (!empty($hapmap)) {
		if (file_exists($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt")) {
			$salt_string = trim(file_get_contents($filePath."/users/".$user."/hapmaps/".$hapmap."/salt.txt"));
			$line = $line.' - hapmap:'.$hapmap.' - '.$salt_string;
		}
	}
	$line = $line.' - end';
	if (!empty($message)) {
		$line = $line.' - '.$message;
	}
	file_put_contents($log_file, $line.PHP_EOL, FILE_APPEND);
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
