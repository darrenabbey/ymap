<?php
function SYSTEM_cleanup($userName,$projectName,$main_dir) {
	if ($userName == "") {
		log_stuff("","","","","","SYSTEM_CLEANER: project:ERROR_CLEANUP failure, user name error.");
	} else {
		if ($projectName == "") {
			log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:ERROR_CLEANUP failure, project name error.");
		} else {
			$dir     = $main_dir."/users/".$userName."/projects/".$projectName;
			if (is_dir($dir)) {
				// DO STUFF HERE.
				if (is_file($dir."/error.txt")) {
					unlink($dir."/datafile_*");
					unlink($dir."/data.pileup");
					unlink($dir."/data_sorted.bam");
					unlink($dir."/data.bam");
					unlink($dir."/putative_SNPs_v4.txt");
					unlink($dir."/SNP_CNV_v1.txt");
					unlink($dir."/data_sorted.bam.bai");
					log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:ERROR_CLEANUP success");
				} else {
					log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:ERROR_CLEANUP not needed, no error.txt file.");
				}
			} else {
				log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:ERROR_CLEANUP failure, user doesn't own project.");
			}
			log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:ERROR_CLEANUP success.");
		}
	}
}
function SYSTEM_force_minimize($userName,$projectName,$main_dir) {
	if ($userName == "") {
		log_stuff("","","","","","SYSTEM_CLEANER: project:MINIMIZE failure, user name error.");
	} else {
		if ($projectName == "") {
			log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:MINIMIZE failure, project name error.");
		} else {
			$dir     = $main_dir."/users/".$userName."/projects/".$projectName;
			if (is_dir($dir)) {
				// DO STUFF HERE.
				minimizeProject($dir);
				log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:MINIMIZE success");
			} else {
				log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:MINIMIZE failure, user doesn't own project.");
			}
			log_stuff($userName,$projectName,"","","","SYSTEM_CLEANER: project:MINIMIZE success.");
		}
	}
}
function minimizeProject($dir) {
	$dir = $dir."/";
	// Make a temp directory.
	$temp_dir = $dir."/temp/";
	mkdir($temp_dir);

	// Get array of all project files
	$files = scandir($dir);

	// Move files we want to keep into temp folder.
	foreach ($files as $file) {
		if (in_array($file, array("complete.txt","dataFormat.txt","genome.txt","index.php","name.txt","parent.txt","process_log.txt"."figVer.txt","working_done.txt"))) {
			rename($dir.$file, $temp_dir.$file);
		}
		$file_ext = substr(strrchr($file, '.'), 1);
		// mv [png|eps|bed|gff3] files.
		if (($file_ext == "png") or ($file_ext == "eps") or ($file_ext == "bed") or ($file_ext == "gff3")) {
			rename($dir.$file, $temp_dir.$file);
		}
	}

	// Refresh array of all project files
	$files = scandir($dir);

	// Delete remaining project files.
	foreach ($files as $file) {
		if (in_array($file, array(".","..","temp"))) continue;
		unlink($dir.$file);
	}

	//=============================================
	// Move needed files back to project directory.
	//---------------------------------------------

	// Get array of remaining files
	$files = scandir($temp_dir);

	// Move the saved files back to the project directory.
	foreach ($files as $file) {
		rename($temp_dir.$file,$dir.$file);
	}

	// Delete temp directory.
	rmdir($temp_dir);

	// Make minimized.txt file in project dir to mark project as minimized.
	$minimizedFile = $dir."/minimized.txt";
	$minimized     = fopen($minimizedFile, 'w');
	fclose($minimized);
}



//========================================================================================================================
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
function secureNewDirectory($dir) {
	// Generate 'index.php' file into each directory, to redirect to main page
	// to prevent users from exploring directory tree.
	$myfile = fopen($dir."/index.php", "w");
	$txt = "<?php\nsession_start();\nerror_reporting(E_ALL);\nini_set('display_errors', 1);\nsession_destroy();\nheader('Location: ../');\n?>";
	fwrite($myfile,$txt);
	fclose($myfile);
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
		chmod($log_file, 0666);
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
function make_salt($user,$project,$genome,$hapmap) {
	// Clean up path to find install directory.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	// Figure out which path it is we're working with.
	if (!empty($project)) {
		$activePath = $filePath."/users/".$user."/projects/".$project;
	} elseif (!empty($genome)) {
		$activePath = $filePath."/users/".$user."/genomes/".$genome;
	} elseif (!empty($hapmap)) {
		$activePath = $filePath."/users/".$user."/hapmaps/".$hapmap;
	}

	// Make a salt string and place it in project/genome/hapmap directory.
	$salt_string = bin2hex(random_bytes(16 / 2));
	file_put_contents($activePath."/salt.txt", $salt_string);

	return $salt_string;
}
function get_salt($user,$project,$genome,$hapmap) {
	// Clean up path to find install directory.
	$filePath = getcwd();
	$filePath = str_replace("/scripts_genomes_enhanced_annotations","",$filePath);
	$filePath = str_replace("/scripts_genomes","",$filePath);
	$filePath = str_replace("/scripts_seqModules","",$filePath);
	$filePath = str_replace("/scripts_SnpCghArray","",$filePath);
	$filePath = str_replace("/scripts_WGseq","",$filePath);
	$filePath = str_replace("/scripts_hapmaps","",$filePath);
	$filePath = str_replace("/scripts_ddRADseq","",$filePath);

	// Figure out which path it is we're working with.
	if (!empty($project)) {
		$activePath = $filePath."/users/".$user."/projects/".$project;
	} elseif (!empty($genome)) {
		$activePath = $filePath."/users/".$user."/genomes/".$genome;
	} elseif (!empty($hapmap)) {
		$activePath = $filePath."/users/".$user."/hapmaps/".$hapmap;
	}

	// Get existing salt string.
	if (file_exists($activePath."/salt.txt")) {
		$salt_string = trim(file_get_contents($activePath."/salt.txt"));
	} else {
		$salt_string = "[no salt]";
	}

	return $salt_string;
}
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
		chmod($log_file, 0666);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s');
	$line = $line.' - user:'.$user;

	// Salt defind during daemon processing.
	$salt_string = get_salt($user,$project,$genome,$hapmap);
	if (!empty($project)) {
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
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
		chmod($log_file, 0666);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s');
	$line = $line.' - user:'.$user;

	// Reset salt, as new process is initiated.
	$salt_string = make_salt($user,$project,$genome,$hapmap);
	if (!empty($project)) {
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
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
		chmod($log_file, 0666);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s');
	$line = $line.' - user:'.$user;

	// Salt defind during daemon processing.
	$salt_string = get_salt($user,$project,$genome,$hapmap);
	if (!empty($project)) {
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
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
		chmod($log_file, 0666);
	}

	// add comment to log file.
	$line = date('Y-m-d H:i:s');
	$line = $line.' - user:'.$user;

	// Salt defind during daemon processing.
	$salt_string = get_salt($user,$project,$genome,$hapmap);
	if (!empty($project)) {
		$line = $line.' - project:'.$project.' - '.$salt_string;
	} elseif (!empty($genome)) {
		$line = $line.' - genome:'.$genome.' - '.$salt_string;
	} elseif (!empty($hapmap)) {
		$line = $line.' - hapmap:'.$hapmap.' - '.$salt_string;
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

function deleteDirectory($dirPath) {
	// Check if the directory exists and is a directory
	if (!file_exists($dirPath) || !is_dir($dirPath)) {
		throw new InvalidArgumentException("Directory does not exist or is not a directory: $dirPath");
	}
	// Create recursive iterator to traverse the directory
	$iterator = new RecursiveIteratorIterator(
		new RecursiveDirectoryIterator($dirPath, RecursiveDirectoryIterator::SKIP_DOTS),
		RecursiveIteratorIterator::CHILD_FIRST // Process children before parents (files before dirs)
	);
	foreach ($iterator as $file) {
		if ($file->isDir()) {
			// Delete empty subdirectory
			if (!rmdir($file->getPathname())) {
				throw new RuntimeException("Failed to delete directory: " . $file->getPathname());
			}
		} else {
			// Delete file
			if (!unlink($file->getPathname())) {
				throw new RuntimeException("Failed to delete file: " . $file->getPathname());
			}
		}
	}
	// Delete the now-empty target directory
	if (!rmdir($dirPath)) {
		throw new RuntimeException("Failed to delete target directory: $dirPath");
	}
	return true;
}

?>
