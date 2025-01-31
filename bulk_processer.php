<?php
	//======================================================
	// To run php script, but don't wait for it to conclude:
	//	exec("php script.php > /dev/null &");
	//------------------------------------------------------

	if (!isset($_SERVER["HTTP_HOST"])) {
		//=============================
		// Script run from commandline.
		//-----------------------------
		error_reporting(E_ALL);
		require_once 'constants.php';
		require_once 'sharedFunctions.php';
		require_once 'POST_validation.php';
		ini_set('display_errors', 1);

		// php bulk_processer.php user=[user] ymaps=[number]
		if (isset($argv[1])) {
			parse_str($argv[1], $output1);
			if (isset($output1['user'])) {
				$user           = $output1['user'];
			} else {
				$user = '';
				$YMAP_instances = "";
				echo "*-------------------------*\n";
				echo "| YMAP command-line tool. |\n";
				echo "*------------------------------------*------------------------------------------------------*\n";
				echo "| Use : php bulk_processer.php user=[user] ymaps=[number] > /dev/null 2>&1 &                |\n";
				echo "|    To run bulk process manager, but not output stdout.                                    |\n";
				echo "|        user  = YMAP user account.                                                         |\n";
				echo "|        ymaps = number of datasets to run at once. (optional)                              |\n";
				echo "*-------------------------------------------------------------------------------------------*\n";
				exit;
			}

			if (isset($argv[2])) {
				parse_str($argv[2], $output2);
				if (isset($output2['ymaps'])) {
					$YMAP_instances = $output2['ymaps'];
				} else {
					$YMAP_instances = $MAX_BULK_PARALLEL;
				}
			} else {
				$YMAP_instances = $MAX_BULK_PARALLEL;
			}
		} else {
			$user = "";
			$YMAP_instances = "";
			echo "*-------------------------*\n";
			echo "| YMAP command-line tool. |\n";
			echo "*------------------------------------*------------------------------------------------------*\n";
			echo "| Use : php bulk_processer.php user=[user] ymaps=[number] > /dev/null 2>&1 &                |\n";
			echo "|    To run bulk process manager, but not output stdout.                                    |\n";
			echo "|        user  = YMAP user account.                                                         |\n";
			echo "|        ymaps = number of datasets to run at once. (optional)                              |\n";
			echo "*-------------------------------------------------------------------------------------------*\n";
			exit;
		}
		$YMAP_instances = (int)$YMAP_instances;
		echo $user."\n".$YMAP_instances."\n";
	} else {
		//===============================
		// Script run from web interface.
		//-------------------------------
		session_start();
		error_reporting(E_ALL);
		require_once 'constants.php';
		require_once 'sharedFunctions.php';
		require_once 'POST_validation.php';
		ini_set('display_errors', 1);

		// If the user is not logged on, redirect to login page.
		if(!isset($_SESSION['logged_on'])){
			session_destroy();
			header('Location: .');
		}
		if(isset($_SESSION['user'])) {
			$user           = $_SESSION['user'];
		} else {
			session_destroy();
			header('Location: .');
		}

		$YMAP_instances = $MAX_BULK_PARALLEL;
	}

	//==================================================================================================
	// This script is intended to manage a bulk data queue, limiting YMAP processes to a certain number.
	//--------------------------------------------------------------------------------------------------

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		$admin_user_flag_file = "users/".$user."/admin.txt";
		if (file_exists($admin_user_flag_file)) {
			// setup log file.
			$logOutputName = "users/".$user."/bulksettings/process_log.txt";
			$logOutput     = fopen($logOutputName, 'w');
			fwrite($logOutput, "Log file initialized.\n");

			// pull project list from projects directory.
			$projects_dir  = "users/".$user."/projects/";
			$project_dirs  = scandir($projects_dir);

			// Remove '.' and '..' from scandir results.
			unset($project_dirs[0]);
			unset($project_dirs[1]);
			$project_dirs_temp = array_values($project_dirs);
			$project_dirs = $project_dirs_temp;


			// Remove 'index.php' file from scandir results.
			if (file_exists("users/".$user."/bulkdata/index.php")) {
				$key = array_search("index.php", $project_dirs);
				unset($project_dirs[$key]);
				$project_dirs_temp = array_values($project_dirs);
				$project_dirs = $project_dirs_temp;
			}

			// Trim list to only projects which contain 'bulk.txt' file.
			foreach ($project_dirs as $key => $project) {
				if (!file_exists($projects_dir.$project."/bulk.txt")) {
					unset($project_dirs[$key]);
				}
			}

			// _Count projects with 'bulk.txt' and 'working.txt'.
			$count_bulk_working = 0;
			foreach ($project_dirs as $key => $project) {
				if (file_exists($projects_dir.$project."/working.txt")) {
					$count_bulk_working += 1;
				}
			}

			// Count projects with 'bulk.txt' and 'complete.txt'.
			$count_bulk_complete = 0;
			foreach ($project_dirs as $key => $project) {
				if (file_exists($projects_dir.$project."/complete.txt")) {
					$count_bulk_complete += 1;
				}
			}

			// Calculate projects remaining to be done.
			$count_bulk_remaining = 0;
                        foreach ($project_dirs as $key => $project) {
				if (!file_exists($projects_dir.$project."/working.txt") && !file_exists($projects_dir.$project."/complete.txt")) {
                                        $count_bulk_remaining += 1;
                                }
                        }


			//=============================================================================================
			// Loop over bulk dataset project directories, firing off new procssess until they're all done.
			//---------------------------------------------------------------------------------------------
			while ($count_bulk_remaining > 0) {
				log_stuff($user,"","","","","[1a] bulk:TEST bulk_processer.php while loop.");
				// Count projects with 'working.txt'.
				$count_bulk_working = 0;
				foreach ($project_dirs as $key => $project) {
					if (file_exists($projects_dir.$project."/working.txt")) {
						$count_bulk_working += 1;
					}
				}

				// Main process loop.
				foreach ($project_dirs as $key => $project) {
					log_stuff($user,"","","","","[2] bulk:TEST bulk_processer.php main process loop.");
					if ($count_bulk_working < $YMAP_instances) {

						if (!file_exists($projects_dir.$project."/working.txt") && !file_exists($projects_dir.$project."/complete.txt")) {
							//=============================
							// Call YMAP processes.
							//-----------------------------
							$project = $project_dirs[$key];
							fwrite($logOutput, "processing: ".$project."\n");

							// Construct filename string from 'datafiles.txt' file.
							$filename_string = file_get_contents($projects_dir.$project_dirs[$key]."/datafiles.txt");
							$filename_lines  = preg_split("/\r\n|\n|\r/", $filename_string);
							if (sizeof($filename_lines) == 3) {
								$filename1 = $filename_lines[0];
								$filename2 = $filename_lines[2];
								$fileName  = $filename1.",".$filename2;
							} else {
								$fileName  = $filename_lines[0];
							}

							// Construct dataformat string from 'dataFormat.txt' file.
							$dataformat_string = file_get_contents($projects_dir.$project_dirs[$key]."/dataFormat.txt");
							$dataformat_lines  = preg_split("/:/", $dataformat_string);
							if ((int)$dataformat_lines[1] == 0) {
								$dataFormat = "WGseq_single";
							} else {
								$dataFormat = "WGseq_paired";
							}
							project_process($user,$project,$dataFormat,$fileName,$key);

							$count_bulk_working += 1;

							log_stuff($user,$project,"","","","bulk:SUCCESS Dataset processing initiated.");

							// Pause after initiating processing of a dataset, to avoid n datasets all piling up at once when done.
							sleep(15);
						}
					}
				}

				// Count projects with 'bulk.txt' and 'complete.txt'.
				$count_bulk_complete = 0;
				foreach ($project_dirs as $key => $project) {
					if (file_exists($projects_dir.$project."/complete.txt")) {
						$count_bulk_complete += 1;
					}
				}

				// Count projects remaining to be done.
				$count_bulk_remaining = 0;
				foreach ($project_dirs as $key => $project) {
					if (!file_exists($projects_dir.$project."/working.txt") && !file_exists($projects_dir.$project."/complete.txt")) {
						$count_bulk_remaining += 1;
					}
				}

				// log output:
				// Change the line below to your timezone!
				date_default_timezone_set('America/Chicago');
				$date = date('m/d/Y h:i:s a', time());
				fwrite($logOutput, "timestamp = ".$date."\n");
				fwrite($logOutput, "\tcomplete   = ".$count_bulk_complete."\n");
				fwrite($logOutput, "\tin process = ".$count_bulk_working."\n");
				fwrite($logOutput, "\tremaining  = ".$count_bulk_remaining."\n");

				// Pause and let YMAP instances run before checking again.
				sleep(60);
			}
			fclose($logOutput);
		} else {
			log_stuff($user,"","","","","bulk:FAIL user attempted to use admin-only 'bulk_procesesser.php' feature.");
		}
	}
	function project_process($user,$project,$dataFormat,$fileName,$key) {
		// "project"
		// "WGseq_single" or "WGseq_paired"
		// "filename" or "filename1,filename2"
		// Position in list, starting with zero.

		// Set session variables.
		$_SESSION['user']       = $user;
		$_SESSION['fileName']   = $fileName;
		$_SESSION['project']    = $project;
		$_SESSION['key']        = $key;

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
		// Call script from commandline.
		// printf($command_string."\n");
		// user=darren fileName= project=AMS2401_canu_contig_16_illumina key=1
		chdir("scripts_seqModules/scripts_WGseq/");
		exec("php ".$conclusion_script." ".$command_string." > /dev/null &");
		chdir("../../");
	}
?>
