<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else if ($_SESSION['logged_on'] == 0) {
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else {
		if(!isset($_SESSION['user'])){
			$user = "";
		} else {
			$user = $_SESSION['user'];
		}
	}
	if ($user == "") {   unset($_SESSION['logged_on']);   }
?>
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<font size='3'>View figures for installed datasets by selecting checkboxes.</font><br><br>
<table width="100%" cellpadding="0"><tr>
<td width="65%" valign="top">
	<?php
	//.---------------.
	//| User projects |
	//'---------------'
	if (isset($_SESSION['logged_on'])) {
		$projectsDir      = "users/".$user."/projects/";
		$projectFolders = [];
		$objects = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($projectsDir), RecursiveIteratorIterator::SELF_FIRST);
		foreach($objects as $name => $object){
			if (is_dir($name)) {
				$name_ = str_replace($projectsDir,"",$name);
				if ($name_ === "." || $name_ === ".." || str_ends_with($name_,"/.") || str_ends_with($name_,"/..")) {
				} else {
					$projectFolders[] = $name_;
				}
			}
		}

		// Sort directories by date, newest first.
		sort($projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {
			$projectFolders[$key] = str_replace($projectsDir,"",$folder);
		}
		// Split project list into ready/working/starting lists for sequential display.
		$projectFolders_subdir    = array();
		$projectFolders_complete  = array();
		$projectFolders_queue     = array();
		$projectFolders_working   = array();
		$projectFolders_initiated = array();
		foreach($projectFolders as $key=>$project) {
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (file_exists("users/".$user."/projects/".$project."/bulk.txt")) {
				array_push($projectFolders_queue, $project);
			} else if (file_exists("users/".$user."/projects/".$project."/name.txt")) {
				array_push($projectFolders_initiated,$project);
			} else {
				array_push($projectFolders_subdir,$project);
			}
		}
		$userProjectCount_initiated = count($projectFolders_initiated);
		$userProjectCount_queue     = count($projectFolders_queue);
		$userProjectCount_working   = count($projectFolders_working );
		$userProjectCount_complete  = count($projectFolders_complete);
		// Sort lists alphabetically.
		array_multisort($projectFolders_subdir,       SORT_ASC, $projectFolders_subdir      );
		array_multisort($projectFolders_complete,     SORT_ASC, $projectFolders_complete    );
		array_multisort($projectFolders_queue,        SORT_ASC, $projectFolders_queue       );
		array_multisort($projectFolders_working,      SORT_ASC, $projectFolders_working     );
		array_multisort($projectFolders_initiated,    SORT_ASC, $projectFolders_initiated   );

		// Build new 'projectFolders' array;
		$userProjectCount = count($projectFolders);

		echo "<font size='2'><b>User installed datasets:</b> (View all.";
		echo "<input id='show_All_User' type='checkbox' onclick=\" open_All_UserProjects(); window.top.hide_combined_fig_menu();\">)</font>";
		echo "<br>\n\t\t";

		$key_offset = 0;
		$prefix = "";

		// Add projects not yet started to user interface.
		foreach($projectFolders_initiated as $key_=>$project) {
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("1", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}

		// Add projects being worked on to user interface.
		foreach($projectFolders_working as $key_=>$project) {
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("1", $key_real, "000000", "FFFFCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}

		// Add projects in queue to user interface.
		foreach($projectFolders_queue as $key_=>$project) {
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("1", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}

		// Add completed projects to user interface.
		foreach($projectFolders_complete as $key_=>$project) {
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("2", $key_real, "000000", "CCFFCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}

		foreach($projectFolders_subdir as $key1_=>$subdir) {
			echo "<input id='show_".$subdir."_User' type='checkbox' onclick=\"open_".$subdir."_UserProjects(); window.top.hide_combined_fig_menu();\"></font> <font size='2'><b>".$subdir."</b></font><br>\n";

			$prefix = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";

			// Add projects not yet started to user interface.
			foreach($projectFolders_initiated as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("1", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}

			// Add other projects being worked on to user interface.
			foreach($projectFolders_working as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("1", $key_real, "000000", "FFFFCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}

			// Add projects in queue to user interface.
			foreach($projectFolders_queue as $key_=>$project) {
				if (str_contains($project,"/")) {
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("1", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}

			// Add completed projects to user interface.
			foreach($projectFolders_complete as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("2", $key_real, "000000", "CCFFCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}
		}


		//
		// Define javascript function to show all complete projects.
		//
		echo "\n\n<script>\n";
		echo "function open_All_UserProjects() {\n";
		foreach($projectFolders_complete as $key_=>$project) {
			$warning_file    = "users/".$user."/projects/".$project."/warning.txt";
			if (file_exists($warning_file)) {
				$warning_string = trim(file_get_contents($warning_file));
			} else {
				$warning_string = "";
			}

			$nameFile        = "users/".$user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$user."/projects/".$project."/parent.txt";

			$projectNameString = file_get_contents($nameFile);
			$projectNameString = trim($projectNameString);

			[$colorString1, $colorString2] = getColors($user,$project);

			// Get parent.
			$handle         = fopen($parent_file,'r');
			$parentString   = trim(fgets($handle));
			fclose($handle);

			// getting figure version for project.
			$versionFile    = "users/".$user."/projects/".$project."/figVer.txt";
			$figVer         = 0;
			if (file_exists($versionFile)) {
				$figVer = intval(trim(file_get_contents($versionFile)));
			}

			$key_real = array_search($project,$projectFolders);
			echo "\tdocument.getElementById('show_p".$key_real."').checked = document.getElementById('show_All_User').checked;\n";
			echo "\tparent.openProject('$user','$project','$key_real','$projectNameString','$colorString1','$colorString2','$parentString','$figVer','$warning_string');\n\n";
		}
		echo "\twindow.top.hide_combined_fig_menu();\n";
		echo "}\n";
		foreach($projectFolders_subdir as $key_=>$subdir) {
			echo "function open_".$subdir."_UserProjects() {\n";
			foreach($projectFolders_complete as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					$warning_file    = "users/".$user."/projects/".$project."/warning.txt";
					if (file_exists($warning_file)) {
						$warning_string = trim(file_get_contents($warning_file));
					} else {
						$warning_string = "";
					}

					$nameFile        = "users/".$user."/projects/".$project."/name.txt";
					$parent_file     = "users/".$user."/projects/".$project."/parent.txt";

					$projectNameString = file_get_contents($nameFile);
					$projectNameString = trim($projectNameString);

					[$colorString1, $colorString2] = getColors($user,$project);

					// Get parent.
					$handle         = fopen($parent_file,'r');
					$parentString   = trim(fgets($handle));
					fclose($handle);

					// getting figure version for project.
					$versionFile    = "users/".$user."/projects/".$project."/figVer.txt";
					$figVer         = 0;
					if (file_exists($versionFile)) {
						$figVer = intval(trim(file_get_contents($versionFile)));
					}

					$key_real = array_search($project,$projectFolders);
					echo "\tdocument.getElementById('show_p".$key_real."').checked = document.getElementById('show_".$subdir."_User').checked;\n";
					echo "\tparent.openProject('$user','$project','$key_real','$projectNameString','$colorString1','$colorString2','$parentString','$figVer','$warning_string');\n\n";
				}
			}
			echo "\twindow.top.hide_combined_fig_menu();\n";
			echo "}\n";
		}
		echo "</script>\n\n";

	} else {
		$userProjectCount_initiated = 0;
		$userProjectCount_working  = 0;
		$userProjectCount_complete = 0;
	}

	function printProjectFolderInfo($subdir,$projectFolders) {
		$key_real = array_search($subdir,$projectFolders);
		echo "<br><font size='2'><b>".$subdir."</b></font>\n";
		echo "<br>";
	}
	function printProjectInfo($frameContainerIx ,$key_, $labelRgbColor, $labelRgbBackgroundColor, $user, $project,$key_display,$prefix) {
		$frameContainerIx = trim($frameContainerIx);
		// Load colors for project.
		[$colorString1, $colorString2] = getColors($user,$project);

		// getting genome name for project.
		if (getHapmapName($user,$project) != "") {
			$genome_name = "<font size='1'> vs genome [".getGenomeName($user,$project)."] & hapmap [".getHapmapName($user,$project)."]</font>";
		} else {
			$genome_name = "<font size='1'> vs genome [".getGenomeName($user,$project)."]</font>";
		}
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

		// Get project folder name.
		$position = strpos($project, '/');
		$project_ = $position !== false ? trim(substr($project,$position+1)) : $project;

		if (file_exists($nameFile) and file_exists($parent_file)) {
			$projectNameString = file_get_contents($nameFile);
			$projectNameString = trim($projectNameString);

			$warning_file    = "users/".$user."/projects/".$project."/warning.txt";
			if (file_exists($warning_file)) {
				$warning_string = trim(file_get_contents($warning_file));
			} else {
				$warning_string = "";
			}

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

			// Collect output file names, passed to javascript function that builds user interface elements.
			// Limit files to valid output file types.
			$projectFiles   = preg_grep('~\.(png|eps|bed|gff3|zip)$~', scandir("users/$user/projects/$project/"));
			sort($projectFiles);
			$json_file_list = json_encode($projectFiles);

			// Get parent.
			$handle         = fopen($parent_file,'r');
			$parentString   = trim(fgets($handle));
			fclose($handle);

			$key = $key_;
			echo $prefix."<span id='p_label_".$key."' style='color:#".$labelRgbColor."; background-color:#".$labelRgbBackgroundColor."'>\n\t\t";
			echo "<font size='2'>".($key_display+1).".";
			if ($frameContainerIx == "2") {
				echo "<input id='show_p".$key."' type='checkbox' onclick=\"parent.openProject('$user','$project','$key','$projectNameString','$colorString1','$colorString2','$parentString','$figVer','$warning_string'); window.top.hide_combined_fig_menu();\" data-file-list='$json_file_list' >";
			} else {
				echo "<input id='show_p".$key."' type='checkbox' onclick=\"parent.openProject('$user','$project','$key','$projectNameString','$colorString1','$colorString2','$parentString','$figVer','$warning_string'); window.top.hide_combined_fig_menu();\" data-file-list='$json_file_list' style='visibility:hidden;'>";
			}
			if ($project_ == $projectNameString) {
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
			} else {
				echo "\n\t\t".$project_." (".$projectNameString.")</font></span> ".$genome_name."\n\t\t";
			}
			echo "<font size='1' style='color:#999999;'> - Completed: ".$figDate."</font>";
			echo "<span id='p2_".$project."_delete'></span><span id='p_".$project."_type'></span>\n\t\t";
			echo "<br>\n\t\t";
			echo "<div id='frameContainer.p1_".$key."'></div>";
		} else {
			// an error has happened;
			$key = $key_;
			echo $prefix."<span id='p_label_".$key."' style='color:#888888;'>\n\t\t";
			echo "<font size='2'>".($key_display+1).".";
			echo "<input id='show_p".$key."' type='checkbox'>";
			echo "\n\t\t".$project_."</font></span> ".$genome_name."\n\t\t";
			echo "<span id='p_".$project."_type'></span>\n\t\t";
			echo "<br>\n\t\t";
			echo "<div id='frameContainer.p2_".$key."'></div>";
		}
	}

	function getColors($user,$project) {
		//[$colorString1, $colorString2] = getColors($user,$project);
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
			$genome      = "";
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

	function getHapmapName($user,$project) {
		// grab genome.txt from project.
		$genome_file = "users/".$user."/projects/".$project."/genome.txt";
		if (file_exists($genome_file)) {
			$handle      = fopen($genome_file,'r');
			$genome      = trim(fgets($handle));
			$hapmap      = trim(fgets($handle));
			fclose($handle);
		} else {
			$hapmap      = "";
		}

		// grab name.txt from genome.
		if ($hapmap != "") {
			$hapmapName_file1 = "users/".$user."/hapmaps/".$hapmap."/name.txt";
			$hapmapName_file2 = "users/default/hapmaps/".$hapmap."/name.txt";
			if (file_exists($hapmapName_file1)) {
				$handle      = fopen($hapmapName_file1,'r');
				$hapmap_name = trim(fgets($handle));
				fclose($handle);
			} else if (file_exists($hapmapName_file2)) {
				$handle      = fopen($hapmapName_file2,'r');
				$hapmap_name = trim(fgets($handle));
				fclose($handle);
			} else {
				$hapmap_name = "";
			}
		} else {
			$hapmap_name = "";
		}

		return $hapmap_name;
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

	echo "<font size='2'><b>Sample datasets:</b> (View all.";
	echo "<input id='showAllDefault' type='checkbox' onclick=\" open_All_DefaultProjects(); window.top.hide_combined_fig_menu();\">)</font>";
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

		$key = $key_ + $userProjectCount_initiated + $userProjectCount_working + $userProjectCount_complete;
		echo "<font size='2'>".($key+1).".";
		echo "<input id='show_p".$key."_sys' type='checkbox' onclick=\"parent.openProject('default','".$project."','".$key."_sys','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."','".$figVer."','');\" data-file-list='".$json_file_list."'>";
		echo $projectNameString."</font>";
		echo "<br>\n\t\t";
	}

	//
	// Define javascript function to show all complete projects.
	//
	echo "\n\n<script>\n";
	echo "function open_All_DefaultProjects() {\n";
	foreach($systemProjectFolders as $key_=>$project) {
		$nameFile        = "users/default/projects/".$project."/name.txt";
		$parent_file     = "users/default/projects/".$project."/parent.txt";

		$projectNameString = file_get_contents($nameFile);
		$projectNameString = trim($projectNameString);

		[$colorString1, $colorString2] = getColors($user,$project);

		// Get parent.
		$handle         = fopen($parent_file,'r');
		$parentString   = trim(fgets($handle));
		fclose($handle);

		// getting figure version for project.
		$versionFile    = "users/default/projects/".$project."/figVer.txt";
		$figVer         = 0;
		if (file_exists($versionFile)) {
			$figVer = intval(trim(file_get_contents($versionFile)));
		}

		$key = $key_ + $userProjectCount_initiated + $userProjectCount_working + $userProjectCount_complete;
		echo "\tdocument.getElementById('show_p".$key."_sys').checked = document.getElementById('showAllDefault').checked;\n";
		echo "\tparent.openProject('default','$project','".$key."_sys','$projectNameString','$colorString1','$colorString2','$parentString','$figVer','');\n\n";
	}
	echo "\twindow.top.hide_combined_fig_menu();\n";
	echo "}\n";
	echo "</script>\n\n";

	?>
</td></tr></table>
<script type="text/javascript">

if(localStorage.getItem("projectsShown")){
	var projectsShown = localStorage.getItem("projectsShown");
}
</script>
