<?php
	session_start();
	$calledBy = php_sapi_name();
	//==========================================================================================
	// YMAP processing queue status
	//------------------------------------------------------------------------------------------

	require_once 'constants.php';
	require_once 'sharedFunctions.php';

	// 0. Initialize projects list.
	$init_list  = [];
	$start_list = [];
	$end_list   = [];

	// 1. Grab init/start/end project entries from queue logs.
	$queue_dir   = $base_dir."/queue/";
	$queue_files = array_slice(scandir($queue_dir), 2);
	foreach ($queue_files as $key1 => $queue_file) {
		if (str_contains($queue_file,".log")) {
			$queue_contents = trim(file_get_contents($queue_dir.$queue_file));
			if ($queue_contents) {
				$outline = "";
				$queue_lines = preg_split("/\R/", $queue_contents);
				foreach($queue_lines as $key2 => $line){
					$line_parts = explode(" - ",$line);
					if (sizeof($line_parts) >= 3) {
						$time            = $line_parts[0];
						$user            = str_replace("user:", "", $line_parts[1]);
						if (str_contains($line_parts[2], "project:")) {
							$name      = str_replace("project:", "", $line_parts[2]);
							$entryType = "project";
						} elseif (str_contains($line_parts[2], "genome:")) {
							$name  = str_replace("genome:", "", $line_parts[2]);
							$entryType = "genome";
						} elseif (str_contains($line_parts[2], "hapmap:")) {
							$name  = str_replace("hapmap:", "", $line_parts[2]);
							$entryType = "hapmap";
						} else {
							// Unrecognized queue entry.
						}
						$salt            = $line_parts[3];
						$status          = $line_parts[4];

						$entry   = [];
						$entry[] = $time;
						$entry[] = $user;
						$entry[] = $name;
						$entry[] = $salt;
						$entry[] = $status;
						$entry[] = $entryType;

						if ($status == "init") {
							$init_list[] = $entry;
						} else if ($status == "start") {
							$start_list[] = $entry;
						} else if ($status == "end") {
							$end_list[] = $entry;
						}
					}
				}
			}
		}
	}
	$count_queue_done = sizeof($end_list);

	// 2. Drop start/end entries from init queue list.
	foreach ($start_list as $key1 => $start_entry) {
		$count = sizeof($init_list);
		foreach (array_reverse($init_list) as $key2 => $init_entry) {
			$start_user    = $start_entry[1];
			$start_name    = $start_entry[2];
			$start_salt    = $start_entry[3];
			$init_user     = $init_entry[1];
			$init_name     = $init_entry[2];
			$init_salt     = $init_entry[3];
			if (($start_user == $init_user) && ($start_name == $init_name) && ($start_salt == $init_salt)) {
				$new_key = $count-$key2-1;
				array_splice($init_list, $new_key, 1);
				break;
			}
		}
	}
	foreach ($end_list as $key1 => $end_entry) {
		$count = sizeof($init_list);
		foreach (array_reverse($init_list) as $key2 => $init_entry) {
			$end_user     = $end_entry[1];
			$end_name     = $end_entry[2];
			$end_salt     = $end_entry[3];
			$init_user    = $init_entry[1];
			$init_name    = $init_entry[2];
			$init_salt    = $init_entry[3];
			if (($end_user == $init_user) && ($end_name == $init_name) && ($end_salt == $init_salt)) {
				$new_key = $count-$key2-1;
				array_splice($init_list, $new_key, 1);
				break;
			}
		}
	}
	$count_queue_initialized = sizeof($init_list);
	//print_r($start_list);

	// 3. Drop end entries from start queue list.
	foreach ($end_list as $key1 => $end_entry) {
		$count = sizeof($start_list);
		foreach (array_reverse($start_list) as $key2 => $start_entry) {
			$end_user      = trim($end_entry[1]);
			$end_name      = trim($end_entry[2]);
			$end_salt      = trim($end_entry[3]);
			$start_user    = trim($start_entry[1]);
			$start_name    = trim($start_entry[2]);
			$start_salt    = trim($start_entry[3]);
			if (($end_user == $start_user) && ($end_name == $start_name) && ($end_salt == $start_salt)) {
				$new_key = $count-$key2-1;
				array_splice($start_list, $new_key, 1);
				break;
			}
		}
	}
	$count_queue_working = sizeof($start_list);

	// 4. Drop active projects/genomes/hapmaps without a 'bulk.txt' file.
	$count = sizeof($start_list);
	foreach (array_reverse($start_list) as $key1 => $entry) {
		$user      = $entry[1];
		$entryType = $entry[5];
		$name      = $entry[2];
		if ($entryType == "project") {
			$Directory = $base_dir."/users/".$user."/projects/".$name."/";
			if (!file_exists($Directory."bulk.txt")) {
				array_splice($start_list, $count-$key1-1, 1);
			}
		} elseif ($entryType == "genome") {
			$Directory = $base_dir."/users/".$user."/genomes/".$name."/";
			if (!file_exists($Directory."bulk.txt")) {
				array_splice($start_list, $count-$key1-1, 1);
			}
		} elseif ($entryType == "hapmap") {
			$Directory = $base_dir."/users/".$user."/hapmaps/".$name."/";
			if (!file_exists($Directory."bulk.txt")) {
				array_splice($start_list, $count-$key1-1, 1);
			}
		} else {
			// Something went wrong.
		}
	}
	$count_queue_working = sizeof($start_list);

	if ($calledBy === "cli") {
		//===========================================================
		//
		// Called by commandline.
		//	Output nicely formated text for commandline interface.
		//
		//===========================================================
		print_r("#\tYMAPs initialized: ".$count_queue_initialized."\n#\t\t");
		$stringLength = 0;
		foreach ($init_list as $key=>$value) {
			$key_   = $key+1;
			$user   = $value[1];
			$name   = $value[2];
			$type   = $value[5];
			$string = "[{$key_}] ".$user.":".$type.":".$name;
			print_r($string);
			$stringLength += strlen($string);
			if ($stringLength > 80) {
				print_r("\n#\t\t");
				$stringLength = 0;
			} else {
				print_r("\t");
			}
		}
		if (sizeof($init_list) > 0) {
			print_r("\n");
		}
		print_r("#\n#\tYMAPs processing:  ".$count_queue_working."\n#\t\t");
		foreach ($start_list as $key=>$value) {
			$key_ = $key+1;
			$user = $value[1];
			$name = $value[2];
			$type = $value[5];

			if ($type == "project") {	$file = $main_dir."/users/".$user."/projects/".$name."/condensed_log.txt";
			} elseif ($type == "genome") {	$file = $main_dir."/users/".$user."/genomes/".$name."/condensed_log.txt";
			} elseif ($type == "hapmap") {	$file = $main_dir."/users/".$user."/hapmaps/".$name."/condensed_log.txt";
			} else {
				// Something went wrong.
			}
			$data = file($file);
			$line = trim($data[count($data)-1]);
			print_r("[{$key_}] ".$user.":".$type.":".$name." = \e[33m'".$line."'\e[0m");
			if (($key+1) % 1 == 0) {
				print_r("\n#\t\t");
			} else {
				print_r("\t");
			}
		}
		print_r("\n#\tYMAPs complete:    ".$count_queue_done."\n");
	} else {
		//===========================================================
		//
		// Called by web server.
		//	Output simple string with initialized and started counts for web interface.
		//
		//===========================================================
		$queue_status_init  = count($init_list);
		$queue_status_start = count($start_list);
	}
?>
