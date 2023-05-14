<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	require_once 'SecureNewDirectory.php';
	ini_set('display_errors', 1);

	// If the user is not logged on, redirect to login page.
	if(!isset($_SESSION['logged_on'])){
		session_destroy();
		header('Location: .');
	}

	// Load user string from session.
	$user   = $_SESSION['user'];

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
?>
	<html>
	<body>
	<script type="text/javascript">
	var el1 = parent.document.getElementById('Hidden_InstallNewGenome');
	el1.style.display = 'none';

	var el2 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('name_error_comment');
	el2.style.visibility = 'visible';

	window.location = "genome.create_window.php";
	</script>
	</body>
	</html>
<?php
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
?>
	<html>
	<body>
	<script type="text/javascript">
	var el1 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('newly_installed_list');
	el1.innerHTML += "<?php echo $_SESSION['pending_install_genome_count']; ?>. <?php echo $genome; ?><br>";

	var el2 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('pending_comment');
	el2.style.visibility = 'visible';

	var el3 = parent.document.getElementById('panel_genome_iframe').contentDocument.getElementById('name_error_comment');
	el3.style.visibility = 'hidden';

	var el4 = parent.document.getElementById('Hidden_InstallNewGenome');
	el4.style.display = 'none';

	window.location = "genome.create_window.php";
	</script>
	</body>
	</html>
<?php
	}
?>
