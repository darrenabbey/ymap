<?php
	//==========================================================================================
	// YMAP processing queue daemon, with signal handling.
	//	from example at: https://www.funwithlinux.net/blog/run-php-script-as-daemon-process/
	//------------------------------------------------------------------------------------------
	require_once 'constants.php';
	require_once 'sharedFunctions.php';

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
		error_log("Received shutdown signal ({$signal}). Cleaning up...");
	}

	/**
	 * Signal handler for SIGHUP (reload configuration)
	 */
	function handleReload($signal) {
		error_log("Received SIGHUP (reload signal). Reloading config...");
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
			//print_r($projects_init_list);
			//print_r($projects_start_list);
			//print_r($projects_end_list);

			// 2. Cleanup queue log files.
			foreach ($queue_files as $key1 => $queue_file) {
				if (str_contains($queue_file,".log")) {
				}
			}

			// 2. Drop end entries from start queue list.
			foreach ($projects_end_list as $key1 => $project_end_entry) {
				$count = sizeof($projects_init_list);
				foreach (array_reverse($projects_start_list) as $key2 => $project_start_entry) {
					$end_user      = $project_end_entry[1];
					$end_project   = $project_end_entry[2];
					$end_salt      = $project_end_entry[3];
					$start_user    = $project_start_entry[1];
					$start_project = $project_start_entry[2];
					$start_salt    = $project_start_entry[3];
					if (($end_user == $start_user) && ($end_project == $start_project) && ($end_salt == $start_salt)) {
						array_splice($projects_start_list, $count-$key2-1, 1);
					}
				}
			}
			$count_bulk_working = sizeof($projects_start_list);

			// 3. Drop start/end entries from init queue list.
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
						array_splice($projects_init_list, $count-$key2-1, 1);
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
						array_splice($projects_init_list, $count-$key2-1, 1);
					}
				}
			}
			$count_bulk_initalized = sizeof($projects_init_list);
			//print_r($projects_init_list);

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
			print_r($projects_init_list);
			$count_bulk_working = sizeof($projects_start_list);

			// 5. Fire off YMAP processes.
			if (($count_bulk_working < $MAX_BULK_PARALLEL) && (sizeof($projects_init_list) >= 1)) {
				//=============================
				// Call YMAP processes.
				//-----------------------------
				$user    = $projects_init_list[0][1];
				$project = $projects_init_list[0][2];

				$project_dir   = $base_dir."/users/".$user."/projects/".$project."/";

				// Construct filename string from 'datafiles.txt' file.
				$filename_string = trim(file_get_contents($project_dir."datafiles.txt"));
				$filename_lines  = preg_split("/\r\n|\n|\r/", $filename_string);

				if (sizeof($filename_lines) == 2) {
					$filename1 = $filename_lines[0];
					$filename2 = $filename_lines[1];
					$fileName  = $filename1.",".$filename2;
				} else {
					$fileName  = $filename_lines[0];
				}

				// Construct dataformat string from 'dataFormat.txt' file.
				$dataformat_string = file_get_contents($project_dir."/dataFormat.txt");
				$dataformat_lines  = preg_split("/:/", $dataformat_string);

				if ((int)$dataformat_lines[1] == 0) {
					$dataFormat = "WGseq_single";
				} else {
					$dataFormat = "WGseq_paired";
				}
				$projectDirectory = $base_dir."/users/".$user."/projects/".$project."/";
				project_process($user,$project,$dataFormat,$fileName,$projectDirectory);
				//$count_bulk_working += 1;

				log_stuff($user,$project,"","","","YMAP_daemon:SUCCESS Dataset processing initiated.");
			}

			// Sleep for 10 seconds to keep daemon from running continuously.
			sleep(10);

		} catch (Exception $e) {
			// Log errors but continue running
			error_log("Error: " . $e->getMessage() . " (Line: " . $e->getLine() . ")");
			sleep(5); // Avoid spamming logs on repeated errors
		}
	}

	// Cleanup code (e.g., close database connections, save state)
	error_log("YMAP daemon stopped successfully.");


	// Function to initiate and release a YMAP thread to process data for a project.
	function project_process($user,$project,$dataFormat,$fileName,$projectDirectory) {
		if ((!file_exists($projectDirectory."working.txt")) && (!file_exists($projectDirectory."complete.txt"))) {
			// Set session variables.
			$_SESSION['user']       = $user;
			$_SESSION['fileName']   = $fileName;
			$_SESSION['project']    = $project;
			$key = "1";
			$_SESSION['key']        = $key;		// to be removed later once everything is processed through queue.

			// Set string to pass via commandline.
			$command_string  = $user." ".$fileName." ".$project." ".$key;

			// Initiate project processing.
			$conclusion_script = "";
			switch ($dataFormat) {
				case "WGseq_single":
					$conclusion_script = "project.single_WGseq.install_1.php";
					break;
				case "WGseq_paired":
					$conclusion_script = "project.paired_WGseq.install_1.php";
					break;
			}

			// Run processing script.
			chdir("scripts_seqModules/scripts_WGseq/");
			exec("php ".$conclusion_script." ".$command_string." > /dev/null &");
			chdir("../../");
		}
	}
?>
