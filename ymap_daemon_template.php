<?php
ini_set('memory_limit', '5M');
	//==========================================================================================
	// YMAP processing queue daemon setp:
	//------------------------------------------------------------------------------------------
BASE_DIR_temp

	$visualOutput = false;

	require_once $script_directory.'constants.php';
	require_once $script_directory.'sharedFunctions.php';

	// Enable signal handling (required for pcntl functions)
	declare(ticks=1);

	// Flag to control the main loop
	$running = true;

	/**
	 * Signal handler for SIGTERM and SIGINT (graceful shutdown)
	 */
	function handleShutdown($signal) {
		global $running;
		$running = false;
		error_log("Received shutdown signal ({$signal}). Cleaning up...", 0, "/var/log/ymap_daemon.log");
	}

	/**
	 * Signal handler for SIGHUP (reload configuration)
	 */
	function handleReload($signal) {
		error_log("Received SIGHUP (reload signal). Reloading config...", 0, "/var/log/ymap_daemon.log");
		// Add logic to reload config files here
	}

	// Register signal handlers
	pcntl_signal(SIGTERM, 'handleShutdown'); // Termination signal (kill)
	pcntl_signal(SIGINT, 'handleShutdown');  // Interrupt signal (Ctrl+C)
	pcntl_signal(SIGHUP, 'handleReload');    // Hangup signal (reload)

	// Main daemon loop
	while ($running) {
		try {
			// --------------------------------------------------
			// YOUR TASK HERE (e.g., process data, monitor files)
			// --------------------------------------------------
			// 0. Initialize projects list.
			$init_list  = [];
			$start_list = [];
			$end_list   = [];

			// 0. Check if queue is paused or not.
			if (is_file($base_dir."/queue/error.txt")) {
				$SUPER_ONLY = True;
			} else {
				$SUPER_ONLY = False;
			}

			// 1. Grab init/start/end project entries from queue logs.
			$queue_dir   = $base_dir."/queue/";
			$queue_files = array_slice(scandir($queue_dir), 2);
			foreach ($queue_files as $key1 => $queue_file) {
				if (str_contains($queue_file,".log")) {
					$queue_contents = trim(file_get_contents($queue_dir.$queue_file));
					if ($queue_contents) {
						// Queue contents example:
						//	2026-05-08 00:08:15 - user:darrenFY - project:TJ4771_R1_clean - b1be4a21a5e6f7a1 - init - from: project_bulk.create_server.php
						//	2026-05-08 00:08:15 - user:darrenFY - project:TJ4772_R1_clean - c75617867d1e1356 - init - from: project_bulk.create_server.php
						//	2026-05-08 00:08:15 - user:darrenFY - project:TJ4773_R1_clean - 9537892444c7e1c4 - init - from: project_bulk.create_server.php
						$outline = "";
						$queue_lines = preg_split("/\R/", $queue_contents);
						foreach($queue_lines as $key2 => $line){
							$line_parts = explode(" - ",$line);
							if (sizeof($line_parts) >= 3) {
								$time            = $line_parts[0];
								$userName        = str_replace("user:", "", $line_parts[1]);
								if (str_contains($line_parts[2], "project:")) {
									$entryName = str_replace("project:", "", $line_parts[2]);
									$entryType = "project";
								} elseif (str_contains($line_parts[2], "genome:")) {
									$entryName = str_replace("genome:", "", $line_parts[2]);
									$entryType = "genome";
								} elseif (str_contains($line_parts[2], "hapmap:")) {
									$entryName  = str_replace("hapmap:", "", $line_parts[2]);
									$entryType = "hapmap";
								} else {
									// Unrecognized queue entry.
								}
								$salt            = $line_parts[3];
								$status          = $line_parts[4];

								$entry   = [];
								$entry[] = $time;
								$entry[] = $userName;
								$entry[] = $entryName;
								$entry[] = $salt;
								$entry[] = $status;
								$entry[] = $entryType;

								if ($status == "init") {
									if ($SUPER_ONLY == True) {
										if (is_file($base_dir."/users/".$userName."/super.txt")) {
											$init_list[] = $entry;
										}
									} else {
										$init_list[] = $entry;
									}
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
				$userName  = $entry[1];
				$entryType = $entry[5];
				$entryName = $entry[2];
				if ($entryType == "project") {
					$Directory = $base_dir."/users/".$userName."/projects/".$entryName."/";
					if (!file_exists($Directory."bulk.txt")) {
						array_splice($start_list, $count-$key1-1, 1);
					}
				} elseif ($entryType == "genome") {
					$Directory = $base_dir."/users/".$userName."/genomes/".$entryName."/";
					if (!file_exists($Directory."bulk.txt")) {
						array_splice($start_list, $count-$key1-1, 1);
					}
				} elseif ($entryType == "hapmap") {
					$Directory = $base_dir."/users/".$userName."/hapmaps/".$entryName."/";
					if (!file_exists($Directory."bulk.txt")) {
						array_splice($start_list, $count-$key1-1, 1);
					}
				} else {
					// Something went wrong.
				}
			}
			$count_queue_working = sizeof($start_list);

			// 5. Delete old log files that are done.
			foreach ($queue_files as $key1 => $queue_file) {
				if ((str_contains($queue_file,".log")) && ($queue_file <> date('Y-m-d')."_queue.log")) {
					// Grap the init entries from this queue file.
					$oldinit_list = [];
					$oldqueue_contents = trim(file_get_contents($queue_dir.$queue_file));
					if ($oldqueue_contents) {
						$outline = "";
						$oldqueue_lines = preg_split("/\R/", $oldqueue_contents);
						foreach($oldqueue_lines as $key2 => $oldline){
							$oldline_parts = explode(" - ",$oldline);
							if (sizeof($line_parts) >= 3) {
								$time            = $oldline_parts[0];
								$userName        = str_replace("user:", "", $oldline_parts[1]);

								if (str_contains($oldline_parts[2], "project:")) {
									$entryName = str_replace("project:", "", $oldline_parts[2]);
									$entryType = "project";
								} elseif (str_contains($oldline_parts[2], "genome:")) {
									$entryName = str_replace("genome:", "", $oldline_parts[2]);
									$entryType = "genome";
								} elseif (str_contains($oldline_parts[2], "hapmap:")) {
									$entryName = str_replace("hapmap:", "", $oldline_parts[2]);
									$entryType = "hapmap";
								} else {
									// Something went wrong.
								}

								$salt            = $oldline_parts[3];
								$status          = $oldline_parts[4];

								$oldentry   = [];
								$oldentry[] = $time;
								$oldentry[] = $userName;
								$oldentry[] = $entryName;
								$oldentry[] = $salt;
								$oldentry[] = $status;

								if ($status == "init") {
									$oldinit_list[] = $oldentry;
								}
							}
						}
					}

					// Remove any that match with done entries from any queue file.
					foreach ($end_list as $key1 => $end_entry) {
						$count = sizeof($oldinit_list);
						foreach (array_reverse($oldinit_list) as $key2 => $oldinit_entry) {
							$end_user        = $end_entry[1];
							$end_name        = $end_entry[2];
							$end_salt        = $end_entry[3];
							$oldinit_user    = $oldinit_entry[1];
							$oldinit_name    = $oldinit_entry[2];
							$oldinit_salt    = $oldinit_entry[3];
							if (($end_user == $oldinit_user) && ($end_name == $oldinit_name) && ($end_salt == $oldinit_salt)) {
								$new_key = $count-$key2-1;
								array_splice($oldinit_list, $new_key, 1);
								break;
							}
						}
					}

					// If there are no entries left in {$oldinit_list}, then delete the queue file.
					if (sizeof($oldinit_list) == 0) {
						unlink($queue_dir.$queue_file);
					}
				}
			}


			//===========================================================
			if ($visualOutput == true) {
				print_r("===================================================================\n");
				print_r("YMAPs initialized: ".$count_queue_initialized."\n");
				foreach ($init_list as $key=>$value) {
					print_r("\t[{$key}] ".$value[5].":".$value[2]);
					if (($key+1) % 7 == 0) {
						print_r("\n");
				} else {
						print_r("\t");
					}
				}
				if (sizeof($init_list) > 0) {
					print_r("\n");
				}
				print_r("YMAPs processing:  ".$count_queue_working."\n");
				foreach ($start_list as $key=>$value) {
					print_r("\t[{$key}] ".$value[5].":".$value[2]);
					if (($key+1) % 7 == 0) {
						print_r("\n");
					} else {
						print_r("\t");
					}
				}
				if (sizeof($start_list) > 0) {
					print_r("\n");
				}
				print_r("YMAPs complete:    ".$count_queue_done."\n");
				//print_r($start_list);
				//print_r($end_list);
			}
			//===========================================================


			// 5. Fire off YMAP processes.
			if (($count_queue_working < $MAX_QUEUE_PARALLEL) && ($count_queue_initialized >= 1)) {
				//=============================
				// Call YMAP processes.
				//-----------------------------
				// Grab the first entry from the init list.
				$userName  = $init_list[0][1];
				$entryName = $init_list[0][2];
				$entryType = $init_list[0][5];

				//print_r($userName.":".$entryName.":".$entryType."\n");

				if ($entryType == "project") {
					$dir  = $base_dir."users/".$userName."/projects/".$entryName."/";
				} elseif ($entryType == "genome") {
					$dir   = $base_dir."users/".$userName."/genomes/".$entryName."/";
				} elseif ($entryType == "hapmap") {
					$dir   = $base_dir."users/".$userName."/hapmaps/".$entryName."/";
				}
				//print_r("# ".$dir."\n");
				if (is_dir($dir)) {
					if ($entryType == "project") {
						// Construct filename string from 'datafiles.txt' file.
						if (file_exists($dir."datafiles.txt")) {
							$filename_string = trim(file_get_contents($dir."datafiles.txt"));
							$filename_lines  = preg_split("/\r\n|\n|\r/", $filename_string);

							if (sizeof($filename_lines) == 2) {
								$filename1 = $filename_lines[0];
								$filename2 = $filename_lines[1];
								$fileName  = $filename1.",".$filename2;
							} else {
								$fileName  = $filename_lines[0];
							}
						} else {
							$fileName = "";
						}

						// Construct dataformat string from 'dataFormat.txt' file.
						if (file_exists($dir."dataFormat.txt")) {
							$dataformat_string = file_get_contents($dir."/dataFormat.txt");
						}
						$dataformat_lines  = preg_split("/:/", $dataformat_string);

						if ((int)$dataformat_lines[1] == 0) {
							$dataFormat = "WGseq_single";
						} else {
						 	$dataFormat = "WGseq_paired";
						}
						project_process($base_dir,$userName,$entryName,$dataFormat,$fileName,$dir);
					} elseif ($entryType == "genome") {
						//print_r("# ".$userName.":".$entryName.":".$entryType." trying to start.\n");
						genome_process($base_dir,$userName,$entryName,$dir);
					} elseif ($entryType == "hapmap") {
					} else {
						// Something went wrong.
					}
				}
			}

			// Force garbage collection;
			gc_collect_cycles();

			// Sleep for 10 seconds to keep daemon from running continuously.
			sleep(10);

		} catch (Exception $e) {
			// Force garbage collection;
			gc_collect_cycles();

			// Log errors but continue running
			error_log("Error: " . $e->getMessage() . " (Line: " . $e->getLine() . ")", 0, "/var/log/ymap_daemon.log");
			sleep(5); // Avoid spamming logs on repeated errors
		}
	}

	// Cleanup code (e.g., close database connections, save state)
	error_log("YMAP daemon stopped successfully.", 0, "/var/log/ymap_daemon.log");


	// Function to initiate and release a YMAP thread to process data for a project.
	function project_process($base_dir,$userName,$entryName,$dataFormat,$fileName,$Directory) {
		if ((!file_exists($Directory."working.txt")) && (!file_exists($Directory."complete.txt"))) {
			// Set session variables.
			$_SESSION['user']       = $userName;
			$_SESSION['fileName']   = $fileName;
			$_SESSION['project']    = $entryName;
			$key = "1";
			$_SESSION['key']        = $key;		// to be removed later once everything is processed through queue?

			// Initiate project processing.
			if (!file_exists($Directory."update.txt")) {
				// Start an initial YMAP process.
				switch ($dataFormat) {
					case "WGseq_single":
						$conclusion_script = "php project.single_WGseq.install_1.php";
						break;
					case "WGseq_paired":
						$conclusion_script = "php project.paired_WGseq.install_1.php";
						break;
				}
				$command_string  = $userName." ".$fileName." ".$entryName." ".$key;
			} else {
				// Start an update YMAP process.
				$conclusion_script = "php project.WGseq.update_1.php";
				$command_string  = $userName." ".$entryName;
			}
			// Run processing script.
			chdir($base_dir."/scripts_seqModules/scripts_WGseq/");
			$salt_string = get_salt($userName,$entryName,'','');
			exec($conclusion_script." ".$command_string." > /dev/null 2> ".$Directory."/process_log.txt &");
			chdir($base_dir);
			queue_start($userName,$entryName,"","","from: ymap_daemon");
			log_stuff($userName,$entryName,"","",$salt_string,"YMAP_daemon:SUCCESS project started.");
		}
	}
	function genome_process($base_dir,$userName,$entryName,$Directory) {
		//print_r("# testpoint1: ".$Directory."\n");
		if ((!file_exists($Directory."working3.txt")) && (!file_exists($Directory."working_done.txt"))) {
			//print_r("# testpoint2\n");
			// Set session variables.
			$_SESSION['user']       = $userName;
			$_SESSION['genome']     = $entryName;
			$key = "1";
			$_SESSION['key']        = $key;         // to be removed later once everything is processed through queue?

			// Generate 'working3.txt' to tell main page that genome installation is in process.
			$outputName      = $Directory."working3.txt";
			$output          = fopen($outputName, 'w');
			$startTimeString = date("Y-m-d H:i:s");
			fwrite($output, $startTimeString);
			fclose($output);

			// Initiate genome processing.
			if (!file_exists($Directory."update.txt")) {
				// Start an initial YMAP process.
				$conclusion_script = "php genome.install_5.php";
				$command_string  = $userName." ".$entryName;
			} else {
				// Start an update YMAP process.
				$conclusion_script = ""; //"php genome.update_1.php";
				$command_string  = $userName." ".$entryName;
			}
			// Run processing script.
			chdir($base_dir."/scripts_genomes/");
			$salt_string = get_salt($userName,'',$entryName,'');
			exec($conclusion_script." ".$command_string." > /dev/null 2> ".$Directory."/process_log.txt &");
			chdir($base_dir);
			queue_start($userName,"",$entryName,"","from: ymap_daemon");
			log_stuff($userName,"",$entryName,"",$salt_string,"YMAP_daemon:SUCCESS genome started.");
		}
	}
	function hapmap_process($base_dir,$userName,$hapmap,$dataFormat,$fileName,$hapmapDirectory) {
		log_stuff($userName,"","",$hapmap,"","YMAP_daemon:SUCCESS hapmap started.");
	}
?>
