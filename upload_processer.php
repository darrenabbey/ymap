<?php
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
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	// This script is intended to take information from file uploaders and then initiate the pipeline scripts to start processing.
	// This has been added to minimize the changes necessary to the uploader when a new version is installed.

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// validate POST strings.
		$genome     = sanitize_POST("genome");
		$project    = sanitize_POST("project");
		$dataFormat = sanitize_POST("dataFormat");
		$fileName   = sanitizeFile_POST("fileName");
		$key        = sanitize_POST("key");

		// fix file names:
		$fileName_ = pathinfo($fileName, PATHINFO_FILENAME);
		$fileType_ = pathinfo($fileName, PATHINFO_EXTENSION);
		$fileName  = str_replace(".","-",$fileName_).".".$fileType_;

		if ($project != "") {
			// Confirm if requested project exists.
			$project_dir = "users/".$user."/projects/".$project;
			if (!is_dir($project_dir)) {
				log_stuff($user,$project,"","",$project_dir,"UPLOAD fail: user attempted to upload to non-existent project!");
				// Should never happen: Force logout.
				session_destroy();
				header('Location: .');
			}

			// Confirm if requested file exists in project.
			if (str_contains($fileName,",")) {
				// Two filenames, separated by a comma.
				// first filename has "." in front of extension converted to "-" by uploader as part of filename safety processing.
				$fileNames      = explode(",",$fileName);
				$fileName1      = $fileNames[0];
				$fileName2      = $fileNames[1];
				$fileExtension2 = pathinfo($fileName2, PATHINFO_EXTENSION);
				// assumes both files have the same extension. Will fail later if they don't.
				$fileName1      = str_replace("-".$fileExtension2, ".".$fileExtension2, $fileName1);
				// rebuilt corrected filename string.
				$fileName       = $fileName1.",".$fileName2;
				if (!file_exists($project_dir."/".$fileName1) or !file_exists($project_dir."/".$fileName2)) {
					log_stuff($user,$project,"","",$project_dir."/".$fileName,"UPLOAD fail: user attempted to process a non-existent file[2]!");
					log_stuff($user,$project,"","","","1: ".$fileName1);
					log_stuff($user,$project,"","","","2: ".$fileName2);
					// Should never happen: Force logout.
					session_destroy();
					header('Location: .');
				}
			} else {
				// One filename.
				if (!file_exists($project_dir."/".$fileName)) {
					log_stuff($user,$project,"","",$project_dir."/".$fileName,"UPLOAD fail: user attempted to process a non-existent file!");
					// Should never happen: Force logout.
					session_destroy();
					header('Location: .');
				}
			}
		} else if ($genome != "") {
			// Confirm if requested genome exists.
			$genome_dir = "users/".$user."/genomes/".$genome;
			if (!is_dir($genome_dir)) {
				log_stuff($user,"","",$genome,$genome_dir,"UPLOAD fail: user attempted to upload to non-existent genome!");
				// Should never happen: Force logout.
				session_destroy();
				header('Location: .');
			}

			// Confirm if requested file exists in genome.
			if (!file_exists($genome_dir."/".$fileName)) {
				log_stuff($user,"","",$genome,$genome_dir."/".$fileName,"UPLOAD fail: user attempted to process a non-existent file!");
				// Should never happen: Force logout.
				session_destroy();
				header('Location: .');
			}
		} else {
			log_stuff($user,"","","","","UPLOAD fail: null genome & project strings!");
			// No genome or project, should never happen: Force logout.
			session_destroy();
			header('Location: .');
		}

		if ($project != "") {
			log_stuff($user,$project,"","",$project_dir."/".$fileName,"UPLOAD success: initial project file location checks pass.");
		} else if ($genome != "") {
			log_stuff($user,"","",$genome,$genome_dir."/".$fileName,"UPLOAD success: initial genome file location checks pass.");
		}

		// set session variables.
		$_SESSION['dataFormat'] = $dataFormat;
		$_SESSION['fileName']   = $fileName;
		$_SESSION['genome']     = $genome;
		$_SESSION['project']    = $project;
		$_SESSION['key']        = $key;

		if ($project != "") {
			// initiate project processing.
			$conclusion_script = "";
			switch ($dataFormat) {
				case "SnpCghArray":
					$conclusion_script = "scripts_SnpCghArray/project.SnpCgh.install.php";
					break;
				case "WGseq_single":
					$conclusion_script = "scripts_seqModules/scripts_WGseq/project.single_WGseq.install_1.php";
					break;
				case "WGseq_paired":
					$conclusion_script = "scripts_seqModules/scripts_WGseq/project.paired_WGseq.install_1.php";
					break;
				case "ddRADseq_single":
					$conclusion_script = "scripts_seqModules/scripts_ddRADseq/project.single_ddRADseq.install_1.php";
					break;
				case "ddRADseq_paired":
					$conclusion_script = "scripts_seqModules/scripts_ddRADseq/project.paired_ddRADseq.install_1.php";
					break;
			}
		} else if ($genome != "") {
			// initiate genome processing.
			// ideally loaded into iframe id="Hidden_InstallNewGenome_Frame" defined in index.php
			$conclusion_script = "scripts_genomes/genome.install_1.php";
		}

		// troubleshooting output
		//print "[upload_processer.php]\n";       print "user:        ".$user."\n";              print "project:     ".$project."\n";  print "genome:      ".$genome."\n";
		//print "data format: ".$dataFormat."\n"; print "script:      ".$conclusion_script."\n"; print "filename:    ".$fileName."\n"; print "key:         ".$key."\n";

		// Move to user directory
		chdir("users/".$user);

		// Open processing script.
		header("Location: ".$conclusion_script);
	}
?>
