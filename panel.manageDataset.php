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

	require_once 'constants.php';
	require_once 'sharedFunctions.php';

	// If too many projects are updating at the same time, the user interface stalls out.
	// 	10 projects is double what is shown on-screen at once time.
	//	User will need to reload page to refresh once those 10 are done.
	$bulk_ui_projects_showAll = False;
	$bulk_ui_projects_limit   = 11;

?>
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<font size='3'>
	Install or delete short-read or long-read sequence datasets.
	<font size='2'>
	<div style="margin-left: 20;">
		<li><?php
			// Show queue status.
			require 'queue_status.php';
			$queue_count = (int)$queue_status_init + (int)$queue_status_start;
			if ($queue_count > 0) {
				if ($MAX_QUEUE_PARALLEL > 1) {
					echo "<b>There are currently ".$queue_count." datasets in the queue, which is running up to ".$MAX_QUEUE_PARALLEL." datasets at a time.</b> Each takes ~".$QUEUE_TIME_ESTIMATE." minutes to complete. Data uploaded now will start processing in ~".number_format(($queue_count*$QUEUE_TIME_ESTIMATE/60/$MAX_QUEUE_PARALLEL),1)." hours.";
				} else {
					echo "<b>There are currently ".$queue_count." datasets in the queue, which is running 1 dataset at a time.</b> Each takes ~".$QUEUE_TIME_ESTIMATE." minutes to complete. Data uploaded now will start processing in ~".number_format(($queue_count*$QUEUE_TIME_ESTIMATE/60),1)." hours.";
				}
			} else {
				echo "<b>There are currently no datasets in the queue.</b> Each takes ~".$QUEUE_TIME_ESTIMATE." minutes to complete.";
			}
		?></li>
		<li>Queue capacity and completion time predictions may be adjusted as admin learns the capacity of this server.</li>
		<li>Filenames should only have alphanumeric characters (letters, numbers, underscores and dashes) in their names (no spaces or other special characters!).</li>
                <li>Is your upload stuck? To resume it: Wait until all other uploads are done, refresh the page, and re-add the files for upload.</li>
<?php
		if (is_file($base_dir."/queue/error.txt")) {
			$queue_message = trim(file_get_contents($base_dir."/queue/error.txt"));
			echo "<font size='4' style='color:red;'><b>".$queue_message."</b></font>";
		}
?>
	</div>
	</font>
	<br>
</font>
<?php
	if (isset($_SESSION['logged_on'])) {
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota = getUserQuota($user);
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

		// Show Install new dataset button only if user has space
		if(!$exceededSpace) {
			echo "<input name='button_InstallNewDataset' type='button' value='Install New Dataset' onclick='";
				echo "parent.document.getElementById(\"Hidden_InstallNewDataset_Frame\").contentWindow.location.reload(); ";
				echo "parent.show_hidden(\"Hidden_InstallNewDataset\"); ";
				echo "parent.update_interface();";
			echo "'>";
			//echo "<font color='red' size='2'> (Wait until uploads complete!)</font>";

			$admin_user_flag_file = "users/".$user."/admin.txt";
			if (file_exists($admin_user_flag_file)) {
				echo "<br><input name='button_InstallBulkDataset' type='button' value='Install Bulk Dataset'  style='background-color:#FFCCCC;' onclick='";
					echo "parent.document.getElementById(\"Hidden_InstallBulkDataset_Frame\").contentWindow.location.reload(); ";
					echo "parent.show_hidden(\"Hidden_InstallBulkDataset\"); ";
					echo "parent.update_interface();";
				echo "'>";
				//echo "<font color='red' size='2'> (Wait until uploads complete!)</font><br>";
				echo "<br>";
			}

			echo "<input name='button_MakeNewFolder' type='button' value='Add Dataset Group' onclick='";
				echo "parent.document.getElementById(\"Hidden_MakeNewFolder_Frame\").contentWindow.location.reload(); ";
				echo "parent.show_hidden(\"Hidden_MakeNewFolder\"); ";
			echo "'><br>";
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
		//array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);
		sort($projectFolders);
		//print_r($projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {   $projectFolders[$key] = str_replace($projectsDir,"",$folder);   }

		// Split project list into ready/working/initiated lists for sequential display.
		$projectFolders_subdir       = array();
		$projectFolders_complete     = array();
		$projectFolders_bulk         = array();
		$projectFolders_bulk_working = array();
		$projectFolders_working      = array();
		$projectFolders_initiated    = array();
		foreach($projectFolders as $key=>$project) {
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$user."/projects/".$project."/bulk.txt")) {
				if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
					array_push($projectFolders_bulk_working, $project);
				} else {
					array_push($projectFolders_bulk, $project);
				}
			} else if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (file_exists("users/".$user."/projects/".$project."/name.txt")) {
				array_push($projectFolders_initiated,$project);
			} else {
                                array_push($projectFolders_subdir,$project);
			}
		}
		array_multisort(array_map('filemtime', $projectFolders_complete    ), SORT_ASC, $projectFolders_complete    );
		array_multisort(array_map('filemtime', $projectFolders_bulk        ), SORT_ASC, $projectFolders_bulk        );
		array_multisort(array_map('filemtime', $projectFolders_bulk_working), SORT_ASC, $projectFolders_bulk_working);
		array_multisort(array_map('filemtime', $projectFolders_working     ), SORT_ASC, $projectFolders_working     );
		array_multisort(array_map('filemtime', $projectFolders_initiated   ), SORT_ASC, $projectFolders_initiated   );
		$userProjectCount_complete     = count($projectFolders_complete);
		$userProjectCount_bulk         = count($projectFolders_bulk);
		$userProjectCount_bulk_working = count($projectFolders_bulk_working);
		$userProjectCount_working      = count($projectFolders_working);
		$userProjectCount_initiated    = count($projectFolders_initiated);

		// Sort bulk, working, and complete projects alphabetically.
		array_multisort($projectFolders_subdir,       SORT_ASC, $projectFolders_subdir);
		array_multisort($projectFolders_complete,     SORT_ASC, $projectFolders_complete    );
		array_multisort($projectFolders_bulk,         SORT_ASC, $projectFolders_bulk        );
		array_multisort($projectFolders_bulk_working, SORT_ASC, $projectFolders_bulk_working);
		array_multisort($projectFolders_working,      SORT_ASC, $projectFolders_working     );
		array_multisort($projectFolders_initiated,    SORT_ASC, $projectFolders_initiated   );


		// Build new 'projectFolders' array;
		$userProjectCount = count($projectFolders);
		// displaying size if it's bigger then 0
		if ($currentSize > 0) {
			echo "<b><font size='2'>User installed datasets: (currently using " . $currentSize . "G of " . $quota . "G)</font></b>\n\t\t\t\t";
		} else {
			echo "<b><font size='2'>User installed datasets:</font></b>\n\t\t\t\t";
		}
		echo "<br>\n\t\t\t\t";

		// 1: project complete.
		// 2: project working.
		// 3: project initiated, quota not filled.
		// 4: project initiated, quota filled.
		// 5: project in bulk-processing-queue.
		$key_offset = 0;
		$prefix="";
		foreach($projectFolders_initiated as $key_=>$project) {
			// add initiated bulk/other projects to user interface.
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				if (!$exceededSpace) {
					printProjectInfo("3", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
				} else {
					printProjectInfo("4", $key_real, "888888", "FFFFFF", $user, $project,$key_offset,$prefix);
				}
				$key_offset += 1;
			}
		}
		foreach($projectFolders_bulk_working as $key_=>$project) {
			// add working bulk projects to user interface.
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("5", $key_real, "000000", "FFFFCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}
		foreach($projectFolders_bulk as $key_=>$project) {
			// add working bulk projects to user interface.
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("5", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}
		foreach($projectFolders_working as $key_=>$project) {
			// add other working projects to user interface.
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("2", $key_real, "000000", "FFFFCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}
		foreach($projectFolders_complete as $key_=>$project) {
			// add complete bulk/other projects to user interface.
			if (!str_contains($project,"/")) {
				$key_real = array_search($project,$projectFolders);
				printProjectInfo("1", $key_real, "000000", "CCFFCC", $user, $project,$key_offset,$prefix);
				$key_offset += 1;
			}
		}
		// 1: project complete.
		// 2: project working.
		// 3: project initiated, quota not filled.
		// 4: project initiated, quota filled.
		// 5: project in bulk-processing-queue.
		$prefix = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";

		foreach($projectFolders_subdir as $key1_=>$subdir) {
			printProjectFolderInfo($subdir,$projectFolders);
			foreach($projectFolders_initiated as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					// add initiated bulk/other projects to user interface.
					$key_real = array_search($project,$projectFolders);
					if (!$exceededSpace) {
						printProjectInfo("3", $key_real, "CC0000", "FFCCCC", $user, $project,$key_offset,$prefix);
					} else {
						printProjectInfo("4", $key_real, "888888", "FFFFFF", $user, $project,$key_offset,$prefix);
					}
					$key_offset += 1;
				}
			}
			foreach($projectFolders_bulk_working as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					// add working bulk projects to user interface.
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("5", $key_real, "000000", "FFFFCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}
			foreach($projectFolders_bulk as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					// add working bulk projects to user interface.
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("5", $key_real, "000000", "FFCCCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}
			foreach($projectFolders_working as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					// add other working projects to user interface.
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("2", $key_real, "BB9900", "FFFFCC", $user, $project,$key_offset,$prefix);
					$key_offset += 1;
				}
			}
			foreach($projectFolders_complete as $key_=>$project) {
				if (str_starts_with($project, $subdir . "/")) {
					// add complete bulk/other projects to user interface.
					$key_real = array_search($project,$projectFolders);
					printProjectInfo("1", $key_real, "000000", "CCFFCC", $user, $project,$key_offset,$prefix);
					$key_offset  += 1	;
				}
			}
		}

		echo "\n";
?>
<script type='text/javascript'>
	function loadExternal(imageUrl) {
		window.open(imageUrl);
	}
</script>
<?php
	}
	function printProjectFolderInfo($subdir,$projectFolders) {
		$key_real = array_search($subdir,$projectFolders);
		echo "<br><font size='2'><b>".$subdir."</b></font>\n";

		// Only allow delete if project group is empty.
		$foundList = array_filter($projectFolders, function($item) use ($subdir) { return str_contains($item, $subdir); });
		$count = count($foundList);
		if ($count == 1) {
			echo "<span id='p_delete_".$key_real."'></span>\n";
			if (!file_exists("users/".$user."/projects/".$project."/locked.txt")) {
				echo "<button id='project_delete_".$key_real."' type='button' onclick=\"parent.deleteProjectConfirmation('".$subdir."','".$key_real."');\">Delete</button>";
			} else {
				echo "<font size='2' color='red'>[Project group locked for admin review.]</font>";
			}
			echo "\t\t\t\t";
			echo "<div id='frameContainer.p".$frameContainerIx."_".$key_real."'></div>\n\n\t\t\t\t";
		} else {
			echo "<br>";
		}
	}

	function printProjectInfo($frameContainerIx, $key, $labelRgbColor, $labelRgbBackgroundColor, $user, $project,$key_display,$prefix) {
		// $frameContainerIx values:
		//	1: project complete.
		//	2: project working.
		//	3: project initiated, quota not filled.
		//	4: project initiated, quota filled.
		//	5: project in bulk-processing-queue.

		// Get display name.
		$projectNameString = file_get_contents("users/".$user."/projects/".$project."/name.txt");
		$projectNameString = trim($projectNameString);

		// Get project folder name.
		$position = strpos($project, '/');
		$project_ = $position !== false ? trim(substr($project,$position+1)) : $project;

		echo $prefix."<span id='p_label_".$key."' style='color:#".$labelRgbColor."; background-color:#".$labelRgbBackgroundColor.";'>\n\t\t\t\t";
		echo "<font size='2'>".($key_display+1).".";

		if ($frameContainerIx == "1") {
			// define update dataset button, which passes key value to update project page in iframe of main page.
			if (!file_exists("users/".$user."/projects/".$project."/locked.txt")) {
				if (file_exists("users/".$user."/projects/".$project."/complete.txt") && file_exists("users/".$user."/projects/".$project."/putative_SNPs_v4.zip") && file_exists("users/".$user."/projects/".$project."/SNP_CNV_v1.zip")) {
					echo "<button id='project_update_".$key."' type='button' onclick='";
					echo "parent.document.getElementById(\"Hidden_UpdateDataset_Frame\").contentWindow.location.href = \"project.update_window.php?key=".$key."\";\n";
					echo "parent.show_hidden(\"Hidden_UpdateDataset\"); ";
					echo "getElementById(\"project_update_".$key."\").style.display = \"none\";";
					echo "'>Update</button>";
				}
			}
		}

		if ($project_ == $projectNameString) {
			echo " <div style='display: inline-block'> ".$projectNameString." </div>";
		} else {
			echo " <div style='display: inline-block'> ".$project_." (".$projectNameString.") </div>";
		}

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
				chmod($totalSizeFile, 0774);
			}
			// printing total size
			echo " <font color='black' size='1'>(". $projectSizeStr .")</font>";
		}

		echo "</font></span>\n\t\t\t\t";

		echo "<span id='p_delete_".$key."'></span>\n";

                if (!file_exists("users/".$user."/projects/".$project."/locked.txt")) {
			echo "<button id='project_delete_".$key."' type='button' onclick=\"parent.deleteProjectConfirmation('".$project."','".$key."');\">Delete</button>";
		} else {
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
	foreach($projectFolders_initiated as $key_=>$project) {	// frameContainer.p3_[$key] : initiated.
		$key_real = array_search($project,$projectFolders);
		$project  = $projectFolders[$key_real];
		// Read in dataFormat string for project.
		$handle     = fopen("users/".$user."/projects/".$project."/dataFormat.txt", "r");
		$dataFormat = fgets($handle);
		fclose($handle);
		echo "\n// javascript for project #".$key_real.", '".$project."'\n";
		echo "var el_p               = document.getElementById('frameContainer.p3_".$key_real."');\n";
		// Javascript to build file load button interface.
		echo "el_p.innerHTML         = '<iframe id=\"p_".$key_real."\" name=\"p_".$key_real."\" class=\"upload\" ";
		if ((strlen($dataFormat) > 1) && ($dataFormat[2] == '1')) {
			// paired files to be uploaded.
			echo "style=\"height:76px\" src=\"uploader.2.php\"";
		} else {
			// single file to be uploaded.
			echo "style=\"height:38px\" src=\"uploader.1.php\"";
		}
		echo " marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n";
		echo "var p_iframe           = document.getElementById('p_".$key_real."');\n";
		echo "var p_js               = p_iframe.contentWindow;\n";
		echo "p_js.display_string    = new Array();\n";
		echo "p_js.user              = '".$user."';\n";
		echo "p_js.project           = '".$project."';\n";
		echo "p_js.key               = 'p_".$key_real."';\n";
		if ($dataFormat == '0') {
			// SnpCgh microarray
			echo "p_js.display_string[0] = 'Add : SnpCgh array data...';\n";
			echo "p_js.dataFormat        = 'SnpCghArray';\n";
		} else if (($dataFormat == '1:0:0') || ($dataFormat == '1:0:1')) {
			// WGseq (short-read): single-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Single-end-read WGseq data (FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'WGseq_single';\n";
		} else if (($dataFormat == '1:1:0') || ($dataFormat == '1:1:1')) {
			// WGseq (short-read): paired-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Paired-end-read WGseq data (1/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.display_string[1] = 'Add : Paired-end-read WGseq data (2/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'WGseq_paired';\n";
		} else if (($dataFormat == '1:2:0') || ($dataFormat == '1:2:1') || ($dataFormat == '1:3:0') || ($dataFormat == '1:3:1')) {
			// WGseq (short-read): [SAM/BAM/TXT]
			echo "p_js.display_string[0] = 'Add : WGseq data (SAM/BAM/TXT)...';\n";
			echo "p_js.dataFormat        = 'WGseq_single';\n";
		} else if (($dataFormat == '2') || ($dataFormat == '2:0:0') || ($dataFormat == '2:0:1')) {
			// WGseq (long-read): [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : WGseq long-read data (FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'WGseq_long';\n";
		} else if (($dataFormat == '2:2:0') || ($dataFormat == '2:2:1') || ($dataFormat == '2:3:0') || ($dataFormat == '2:3:1')) {
			// WGseq (long-read): [SAM/BAM/TXT]
			echo "p_js.display_string[0] = 'Add : WGseq data (SAM/BAM)...';\n";
			echo "p_js.dataFormat        = 'WGseq_long';\n";
		} else if (($dataFormat == '3:0:0') || ($dataFormat == '3:0:1')) {
			// ddRADseq : single-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Single-end-read ddRADseq data (FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'ddRADseq_single';\n";
		} else if (($dataFormat == '3:1:0') || ($dataFormat == '3:1:1')) {
			// ddRADseq : paired-end [FASTQ/ZIP/GZ]
			echo "p_js.display_string[0] = 'Add : Paired-end-read ddRADseq data (1/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.display_string[1] = 'Add : Paired-end-read ddRADseq data (2/2; FASTQ/ZIP/GZ)...';\n";
			echo "p_js.dataFormat        = 'ddRADseq_paired';\n";
		} else if (($dataFormat == '3:2:0') || ($dataFormat == '3:2:1') || ($dataFormat == '3:3:0') || ($dataFormat == '3:3:1')) {
			// ddRADseq : [SAM/BAM/TXT]
			echo "p_js.display_string[0] = 'Add : ddRADseq data (SAM/BAM/TXT)...';\n";
			echo "p_js.dataFormat        = 'ddRADseq_single';\n";
		} else if ($dataFormat == '4') {
			// FASTA
			echo "p_js.display_string[0] = 'Add : FASTA data...';\n";
			echo "p_js.dataFormat        = 'FASTA';\n";
		}
	}
	foreach($projectFolders_bulk_working as $key_=>$project) {
		$key_real = array_search($project,$projectFolders);
		$project  = $projectFolders[$key_real];
		echo "\n// javascript for project #".$key_real.", '".$project."'\n";
		echo "var el_p5           = document.getElementById('frameContainer.p5_".$key_real."');\n";
		if ($bulk_ui_projects_showAll) {
			echo "el_p5.innerHTML      = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<iframe id=\"p_".$key_real."\" name=\"p_".$key_real."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
			echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"90%\" frameborder=\"0\"></iframe>';\n";
		} else {
			if ($key_ < $bulk_ui_projects_limit) {
				echo "el_p5.innerHTML      = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<iframe id=\"p_".$key_real."\" name=\"p_".$key_real."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
				echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"90%\" frameborder=\"0\"></iframe>';\n";
			} else {
			}
		}
		echo "var p_iframe        = document.getElementById('p_".$key_real."');\n";
		echo "var p_js            = p_iframe.contentWindow;\n";
		echo "p_js.user           = \"".$user."\";\n";
		echo "p_js.project        = \"".$project."\";\n";
		echo "p_js.key            = \"p_".$key_real."\";\n";
	}
	foreach($projectFolders_bulk as $key_=>$project) {
		$key_real = array_search($project,$projectFolders);
		$project  = $projectFolders[$key_real];
		echo "\n// javascript for project #".$key_real.", '".$project."'\n";
		echo "var el_p5           = document.getElementById('frameContainer.p5_".$key_real."');\n";
		if ($bulk_ui_projects_showAll) {
			echo "el_p5.innerHTML      = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<iframe id=\"p_".$key_real."\" name=\"p_".$key_real."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
			echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"90%\" frameborder=\"0\"></iframe>';\n";
		} else {
			if ($key_ < $bulk_ui_projects_limit) {
				echo "el_p5.innerHTML      = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<iframe id=\"p_".$key_real."\" name=\"p_".$key_real."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
				echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"90%\" frameborder=\"0\"></iframe>';\n";
			} else {
			}
		}
		echo "var p_iframe        = document.getElementById('p_".$key_real."');\n";
		echo "var p_js            = p_iframe.contentWindow;\n";
		echo "p_js.user           = \"".$user."\";\n";
		echo "p_js.project        = \"".$project."\";\n";
		echo "p_js.key            = \"p_".$key_real."\";\n";
	}
	foreach($projectFolders_working as $key_=>$project) {
		$key_real = array_search($project,$projectFolders);
		$project  = $projectFolders[$key_real];
		echo "\n// javascript for project #".$key_real.", '".$project."'\n";
		echo "var el_p2           = document.getElementById('frameContainer.p2_".$key_real."');\n";
		echo "el_p2.innerHTML     = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<iframe id=\"p_".$key_real."\" name=\"p_".$key_real."\" class=\"upload\" style=\"height:38px; border:0px;\" ";
		echo     "src=\"project.working.php\" marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"90%\" frameborder=\"0\"></iframe>';\n";
		echo "var p_iframe        = document.getElementById('p_".$key_real."');\n";
		echo "var p_js            = p_iframe.contentWindow;\n";
		echo "p_js.user           = \"".$user."\";\n";
		echo "p_js.project        = \"".$project."\";\n";
		echo "p_js.key            = \"p_".$key_real."\";\n";
	}
}
?>
</script>
