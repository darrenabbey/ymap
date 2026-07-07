<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	ini_set('display_errors', 1);

	// If the user is not logged on, redirect to login page.
	if (!isset($_SESSION['logged_on'])) {
		session_destroy();
		header('Location: .');
	} else if ($_SESSION['logged_on'] == 0) {
		session_destroy();
		header('Location: .');
	}

	// Load user string from session.
	if(isset($_SESSION['user'])) {
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// Validate input strings.
		$project         = sanitize_POST("project");
		if (!file_exists("users/".$user."/projects/".$project)) {
			log_stuff($user,$project,"","","","project:UPDATE failure, no such project for this user.");
			header('Location: .');
		}
		$name            = whitelistHTML_POST("name");
		$groupKey        = sanitizeIntChar_POST("groupKey");
		$ploidy          = sanitizeFloat_POST("ploidy");
		$ploidyBase      = sanitizeFloat_POST("ploidyBase");
		$showAnnotations = sanitizeIntChar_POST("showAnnotations");
		$hapmap          = sanitize_POST("hapmap");

		// Define some directories for later use.
		$project_dir  = "users/".$user."/projects/".$project;

		// Initialize log files.
		$logOutputName = $project_dir."/process_log.txt";
		$logOutput     = fopen($logOutputName, 'a');
		fwrite($logOutput, "Log file restarted.\n");
		fwrite($logOutput, "#..............................................................................\n");
		fwrite($logOutput, "Running 'project.update_server.php'.\n");
		fwrite($logOutput, "Variables passed :\n");
		fwrite($logOutput, "\tuser         = '".$user."'\n");
		fwrite($logOutput, "\tproject      = '".$project."'\n");
		fwrite($logOutput, "#============================================================================== 1\n");
		fwrite($logOutput, "\tproject_dir  = '".$project_dir."'\n");

		$condensedLogOutputName = $project_dir."/condensed_log.txt";
		$condensedLogOutput     = fopen($condensedLogOutputName, 'w');
		fwrite($condensedLogOutput, "Added to processing queue.\n");
		fclose($condensedLogOutput);

//
// ================================================================================================================
//

		// Get existing name.
		$fileName       = $project_dir."/name.txt";
		$fileID         = fopen($fileName, 'r');
		$name_old     = trim(fgets($fileID));
		fclose($fileID);

		//===================================
		// Get existing groupKey (and group).
		//-----------------------------------

		// Get existing project group.
		if (str_contains($project,'/')) {
			$pos       = strpos($project, '/');
			$group_old = substr($project, 0, $pos);
		} else {
			$group_old = "";
                }

		// Figure out what project groups there are.
		$projectsDir      = "users/".$user."/projects/";
		$projectFolders = [];
		$objects = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($projectsDir), RecursiveIteratorIterator::SELF_FIRST);
		foreach($objects as $entry => $object){
			if (is_dir($entry)) {
				$name_ = str_replace($projectsDir,"",$entry);
				if (str_contains($name_,"..") or str_contains($name_,".")) {
				} else {
					$projectFolders[] = $name_;
				}
			}
		}
		foreach($projectFolders as $key_=>$folder) {   $projectFolders[$key_] = str_replace($projectsDir,"",$folder);   }
		sort($projectFolders);

		// Split project list into ready/working/starting lists for sequential display.
		$projectFolders_subdir   = array();
		foreach($projectFolders as $projectName) {
			if (file_exists("users/".$user."/projects/".$projectName."/complete.txt")) {
			} else if (file_exists("users/".$user."/projects/".$projectName."/working.txt")) {
			} else if (file_exists("users/".$user."/projects/".$projectName."/name.txt")) {
			} else {
				array_push($projectFolders_subdir,$projectName);
			}
		}
		sort($projectFolders_subdir);

		// Determine old group key.
		$groupKey_old = array_search($group_old, $projectFolders_subdir)+1;

		//-----------------------------------
		// Get existing group key (above).
		//===================================

		// Get existing ploidy and ploidyBase.
		$fileName       = $project_dir."/ploidy.txt";
		$fileID         = fopen($fileName, 'r');
		$ploidy_old     = trim(fgets($fileID));
		$ploidyBase_old = trim(fgets($fileID));
		fclose($fileID);

		// Grab data format numbers from 'dataFormat.txt'.
		$dataFileStrings         = file_get_contents("users/".$user."/projects/".$project."/dataFormat.txt");
		$dataStrings             = explode(":",$dataFileStrings);
		$dataType                = (int)$dataStrings[0];
		$readType                = (int)$dataStrings[1];
		$performIndelRealignment = (int)$dataStrings[2];
		fwrite($logOutput, "\tGrabbed 'dataFormat.txt' file.\n");

		// Get existing showAnnotations selection.
		if (file_exists($project_dir."/showAnnotations.txt")) {
			$fileName            = $project_dir."/showAnnotations.txt";
			$fileID              = fopen($fileName, 'r');
			$showAnnotations_old = (int)trim(fgets($fileID));
			fclose($fileID);
		} else {
			$showAnnotations_old = false;
			fwrite($logOutput, "\t'showAnnotations.txt' file not found, using defaults.\n");
		}

		// Get existing hapmap.
		$fileName       = $project_dir."/genome.txt";
		$fileID         = fopen($fileName, 'r');
		$genome_old     = trim(fgets($fileID));
		$hapmap_old     = trim(fgets($fileID));
		fclose($fileID);

		// Get existing parent.
		$fileName       = $project_dir."/parent.txt";
		$fileID         = fopen($fileName, 'r');
		$parent_old     = trim(fgets($fileID));
		fclose($fileID);

		// Get existing data bias correction selections.
		if (file_exists($project_dir."/dataBiases.txt")) {
			$fileName            = $project_dir."/dataBiases.txt";
			$fileID              = fopen($fileName, 'r');
			$bias_length_old     = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$bias_GC_old         = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$bias_unused         = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$bias_end_old        = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			fclose($fileID);
			fwrite($logOutput, "\tGrabbed 'dataBiases.txt' file.\n");
		} else {
			$bias_length_old = false;
			$bias_GC_old     = true;
			$bias_unused     = false;
			$bias_end_old    = false;
			fwrite($logOutput, "\t'dataBiases.txt' file not found, using defaults.\n");
		}

		// Get existing figure selections.
		if (file_exists($project_dir."/figure_options.txt")) {
			$fileName            = $project_dir."/figure_options.txt";
			$fileID              = fopen($fileName, 'r');
			$fig_A1_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_A2_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_B1_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_B2_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_C_old           = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_D1_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_D2_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_E_old           = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_F1_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_F2_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_G1_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			$fig_G2_old          = filter_var(trim(fgets($fileID)), FILTER_VALIDATE_BOOLEAN);
			fclose($fileID);
			fwrite($logOutput, "\tGrabbed 'figure_options.txt' file.\n");
		} else {
			$fig_A1_old          = false;
			$fig_A2_old          = false;
			$fig_B1_old          = false;
			$fig_B2_old          = false;
			$fig_C_old           = false;
			$fig_D1_old          = false;
			$fig_D2_old          = false;
			$fig_E_old           = false;
			$fig_F1_old          = false;
			$fig_F2_old          = false;
			$fig_G1_old          = false;
			$fig_G2_old          = false;
			fwrite($logOutput, "\t'figure_options.txt' file not found, using defaults.\n");
		}

//
// ================================================================================================================
//

		// Get group directory name, if selected.
		if ($groupKey == 0) {
			$group_new = "";
		} else {
			$group_new = $projectFolders_subdir[$groupKey-1]."/";
		}

		// Determine old project name (without any group names).
		if ($group_old == "") {
			$projectTrimmed = $project;
		} else {
			$projectTrimmed = str_replace($group_old."/", "", $project);
		}

		// If group_new is different than group_old, move project folder.
		if ($group_old != $group_new) {
			$source = "users/".$user."/projects/".$project;
			$destination = "users/".$user."/projects/".$group_new."/".$projectTrimmed;

			if (rename($source, $destination)) {
				echo "UPDATE: Folder moved successfully.";
			} else {
				echo "UPDATE: Error, unable to move folder.";
			}
			$project = $group_new."/".$projectTrimmed;
		}
		$UpdateFigures = false;

		// Update 'name.txt' file.
		if ($name == $name_old) {
			fwrite($logOutput, "\t'name.txt' file did not need to be updated.\n");
		} else {
			$fileName = $project_dir."/name.txt";
			$file     = fopen($fileName, 'w');
			fwrite($file, $name);
			fclose($file);
			chmod($fileName,0774);
			fwrite($logOutput, "\tUpdated 'name.txt' file.\n");
		}

		// Update 'ploidy.txt' file.
		if (($ploidy == $ploidy_old) && ($ploidyBase == $ploidyBase_old)) {
			fwrite($logOutput, "\t'ploidy.txt' file did not need to be updated.\n");
		} else {
			$fileName = $project_dir."/ploidy.txt";
			$file     = fopen($fileName, 'w');
			if (is_numeric($ploidy)) {
				fwrite($file, $ploidy."\n");
				if (is_numeric($ploidyBase)) {
					fwrite($file, $ploidyBase);
				} else {
					fwrite($file, "2.0");
				}
			} else {
				fwrite($file, "2.0\n");
				if (is_numeric($ploidy)) {
					fwrite($file, $ploidyBase);
				} else {
					fwrite($file, "2.0");
				}
			}
			fclose($file);
			chmod($fileName,0774);
			fwrite($logOutput, "\tUpdated 'ploidy.txt' file.\n");
			$UpdateFigures = true;
		}

		// Update 'genome.txt' file.
		if ($hapmap == $hapmap_old) {
			fwrite($logOutput, "\t'genome.txt' file hapmap entry did not need to be updated.\n");
		} else {
			$fileName = $project_dir."/genome.txt";
			$file     = fopen($fileName, 'w');
			fwrite($file, $genome_old."\n");
			fwrite($file, $hapmap);
			fclose($file);
			chmod($fileName,0774);
			fwrite($logOutput, "\tUpdated 'genome.txt' file hapmap entry.\n");
			$UpdateFigures = true;
		}

		// Update 'snowAnnotations.txt' file.
		if ($showAnnotations == $showAnnotations_old) {
			fwrite($logOutput, "\t'showAnnotations.txt' file did not need to be updated.\n");
		} else {
			$fileName = $project_dir."/showAnnotations.txt";
			$file     = fopen($fileName, 'w');
			fwrite($file, $showAnnotations);
			fclose($file);
			chmod($fileName,0774);
			fwrite($logOutput, "\tUpdated 'showAnnotations.txt' file.\n");
			$UpdateFigures = true;
		}

		// Update 'dataBiases.txt' file.
		if ($dataType == 0) { // SnpCghArray
			$bias_length = false;
			$bias_GC     = filter_input(INPUT_POST, "0_bias2", FILTER_VALIDATE_BOOLEAN);
			$bias_end    = filter_input(INPUT_POST, "0_bias4", FILTER_VALIDATE_BOOLEAN);
		} else if (($dataType == 1) || ($dataType == 2)) { // WGseq
			$bias_length = false;
			$bias_GC     = filter_input(INPUT_POST, "1_bias2", FILTER_VALIDATE_BOOLEAN);
			$bias_end    = filter_input(INPUT_POST, "1_bias4", FILTER_VALIDATE_BOOLEAN);
		} else if ($dataType == 3) { // ddRADseq
			$bias_length = filter_input(INPUT_POST, "2_bias1", FILTER_VALIDATE_BOOLEAN);
			$bias_GC     = filter_input(INPUT_POST, "2_bias2", FILTER_VALIDATE_BOOLEAN);
			$bias_end    = filter_input(INPUT_POST, "2_bias4", FILTER_VALIDATE_BOOLEAN);
		}
		if (($bias_GC === $bias_GC_old) && ($bias_end === $bias_end_old) && ($bias_length === $bias_length_old)) {
			fwrite($logOutput, "\t'dataBiases.txt' file did not need to be updated.\n");
		} else {
			// Regenerate 'dataBiases.txt' file.
			$fileName2 = "users/".$user."/projects/".$project."/dataBiases.txt";
			$file2     = fopen($fileName2, 'w');
			$bias_length_str = $bias_length ? 'True' : 'False';
			$bias_GC_str     = $bias_GC ? 'True' : 'False';
			$bias_end_str    = $bias_end ? 'True' : 'False';
			fwrite($file2, "$bias_length_str\n$bias_GC_str\nFalse\n$bias_end_str");
			fclose($file2);
			chmod($fileName1,0774);
			fwrite($logOutput, "\tUpdated 'dataBiases.txt' file.\n");
			$UpdateFigures = true;
		}

		// Update 'figure_options.txt' file.
		$fig_A1          = sanitizeBoolean_POST("fig_A1");
		$fig_A2          = sanitizeBoolean_POST("fig_A2");
		$fig_B1          = sanitizeBoolean_POST("fig_B1");
		$fig_B2          = sanitizeBoolean_POST("fig_B2");
		$fig_C           = sanitizeBoolean_POST("fig_C");
		$fig_D1          = sanitizeBoolean_POST("fig_D1");
		$fig_D2          = sanitizeBoolean_POST("fig_D2");
		$fig_E           = sanitizeBoolean_POST("fig_E");
		$fig_F1          = sanitizeBoolean_POST("fig_F1");
		$fig_F2          = sanitizeBoolean_POST("fig_F2");
		$fig_G1          = sanitizeBoolean_POST("fig_G1");
		$fig_G2          = sanitizeBoolean_POST("fig_G2");
		$current_figs = [$fig_A1,	$fig_A2,	$fig_B1,	$fig_B2,	$fig_C,		$fig_D1,	$fig_D2,	$fig_E,		$fig_F1,	$fig_F2,	$fig_G1,	$fig_G2		];
		$old_figs     = [$fig_A1_old,	$fig_A2_old,	$fig_B1_old,	$fig_B2_old,	$fig_C_old,	$fig_D1_old,	$fig_D2_old,	$fig_E_old,	$fig_F1_old,	$fig_F2_old,	$fig_G1_old,	$fig_G2_old	];
		if ($current_figs === $old_figs) {
			fwrite($logOutput, "\t'figure_options.txt' file did not need to be updated.\n");
		} else {
			// Update figure selections file.
			$fileName3 = "users/".$user."/projects/".$project."/figure_options.txt";
			$file3     = fopen($fileName3, 'w');
			fwrite($file3,"Figures\n");
			if ($fig_A1 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_A2 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_B1 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_B2 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_C  != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_D1 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_D2 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_E  != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_F1 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_F2 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_G1 != 1) { fwrite($file3,"False\n"); } else { fwrite($file3,"True\n"); }
			if ($fig_G2 != 1) { fwrite($file3,"False");   } else { fwrite($file3,"True"); }
			fclose($file3);
			chmod($fileName3,0774);
			fwrite($logOutput, "\tUpdated 'figure_options.txt' file.\n");
			$UpdateFigures = true;
		}

//
// ================================================================================================================
//

		$fileName = $project_dir."/figVer.txt";
		if ($UpdateFigures == true) {
			// Update/generate 'figVer.txt file to let user interface know to force reload of images instead of using cached versions.
			if (file_exists($fileName)) {
				$figVer = intval(file_get_contents($fileName));
				fwrite($logOutput, "\tIncremented 'figVer.txt' file.\n");
			} else {
				$figVer = 0;
				fwrite($logOutput, "\tGenerated 'figVer.txt' file.\n");
			}
			$file     = fopen($fileName, 'w');
			fwrite($file, $figVer+1);
			fclose($file);
			chmod($fileName,0774);

			// Generate 'working.txt' file to let pipeline know processing is started.
			$fileName = $project_dir."/working.txt";
			$file     = fopen($fileName, 'w');
			$startTimeString = date("Y-m-d H:i:s");
			fwrite($file, $startTimeString);
			fclose($file);
			chmod($fileName,0774);
			fwrite($logOutput, "\tGenerated 'working.txt' file.\n");

			// Remove 'working_done.txt' file to let pipeline know processing isn't done.
			unlink($project_dir."/working_done.txt");
			fwrite($logOutput, "\tRemoved 'working_done.txt' file.\n");

			// Remove 'complete.txt' file to let pipeline know processing isn't done.
			unlink($project_dir."/complete.txt");
			fwrite($logOutput, "\tRemoved 'complete.txt' file.\n");

			// set session variables.
			$_SESSION['project'] = $project;
			$_SESSION['pending_install_project_count'] += 1;

			// initiate project processing.
			$conclusion_script = "";
			switch ($dataType) {
				case 0: //"SnpCghArray":
					$conclusion_script = "scripts_SnpCghArray/project.SnpCgh.update.php";
					break;
				case 1: //"WGseq_short":
					unlink("users/".$user."/projects/".$project."/working.txt");
					file_put_contents("users/".$user."/projects/".$project."/bulk.txt", "updating");
					queue_reinit($user,$project,"","","project.update_server.php");
					//$conclusion_script = "scripts_seqModules/scripts_WGseq/project.WGseq.update_1.php";
					break;
				case 2: //"WGseq_long";
					unlink("users/".$user."/projects/".$project."/working.txt");
					file_put_contents("users/".$user."/projects/".$project."/bulk.txt", "updating");
					queue_reinit($user,$project,"","","project.update_server.php");
					//$conclusion_script = "scripts_seqModules/scripts_WGseq/project.WGseq.update_1.php";
					break;
				case 3: //"ddRADseq":
					$conclusion_script = "scripts_seqModules/scripts_ddRADseq/project.ddRADseq.update_1.php";
					break;
				case 4: //"FASTA":
					unlink("users/".$user."/projects/".$project."/working.txt");
					file_put_contents("users/".$user."/projects/".$project."/bulk.txt", "updating");
					queue_reinit($user,$project,"","","project.update_server.php");
					//$conclusion_script = "scripts_seqModules/scripts_WGseq/project.WGseq.update_1.php";
					break;
			}

			log_stuff($user,$project,"","","","project:UPDATE initiated.");
			// Move to user directory
			chdir("users/".$user);

			// Open processing script.
			if ($conclustion_script <> "") {
				fwrite($logOutput, "\tCalling next script: ".$conclusion_script."\n");
				header("Location: ".$conclusion_script);
			}
		} else {
			log_stuff($user,$project,"","","","project:UPDATE project moved to new group without other updates.");
		}

	}
?>
