<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	"http://w3.org/TR/html4/loose.dtd">
<HEAD>
	<style type="text/css">
		body {font-family: arial;}
	</style>
	<meta charset="UTF-8">
</HEAD>
<BODY>
<?php
	session_start();
	error_reporting(E_ALL);
        require_once '../../constants.php';
	require_once '../../POST_validation.php';
	require_once '../../SecureNewDirectory.php';
	require_once '../../sharedFunctions.php';
        ini_set('display_errors', 1);

	// If the user is not logged on, redirect to login page.
	if(!isset($_SESSION['logged_on'])){
		session_destroy();
		?><script type="text/javascript"> parent.location.reload(); </script><?php
	}

	// Load user string from session.
	$user       = $_SESSION['user'];

	// Validate input strings.
	$hapmap            = sanitize_POST("hapmap");
	$genome            = sanitize_POST("genome");
	$HapmapSetupOption = sanitizeFloat_POST("HapmapSetupOption");
	$parent            = sanitize_POST("parent");
	$child             = sanitize_POST("child");
	$parentHaploid1    = sanitize_POST("parentHaploid1");
	$parentHaploid2    = sanitize_POST("parentHaploid2");
	$parentHapmap      = sanitize_POST("parentHapmap");
	$derived           = sanitize_POST("derived");

	// a couple directories for later use.
	$hapmap_dir1 = "../../users/".$user."/hapmaps/".$hapmap;
	$hapmap_dir2 = "../../users/default/hapmaps/".$hapmap;

	// Confirm if requested genome exists.
	$genome_dir1 = "../../users/".$user."/genomes/".$genome;
	$genome_dir2 = "../../users/default/genomes/".$genome;
	if (!(is_dir($genome_dir1) || is_dir($genome_dir2))) {
		// Genome doesn't exist, should never happen: Force logout.
		session_destroy();
		?><script type="text/javascript"> parent.location.reload(); </script><?php
	}

	if ($parent != '') {
		// Confirm if requested project1 project exists.
		$parent_dir1 = "../../users/".$user."/projects/".$parent;
		$parent_dir2 = "../../users/default/projects/".$parent;
		if (!(is_dir($parent_dir1) || is_dir($parent_dir2))) {
			// Parent project doesn't exist, should never happen: Force logout.
			session_destroy();
			?><script type="text/javascript"> parent.location.reload(); </script><?php
		}
	}

	if ($child != '') {
		// Confirm if requested project1 project exists.
		$child_dir1 = "../../users/".$user."/projects/".$child;
		$child_dir2 = "../../users/default/projects/".$child;
		if (!(is_dir($child_dir1) || is_dir($child_dir2))) {
			// Child project doesn't exist, should never happen: Force logout.
			session_destroy();
			?><script type="text/javascript"> parent.location.reload(); </script><?php
		}
	}

	if ($parentHaploid1 != '') {
		// Confirm if requested parentHaploid1 project exists.
		$parentHaploid1_dir1 = "../../users/".$user."/projects/".$parentHaploid1;
		$parentHaploid1_dir2 = "../../users/default/projects/".$parentHaploid1;
		if (!(is_dir($parentHaploid1_dir1) || is_dir($parentHaploid1_dir2))) {
			// parentHaploid1 project doesn't exist, should never happen: Force logout.
			session_destroy();
			?><script type="text/javascript"> parent.location.reload(); </script><?php
		}
	}

	if ($parentHaploid2 != '') {
		// Confirm if requested parentHaploid2 project exists.
		$parentHaploid2_dir1 = "../../users/".$user."/projects/".$parentHaploid2;
		$parentHaploid2_dir2 = "../../users/default/projects/".$parentHaploid2;
		if (!(is_dir($parentHaploid2_dir1) || is_dir($parentHaploid2_dir2))) {
			// parentHaploid2 project doesn't exist, should never happen: Force logout.
			session_destroy();
			?><script type="text/javascript"> parent.location.reload(); </script><?php
		}
	}

	if ($parentHapmap != '') {
		// Confirm if requested parentHapmap project exists.
		$parentHapmap_dir1 = "../../users/".$user."/hapmaps/".$parentHapmap;
		$parentHapmap_dir2 = "../../users/default/hapmaps/".$parentHapmap;
		if (!(is_dir($parentHapmap_dir1) || is_dir($parentHapmap_dir2))) {
			// parentHapmap project doesn't exist, should never happen: Force logout.
			session_destroy();
			?><script type="text/javascript"> parent.location.reload(); </script><?php
		}
		if (is_dir($parentHapmap_dir1)) {
			$parentHapmap_dir = $parentHapmap_dir1;
		} else {
			$parentHapmap_dir = $parentHapmap_dir2;
		}

	}

	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	// Deals with accidental deletion of user/hapmaps dir.
	$dir1            = "../../users/".$user."/hapmaps";
	if (!file_exists($dir1)){
		mkdir($dir1);
		secureNewDirectory($dir1);
		chmod($dir1,0777);
	}

	if (file_exists($hapmap_dir1) || file_exists($hapmap_dir2)) {
		// Directory already exists
		echo "Hapmap '".$hapmap."' directory already exists.";
		exit;
	} else {
		if (($HapmapSetupOption == 2) || ($HapmapSetupOption == 1)) {
			// Make a form to generate a form to POST information to pass along to the next page in the process.
			echo "<script type=\"text/javascript\">\n";
			echo "\tvar autoSubmitForm = document.createElement('form');\n";
			echo "\t\tautoSubmitForm.setAttribute('method','post');\n";
			echo "\t\tautoSubmitForm.setAttribute('action','hapmap.install_2.php');\n";

			echo "\tvar input2 = document.createElement('input');\n";
			echo "\t\tinput2.setAttribute('type','hidden');\n";
			echo "\t\tinput2.setAttribute('name','hapmap');\n";
			echo "\t\tinput2.setAttribute('value','{$hapmap}');\n";
			echo "\t\tautoSubmitForm.appendChild(input2);\n";

			echo "\tvar input2 = document.createElement('input');\n";
			echo "\t\tinput2.setAttribute('type','hidden');\n";
			echo "\t\tinput2.setAttribute('name','genome');\n";
			echo "\t\tinput2.setAttribute('value','{$genome}');\n";
			echo "\t\tautoSubmitForm.appendChild(input2);\n";

			echo "\tvar input3 = document.createElement('input');\n";
			echo "\t\tinput3.setAttribute('type','hidden');\n";
			echo "\t\tinput3.setAttribute('name','HapmapSetupOption');\n";
			echo "\t\tinput3.setAttribute('value','{$HapmapSetupOption}');\n";
			echo "\t\tautoSubmitForm.appendChild(input3);\n";

			if ($HapmapSetupOption == 2) {
				$project1 = $parent;
				$project2 = $child;
			} else if ($HapmapSetupOption == 1) {
				$project1 = $parentHaploid1;
				$project2 = $parentHaploid2;
			}

			echo "\tvar input4 = document.createElement('input');\n";
			echo "\t\tinput4.setAttribute('type','hidden');\n";
			echo "\t\tinput4.setAttribute('name','project1');\n";
			echo "\t\tinput4.setAttribute('value','{$project1}');\n";
			echo "\t\tautoSubmitForm.appendChild(input4);\n";

			echo "\tvar input5 = document.createElement('input');\n";
			echo "\t\tinput5.setAttribute('type','hidden');\n";
			echo "\t\tinput5.setAttribute('name','project2');\n";
			echo "\t\tinput5.setAttribute('value','{$project2}');\n";
			echo "\t\tautoSubmitForm.appendChild(input5);\n";
			echo "\t\tdocument.body.appendChild(autoSubmitForm);";
			echo "\tautoSubmitForm.submit();\n";

			echo "</script>";
		} else {
			// Pass control over to a shell script ('scripts_seqModules/scripts_hapmaps/hapmap.trim_1.sh') to continue processing.

			// make new hapmap dir.
			$hapmap_dir       = "../../users/".$user."/hapmaps/".$hapmap;
			mkdir($hapmap_dir);

			// Generate 'working.txt' file to let pipeline know processing is started.
			$fileName   = $hapmap_dir."/working.txt";
			$file       = fopen($fileName, 'w');
			$startTimeString = date("Y-m-d H:i:s");
			fwrite($file, $startTimeString);
			fclose($file);
			chmod($fileName,0664);

			// migrate files from parentHapmap
			copy($parentHapmap_dir."/index.php",$hapmap_dir."/index.php");
			copy($parentHapmap_dir."/colors.txt",$hapmap_dir."/colors.txt");
			copy($parentHapmap_dir."/genome.txt",$hapmap_dir."/genome.txt");

			// generate name.txt file.
			$fileName   = $hapmap_dir."/name.txt";
			$file       = fopen($fileName, 'w');
			$nameString = $parentHapmap." -> ".$hapmap;
			fwrite($file, $nameString);
			fclose($file);
			chmod($fileName,0664);

			// make trimmed hapmap.
			$system_call_string = "sh hapmap.trim_1.sh ".$user." ".$hapmap." ".$parentHapmap." ".$derived." > /dev/null &";
			system($system_call_string);
		}
	}

	log_stuff($user,"",$hapmap,"","","H:CREATE success");
?>
</BODY>
</HTML>
