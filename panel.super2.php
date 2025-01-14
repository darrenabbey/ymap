<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';

	if(isset($_SESSION['logged_on'])) {
		// check if super is logged in.
		$super_user_flag_file = "users/".$user."/super.txt";
		if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
			$super_logged_in = "true";
		} else {
			$super_logged_in = "false";
		}

		// check if admin is logged in.
		$admin_user_flag_file = "users/".$user."/admin.txt";
		if (file_exists($admin_user_flag_file)) {  // Super-user privilidges.
			$admin_logged_in = "true";
		} else {
			$admin_logged_in = "false";
		}
	} else {
		$super_logged_in = "false";
		$admin_logged_in = "false";
	}
?>
<html style="background: #FFDDDD;">
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<?php
	if ($super_logged_in == "true") {
		echo "<font size='4'><b>Super review of user installed datasets: View projects in process or stalled.<b></font><br>";
	} else if ($admin_logged_in == "true") {
		echo "<font size='4'><b>No admin user functions at this time.<b></font><br>";
	} else {
		echo "<font size='4'><br>Your account has not been provided with administrator priviledges.</b></font><br>";
	}

	if (($super_logged_in == "true") and isset($_SESSION['logged_on'])) {
		// get list of users:
		$userDir      = "users/";
		$userFolders  = array_diff(glob($userDir."*\/"), array('..', '.', 'users/default/'));
		// Sort directories.
		array_multisort($userFolders, SORT_ASC, $userFolders);
		// Trim path from each folder string.
		foreach($userFolders as $key=>$folder) {   $userFolders[$key] = str_replace($userDir,"",$folder);   }
		$userCount = count($userFolders);

		// Make panel reload button:
		echo "<form action='' method='post'>";
		echo "<input type='submit' value='Reload this tab only.'>";
		echo "</form>";
	}
?>
<hr>
<script type="text/javascript" src="js/jquery-3.6.3.js"></script>
<script type="text/javascript" src="js/jquery.form.js"></script>

<table width="100%" cellpadding="0"><tr>
<td width="75%" valign="top">
	<?php
	// .---------------.
	// | User projects |
	// '---------------'
	if (($super_logged_in == "true") and isset($_SESSION['logged_on'])) {
		$userProjectCount = 0;
		$sumKey = 0;
		foreach($userFolders as $userKey=>$admin_as_user) {
			// Cleanup admin_as_user names;
			$admin_as_user = substr($admin_as_user, 0, -1);

			// Only show projects from user accounts, not admin accounts.
			$adminFile = "users/".$admin_as_user."/admin.txt";
			if (file_exists($adminFile)) {
				$adminUser = true;
			} else {
				$adminUser = false;
			}

			if ($adminUser == false) {
				// Get list of projects per user.
				$projectsDir      = "users/".$admin_as_user."/projects/";
				$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.'));

				// Sort directories by date, newest first.
				array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);

				// Trim path from each folder string.
				foreach($projectFolders as $key=>$folder) {
					$projectFolders[$key] = str_replace($projectsDir,"",$folder);
				}

				// Split project list into ready/working/starting lists for sequential display.
				$projectFolders_starting = array();
				$projectFolders_working  = array();
				$projectFolders_complete = array();
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
				array_multisort($projectFolders_starting, SORT_ASC, $projectFolders_starting);
				array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working);
				array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);

				// Add to user project count.
				$userProjectCount = $userProjectCount + count($projectFolders_working);

				// Push in-process projects to display.
				foreach($projectFolders_working as $key_=>$project) {
					printProjectInfo("2", $key_+count($projectFolders_starting), "BB9900", "FFFFFF", $admin_as_user, $project, $sumKey);
					$sumKey += 1;
				}
			}
		}
	}

	function printProjectInfo($frameContainerIx, $key, $labelRgbColor, $labelRgbBackgroundColor, $user, $project, $sumKey) {
		if ($key%2 == 0) {
			$bgColor = "#FFDDDD";
		} else {
			$bgColor = "#DDBBBB";
		}

		// getting genome name for project.
		$genome_name = "<font size='1'> vs genome [".getGenomeName($user,$project)."]</font>";
		$genome_name = str_replace("+ ","",$genome_name);

		// get project name string.
		$projectNameFile = "users/".$user."/projects/".$project."/name.txt";
		$projectNameString = file_get_contents($projectNameFile);
		$projectNameString = trim($projectNameString);

		$projectNameString = file_get_contents("users/".$user."/projects/".$project."/name.txt");
		$projectNameString = trim($projectNameString);

		echo "<table style='background-color:".$bgColor.";' width='100%'><tr><td>\n";
		echo "<span id='p_label_".$sumkey."_super2' style='color:#".$labelRgbColor."; background-color:#".$labelRgbBackgroundColor.";'>\n\t\t\t\t";
		echo "<font size='2'>[".$user."] ".($sumKey+1).". &nbsp; &nbsp;";

		echo $projectNameString." ";
		echo "</font></span> ".$genome_name."\n";

		// Load error.txt from project folder into $_SESSION.
		$errorFile     = "users/".$user."/projects/".$project."/error.txt";
		if (file_exists($errorFile)) {
			$error = trim(file_get_contents($errorFile));
		} else {
			$error = "";
		}

		// Button to add/change error message for user project.
		echo "\t\t<br><form action='' method='post' style='display: inline;'>\n";
		echo "\t\t\t<input name='button_ErrorProject' type='button' value='Add/change error.' onclick='";
			echo "parent.document.getElementById(\"Hidden_Admin_Frame\").src = \"admin.error_window.php\"; ";
			echo "parent.show_hidden(\"Hidden_Admin\"); ";
			echo "parent.update_interface();";
			echo "localStorage.setItem(\"user\",\"".$user."\");";
			echo "localStorage.setItem(\"projectKey\",\"".$key."\");";
			echo "localStorage.setItem(\"projectName\",\"".$project."\");";
			echo "localStorage.setItem(\"projectError\",".json_encode($error).");";
		echo "'>";
		if (file_exists("users/".$user."/projects/".$project."/locked.txt")) {
			echo "<input type='button' value='Unlock.' onclick=\"user = '$user'; key = '$key'; $.ajax({url:'admin.unlockUserProject_server.php',type:'post',data:{key:key,user:user},success:function(answer){console.log(answer);}}); parent.update_interface(); setTimeout(()=> {location.replace('panel.super2.php')},100);\">";
		} else {
			echo "<input type='button' value='Lock.'   onclick=\"user = '$user'; key = '$key'; $.ajax({url:'admin.lockUserProject_server.php',type:'post',data:{key:key,user:user},success:function(answer){console.log(answer);}}); parent.update_interface(); setTimeout(()=> {location.replace('panel.super2.php')},100);\">";
		}
		echo "<input type='button' value='Copy to admin.'  onclick=\"key = '$key'; user = '$user'; $.ajax({url:'admin.copyProjectToAdmin_server.php',type:'post',data:{key:key,user:user},success:function(answer){console.log(answer);}}); parent.update_interface(); location.replace('panel.super2.php');\">";

		echo "\t\t</form>\n";

		echo "\t\t</font>\n\t\n\t\t\t\t";
		echo "<div id='frameContainer.p".$frameContainerIx."_".$sumKey."_super2'></div>\n\n\t\t\t\t";
		echo "</td></tr></table>";
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
</td></tr></table>


<script type="text/javascript">
<?php
//.--------------------------------------------------------------------.
//| javascript to load "project.working.php" for each working project. |
//'--------------------------------------------------------------------'
if (isset($_SESSION['logged_on'])) {
	$sumKey = 0;
	foreach($userFolders as $userKey=>$admin_as_user) {
		// Cleanup admin_as_user names;
		$admin_as_user = substr($admin_as_user, 0, -1);

		if ($admin_as_user != $user) {
			// Get list of projects per user.
			$projectsDir      = "users/".$admin_as_user."/projects/";
			$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.'));
			// Sort directories by date, newest first.
			array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);
			// Trim path from each folder string.
			foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectsDir,"",$folder);   }
			// Split project list into ready/working/starting lists for sequential display.
			$projectFolders_working  = array();

			foreach($projectFolders as $key=>$project) {
				if (file_exists("users/".$admin_as_user."/projects/".$project."/complete.txt")) {
				} else if (file_exists("users/".$admin_as_user."/projects/".$project."/working.txt")) {
					if (!file_exists("users/".$admin_as_user."/admin.txt")) {
						array_push($projectFolders_working, $project);
					}
				}
			}

			$userProjectCount_working  = count($projectFolders_working);
			// Sort complete and working projects alphabetically.
			array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working);

			foreach($projectFolders_working as $key_=>$project) {   // frameContainer.p2_[$key] : working.
				$key      = $key_ + $userProjectCount_starting;
				//$project  = $projectFolders[$key];
				//$handle   = fopen("users/".$admin_as_user."/projects/".$project."/dataFormat.txt", "r");
				//$dataFormat = fgets($handle);
				//fclose($handle);
				echo "\n// javascript for project #".$key+$sumKey."_super2, '".$project."'\n";
				echo "var el_p            = document.getElementById('frameContainer.p2_".$key+$sumKey."_super2');\n";
				echo "el_p.innerHTML      = '<iframe id=\"p_".$key+$sumKey."_super2\" name=\"p_".$key+$sumKey."_super2\" class=\"upload\" style=\"height:38px; border:0px;\" ";
				echo     "src=\"project.admin_working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n";
				echo "var p_iframe        = document.getElementById('p_".$key+$sumKey."_super2');\n";
				echo "var p_js            = p_iframe.contentWindow;\n";
				echo "p_js.user           = \"".$admin_as_user."\";\n";
				echo "p_js.project        = \"".$project."\";\n";
				echo "p_js.key            = \"p_".$key+$sumKey."_super2\";\n";
			}
			$sumKey += count($projectFolders_working);
		}
	}
}
?>
</script>
