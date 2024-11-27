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
		$ploidy          = sanitizeFloat_POST("ploidy");
		$ploidyBase      = sanitizeFloat_POST("ploidyBase");
		$dataFormat      = sanitizeIntChar_POST("dataFormat");
		$showAnnotations = sanitizeIntChar_POST("showAnnotations");

		// Define some directories for later use.
		$project_dir  = "users/".$user."/projects/".$project;


		//========================================================
		// Project directory exists, lets update it
		//--------------------------------------------------------
		$_SESSION['pending_install_project_count'] += 1;

		// Initialize log files.
		$logOutputName = $project_dir."/process_log.txt";
		$logOutput     = fopen($logOutputName, 'a');
		fwrite($logOutput, "Log file restarted.\n");
		fwrite($logOutput, "#..............................................................................\n");
		fwrite($logOutput, "Running 'scripts_seqModules/scripts_WGseq/project.WGseq.update_1.php'.\n");
		fwrite($logOutput, "Variables passed :\n");
		fwrite($logOutput, "\tuser     = '".$user."'\n");
		fwrite($logOutput, "\tproject  = '".$project."'\n");
		fwrite($logOutput, "#============================================================================== 1\n");

		$condensedLogOutputName = $project_dir."/condensed_log.txt";
		$condensedLogOutput     = fopen($condensedLogOutputName, 'w');
		fwrite($condensedLogOutput, "Updating.\n");
		fclose($condensedLogOutput);

		// Update 'ploidy.txt' file.
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
		chmod($fileName,0664);
		fwrite($logOutput, "\tUpdated 'ploidy.txt' file.\n");

		// Update 'snowAnnotations.txt' file.
		$fileName = $project_dir."/showAnnotations.txt";
		$file     = fopen($fileName, 'w');
		fwrite($file, $showAnnotations);
		fclose($file);
		chmod($fileName,0664);
		fwrite($logOutput, "\tUpdated 'showAnnotations.txt' file.\n");

		// Generate 'working.txt' file to let pipeline know processing is started.
		$fileName = $project_dir."/working.txt";
		$file     = fopen($fileName, 'w');
		$startTimeString = date("Y-m-d H:i:s");
		fwrite($file, $startTimeString);
		fclose($file);
		chmod($fileName,0664);
		fwrite($logOutput, "\tGenerated 'working.txt' file.\n");

		// Update/generate 'figVer.txt file to let user interface know to force reload of images instead of using cached versions.
		$fileName = $project_dir."/figVer.txt";
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
		chmod($fileName,0664);

		// Remove 'working_done.txt' file to let pipeline know processing isn't done.
		unlink($project_dir."/working_done.txt");
		fwrite($logOutput, "\tRemoved 'working_done.txt' file.\n");

		// Remove 'complete.txt' file to let pipeline know processing isn't done.
		unlink($project_dir."/complete.txt");
		fwrite($logOutput, "\tRemoved 'complete.txt' file.\n");


		// set session variables.
		$_SESSION['project']    = $project;
		$_SESSION['key']        = $key;

		// Figure out dataFormat.
		// Grab data format numbers from 'dataFormat.txt'.
		$dataFileStrings         = file_get_contents("users/".$user."/projects/".$project."/dataFormat.txt");
		$dataStrings             = explode(":",$dataFileStrings);
		$dataType                = $dataStrings[0];
		$readType                = $dataStrings[1];
		$performIndelRealignment = $dataStrings[2];

		// Regenerate 'dataBiases.txt' file.
		$fileName2 = "users/".$user."/projects/".$project."/dataBiases.txt";
		$file2     = fopen($fileName2, 'w');
		if ($dataFormat == "0") { // SnpCghArray
			$bias_GC     = filter_input(INPUT_POST, "0_bias2", FILTER_SANITIZE_STRING);
			$bias_end    = filter_input(INPUT_POST, "0_bias4", FILTER_SANITIZE_STRING);
			if (strcmp($bias_GC ,"") == 0) { $bias_GC  = "False"; }
			if (strcmp($bias_end,"") == 0) { $bias_end = "False"; }
			fwrite($file2,"False\n".$bias_GC."\nFalse\n".$bias_end);
		} else if ($dataFormat == "1") { // WGseq
			$bias_GC     = filter_input(INPUT_POST, "1_bias2", FILTER_SANITIZE_STRING);
			$bias_end    = filter_input(INPUT_POST, "1_bias4", FILTER_SANITIZE_STRING);
			if (strcmp($bias_GC ,"") == 0) { $bias_GC  = "False"; }
			if (strcmp($bias_end,"") == 0) { $bias_end = "False"; } else {$bias_GC  = "True"; }
			fwrite($file2,"False\n".$bias_GC."\nFalse\n".$bias_end);
		} else if ($dataFormat == "2") { // ddRADseq
			$bias_length = filter_input(INPUT_POST, "2_bias1", FILTER_SANITIZE_STRING);
			$bias_GC     = filter_input(INPUT_POST, "2_bias2", FILTER_SANITIZE_STRING);
			$bias_end    = filter_input(INPUT_POST, "2_bias4", FILTER_SANITIZE_STRING);
			if (strcmp($bias_length,"") == 0) { $bias_length = "False"; }
			if (strcmp($bias_GC    ,"") == 0) { $bias_GC     = "False"; }
			if (strcmp($bias_end   ,"") == 0) { $bias_end    = "False"; }
			fwrite($file2,$bias_length."\n".$bias_GC."\nFalse\n".$bias_end);
		}
		fclose($file2);
		chmod($fileName1,0664);

		// initiate project processing.
		$conclusion_script = "";
		switch ($dataType) {
			case "0": //"SnpCghArray":
				$conclusion_script = "scripts_SnpCghArray/project.SnpCgh.update.php";
				break;
			case "1": //"WGseq_single":
				$conclusion_script = "scripts_seqModules/scripts_WGseq/project.WGseq.update_1.php";
				break;
			case "2": //"ddRADseq_single":
				$conclusion_script = "scripts_seqModules/scripts_ddRADseq/project.ddRADseq.update_1.php";
				break;
			}

		log_stuff($user,$project,"","","","project:UPDATE initiated.");
		// Move to user directory
		chdir("users/".$user);

		// Open processing script.
		fwrite($logOutput, "\tCalling next script: ".$conclusion_script."\n");
		header("Location: ".$conclusion_script);
	}
?>
