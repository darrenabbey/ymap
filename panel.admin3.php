<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';

	// check if admin is logged in.
	$super_user_flag_file = "users/".$user."/super.txt";
	if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
		$admin_logged_in = "true";
	} else {
		$admin_logged_in = "false";
	}
?>
<html style="background: #FFDDDD;">
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<font size='3'>Check figures status of user installed datasets:</font><br>
<?php
	// check to see if value was passed to page.
	if (isset($_POST['admin_as_user'])) {
		$admin_as_user_key = sanitizeInt_POST('admin_as_user');
	} else {
		$admin_as_user_key = 0;
	}

	// get list of users:
	$userDir      = "users/";
	$userFolders  = array_diff(glob($userDir."*\/"), array('..', '.', 'users/default/'));
	// Sort directories.
	array_multisort($userFolders, SORT_ASC, $userFolders);
	// Trim path from each folder string.
	foreach($userFolders as $key=>$folder) { $userFolders[$key] = str_replace($userDir,"",$folder); }
	// Trim last char from each folder string.
	foreach($userFolders as $key=>$folder) { $userFolders[$key] = substr($folder, 0, -1); }
	$userCount = count($userFolders);

	// Make selection form:
	echo "<form action='' method='post'>";
	echo "<input type='submit' value='Reload this tab only as user:'>";
	echo "<select name='admin_as_user' id='admin_as_user'>";
	foreach($userFolders as $key=>$folder) {
		if ($key == $admin_as_user_key) {
			echo "<option value='".$key."' selected>".$folder."</option>";
			$admin_as_user = $folder;
		} else {
			echo "<option value='".$key."'>".$folder."</option>";
		}
	}
	echo "</select> ";
	echo "</form>";

	if (isset($_SESSION['logged_on'])) {
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($admin_as_user);
		// getting user quota in Gigabytes
		$quota_ = getUserQuota($admin_as_user);
		if ($quota_ > $quota) {   $quota = $quota_;   }
		// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
		$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
		if ($exceededSpace) {
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (" . $quota . "G) please clear space and then reload to add new dataset</span><br><br>";
		}
	}
?>
<hr>
<table width="100%" cellpadding="0"><tr>
<td width="65%" valign="top">
	<?php
	//.---------------.
	//| User projects |
	//'---------------'
	if (isset($_SESSION['logged_on'])) {
		$projectsDir      = "users/".$admin_as_user."/projects/";
		$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.'));
		// Sort directories by date, newest first.
		array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);
		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectsDir,"",$folder);   }
		$projectFolders = array_diff($projectFolders, array('index.php'));
		// Split project list into ready/working/starting lists for sequential display.
		$projectFolders_complete       = array();
		$projectFolders_working        = array();
		$projectFolders_starting       = array();
		foreach($projectFolders as $key=>$project) {
			if (file_exists("users/".$admin_as_user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$admin_as_user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (is_dir("users/".$admin_as_user."/projects/".$project)) {
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
		$projectFolders   = array_merge($projectFolders_starting, $projectFolders_working, $projectFolders_complete);
		$userProjectCount = count($projectFolders);

		$default_projectsDir    = "users/default/projects/";
		$default_projectFolders = array_diff(glob($default_projectsDir."*"), array('..', '.'));
		foreach($default_projectFolders as $key=>$folder) { $default_projectFolders[$key] = str_replace($default_projectsDir,"",$folder); }
		$default_projectFolders = array_diff($default_projectFolders, array('index.php'));
		$defaultProjectCount    = count($default_projectFolders);

		$admin_projectsDir      = "users/".$user."/projects/";
		$admin_projectFolders   = array_diff(glob($admin_projectsDir."*"), array('..', '.'));
		foreach($admin_projectFolders as $key=>$folder) { $admin_projectFolders[$key] = str_replace($admin_projectsDir,"",$folder); }
		$admin_projectFolders   = array_diff($admin_projectFolders, array('index.php'));
		$adminProjectCount      = count($admin_projectFolders);

		echo "<b><font size='2'>User installed datasets:</font></b>\n\t\t";
		echo "<br>\n\t\t";
		foreach($projectFolders_starting as $key_=>$project) {
			// Load colors for project.
			[$colorString1, $colorString2] = getColors($admin_as_user,$project);

			// getting genome name for project.
			$genome_name = "<font size='1'>[".getGenomeName($admin_as_user,$project)."]</font>";
			$genome_name = str_replace("+ ","",$genome_name);

			// getting project name
			$nameFile        = "users/".$admin_as_user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$admin_as_user."/projects/".$project."/parent.txt";
			if (file_exists($nameFile) and file_exists($parent_file)) {
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);

				$dataFormat_file        = "users/".$admin_as_user."/projects/".$project."/dataFormat.txt";
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
				$key       = $key_;
				echo "<span id='p_label_".$key."_admin' style='color:#CC0000;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."_admin' type='checkbox' onclick=\"parent.openProject('".$admin_as_user."','".$project."','".$key."_admin','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."');\" style=\"visibility:hidden;\">";
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."_admin'></div>";
			} else {
				// an error has happened.
				$key = $key_;
				echo "<span id='p_label_".$key."_admin' style='color:#888888;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input id='show_".$key."_admin' type='checkbox'>";
				echo "\n\t\t".$project."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."_admin'></div>";
			}
		}
		foreach($projectFolders_working as $key_=>$project) {
			// Load colors for project.
			[$colorString1, $colorString2] = getColors($admin_as_user,$project);

			// getting genome name for project.
			$genome_name = "<font size='1'>[".getGenomeName($admin_as_user,$project)."]</font>";
			$genome_name = str_replace("+ ","",$genome_name);

			$nameFile        = "users/".$admin_as_user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$admin_as_user."/projects/".$project."/parent.txt";
			if (file_exists($nameFile) and file_exists($parent_file)) {
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);

				$dataFormat_file        = "users/".$admin_as_user."/projects/".$project."/dataFormat.txt";
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
				$key = $key_ + $userProjectCount_starting;
				echo "<span id='p_label_".$key."_admin' style='color:#BB9900;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input  id='show_".$key."_admin' type='checkbox' onclick=\"parent.openProject('".$admin_as_user."','".$project."','".$key."_admin','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."');\" style=\"visibility:hidden;\">";
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."_admin'></div>";
			} else {
				// an error has happend.
				$key = $key_ + $userProjectCount_starting;
				echo "<span id='p_label_".$key."_admin' style='color:#888888;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input  id='show_".$key."_admin' type='checkbox'>";
				echo "\n\t\t".$project."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."_admin'></div>";
			}
		}
		foreach($projectFolders_complete as $key_=>$project) {
			// Load colors for project.
			[$colorString1, $colorString2] = getColors($admin_as_user,$project);

			// getting genome name for project.
			$genome_name = "<font size='1'>[".getGenomeName($admin_as_user,$project)."]</font>";
			$genome_name = str_replace("+ ","",$genome_name);

			$nameFile        = "users/".$admin_as_user."/projects/".$project."/name.txt";
			$parent_file     = "users/".$admin_as_user."/projects/".$project."/parent.txt";
			if (file_exists($nameFile) and file_exists($parent_file)) {
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);

				$dataFormat_file        = "users/".$admin_as_user."/projects/".$project."/dataFormat.txt";
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

				$json_file_list       = json_encode(scandir("users/$admin_as_user/projects/$project"));
				$JSONproject          = json_encode("$project");
				$handle               = fopen($parent_file,'r');
				$parentString         = trim(fgets($handle));
				fclose($handle);
				$key = $key_ + $userProjectCount_starting + $userProjectCount_working;
				echo "<span id='project_label_".$key."_admin' style='color:#00AA00;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input  id='show_".$key."_admin' type='checkbox' onclick=\"parent.openProject('".$admin_as_user."','".$project."','".$key."_admin','".$projectNameString."','".$colorString1."','".$colorString2."','".$parentString."'); window.top.hide_combined_fig_menu();\" data-file-list='$json_file_list' >";
				echo "\n\t\t".$projectNameString."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p2_".$project."_delete'></span><span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p1_".$key."_admin'></div>";
			} else {
				// an error has happened;
				$key = $key_ + $userProjectCount_starting;
				echo "<span id='p_label_".$key."_admin' style='color:#888888;'>\n\t\t";
				echo "<font size='2'>".($key+1).".";
				echo "<input  id='show_".$key."_admin' type='checkbox'>";
				echo "\n\t\t".$project."</font></span> ".$genome_name."\n\t\t";
				echo "<span id='p_".$project."_type'></span>\n\t\t";
				echo "<br>\n\t\t";
				echo "<div id='frameContainer.p2_".$key."_admin'></div>";
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
<br>
</td></tr></table>
<script type="text/javascript">

if(localStorage.getItem("projectsShown")){
	var projectsShown = localStorage.getItem("projectsShown");
}
</script>
