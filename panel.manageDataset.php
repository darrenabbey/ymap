<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
?>
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<font size='3'>
	Install or delete next generation sequence and SNP/CGH microarray datasets in your user account.
	<font size='2'>
        <p>
            <b>IMPORTANT:</b>
            <ol>
                <li>Filenames should only have alphanumeric characters (letters, numbers, underscores and dashes) in their names (no spaces or other special characters!).</li>
		<li>Is your upload stuck? To resume it: When all other uploads are finished, refresh the page and re-add the files for upload.</li>
            </ol>
        </p>
	</font>
</font>
<?php
	if (isset($_SESSION['logged_on'])) {
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota_ = getUserQuota($user);
		if ($quota_ > $quota) {   $quota = $quota_;   }
		// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
		$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
		if ($exceededSpace) {
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (".$quota."G). ";
			echo "Clear space by deleting/minimizing projects or wait until datasets finish processing before adding a new dataset.</span><br><br>";
		}
	}
?>
<table width="100%" cellpadding="0"><tr>
<td width="25%" valign="top">
	<?php
	// .------------------.
	// | Make new project |
	// '------------------'
	if (isset($_SESSION['logged_on'])) {
		// show Install new dataset button only if user has space
		if(!$exceededSpace) {
			echo "<input name='button_InstallNewDataset' type='button' value='Install New Dataset' onclick='";
				echo "parent.document.getElementById(\"Hidden_InstallNewDataset_Frame\").contentWindow.location.reload(); ";
				echo "parent.show_hidden(\"Hidden_InstallNewDataset\"); ";
				echo "parent.update_interface();";
			echo "'><br>";

			// DRAGON : trying to do bulk data processing through user interface.
			$admin_user_flag_file = "users/".$user."/admin.txt";
			if (file_exists($admin_user_flag_file)) {
				echo "<input name='button_InstallBulkDataset' type='button' value='Admin: Install Bulk Dataset'  style='background-color:#FFCCCC;' onclick='";
					echo "parent.document.getElementById(\"Hidden_InstallBulkDataset_Frame\").contentWindow.location.reload(); ";
					echo "parent.show_hidden(\"Hidden_InstallBulkDataset\"); ";
					echo "parent.update_interface();";
				echo "'><br>";
				$_SESSION['user']  = $user;
				?>
				<form id="bulk_process" action="run_bulk_processer.php" method="post">
				<input	name='button_ProcessBulkDataset' type='submit' value='Admin: Process Bulk Dataset' style='background-color:#FFCCCC;'
					onclick='parent.update_interface();'>
				</form>
				<?php
			}

			echo "<font color='red' size='2'> (Wait until uploads complete!)</font><br>";
		}

		$_SESSION['pending_install_project_count'] = 0;
		?><br>
		<b><font size='2'>Datasets Pending</font></b>
		<div class='tab' style='color:#CC0000; font-size:10pt;' id='newly_installed_list' name='newly_installed_list'></div>
		<div style='color:#CC0000; font-size:10pt; visibility:hidden; text-align:left;' id='pending_comment'    name='pending_comment'>
			Reload page after any current uploads have completed to prepare pending datasets for upload.<br><br>Additional datasets can
			be defined with the 'Install New Dataset' button while files upload.
		</div>
		<div style='color:#CC0000; font-size:10pt; visibility:hidden; text-align:left;' id='bulk_comment'       name='bulk_comment'>
			Reload page to see status of bulk dataset processing.
		</div>
		<div style='color:#CC0000; font-size:10pt; visibility:hidden; text-align:left;' id='name_error_comment' name='name_error_comment'>
			(Entered dataset name is already in use.)
		</div>
		<?php
	}
	?>
</td>
<td width="75%" valign="top">
	<?php
	// .---------------.
	// | User projects |
	// '---------------'
	$userProjectCount = 0;
	if (isset($_SESSION['logged_on'])) {
		$projectsDir      = "users/".$user."/projects/";
		$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.'));

		// Sort directories by date, newest first.
		array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectsDir,"",$folder);   }

		// Split project list into ready/working/starting lists for sequential display.
		$projectFolders_starting = array();
		$projectFolders_bulk     = array();
		$projectFolders_working  = array();
		$projectFolders_complete = array();
		foreach($projectFolders as $key=>$project) {
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$user."/projects/".$project."/bulk.txt")) {
				array_push($projectFolders_bulk, $project);
			} else if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (is_dir("users/".$user."/projects/".$project)) {
				array_push($projectFolders_starting,$project);
			}
		}
		$userProjectCount_starting = count($projectFolders_starting);
		$userProjectCount_bulk     = count($projectFolders_bulk);
		$userProjectCount_working  = count($projectFolders_working);
		$userProjectCount_complete = count($projectFolders_complete);

		// Sort bulk, working, and complete projects alphabetically.
		array_multisort($projectFolders_bulk,     SORT_ASC, $projectFolders_bulk    );
		array_multisort($projectFolders_working,  SORT_ASC, $projectFolders_working );
		array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);
		// Build new 'projectFolders' array;
		$projectFolders   = array();
		$projectFolders   = array_merge($projectFolders_starting, $projectFolders_bulk, $projectFolders_working, $projectFolders_complete);
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
				printProjectInfo("3", $key_, "CC0000", "FFFFFF", $user, $project);
			} else {
				printProjectInfo("4", $key_, "888888", "FFFFFF", $user, $project);
			}
			$key_starting = $key;
		}
		foreach($projectFolders_bulk as $key_=>$project) {
			printProjectInfo("5", $key_ + count($projectFolders_starting), "000000", "CCCCCC", $user, $project);
			$key_working = $key;
		}
		foreach($projectFolders_working as $key_=>$project) {
			printProjectInfo("2", $key_ + count($projectFolders_bulk) + count($projectFolders_starting), "BB9900", "FFFFFF", $user, $project);
			$key_working = $key;
		}
		foreach($projectFolders_complete as $key_=>$project) {
			if (file_exists("users/".$user."/projects/".$project."/bulk.txt")) {
				printProjectInfo("2", $key_ + count($projectFolders_bulk)+ count($projectFolders_starting) + count($projectFolders_working), "000000", "CCFFCC", $user, $project);
			} else {
				printProjectInfo("2", $key_ + count($projectFolders_bulk)+ count($projectFolders_starting) + count($projectFolders_working), "00CC00", "FFFFFF", $user, $project);
			}
		}
		// 1: project complete.
		// 2: project working.
		// 3: project starting, quota not filled.
		// 4: project starting, quota filled.
		// 5: project in bulk-processing-queue.
		echo "\n";
?>
<script type='text/javascript'>
	function loadExternal(imageUrl) {
		window.open(imageUrl);
	}
</script>
<?php
	}

	function printProjectInfo($frameContainerIx, $key, $labelRgbColor, $labelRgbBackgroundColor, $user, $project) {
		// $frameContainerIx values:
		//	1: project complete.
		//	2: project working.
		//	31: project starting, quota not filled.
		//	4: project starting, quota filled.
		//	5: project in bulk-processing-queue.

		$projectNameFile = "users/".$user."/projects/".$project."/name.txt";
		$projectNameString = file_get_contents($projectNameFile);
		$projectNameString = trim($projectNameString);

		$projectNameString = file_get_contents("users/".$user."/projects/".$project."/name.txt");
		$projectNameString  = trim($projectNameString);
		echo "<span id='p_label_".$key."' style='color:#".$labelRgbColor."; background-color:#".$labelRgbBackgroundColor.";'>\n\t\t\t\t";
		echo "<font size='2'>".($key+1).".";
		if (!file_exists("users/".$user."/projects/".$project."/locked.txt")) {
			echo "<button id='project_delete_".$key."' type='button' onclick=\"parent.deleteProjectConfirmation('".$project."','".$key."');\">Delete</button>";
			if (!file_exists("users/".$user."/projects/".$project."/minimized.txt") && file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				echo "<button id='project_minimize_".$key."' type='button' onclick=\"parent.minimizeProjectConfirmation('".$project."','".$key."');\">Minimize</button>";
			}
		}
		echo $projectNameString;

		// checks condensed log to see if initial processing is done.
		if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
			if (file_exists("users/".$user."/projects/".$project."/working2.txt") == false) {
				if ($exceededSpace) {
					echo "<button id='project_finalize_".$key."' type='button' onclick=\"parent.show_hidden('Hidden_InstallNewproject2'); getElementById('project_finalize_".$key."').style.display = 'none';;\">Finalize</button>";
				}
			}
		}

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
				chmod($totalSizeFile, 0664);
			}
			// printing total size
			echo " <font color='black' size='1'>(". $projectSizeStr .")</font>";
		}

		echo "</font></span>\n\t\t\t\t";
		echo "<span id='p_delete_".$key."'></span>\n";
		if (!file_exists("users/".$user."/projects/".$project."/minimized.txt") && file_exists("users/".$user."/projects/".$project."/complete.txt")) {
			echo "<span id='p_minimize_".$key."'></span>\n";
		}

		if ($frameContainerIx == "1") {
			// define update dataset button, which passes key value to update project page in iframe of main page.
			if (!file_exists("users/".$user."/projects/".$project."/locked.txt")) {
				if (!file_exists("users/".$user."/projects/".$project."/minimized.txt") && file_exists("users/".$user."/projects/".$project."/complete.txt")) {
					echo "<button id='project_update_".$key."' type='button' onclick='";
					echo "parent.document.getElementById(\"Hidden_UpdateDataset_Frame\").contentWindow.location.href = \"project.update_window.php?key=".$key."\";\n";
					echo "parent.show_hidden(\"Hidden_UpdateDataset\"); ";
					echo "getElementById(\"project_update_".$key."\").style.display = \"none\";";
					echo "getElementById(\"project_minimize_".$key."\").style.display = \"none\";";
					echo "'>Update Dataset</button><br>";
				}
			}
		}

		if (file_exists("users/".$user."/projects/".$project."/locked.txt")) {
			echo "<font size='2' color='red'>[Project locked for admin review.]</font>";
		}

		echo "\t\t\t\t";
		echo "<div id='frameContainer.p".$frameContainerIx."_".$key."'></div>\n\n\t\t\t\t";
	}

	?>
</td></tr></table>
<?php
	//.-----------------.
	//| System projects |
	//'-----------------'
	$projectsDir          = "users/default/projects/";
	$systemProjectFolders = array_diff(glob($projectsDir."*"), array('..', '.'));
	// Sort directories by date, newest first.
	array_multisort(array_map('filemtime', $systemProjectFolders), SORT_DESC, $systemProjectFolders);
	// Trim path from each folder string.
	foreach($systemProjectFolders as $key=>$folder) {   $systemProjectFolders[$key] = str_replace($projectsDir,"",$folder);   }
	$systemProjectCount = count($systemProjectFolders);
?>


<script type="text/javascript">
var userProjectCount   = "<?php echo $userProjectCount; ?>";
var systemProjectCount = "<?php echo $systemProjectCount; ?>";
<?php
//.----------------.
//| Uploading data |
//'----------------'
if (isset($_SESSION['logged_on'])) {
	foreach($projectFolders_starting as $key_=>$project) {	// frameContainer.p3_[$key] : starting.
		$key      = $key_;
		$project  = $projectFolders[$key];
		// Read in dataFormat string for project.
		$handle     = fopen("users/".$user."/projects/".$project."/dataFormat.txt", "r");
		$dataFormat = fgets($handle);
		fclose($handle);
		echo "\n// javascript for project #".$key.", '".$project."'\n";
		echo "var el_p               = document.getElementById('frameContainer.p3_".$key."');\n";
		// Javascript to build file load button interface.
		echo "el_p.innerHTML         = '<iframe id=\"p_".$key."\" name=\"p_".$key."\" class=\"upload\" ";
		if ((strlen($dataFormat) > 1) && ($dataFormat[2] == '1')) {
			// paired files to be uploaded.
			echo "style=\"height:76px\" src=\"uploader.2.php\"";
		} else {
			// single file to be uploaded.
			echo "style=\"height:38px\" src=\"uploader.1.php\"";
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
	foreach($projectFolders_bulk as $key_=>$project) {      // frameContainer.p5_[$key] : in bulk-processing queue.
		$key      = $key_ + $userProjectCount_starting;
		$project  = $projectFolders[$key];
		echo "\n// javascript for project #".$key.", '".$project."'\n";
		echo "var el_p            = document.getElementById('frameContainer.p5_".$key."');\n";
		echo "el_p.innerHTML      = '<iframe id=\"p_".$key."\" name=\"p_".$key."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
		echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n";
		echo "var p_iframe        = document.getElementById('p_".$key."');\n";
		echo "var p_js            = p_iframe.contentWindow;\n";
		echo "p_js.user           = \"".$user."\";\n";
		echo "p_js.project        = \"".$project."\";\n";
		echo "p_js.key            = \"p_".$key."\";\n";
	}
	foreach($projectFolders_working as $key_=>$project) {   // frameContainer.p2_[$key] : working.
		$key      = $key_ + $userProjectCount_starting + $userProjectCount_bulk;
		$project  = $projectFolders[$key];
		echo "\n// javascript for project #".$key.", '".$project."'\n";
		echo "var el_p            = document.getElementById('frameContainer.p2_".$key."');\n";
		echo "el_p.innerHTML      = '<iframe id=\"p_".$key."\" name=\"p_".$key."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
		echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n";
		echo "var p_iframe        = document.getElementById('p_".$key."');\n";
		echo "var p_js            = p_iframe.contentWindow;\n";
		echo "p_js.user           = \"".$user."\";\n";
		echo "p_js.project        = \"".$project."\";\n";
		echo "p_js.key            = \"p_".$key."\";\n";
	}
}
?>
</script>
