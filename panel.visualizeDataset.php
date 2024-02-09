<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
?>
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<font size='3'>View figures for installed datasets at bottom of page by selecting checkboxes.</font><br><br>
<table width="100%" cellpadding="0"><tr>
<td width="65%" valign="top">
	<?php
	//.---------------.
	//| User projects |
	//'---------------'
	if (isset($_SESSION['logged_on'])) {
		$projectsDir      = "users/".$user."/projects/";
		$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.'));
		// Sort directories by date, newest first.
		array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);
		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectsDir,"",$folder);   }
		// Split project list into ready/working/starting lists for sequential display.
		$projectFolders_complete = array();
		$projectFolders_working  = array();
		$projectFolders_starting = array();
		foreach($projectFolders as $key=>$project) {
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (is_dir("users/".$user."/projects/".$project)) {
				array_push($projectFolders_starting,$project);
			}
		}
		$userProjectCount_starting = count($projectFolders_starting);
		$userProjectCount_working  = count($projectFolders_working);
		$userProjectCount_complete = count($projectFolders_complete);

		// Sort complete and working projects alphabetically.
		array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working);
		array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);
		// Build new 'projectFolders' array;
		$projectFolders   = array();
		$projectFolders   = array_merge($projectFolders_working, $projectFolders_starting, $projectFolders_complete);
		$userProjectCount = count($projectFolders);

		echo "<b><font size='2'>User installed datasets:</font></b>\n\t\t";
		echo "<br>\n\t\t";

		foreach($projectFolders_working as $key_=>$project) {
			// Load colors for project.
			[$colorString1, $colorString2] = getColors($user,$project);

			// getting genome name for project.
			$genome_name = "<font size='1'> vs genome [".getGenomeName($user,$project)."]</font>";
			$genome_name = str_replace("+ ","",$genome_name);

			// getting figure version for project.
			$versionFile     = "users/".$user."/projects/".$project."/figVer.txt";
			if (file_exists($versionFile)) {
				$figVer = intval(trim(file_get_contents($versionFile)));
			} else {
				$figVer = 0;
			}

			// getting project name.
			$nameFile        = "users/".$user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$user."/projects/".$project."/parent.txt";
			if (file_exists($nameFile) and file_exists($parent_file)) {
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);

				$dataFormat_file        = "users/".$user."/projects/".$project."/dataFormat.txt";
				if (file_exists($dataFormat_file)) {
					$handle       = fopen($dataFormat_file,'r');
					$dataFormat     = trim(fgets($handle));
					fclose($handle);
				} else {
					$dataFormat     = 'null';
				}
				if (strcmp($dataFormat,"0") == 0) {
					$colorString1 = "cyan";
					$colorString2 = "magenta";
					}
				$handle               = fopen($parent_file,'r');
				$parentString         = trim(fgets($handle));
				fclose($handle);
				$key = $key_;
				echo "<span id='p_label_".$key."' style='color:#BB9900;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."' type='checkbox' onclick=\"parent.openProject('".$user."','".$project."','".$key."','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."','".$figVer."');\" style=\"visibility:hidden;\">";
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."'></div>";
			} else {
				// an error has happend.
				$key = $key_;
				echo "<span id='p_label_".$key."' style='color:#888888;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."' type='checkbox'>";
				echo "\n\t\t".$project."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."'></div>";
			}
		}

		foreach($projectFolders_starting as $key_=>$project) {
			// Load colors for project.
			[$colorString1, $colorString2] = getColors($user,$project);

			// getting genome name for project.
			$genome_name = "<font size='1'> vs genome [".getGenomeName($user,$project)."]</font>";
			$genome_name = str_replace("+ ","",$genome_name);

			// getting figure version for project.
			$versionFile     = "users/".$user."/projects/".$project."/figVer.txt";
			if (file_exists($versionFile)) {
				$figVer = intval(trim(file_get_contents($versionFile)));
			} else {
				$figVer = 0;
			}

			// getting project name.
			$nameFile        = "users/".$user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$user."/projects/".$project."/parent.txt";
			if (file_exists($nameFile) and file_exists($parent_file)) {
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);

				$dataFormat_file        = "users/".$user."/projects/".$project."/dataFormat.txt";
				if (file_exists($dataFormat_file)) {
					$handle         = fopen($dataFormat_file,'r');
					$dataFormat     = trim(fgets($handle));
					fclose($handle);
				} else {
					$dataFormat     = 'null';
				}
				if (strcmp($dataFormat,"0") == 0) {
					$colorString1 = "cyan";
					$colorString2 = "magenta";
				}

				$handle               = fopen($parent_file,'r');
				$parentString         = trim(fgets($handle));
				fclose($handle);
				$key = $key_ + $userProjectCount_working;
				echo "<span id='p_label_".$key."' style='color:#CC0000;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."' type='checkbox' onclick=\"parent.openProject('".$user."','".$project."','".$key."','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."','".$figVer."');\" style=\"visibility:hidden;\">";
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."'></div>";
			} else {
				// an error has happened.
				$key = $key_ + + $userProjectCount_working;
				echo "<span id='p_label_".$key."' style='color:#888888;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."' type='checkbox'>";
				echo "\n\t\t".$project."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."'></div>";
			}
		}

		foreach($projectFolders_complete as $key_=>$project) {
			// Load colors for project.
			[$colorString1, $colorString2] = getColors($user,$project);

			// getting genome name for project.
			$genome_name = "<font size='1'> vs genome [".getGenomeName($user,$project)."]</font>";
			$genome_name = str_replace("+ ","",$genome_name);

			// getting figure version for project.
			$versionFile     = "users/".$user."/projects/".$project."/figVer.txt";
			if (file_exists($versionFile)) {
				$figVer = intval(trim(file_get_contents($versionFile)));
			} else {
				$figVer = 0;
			}

			// getting project processing completion date/time.
			$dateFile     = "users/".$user."/projects/".$project."/working_done.txt";
			if (file_exists($dateFile)) {
				$figDate = trim(file_get_contents($dateFile));
			} else {
				$figDate = 0;
			}

			// getting project name.
			$nameFile        = "users/".$user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$user."/projects/".$project."/parent.txt";
			if (file_exists($nameFile) and file_exists($parent_file)) {
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);

				$dataFormat_file        = "users/".$user."/projects/".$project."/dataFormat.txt";
				if (file_exists($dataFormat_file)) {
					$handle       = fopen($dataFormat_file,'r');
					$dataFormat     = trim(fgets($handle));
					fclose($handle);
				} else {
					$dataFormat     = 'null';
				}
				if (strcmp($dataFormat,"0") == 0) {
					$colorString1 = "cyan";
					$colorString2 = "magenta";
				}

				// Limit files list to valid output file types.
				$projectFiles	= preg_grep('~\.(png|eps|bed|gff3)$~', scandir("users/$user/projects/$project/"));
				sort($projectFiles);
				$json_file_list	= json_encode($projectFiles);

				// Get parent.
				$handle		= fopen($parent_file,'r');
				$parentString	= trim(fgets($handle));
				fclose($handle);

				$key = $key_ + $userProjectCount_starting + $userProjectCount_working;
				echo "<span id='project_label_".$key."' style='color:#00AA00;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_$key' type='checkbox' onclick=\"parent.openProject('$user','$project','$key','$projectNameString','$colorString1','$colorString2','$parentString','$figVer'); window.top.hide_combined_fig_menu();\" data-file-list='$json_file_list' >";
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
				echo "<font size='1' style='color:#999999;'> - Completed: ".$figDate."</font>";
				echo "<span id='p2_".$project."_delete'></span><span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p1_".$key."'></div>";
			} else {
				// an error has happened;
				$key = $key_ + $userProjectCount_starting;
				echo "<span id='p_label_".$key."' style='color:#888888;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."' type='checkbox'>";
				echo "\n\t\t".$project."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."'></div>";
			}
		}

	} else {
		$userProjectCount_starting = 0;
		$userProjectCount_working  = 0;
		$userProjectCount_complete = 0;
	}

	function getColors($user,$project) {
		//[$colorStrin1, $colorStrin2] = getColors($user,$project);
		$colors_file  = "users/".$user."/projects/".$project."/colors.txt";
		if (file_exists($colors_file)) {
			$handle       = fopen($colors_file,'r');
			$colorString1 = trim(fgets($handle));
			$colorString2 = trim(fgets($handle));
			fclose($handle);
		} else {
			$colorString1 = 'null';
			$colorString2 = 'null';
		}
		return [$colorString1,$colorString2];
	}


	function getGenomeName($user,$project) {
		// grab genome.txt from project.
		$genome_file = "users/".$user."/projects/".$project."/genome.txt";
		if (file_exists($genome_file)) {
			$handle      = fopen($genome_file,'r');
			$genome      = trim(fgets($handle));
			fclose($handle);
		} else {
			$genome      = '';
		}

		// grab name.txt from genome.
		if ($genome != "") {
			$genomeName_file1 = "users/".$user."/genomes/".$genome."/name.txt";
			$genomeName_file2 = "users/default/genomes/".$genome."/name.txt";
			if (file_exists($genomeName_file1)) {
				$handle      = fopen($genomeName_file1,'r');
				$genome_name = trim(fgets($handle));
				fclose($handle);
			} else if (file_exists($genomeName_file2)) {
				$handle      = fopen($genomeName_file2,'r');
				$genome_name = trim(fgets($handle));
				fclose($handle);
			} else {
				$genome_name = "";
			}
		} else {
			$genome_name = "";
		}

		return $genome_name;
	}

	?>
</td><td width="35%" valign="top">
	<br><?php
	//.-----------------.
	//| System projects |
	//'-----------------'
	$projectsDir            = "users/default/projects/";
	$systemProjectFolders_1 = array_diff(glob($projectsDir."*"), array('..', '.'));
	// Sort directories by date, newest first.
	array_multisort($systemProjectFolders_1, SORT_ASC, $systemProjectFolders_1);
	// Trim path from each folder string.
	foreach($systemProjectFolders_1 as $key=>$folder) {
		$systemProjectFolders_1[$key] = str_replace($projectsDir,"",$folder);
	}
	// Remove any non-folders from list.
	$systemProjectFolders = array();
	foreach($systemProjectFolders_1 as $project) {
		if (is_dir("users/default/projects/".$project)) {
			array_push($systemProjectFolders,$project);
		}
	}
	$systemProjectCount = count($systemProjectFolders);
	echo "<b><font size='2'>Sample datasets:</font></b>\n\t\t";
	echo "<br>\n\t\t";
	foreach ($systemProjectFolders as $key_=>$project) {
		// Load colors for project.
		$colors_file          = "users/default/projects/".$project."/colors.txt";
		if (file_exists($colors_file)) {
			$handle       = fopen($colors_file,'r');
			$colorString1 = trim(fgets($handle));
			$colorString2 = trim(fgets($handle));
			fclose($handle);
		} else {
			$colorString1 = 'null';
			$colorString2 = 'null';
		}

		// getting figure version for project.
		$versionFile     = "users/default/projects/".$project."/figVer.txt";
		if (file_exists($versionFile)) {
			$figVer = intval(trim(file_get_contents($versionFile)));
		} else {
			$figVer = 0;
		}

		// Limit files list to valid output file types.
		$projectFiles   = preg_grep('~\.(png|eps|bed|gff3)$~', scandir("users/default/projects/$project/"));
		sort($projectFiles);
		$json_file_list = json_encode($projectFiles);

		// Get parent.
		$parent_file    = "users/default/projects/".$project."/parent.txt";
		$handle         = fopen($parent_file,'r');
		$parentString   = trim(fgets($handle));
		fclose($handle);

		$nameFile       = "users/default/projects/".$project."/name.txt";
		if (file_exists($nameFile)) {
			$projectNameString = file_get_contents($nameFile);
			$projectNameString = trim($projectNameString);
		} else {
			$projectNameString = $project;
		}

		$key = $key_ + $userProjectCount_starting + $userProjectCount_working + $userProjectCount_complete;
		echo "<font size='2'>".($key+1).".";
		echo "<input id='show_".$key."_sys' type='checkbox' onclick=\"parent.openProject('default','".$project."','".$key."_sys','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."','".$figVer."');\" data-file-list='".$json_file_list."'>";

		echo $projectNameString."</font>";
		echo "<br>\n\t\t";
	}
	?>
</td></tr></table>
<script type="text/javascript">

if(localStorage.getItem("projectsShown")){
	var projectsShown = localStorage.getItem("projectsShown");
}
</script>
