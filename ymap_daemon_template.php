<?php
	//==========================================================================================
	// YMAP processing queue daemon setp:
	//------------------------------------------------------------------------------------------
BASE_DIR_temp

	require_once $script_directory.'constants.php';
	//require_once $script_directory.'sharedFunctions.php';

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
			$projects_init_list  = [];
			$projects_start_list = [];
			$projects_end_list   = [];

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
								$user            = str_replace("user:", "", $line_parts[1]);
								$project         = str_replace("project:", "", $line_parts[2]); // (or genome, or hapmap?).
								$salt            = $line_parts[3];
								$status          = $line_parts[4];

								$project_entry   = [];
								$project_entry[] = $time;
								$project_entry[] = $user;
								$project_entry[] = $project;
								$project_entry[] = $salt;
								$project_entry[] = $status;

								if ($status == "init") {
									$projects_init_list[] = $project_entry;
								} else if ($status == "start") {
									$projects_start_list[] = $project_entry;
								} else if ($status == "end") {
									$projects_end_list[] = $project_entry;
								}
							}
						}
					}
				}
			}
			$count_queue_done = sizeof($projects_end_list);

			// 2. Drop start/end entries from init queue list.
			foreach ($projects_start_list as $key1 => $project_start_entry) {
				$count = sizeof($projects_init_list);
				foreach (array_reverse($projects_init_list) as $key2 => $project_init_entry) {
					$start_user    = $project_start_entry[1];
					$start_project = $project_start_entry[2];
					$start_salt    = $project_start_entry[3];
					$init_user     = $project_init_entry[1];
					$init_project  = $project_init_entry[2];
					$init_salt     = $project_init_entry[3];
					if (($start_user == $init_user) && ($start_project == $init_project) && ($start_salt == $init_salt)) {
						$new_key = $count-$key2-1;
						array_splice($projects_init_list, $new_key, 1);
						break;
					}
				}
			}
			foreach ($projects_end_list as $key1 => $project_end_entry) {
				$count = sizeof($projects_init_list);
				foreach (array_reverse($projects_init_list) as $key2 => $project_init_entry) {
					$end_user     = $project_end_entry[1];
					$end_project  = $project_end_entry[2];
					$end_salt     = $project_end_entry[3];
					$init_user    = $project_init_entry[1];
					$init_project = $project_init_entry[2];
					$init_salt    = $project_init_entry[3];
					if (($end_user == $init_user) && ($end_project == $init_project) && ($end_salt == $init_salt)) {
						$new_key = $count-$key2-1;
						array_splice($projects_init_list, $new_key, 1);
						break;
					}
				}
			}
			$count_queue_initialized = sizeof($projects_init_list);
			//print_r($projects_start_list);

			// 3. Drop end entries from start queue list.
			foreach ($projects_end_list as $key1 => $project_end_entry) {
				$count = sizeof($projects_start_list);
				foreach (array_reverse($projects_start_list) as $key2 => $project_start_entry) {
					$end_user      = trim($project_end_entry[1]);
					$end_project   = trim($project_end_entry[2]);
					$end_salt      = trim($project_end_entry[3]);
					$start_user    = trim($project_start_entry[1]);
					$start_project = trim($project_start_entry[2]);
					$start_salt    = trim($project_start_entry[3]);
					if (($end_user == $start_user) && ($end_project == $start_project) && ($end_salt == $start_salt)) {
						$new_key = $count-$key2-1;
						//print_r($count." : ".$end_project."\t".$new_key."\n");
						array_splice($projects_start_list, $new_key, 1);
						break;
					}
				}
			}
			$count_queue_working = sizeof($projects_start_list);

			// 4. Drop active projects without a 'bulk.txt' file.
			$count = sizeof($projects_start_list);
			foreach (array_reverse($projects_start_list) as $key1 => $project_entry) {
				$user    = $project_entry[1];
				$project = $project_entry[2];
				$projectDirectory = $base_dir."/users/".$user."/projects/".$project."/";
				if (!file_exists($projectDirectory."bulk.txt")) {
					array_splice($projects_start_list, $count-$key1-1, 1);
				}
			}
			$count_queue_working = sizeof($projects_start_list);

			// 5. Delete old log files that are done.
			foreach ($queue_files as $key1 => $queue_file) {
				if ((str_contains($queue_file,".log")) && ($queue_file <> date('Y-m-d')."_queue.log")) {
					// Grap the init entries from this queue file.
					$oldprojects_init_list = [];
					$oldqueue_contents = trim(file_get_contents($queue_dir.$queue_file));
					if ($oldqueue_contents) {
						$outline = "";
						$oldqueue_lines = preg_split("/\R/", $oldqueue_contents);
						foreach($oldqueue_lines as $key2 => $oldline){
							$oldline_parts = explode(" - ",$oldline);
							if (sizeof($line_parts) >= 3) {
								$time            = $oldline_parts[0];
								$user            = str_replace("user:", "", $oldline_parts[1]);
								$project         = str_replace("project:", "", $oldline_parts[2]); // (or genome, or hapmap?).
								$salt            = $oldline_parts[3];
								$status          = $oldline_parts[4];

								$oldproject_entry   = [];
								$oldproject_entry[] = $time;
								$oldproject_entry[] = $user;
								$oldproject_entry[] = $project;
								$oldproject_entry[] = $salt;
								$oldproject_entry[] = $status;

								if ($status == "init") {
									$oldprojects_init_list[] = $oldproject_entry;
								}
							}
						}
					}

					// Remove any that match with done entries from any queue file.
					foreach ($projects_end_list as $key1 => $project_end_entry) {
						$count = sizeof($oldprojects_init_list);
						foreach (array_reverse($oldprojects_init_list) as $key2 => $oldproject_init_entry) {
							$end_user        = $project_end_entry[1];
							$end_project     = $project_end_entry[2];
							$end_salt        = $project_end_entry[3];
							$oldinit_user    = $oldproject_init_entry[1];
							$oldinit_project = $oldproject_init_entry[2];
							$oldinit_salt    = $oldproject_init_entry[3];
							if (($end_user == $oldinit_user) && ($end_project == $oldinit_project) && ($end_salt == $oldinit_salt)) {
								$new_key = $count-$key2-1;
								array_splice($oldprojects_init_list, $new_key, 1);
								break;
							}
						}
					}

					// If there are no entries left in {$oldprojects_init_list}, then delete the queue file.
					if (sizeof($oldprojects_init_list) == 0) {
						unlink($queue_dir.$queue_file);
					}
				}
			}


		//	//===========================================================
		//	// Temporary troubleshooting output.
		//	print_r("===================================================================\n");
		//	print_r("YMAPs initialized: ".$count_queue_initialized."\n");
		//	foreach ($projects_init_list as $key=>$value) {
		//		print_r("\t[{$key}] ".$value[2]);
		//		if (($key+1) % 7 == 0) {
		//			print_r("\n");
		//		} else {
		//			print_r("\t");
		//		}
		//	}
		//	if (sizeof($projects_init_list) > 0) {
		//		print_r("\n");
		//	}
		//	print_r("YMAPs processing:  ".$count_queue_working."\n");
		//	foreach ($projects_start_list as $key=>$value) {
		//		print_r("\t[{$key}] ".$value[2]);
		//		if (($key+1) % 7 == 0) {
		//			print_r("\n");
		//		} else {
		//			print_r("\t");
		//		}
		//	}
		//	if (sizeof($projects_start_list) > 0) {
		//		print_r("\n");
		//	}
		//	print_r("YMAPs complete:    ".$count_queue_done."\n");
		//	//print_r($projects_start_list);
		//	//print_r($projects_end_list);
		//	//-----------------------------------------------------------


			// 5. Fire off YMAP processes.
			if (($count_queue_working < $MAX_QUEUE_PARALLEL) && ($count_queue_initialized >= 1)) {
				//=============================
				// Call YMAP processes.
				//-----------------------------
				$user    = $projects_init_list[0][1];
				$project = $projects_init_list[0][2];

				//print_r($user.":".$project."\n");

				$project_dir   = $base_dir."/users/".$user."/projects/".$project."/";
				if (is_dir($project_dir)) {
					// Construct filename string from 'datafiles.txt' file.
					if (file_exists($project_dir."datafiles.txt")) {
						$filename_string = trim(file_get_contents($project_dir."datafiles.txt"));
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
					if (file_exists($project_dir."dataFormat.txt")) {
						$dataformat_string = file_get_contents($project_dir."/dataFormat.txt");
					}
					$dataformat_lines  = preg_split("/:/", $dataformat_string);

					if ((int)$dataformat_lines[1] == 0) {
						$dataFormat = "WGseq_single";
					} else {
						$dataFormat = "WGseq_paired";
					}
					$projectDirectory = $base_dir."/users/".$user."/projects/".$project."/";
					project_process($base_dir,$user,$project,$dataFormat,$fileName,$projectDirectory);
					log_stuff($user,$project,"","","","YMAP_daemon:SUCCESS Dataset processing initiated.");
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
	function project_process($base_dir,$user,$project,$dataFormat,$fileName,$projectDirectory) {
		if ((!file_exists($projectDirectory."working.txt")) && (!file_exists($projectDirectory."complete.txt"))) {
			// Set session variables.
			$_SESSION['user']       = $user;
			$_SESSION['fileName']   = $fileName;
			$_SESSION['project']    = $project;
			$key = "1";
			$_SESSION['key']        = $key;		// to be removed later once everything is processed through queue.

			// Initiate project processing.
			if (!file_exists($projectDirectory."update.txt")) {
				//print_r("Init process.\n");
				// Start an initial YMAP process.
				switch ($dataFormat) {
					case "WGseq_single":
						$conclusion_script = "php project.single_WGseq.install_1.php";
						break;
					case "WGseq_paired":
						$conclusion_script = "php project.paired_WGseq.install_1.php";
						break;
				}
				$command_string  = $user." ".$fileName." ".$project." ".$key;
			} else {
				//print_r("Update process.\n");
				// Start an update YMAP process.
				//$conclusion_script = "bash project.WGseq.update_2.sh";
				$conclusion_script = "php project.WGseq.update_1.php";
				$command_string  = $user." ".$project;
			}
			// Run processing script.
			chdir($base_dir."/scripts_seqModules/scripts_WGseq/");
			exec($conclusion_script." ".$command_string." > /dev/null &");
			chdir($base_dir);
		}
	}
?>
