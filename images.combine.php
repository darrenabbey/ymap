<?php
	$calledBy = php_sapi_name();
        error_reporting(E_ALL);
        require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
        ini_set('display_errors', 1);

	if (!($calledBy === "cli")) {
	        // If the user is not logged on, redirect to login page.
	        if(!isset($_SESSION['logged_on'])) {
			session_destroy();
	                header('Location: .');
		} else if ($_SESSION['logged_on'] == 0) {
			session_destroy();
			header('Location: .');
	        } else {
			// Load user string from session.
			if(isset($_SESSION['user'])) {
				$user   = $_SESSION['user'];
			} else {
				$user = "";
				log_stuff("","","","","","user:VALIDATION failure, session expired.");
				header('Location: .');
			}
		}
		if ($user == "") {
			log_stuff("","","","","","user:VALIDATION failure, session expired.");
			header('Location: .');
		}

		// Sanitize input strings.
		$projectsShown = sanitizeProjectsShown_POST("projectsShown");
		$projectsShown = substr($projectsShown, 0, -1);
	} else {
		$user          = trim(file_get_contents("YMAPcli.dat"));
		$projectsShown = "darren:mas202_MRS-g3_illumina:0:<b>mas202</b> MRS-g3_illumina:0:cyan:magenta;darren:mas202_TRE-g5_illumina:1:<b>mas202</b> TRE-g5_illumina:0:cyan:magenta";
	}

	// auxillary functions
	// sets image background to white and init default image parameters
	function setBackgroundWhite($image) {
		$white = imagecolorallocate($image , 255, 255, 255);
		imagefill($image, 0, 0, $white);
		// setting default image parameters
		imagealphablending($image, false);
		imagesavealpha($image, true);
	}

	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n\n";
	echo "projectsShown = '".$projectsShown."'<br><br>\n\n";

	// general variables
	$linearCartoonHeight = 139; //139 the height in px of the cartoon without labels 136 valid so + 4px.

	if ($projectsShown == "" ) {
		echo "<script type='text/javascript'>console.log('1 No images to combine.'); parent.document.getElementById('combined_fig_options').style.display = 'none';</script>\n\n";
	} else {
		echo "<script type='text/javascript'>console.log('1 Combine images from: [".$projectsShown."]'); parent.document.getElementById('combined_fig_options').style.display = 'inline';</script>\n\n";

		//=======================================================
		// Clean up any previously constructed combined figures.
		//-------------------------------------------------------
		$image_file1 = "users/".$user."/combined_figure.1.png";
		$image_file2 = "users/".$user."/combined_figure.2.png";
		$image_file3 = "users/".$user."/combined_figure.3.png";
		$image_file4 = "users/".$user."/combined_figure.4.png";
		if (file_exists($image_file1)) { unlink($image_file1); }
		if (file_exists($image_file2)) { unlink($image_file2); }
		if (file_exists($image_file3)) { unlink($image_file3); }
		if (file_exists($image_file4)) { unlink($image_file4); }

		// break projectsShown string into individual strings per project.
		$projectsShown_entries = explode(";",$projectsShown);

		// process first project string;
		$initial_entry = $projectsShown_entries[0];
		$entry_parts   = explode(":",$initial_entry);
		$fig_user      = $entry_parts[0];
		$fig_project   = $entry_parts[1];
		$fig_key       = $entry_parts[2];

		//================================================================
		// Validate sub-strings received from first projectsShown string.
		//----------------------------------------------------------------
		// Confirm requested user exists.
		$user_dir = "users/".$fig_user;
		if (!is_dir($user_dir)) {
			// user doesn't exist, should never happen: Force logout.
			session_destroy();
			echo "<script type='text/javascript'> parent.location.reload(); </script>";
			exit;
		}
		// Confirm requested project exists.
		$project_dir = "users/".$fig_user."/projects/".$fig_project;
		if (!is_dir($project_dir)) {
			// project doesn't exist, should never happen: Force logout.
			session_destroy();
			echo "<script type='text/javascript'> parent.location.reload(); </script>";
			//echo "<script type='text/javascript'>console.log('\$project_dir = $project_dir');</script>";
			exit;
		}

		// load figure version from project.
		if (file_exists($project_dir.'/figVer.txt')) {
			$figVer  = 'v'.file_get_contents($project_dir.'/figVer.txt').'.';
		} else {
			$figVer  = '';
		}

		// Determine initial figure strings.
		$fig_CNV_SNP     = "users/".$fig_user."/projects/".$fig_project."/fig.CNV-SNP-map.2.".$figVer."png";
		$fig_CNV         = "users/".$fig_user."/projects/".$fig_project."/fig.CNV-map.2.".$figVer."png";
		if (file_exists("users/".$fig_user."/projects/".$fig_project."/fig.allelic_ratio-map.c2.".$figVer."png")) {   // ddRADseq.
			$fig_SNP = "users/".$fig_user."/projects/".$fig_project."/fig.allelic_ratio-map.c2.".$figVer."png";
		} else { // other.
			$fig_SNP = "users/".$fig_user."/projects/".$fig_project."/fig.SNP-map.2.".$figVer."png";
		}
		$fig_CNV_SNP_alt = "users/".$fig_user."/projects/".$fig_project."/fig.CNV-SNP-map.RedGreen.2.".$figVer."png";
		if (file_exists($fig_CNV_SNP))         { $initial_image = $fig_CNV_SNP; }
		elseif (file_exists($fig_CNV_SNP_alt)) { $initial_image = $fig_CNV_SNP_alt; }
		elseif (file_exists($fig_CNV))         { $initial_image = $fig_CNV; }
		elseif (file_exists($fig_SNP))         { $initial_image = $fig_SNP; }

		// Grab genome from user 1st project.
		$genomeName = trim(fgets(fopen("users/".$fig_user."/projects/".$fig_project."/genome.txt", 'r')));

		if ($calledBy === "cli") {
			print_r("users/".$fig_user."/genomes/".$genomeName."/\n");
			print_r("users/default/genomes/".$genomeName."/\n");
		}
		if (file_exists("users/".$fig_user."/genomes/".$genomeName."/")) {
			$genomeDir = "users/".$fig_user."/genomes/".$genomeName."/";
		} else if(file_exists("users/default/genomes/".$genomeName."/")) {
			$genomeDir = "users/default/genomes/".$genomeName."/";
		} else {
			// genome not found?
			$genomeName = "";
			$genomeDir  = "";
			//session_destroy();
			//echo "<script type='text/javascript'> parent.location.reload(); </script>";
			echo "<script type='text/javascript'>console.log('\$genomeName = $genomeName');</script>";
			//exit;
		}

		// Grab display name from 1st user project.
		if (file_exists("users/".$fig_user."/projects/".$fig_project."/")) {
			$projectDir = "users/".$fig_user."/projects/".$fig_project."/";
			$projectName = strip_tags(trim(file_get_contents("users/".$fig_user."/projects/".$fig_project."/name.txt")));
		} else if(file_exists("users/default/projects/".$fig_project."/")) {
			$projectDir = "users/default/projects/".$fig_project."/";
			$projectName = strip_tags(trim(file_get_contents("users/default/projects/".$fig_project."/name.txt")));
		} else {
			// project not found?
			$projectName = "";
			$projectDir  = "";
			//session_destroy();
			//echo "<script type='text/javascript'> parent.location.reload(); </script>";
			echo "<script type='text/javascript'>console.log('\$projectDir = $projectDir');</script>";
			//exit;
		}

		// Grab linear image fragments from genoem.
		$imageFile_top    = $genomeDir."fig.cartoon.2.top.png";
		$imageFile_middle = $genomeDir."fig.cartoon.2.middle.png";
		$imageFile_bottom = $genomeDir."fig.cartoon.2.bottom.png";

		// Load imagees
		$image_top    = imagecreatefrompng($imageFile_top   );
		$image_middle = imagecreatefrompng($imageFile_middle);
		$image_bottom = imagecreatefrompng($imageFile_bottom);

		// Get heights/width of image fragments.
		$imageHeight_top    = imagesy($image_top);
		$imageHeight_middle = imagesy($image_middle);
		$imageHeight_bottom = imagesy($image_bottom);
		$imageHeight        = $imageHeight_top+$imageHeight_middle+$imageHeight_bottom;
		$imageWidth         = imagesx($image_top);

		// define a white bottom panel (some genomes show annotations on individual figures.
		$image_bottom = imagecreate($imageWidth,$imageHeight_bottom);
		imagecolorallocate($image_bottom, 255, 255, 255);

		// determine number of images to combine.
		$numImages     = count($projectsShown_entries);

		// Calculate total final image height.
		$combinedHeight     = $imageHeight_top+$imageHeight_bottom+($imageHeight_middle+$imageHeight_bottom)*$numImages;

		// Make new images containers; width is same for all; height is same for first, then +140px for others (to contain only the cartoons).
		$working1      = imagecreatetruecolor($imageWidth,$combinedHeight);   // CNV-SNP/LOH
		$working2      = imagecreatetruecolor($imageWidth,$combinedHeight);   // CNV
		$working3      = imagecreatetruecolor($imageWidth,$combinedHeight);   // SNP/LOH
		$working4      = imagecreatetruecolor($imageWidth,$combinedHeight);   // CNV-SNP/LOH alternate colors.

		// Set backgrounds to white.
		setBackgroundWhite($working1);
		setBackgroundWhite($working2);
		setBackgroundWhite($working3);
		setBackgroundWhite($working4);

		//=========================
		// Build combined figures.
		//-------------------------
		$height_offset = 0;
		foreach ($projectsShown_entries as $entry_key => $projectsShown_entry) {
			// process subsequent projectsShown strings.
			$entry_parts = explode(":",$projectsShown_entry);
			$fig_user    = $entry_parts[0];
			$fig_project = $entry_parts[1];
			$fig_key     = $entry_parts[2];
			echo "<script type='text/javascript'>console.log('2 Combine images from: ".$fig_user.":".$fig_project.":".$fig_key."');</script>";

			// Grab genome from user project.
			$newGenomeName = trim(fgets(fopen("users/".$fig_user."/projects/".$fig_project."/genome.txt", 'r')));
			if (!(file_exists("users/".$fig_user."/genomes/".$newGenomeName."/") || file_exists("users/default/genomes/".$newGenomeName."/"))) {
				// genome not found?
				$newGenomeName = "";
			}

			// Grab display name from user project.
			if (file_exists("users/".$fig_user."/projects/".$fig_project."/")) {
				$projectDir = "users/".$fig_user."/projects/".$fig_project."/";
				$projectName = strip_tags(trim(file_get_contents("users/".$fig_user."/projects/".$fig_project."/name.txt")));
			} else if(file_exists("users/default/projects/".$fig_project."/")) {
				$projectDir = "users/default/projects/".$fig_project."/";
				$projectName = strip_tags(trim(file_get_contents("users/default/projects/".$fig_project."/name.txt")));
			} else {
				// project not found?
				$projectName = "";
				$projectDir  = "";
				//session_destroy();
				//echo "<script type='text/javascript'>parent.location.reload();</script>";
				echo "<script type='text/javascript'>console.log('$fig_project');</script>";
				//exit;
			}


			//================================================================
			// Validate sub-strings received from projectsShown string.
			//----------------------------------------------------------------
			// Confirm requested user exists.
			$user_dir = "users/".$fig_user;
			if (!file_exists($user_dir)) {
				// user doesn't exist, should never happen: Force logout.
				session_destroy();
				echo "<script type='text/javascript'> parent.location.reload(); </script>";
				exit;
			}

			// load figure version from project.
			if (file_exists($project_dir.'/figVer.txt')) {
				$figVer  = 'v'.file_get_contents($projectDir.'/figVer.txt').'.';
			} else {
				$figVer  = '';
			}

			// Determine figure strings.
			$fig_CNV_SNP             = $projectDir."/fig.CNV-SNP-map.2.".$figVer."png";
			$fig_CNV                 = $projectDir."/fig.CNV-map.2.".$figVer."png";
			if (file_exists(           $projectDir."/fig.allelic_ratio-map.c2.".$figVer."png")) {   // ddRADseq.
				$fig_SNP         = $projectDir."/fig.allelic_ratio-map.c2.".$figVer."png";
			} else { // other.
				$fig_SNP         = $projectDir."/fig.SNP-map.2.".$figVer."png";
			}
			if (file_exists(           $projectDir."/fig.CNV-SNP-map.RedGreen.2.".$figVer."png")) {
				// File doesn't get made for basic analysis.
				$fig_CNV_SNP_alt = $projectDir."/fig.CNV-SNP-map.RedGreen.2.".$figVer."png";
			} else {
				// Default to basic CNV-SNP plot if alternate color scheme file isn't found.
				$fig_CNV_SNP_alt = $fig_CNV_SNP;
			}

			// Loading existing images or making blank white images if source image doesn't exist in project.
			if (file_exists($fig_CNV_SNP)) {	$image1 = imagecreatefrompng($fig_CNV_SNP);
			} else {				$image1 = imagecreate($imageWidth,$imageHeight);
								imagecolorallocate($image1, 255, 255, 255);
			}
			if (file_exists($fig_CNV)) {		$image2 = imagecreatefrompng($fig_CNV);
			} else {				$image2 = imagecreate($imageWidth,$imageHeight);
								imagecolorallocate($image2, 255, 255, 255);
			}
			if (file_exists($fig_SNP)) {		$image3 = imagecreatefrompng($fig_SNP);
			} else {				 $image3 = imagecreate($imageWidth,$imageHeight);
								imagecolorallocate($image3, 255, 255, 255);
			}
			if (file_exists($fig_CNV_SNP_alt)) {	$image4 = imagecreatefrompng($fig_CNV_SNP_alt);
			} else {				$image4 = imagecreate($imageWidth,$imageHeight);
								imagecolorallocate($image4, 255, 255, 255);
			}

			// Grab center fragment of project images.
			$image1_middle = imagecrop($image1, ['x'=>0,'y'=>($imageHeight_top),'width'=>$imageWidth,'height'=>$imageHeight_middle]);
			$image2_middle = imagecrop($image2, ['x'=>0,'y'=>($imageHeight_top),'width'=>$imageWidth,'height'=>$imageHeight_middle]);
			$image3_middle = imagecrop($image3, ['x'=>0,'y'=>($imageHeight_top),'width'=>$imageWidth,'height'=>$imageHeight_middle]);
			$image4_middle = imagecrop($image4, ['x'=>0,'y'=>($imageHeight_top),'width'=>$imageWidth,'height'=>$imageHeight_middle]);

			// Define some colors.
			$white = imagecolorallocate($working1, 255, 255, 255);
			$black = imagecolorallocate($working1,   0,   0,   0);

			if ($entry_key == 0) {
				// Copy top image fragment.
				imagecopy($working1, $image_top, 0, 0, 0, 0,  $imageWidth, $imageHeight_top);
				imagecopy($working2, $image_top, 0, 0, 0, 0,  $imageWidth, $imageHeight_top);
				imagecopy($working3, $image_top, 0, 0, 0, 0,  $imageWidth, $imageHeight_top);
				imagecopy($working4, $image_top, 0, 0, 0, 0,  $imageWidth, $imageHeight_top);
				$height_offset += $imageHeight_top;

				// Copy bottom image fragment as a spacer.
				imagecopy($working1, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				imagecopy($working2, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				imagecopy($working3, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				imagecopy($working4, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				// add in project name.
				if ($genomeName == $newGenomeName) {
					imagestring($working1,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
					imagestring($working2,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
					imagestring($working3,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
					imagestring($working4,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
				} else {
					imagestring($working1,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
					imagestring($working2,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
					imagestring($working3,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
					imagestring($working4,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
				}
				$height_offset += $imageHeight_bottom;

				// Copy middle of linear project figure.
				if ($genomeName == $newGenomeName) {
					imagecopy($working1, $image1_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
					imagecopy($working2, $image2_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
					imagecopy($working3, $image3_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
					imagecopy($working4, $image4_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
				}
				$height_offset += $imageHeight_middle;

				echo "[] ".$entry_key." ".$fig_CNV_SNP."<br>\n";
			} else {
				// Copy bottom image fragment as a spacer.
				imagecopy($working1, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				imagecopy($working2, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				imagecopy($working3, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				imagecopy($working4, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
				// add in project name.
				if ($genomeName == $newGenomeName) {
					imagestring($working1,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
					imagestring($working2,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
					imagestring($working3,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
					imagestring($working4,5,10,$height_offset+$imageHeight_bottom-20,$projectName,$black);
				} else {
					imagestring($working1,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
					imagestring($working2,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
					imagestring($working3,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
					imagestring($working4,5,10,$height_offset+20,$projectName." : Was not analyzed with the same genome name as above, so isn't displayed.",$black);
				}
				$height_offset += $imageHeight_bottom;

				// Copy middle of linear project figure.
				if ($genomeName == $newGenomeName) {
					imagecopy($working1, $image1_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
					imagecopy($working2, $image2_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
					imagecopy($working3, $image3_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
					imagecopy($working4, $image4_middle, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_middle);
				}
				$height_offset += $imageHeight_middle;

				echo "...   ".$entry_key." ".$fig_CNV_SNP."<br>\n";
			}
		}
		// Copy bottom image fragment as end spacer.
		imagecopy($working1, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
		imagecopy($working2, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
		imagecopy($working3, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);
		imagecopy($working4, $image_bottom, 0, $height_offset, 0, 0,  $imageWidth, $imageHeight_bottom);

		// Save images and cleanup.
		imagepng($working1,"users/".$user."/combined_figure.1.png");
		imagepng($working2,"users/".$user."/combined_figure.2.png");
		imagepng($working3,"users/".$user."/combined_figure.3.png");
		imagepng($working4,"users/".$user."/combined_figure.4.png");
		imagedestroy($working1);
		imagedestroy($working2);
		imagedestroy($working3);
		imagedestroy($working4);
		imagedestroy($image1);
		imagedestroy($image2);
		imagedestroy($image3);
		imagedestroy($image4);
	}
?>
