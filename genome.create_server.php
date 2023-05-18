<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	require_once 'SecureNewDirectory.php';
	ini_set('display_errors', 1);

	// If the user is not logged on, redirect to login page.
	if(!isset($_SESSION['logged_on'])) {
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
		// Sanitize input string.
		$genome = sanitize_POST("newGenomeName");

		// construct directory locations.
		$dir1   = "users/".$user."/genomes";
		$dir2   = "users/".$user."/genomes/".$genome;
		$dir3   = "users/default/genomes/".$genome;

		// Deals with accidental deletion of user/genomes dir.
		if (!file_exists($dir1)){
			mkdir($dir1);
			secureNewDirectory($dir1);
			chmod($dir1,0777);
		}

		// Checks if existing genome shares requested name.
		if (file_exists($dir2) || file_exists($dir3)) {
			// Directory already exists
			echo "Genome '".$genome."' directory already exists.";

			log_stuff($user,"","",$genome,"","genome:CREATE failure");

			echo "<html>\n<body>\n<script type='text/javascript'>\n";
			echo "var el1 = parent.document.getElementById('Hidden_InstallNewGenome');\n";
			echo "el1.style.display = 'none';\n\n";
			echo "var el2 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('name_error_comment');\n";
			echo "el2.style.visibility = 'visible';\n\n";
			echo "window.location = 'genome.create_window.php';\n";
			echo "</script>\n</body>\n</html>\n";
		} else {
			// Create the genome folder inside the user's genomes directory
			mkdir($dir2);
			secureNewDirectory($dir2);
			chmod($dir2,0777);

			// Generate 'name.txt' file containing:
			//      one line; name of genome.
			$outputName   = "users/".$user."/genomes/".$genome."/name.txt";
			$output       = fopen($outputName, 'w');
			fwrite($output, $genome);
			fclose($output);

			$_SESSION['pending_install_genome_count'] += 1;
			log_stuff($user,"","",$genome,"","genome:CREATE success");

			echo "<html>\n<body>\n<script type='text/javascript'>\n";
			echo "var el1 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('newly_installed_list');\n";
			echo "el1.innerHTML += ".$_SESSION['pending_install_genome_count'].". ".$genome."<br>\n";
			echo "var el2 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('pending_comment');\n";
			echo "el2.style.visibility = 'visible';\n";
			echo "var el3 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('name_error_comment');\n";
			echo "el3.style.visibility = 'hidden';\n\n";
			echo "var el4 = parent.document.getElementById('Hidden_InstallNewGenome');\n";
			echo "el4.style.display = 'none';\n\n";
			echo "window.location = 'genome.create_window.php';\n";
			echo "</script>\n</body>\n</html>\n";
		}
		log_stuff($user,"","",$genome,"","genome:CREATE success.");
	}
?>
