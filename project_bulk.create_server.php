<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	require_once 'SecureNewDirectory.php';
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
		$admin_user_flag_file = "users/".$user."/admin.txt";
		if (file_exists($admin_user_flag_file)) {
			// Validate input strings.
			$ploidy          = sanitizeFloat_POST("ploidy");
			$ploidyBase      = sanitizeFloat_POST("ploidyBase");
			$dataFormat      = sanitizeIntChar_POST("dataFormat");
			$showAnnotations = sanitizeIntChar_POST("showAnnotations");
			$manualLOH       = sanitizeTabbed_POST("manualLOH");

			$genome          = sanitize_POST("genome");
			$genome_dir1     = "users/".$user."/genomes/".$genome;
			$genome_dir2     = "users/default/genomes/".$genome;
			if (!(is_dir($genome_dir1) || is_dir($genome_dir2))) {
				// Genome doesn't exist, should never happen: Force logout.
				session_destroy();
				header('Location: .');
			}

			$hapmap          = sanitize_POST("selectHapmap");
			if (($hapmap == "none") || ($hapmap == "")) {
				// no hapmap is used.
			} else {
				// Confirm if requested hapmap exists.
				$hapmap_dir1 = "users/".$user."/hapmaps/".$hapmap;
				$hapmap_dir2 = "users/default/hapmaps/".$hapmap;
				if (!(is_dir($hapmap_dir1) || is_dir($hapmap_dir2))) {
					// Hapmap doesn't exist, should never happen: Force logout.
					session_destroy();
					header('Location: .');
				}
			}

			// Figure selection booleans.
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

			// Define some directories for later use.
			$projects_bulkdata     = "users/".$user."/bulkdata";
			$projects_bulksettings = "users/".$user."/bulksettings";
			$projects_dir          = "users/".$user."/projects";

			// Deals with accidental deletion of user/projects dir.
			if (!file_exists($projects_dir)){
				mkdir($projects_dir);
				secureNewDirectory($projects_dir);
				chmod($projects_dir,0777);
			}


			//=============================================================
			// Bulk settings directory doesn't exist, go about creating it.
			//-------------------------------------------------------------

			// Create the bulk data settings folder inside the user's projects directory.
			if (!file_exists($projects_bulksettings)) {
				mkdir($projects_bulksettings);
				secureNewDirectory($projects_bulksettings);
				chmod($$projects_bulksettings,0777);
			}

			// Create figure selections file.
			$fileName = $projects_bulksettings."/figure_options.txt";
			$file     = fopen($fileName, 'w');
				fwrite($file,$fig_A1);
				fwrite($file,$fig_A2);
				fwrite($file,$fig_B1);
				fwrite($file,$fig_B2);
				fwrite($file,$fig_C);
				fwrite($file,$fig_D1);
				fwrite($file,$fig_D2);
				fwrite($file,$fig_E);
				fwrite($file,$fig_F1);
				fwrite($file,$fig_F2);
				fwrite($file,$fig_G1);
				fwrite($file,$fig_G2);
			fclose($file);
			chmod($fileName,0664);

			// Generate 'ploidy.txt' file.
			$fileName = $projects_bulksettings."/ploidy.txt";
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

			// Generate 'dataBiases.txt' files.
			// dataFormat.txt file: #:#:# where 1st # indicates type of data, 2nd # indicates format of input data, & 3rd # indicates if indel-realignment should be done.
			// 1st #: 0=SnpCghArray; 1=WGseq; 2=ddRADseq.
			// 2nd #: 0=single-end-reads FASTQ/ZIP/GZ; 1=paired-end-reads FASTQ/ZIP/GZ; 2=SAM/BAM; 3=TXT.
			// 3rd #: 0=False, no indel-realignment; 1=True, performe indel-realignment.
			$indelRealign = 0;
			$fileName2 = $projects_bulksettings."/dataBiases.txt";
			$file2     = fopen($fileName2, 'w');
			if ($dataFormat == "1") { // WGseq
				$bias_GC     = filter_input(INPUT_POST, "1_bias2");
				$bias_end    = filter_input(INPUT_POST, "1_bias4");
				if ($bias_GC == "") {
					$bias_GC  = "False";
				} else {
					$bias_GC  = "True";
				}
				if ($bias_end == "") {
					$bias_end = "False";
				} else {
					$bias_end = "True";
					$bias_GC  = "True";
				}
				fwrite($file2,"False\n".$bias_GC."\nFalse\n".$bias_end);
			}
			fclose($file2);
			chmod($fileName2,0664);

			// Generate 'snowAnnotations.txt' file.
			$fileName = $projects_bulksettings."/showAnnotations.txt";
			$file     = fopen($fileName, 'w');
			fwrite($file, $showAnnotations);
			fclose($file);
			chmod($fileName,0664);

			// Generate 'genome.txt' file : containing genome used.
			//	1st line : (String) genome name.
			//	2nd line : (String) hapmap name.
			$fileName = $projects_bulksettings."/genome.txt";
			$file     = fopen($fileName, 'w');
			if ($hapmap == "none") {
				fwrite($file, $genome);
			} else {
				fwrite($file, $genome."\n".$hapmap);
			}
			fclose($file);
			chmod($fileName,0664);

			// Generate 'manualLOH.txt' file : contains manual LOH annotation information.
			// one entry per line...  if input was provided.
			// tab-delimited channels.
			//    1. chrID
			//    2. startbp
			//    3. endbp
			//    4. R
			//    5. G
			//    6. B
			if (strlen($manualLOH) > 0) {
				$fileName = $projects_bulksettings."/manualLOH.txt";
				$file     = fopen($fileName, 'w');
				fwrite($file, $manualLOH);
				fclose($file);
				chmod($fileName,0664);
			}

			log_stuff($user,"[BULKDATA]","","","","bulkdata:CREATE settings success.");

// Initialize html here.
?>
<html>
	<body>
	<script type="text/javascript">
<?php

			//===========================================================================================
			// Iterate over bulk data directory files, creating new project directories for each dataset.
			//-------------------------------------------------------------------------------------------

			// Scan bulk data directory
			$bulkdata_files = scandir($projects_bulkdata);

			// Remove '.' and '..' from scandir results.
			unset($bulkdata_files[0]);
			unset($bulkdata_files[1]);
			$bulkdata_files_temp = array_values($bulkdata_files);
			$bulkdata_files = $bulkdata_files_temp;

			// Process each data file name.
			$skip = 0;
			foreach ($bulkdata_files as $key=>$filename) {
				if ($skip == 0) {
					// Strip extensions off filenames.
					$project = pathinfo($filename, PATHINFO_FILENAME);
					$ext1 = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
					if ($ext1 == "gz") {
						$ext2 = strtolower(pathinfo($project, PATHINFO_EXTENSION));
					} else {
						$ext2 = "";
					}

					// Concatenate tiered filenames for gz archives.
					if ($ext2 == "") {
						$ext = ".".$ext1;
					} else {
						$ext = ".".$ext2.".".$ext1;
					}

					// Determine file name without extension.
					$project = str_replace($ext,"",$filename);

					// Replace any "."s in string with "_"s.
					$project = str_replace(".","_",$project);

					// Check if file is one of paired reads. (Name ends in "_R1" or "_R2".)
					// Strip suffix off name if found and skip next filename.
					if ((substr($project,-3) == "_R1") || (substr($project,-3) == "_R2")) {
						$project = substr($project,0,-3);
						$skip = 1;
					}

					// Define a couple directories for later use.
					$project_dir1          = "users/".$user."/projects/".$project;
					$project_dir2          = "users/default/projects/".$project;

					// Check if project already exists in user or default.
					if (file_exists($project_dir1) || file_exists($project_dir2)) {
						// Project directory already exists, so do nothing.
						echo "Project '".$project."' directory already exists.";
						log_stuff($user,$project,"","","","bulkdata:FAIL project name already exists.");
					} else {
						$_SESSION['pending_install_project_count'] += 1;

						// Project doesn't already exist, so create.
						mkdir($project_dir1);
						//secureNewDirectory($project_dir1);
						chmod($project_dir1,0777);

						// Generate 'name.txt' file in project directory containing:
						//      one line; name of project.
						$outputName   = $project_dir1."/name.txt";
						$output       = fopen($outputName, 'w');
						fwrite($output, $project);
						fclose($output);
						chmod($outputName,0664);

						// Copy files from $projects_bulksettings to $project_dir1:
						//      ploidy.txt
						//      parent.txt
						//      dataBiases.txt
						//      snowAnnotations.txt
						//      genome.txt
						//      manualLOH.txt
						if (file_exists($projects_bulksettings."/ploidy.txt")) {                copy($projects_bulksettings."/ploidy.txt", $project_dir1."/ploidy.txt");                        }
						if (file_exists($projects_bulksettings."/parent.txt")) {                copy($projects_bulksettings."/parent.txt", $project_dir1."/parent.txt");                        }
						if (file_exists($projects_bulksettings."/dataBiases.txt")) {            copy($projects_bulksettings."/dataBiases.txt", $project_dir1."/dataBiases.txt");                }
						if (file_exists($projects_bulksettings."/showAnnotations.txt")) {       copy($projects_bulksettings."/showAnnotations.txt", $project_dir1."/showAnnotations.txt");      }
						if (file_exists($projects_bulksettings."/genome.txt")) {                copy($projects_bulksettings."/genome.txt", $project_dir1."/genome.txt");                        }
						if (file_exists($projects_bulksettings."/manualLOH.txt")) {             copy($projects_bulksettings."/manualLOH.txt", $project_dir1."/manualLOH.txt");                  }

						// Generate 'parent.txt' file.
						$fileName = $project_dir1."/parent.txt";
						$file     = fopen($fileName, 'w');
						$parent   = $project;
						fwrite($file, $parent);
						fclose($file);
						chmod($fileName,0664);

						// Generate 'bulk.txt' file.
						$fileName = $project_dir1."/bulk.txt";
						$file     = fopen($fileName, 'w');
						fwrite($file, "initiated");
						fclose($file);
						chmod($fileName,0664);

						// Generate 'condensed_log.txt' file.
						$fileName = $project_dir1."/condensed_log.txt";
						$file     = fopen($fileName, 'w');
						fwrite($file, "");
						fclose($file);
						chmod($fileName,0664);

						// Generate dataFormat.txt files.
						$fileName1 = $project_dir1."/dataFormat.txt";
						$file1     = fopen($fileName1, 'w');
						if (($ext == ".sam") || ($ext == ".bam")) {
							// $readType = 2; SAM/BAM file.
							$readType = 2;
						} elseif ($skip == 1) {
							// $readType = 1; paired-end reads.
							$readType = 1;
						} else {
							// $readType = 0; single-end reads.
							$readType = 0;
						}
						fwrite($file1, "1:".$readType.":0");
						fclose($file1);
						chmod($fileName1,0664);

						// Copy raw data to project directories. Rename raw file as we go.
						$fileName_     = pathinfo($filename, PATHINFO_FILENAME);
						$fileType_     = pathinfo($filename, PATHINFO_EXTENSION);
						$filename_new1 = str_replace(".","-",$fileName_).".".$fileType_;
						copy($projects_bulkdata."/".$filename, $project_dir1."/".$filename_new1);

						// Make txt file containing raw data file name(s).
						$fileName = $project_dir1."/datafiles.txt";
						$file     = fopen($fileName, 'w');
						fwrite($file, $filename_new1."\n");
						fclose($file);
						chmod($fileName,0664);

						// If filename ends with "_R1", copy next file in table if the name includes "_R2".
						if ($skip == 1) {
							$filename2 = $bulkdata_files[$key+1];

							$project2 = pathinfo($filename2, PATHINFO_FILENAME);
							$ext1 = pathinfo($filename2, PATHINFO_EXTENSION);
							if ($ext1 == "gz") {
								$ext2 = pathinfo($project2, PATHINFO_EXTENSION);
							} else {
								$ext2 = "";
							}

							// Concatenate tiered filenames for gz archives.
							if ($ext2 == "") {
								$ext = ".".$ext1;
							} else {
								$ext = ".".$ext2.".".$ext1;
							}

							// Determine file name without extension.
							$project2 = str_replace($ext,"",$filename2);

							// Replace any "."s in string with "_"s.
							$project2 = str_replace(".","_",$project2);

							// Check if file is one of paired reads. (Name ends in "_R1" or "_R2".)
							// Strip suffix off name if found and skip next filename.
							if (substr($project2,-3) == "_R2") {
								copy($projects_bulkdata."/".$filename2, $project_dir1."/".$filename2);

								$fileName_     = pathinfo($filename2, PATHINFO_FILENAME);
								$fileType_     = pathinfo($filename2, PATHINFO_EXTENSION);
								$filename_new2 = str_replace(".","-",$fileName_).".".$fileType_;

								// Make txt file containing raw data file name(s).
								$fileName = $project_dir1."/datafiles.txt";
								$file     = fopen($fileName, 'a');
								fwrite($file, "\n".$filename_new2);
								fclose($file);
								chmod($fileName,0664);
							}
						}
?>
	// Update user interface with project names.
	var el1 = parent.document.getElementById('panel_manageDataset_iframe').contentDocument.getElementById('newly_installed_list');
	el1.innerHTML += "<?php echo $_SESSION['pending_install_project_count']; ?>. <?php echo $project; ?><br>";
<?php
						log_stuff($user,$project,"","","","bulkdata:CREATE individual project success.");
					}
				} else {
					$skip -= 1;
				}
			}
?>
	// Show bulk dataset comment.
	var el2 = parent.document.getElementById('panel_manageDataset_iframe').contentDocument.getElementById('bulk_comment');
	el2.style.visibility = 'visible';

	var el3 = parent.document.getElementById('panel_manageDataset_iframe').contentDocument.getElementById('name_error_comment');
	el3.style.visibility = 'hidden';

	// Reset page frame for next use.
	window.location = "project_bulk.create_window.php";

	// Refresh "projectsShown" string;
	parent.update_projectsShown_after_new_project();
	</script>
	</body>
	</html>
<?php
		} else {
			log_stuff($user,"[BULKDATA]","","","","bulkdata:FAIL user account is not admin!");
		}
	}
?>
