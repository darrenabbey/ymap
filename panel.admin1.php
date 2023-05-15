<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';

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
<font size='3'>
<?php
	if ($admin_logged_in == "true") {
		echo "Your account has been provided with administrator priviledges.<br><br>";
	} else {
		echo "Your account has not been provided with administrator priviledges.<br>";
	}
?>
</font>

<script type="text/javascript" src="js/jquery-3.6.3.js"></script>
<script type="text/javascript" src="js/jquery.form.js"></script>

<hr width="100%">
User account maintenance. <font size="2">(User quota is <?php $quota_ = getUserQuota($user); echo $quota; ?>GB.)</font><br><br>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
	<?php
	//.---------------.
	//| User Accounts |
	//'---------------'
	if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
		$userDir      = "users/";
		$userFolders  = array_diff(glob($userDir."*\/"), array('..', '.', 'users/default/'));
		// Sort directories.
		array_multisort($userFolders, SORT_ASC, $userFolders);
		// Trim path from each folder string.
		foreach($userFolders as $key=>$folder) {   $userFolders[$key] = str_replace($userDir,"",$folder);   }
		$userCount = count($userFolders);

		echo "<table width='100%'>";
		echo "<tr><td width='16%'><font size='2'><b>User Account</b></font></td>";
		echo     "<td width='16%' style='text-align:center'><font size='2'><b>Approval Needed</b></font></td>";
		echo     "<td width='16%' style='text-align:center'><font size='2'><b>Account size</b><br>";

		// calculating user account size.
		$userSizeStr = trim(shell_exec("du -sh " . "users/ | cut -f1"));
		// printing total size.
		echo " (".$userSizeStr." total)";

		echo     "</font></td>";
		echo     "<td width='16%'><font size='2'><b>User Name</b></font></td>";
		echo     "<td width='16%'><font size='2'><b>Email Address</b></font></td>";
		echo     "<td width='16%'><font size='2'><b>Institution</b></font></td>";
		echo "</tr>\n";
		foreach($userFolders as $key=>$userFolder) {
			echo "\t\t<tr style='";
			if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
			echo "'>";
			echo "<td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$userFolder."</font></span>\n";
			echo "\t\t</td><td style='text-align:center'>\n";
			if (!file_exists("users/".$userFolder."/super.txt")) {
				if (file_exists("users/".$userFolder."/locked.txt")) {
					echo "\t\t\t<input type='button' value='Approve user' onclick=\"key = '$key'; $.ajax({url:'admin.approve_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}}); setTimeout(()=> {location.replace('panel.admin1.php')},500);\">\n";
					echo "\t\t\t<input type='button' value='Delete user'  onclick=\"key = '$key'; $.ajax({url:'admin.delete_server.php' ,type:'post',data:{key:key},success:function(answer){console.log(answer);}}); setTimeout(()=> {location.replace('panel.admin1.php')},500);\">\n";
				} else if (file_exists("users/".$userFolder."/active.txt") and ($userFolder != "default/")) {
					echo "\t\t\t<input type='button' value='Lock user' onclick=\"key = '$key'; $.ajax({url:'admin.lockUser_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}}); setTimeout(()=> {location.replace('panel.admin1.php')},500);\">\n";
				}
			} else {
				echo "\t\t\t<font size='2'>[Admin]</font>\n";
			}
			echo "\t\t</td>\n";

			// calculating user account size.
			$userSizeStr = trim(shell_exec("du -sh " . "users/".$userFolder."/ | cut -f1"));
                        // printing total size.
			echo "\t\t<td style='text-align:center'><font size='2'>".$userSizeStr."</font></td>\n";

			echo "\t\t</td>\n";
			if (file_exists("users/".$userFolder."/info.txt")) {
				$info_array = explode("\n", file_get_contents("users/".$userFolder."/info.txt"));
				echo "\t\t<td><font size='2'>";
				echo str_replace("Primary Investigator Name: ","",$info_array[1]);
				echo "\t\t</font></td>";

				echo "\t\t<td><font size='2'>";
				echo str_replace("Primary Investigator Email: ","",$info_array[2]);
				echo "\t\t</font></td>";

				echo "\t\t<td><font size='2'>";
				echo str_replace("Research Institution: ","",$info_array[3]);
				echo "\t\t</font></td>";
			}
			echo "\t\t</tr>\n";
		}
		echo "</table>";
	} else {
		$userCount = 0;
	}
	?>
</td><td width="35%" valign="top">
</td></tr></table>

<hr width="100%">
Copy genomes to default user account.<br><br>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
	<?php
	//.-----------------------.
	//| Admin account genomes |
	//'-----------------------'
	if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
		$genomeDir     = "users/".$_SESSION['user']."/genomes/";
		$genomeFolders = array_diff(glob($genomeDir."*\/"), array('..', '.'));

		// Sort directories by date, newest first.
		array_multisort($genomeFolders, SORT_ASC, $genomeFolders);
		// Trim path from each folder string.
		foreach($genomeFolders as $key=>$folder) {
			$genomeFolders[$key] = str_replace($genomeDir,"",$folder);
		}
		$genomeCount = count($genomeFolders);

		echo "<table width='100%'>";
		echo "<tr><td width='30%'><font size='2'><b>Genomes</b></font></td>";
		echo "<td width='30%'><font size='2'><b>Copy</b></font></td>";
		echo "</tr>\n";
		foreach($genomeFolders as $key=>$genome) {
			echo "\t\t<tr style='";
			if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
			echo "'>";
			echo "<td>\n\t\t\t<span id='genome_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$genome."</font></span>\n";
			echo "\t\t</td><td>\n";
			echo "\t\t\t<input type='button' value='Copy genome to default user' onclick=\"key = '$key'; $.ajax({url:'admin.copyGenome_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			echo "\t\t</td></tr>\n";
		}
		echo "</table>";
	}
?>
</td><td width="35%" valign="top">
</td></tr></table>

<hr width="100%">
Minimize and copy projects to default user account.<br>
<font size='2'>(Minimized projects can only be viewed, can't be used for further analysis.)</font><br><br>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
<?php
	//.-----------------------.
	//| Admin account projects |
	//'-----------------------'
	if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
		$projectDir     = "users/".$_SESSION['user']."/projects/";
		$projectFolders = array_diff(glob($projectDir."*\/"), array('..', '.'));

		// Sort directories by date, newest first.
		array_multisort($projectFolders, SORT_ASC, $projectFolders);
		// Trim path from each folder string.
		foreach($projectFolders as $key=>$folder) {
			$projectFolders[$key] = str_replace($projectDir,"",$folder);
		}
		$projectCount = count($projectFolders);

		echo "<table width='100%'>";
		echo "<tr><td width='30%'><font size='2'><b>Projects</b></font></td>";
		echo "<td><font size='2'><b>Minimize Project</b></font></td>";
		echo "<td><font size='2'><b>Copy</b></font></td>";
		echo "<td><font size='2'><b>Project \"name.txt\" Contents</b></font></td>";
		echo "</tr>\n";
		foreach($projectFolders as $key=>$project) {
			echo "\t\t<tr style='";
			if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
			echo "'>";

			echo "<td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$project."</font></span>\n";
			echo "\t\t</td><td>\n";
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				echo "\t\t\t<input type='button' value='Minimize project' onclick=\"key = '$key'; $.ajax({url:'admin.cleanProject_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			}
			echo "\t\t</td><td>\n";
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				echo "\t\t\t<input type='button' value='Copy project to default user' onclick=\"key = '$key'; $.ajax({url:'admin.copyProject_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			}
			echo "\t\t</td><td>\n";
			$nameFile          = "users/".$user."/projects/".$project."name.txt";
			$projectNameString = file_get_contents($nameFile);
			$projectNameString = trim($projectNameString);
			echo "<font size='2'>".$projectNameString."</font>";

			echo "\t\t</td></tr>\n";
		}
		echo "</table>";
	}
	?>
</td><td width="35%" valign="top">
</td></tr></table>
</html>
