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
<font size='3'>Check installation status of user installed datasets:</font><br>
<?php
	// check to see if value was passed to page.
	if (isset($_POST['admin_as_user'])) {
		$admin_as_user_key = sanitizeInt_POST('admin_as_user');
		$admin_as_user     = 0;
	}

	// get list of users:
	$userDir      = "users/";
	$userFolders  = array_diff(glob($userDir."*\/"), array('..', '.', 'users/default/'));
	// Sort directories.
	array_multisort($userFolders, SORT_ASC, $userFolders);
	// Trim path from each folder string.
	foreach($userFolders as $key=>$folder) {   $userFolders[$key] = str_replace($userDir,"",$folder);   }
	$userCount = count($userFolders);

	// Make selection form:
	echo "<form action='' method='post'>";
	echo "<label for='admin_as_user'>Select a user:</label>";
	echo "<select name='admin_as_user' id='admin_as_user'>";
	foreach($userFolders as $key=>$folder) {
		if ($key == $admin_as_user_key) {
			echo "<option value='".$key."' selected>".$folder."</option>";
			$admin_as_user = $folder;
		} else {
			echo "<option value='".$key."'>".$folder."</option>";
		}
	}
	echo "</select>";
	echo "<input type='submit'>";
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
<td width="75%" valign="top">
	<?php
	// .---------------.
	// | User projects |
	// '---------------'
	$userProjectCount = 0;
	if (isset($_SESSION['logged_on'])) {
		$projectsDir      = "users/".$admin_as_user."/projects/";
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
		// displaying size if it's bigger then 0
		if ($currentSize > 0) {
			echo "<b><font size='2'>User installed datasets: (currently using " . $currentSize . "G of " . $quota . "G)</font></b>\n\t\t\t\t";
		} else {
			echo "<b><font size='2'>User installed datasets:</font></b>\n\t\t\t\t";
		}
		echo "<br>\n\t\t\t\t";


		foreach($projectFolders_starting as $key_=>$project) {
			if (!$exceededSpace) {
				printprojectInfo("3", $key_, "CC0000", $admin_as_user, $project);
			} else {
				printprojectInfo("4", $key_, "888888", $admin_as_user, $project);
			}
		}
		foreach($projectFolders_working as $key_=>$project) {
			printprojectInfo("2", $key_ + $userprojectCount_starting, "BB9900", $admin_as_user, $project);
		}
		foreach($projectFolders_complete as $key_=>$project) {
			printprojectInfo("1", $key_ + $userprojectCount_starting + $userprojectCount_working, "00AA00", $admin_as_user, $project);
		}

?>
<script type='text/javascript'>
	function loadExternal(imageUrl) {
		window.open(imageUrl);
	}
</script>
<?php
	}

	function printProjectInfo($frameContainerIx, $key, $labelRgbColor, $user, $project) {
		$projectNameFile = "users/".$user."/projects/".$project."/name.txt";
		$projectNameString = file_get_contents($projectNameFile);
		$projectNameString = trim($projectNameString);

		$projectyNameString = file_get_contents("users/".$user."/projects/".$project."/name.txt");
		$projectNameString  = trim($projectNameString);
		echo "<span id='p_label_".$key."' style='color:#".$labelRgbColor.";'>\n\t\t\t\t";
		echo "<font size='2'>".($key+1).".";
		echo $projectNameString;

		// display total size of files only if the project is finished processeing
		if ($frameContainerIx == "1") {
			$totalSizeFile = "users/".$user."/projects/". $project ."/totalSize.txt";
			// display total project size: first checking if size already calculated and is stored in totalSize.txt
			if (file_exists($totalSizeFile)) {
				$handle       = fopen($totalSizeFile,'r');
				$projectSizeStr = trim(fgets($handle));
				fclose($handle);
			} else { // calculate size and store in totalSize.txt to avoid calculating again
				// calculating size
				$projectSizeStr = trim(shell_exec("du -sh " . "users/".$user."/projects/". $project . "/ | cut -f1"));
				// saving to file
				$output       = fopen($totalSizeFile, 'w');
				fwrite($output, $projectSizeStr);
				fclose($output);
			}
			// printing total size
			echo " <font color='black' size='1'>(". $projectSizeStr .")</font>";
		}
		echo "</font></span>\n\t\t\t\t";
		echo "\n\t\t\t\t";
		echo "<div id='frameContainer.p".$frameContainerIx."_".$key."'></div>";
	}

	?>
</td></tr></table>

<script type="text/javascript">
var userProjectCount   = "<?php echo $userProjectCount; ?>";
var systemProjectCount = "<?php echo $systemProjectCount; ?>";
<?php
//.----------------.
//| Uploading data |
//'----------------'
if (isset($_SESSION['logged_on'])) {
	foreach($projectFolders_starting as $key_=>$project) {    // frameContainer.p3_[$key] : starting.
		$key      = $key_;
		$project  = $projectFolders[$key];
		// Read in dataFormat string for project.
		$handle     = fopen("users/".$user."/projects/".$project."/dataFormat.txt", "r");
		$dataFormat = fgets($handle);
		fclose($handle);
		echo "\n// javascript for project #".$key.", '".$project."'\n";
		echo "var el_p               = document.getElementById('frameContainer.p3_".$key."');\n";
		// Javascript to build file load button interface.
		echo "el_p.innerHTML         = 'Data <iframe id=\"p_".$key."\" name=\"p_".$key."\" class=\"upload\" ";
		if ((strlen($dataFormat) > 1) && ($dataFormat[2] == '1')) {
			// paired files to be uploaded.
		//	echo "style=\"height:76px\" src=\"uploader.2.php\"";
		} else {
			// single file to be uploaded.
		//	echo "style=\"height:38px\" src=\"uploader.1.php\"";
		}
		echo " marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n";
		echo "var p_iframe           = document.getElementById('p_".$key."');\n";
		echo "var p_js               = p_iframe.contentWindow;\n";
		echo "p_js.display_string    = new Array();\n";
		echo "p_js.user              = '".$user."';\n";
		echo "p_js.project           = '".$project."';\n";
		echo "p_js.key               = 'p_".$key."';\n";
		if ($dataFormat == '0') {
			// SnpCgh microarray
			echo "p_js.display_string[0] = 'Add : SnpCgh array data...';\n";
			echo "p_js.dataFormat        = 'SnpCghArray';\n";
		} else if (($dataFormat == '1:0:0') || ($dataFormat == '1:0:1')) {
			// WGseq : single-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Single-end-read WGseq data (FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'WGseq_single';\n";
		} else if (($dataFormat == '1:1:0') || ($dataFormat == '1:1:1')) {
			// WGseq : paired-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Paired-end-read WGseq data (1/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.display_string[1] = 'Add : Paired-end-read WGseq data (2/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'WGseq_paired';\n";
		} else if (($dataFormat == '1:2:0') || ($dataFormat == '1:2:1') || ($dataFormat == '1:3:0') || ($dataFormat == '1:3:1')) {
			// WGseq : [SAM/BAM/TXT]
			echo "p_js.display_string[0] = 'Add : WGseq data (SAM/BAM/TXT)...';\n";
			echo "p_js.dataFormat        = 'WGseq_single';\n";
		} else if (($dataFormat == '2:0:0') || ($dataFormat == '2:0:1')) {
			// ddRADseq : single-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Single-end-read ddRADseq data (FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'ddRADseq_single';\n";
		} else if (($dataFormat == '2:1:0') || ($dataFormat == '2:1:1')) {
			// ddRADseq : paired-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Paired-end-read ddRADseq data (1/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.display_string[1] = 'Add : Paired-end-read ddRADseq data (2/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'ddRADseq_paired';\n";
		} else if (($dataFormat == '2:2:0') || ($dataFormat == '2:2:1') || ($dataFormat == '2:3:0') || ($dataFormat == '2:3:1')) {
			// ddRADseq : [SAM/BAM/TXT]
			echo "p_js.display_string[0] = 'Add : ddRADseq data (SAM/BAM/TXT)...';\n";
			echo "p_js.dataFormat        = 'ddRADseq_single';\n";
		}
	}
	foreach($projectFolders_working as $key_=>$project) {   // frameContainer.p2_[$key] : working.
		$key      = $key_ + $userProjectCount_starting;
		$project  = $projectFolders[$key];
		$handle   = fopen("users/".$user."/projects/".$project."/dataFormat.txt", "r");
		$dataFormat = fgets($handle);
		fclose($handle);
		echo "\n// javascript for project #".$key.", '".$project."'\n";
		echo "var el_p            = document.getElementById('frameContainer.p2_".$key."');\n";
		echo "el_p.innerHTML      = '<iframe id=\"p_".$key."\" name=\"p_".$key."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
		echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n";
		echo "var p_iframe        = document.getElementById('p_".$key."');\n\t";
		echo "var p_js            = p_iframe.contentWindow;\n";
		echo "p_js.user           = \"".$user."\";\n\t";
		echo "p_js.project        = \"".$project."\";\n\t";
		echo "p_js.key            = \"p_".$key."\";\n";
	}
}
?>
</script>
