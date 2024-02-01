<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';

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
	if ($admin_logged_in == "true") {
		echo "<font size='4'><b>YMAP administrative functions: User approval/deletion; copy items to default user; delete items from default.<b></font><br>";
		echo "<form action='' method='post'>";
		echo "<input type='submit' value='Reload this tab only.'>";
		echo "</form>";
	} else {
		echo "<font size='4'><br>Your account has not been provided with administrator priviledges.</b></font><br>";
	}
?>
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
		echo     "<td width='16%' style='text-align:center'><font size='2'><b>User status</b></font></td>";
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
			if (file_exists("users/".$userFolder."/super.txt")) {
				echo "\t\t\t<font size='2'>[Super admin]</font>\n";
			} else if (file_exists("users/".$userFolder."/admin.txt")) {
				echo "\t\t\t<font size='2'>[Admin]</font>\n";
			} else {
				if (file_exists("users/".$userFolder."/locked.txt")) {
					echo "\t\t\t<input type='button' value='Approve' onclick=\"key = '$key'; $.ajax({url:'admin.approveUser_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}}); setTimeout(()=> {location.replace('panel.admin1.php')},500);\">\n";
					echo "\t\t\t<input type='button' value='Delete'  onclick=\"key = '$key'; $.ajax({url:'admin.deleteUser_server.php' ,type:'post',data:{key:key},success:function(answer){console.log(answer);}}); setTimeout(()=> {location.replace('panel.admin1.php')},500);\">\n";
				} else if (file_exists("users/".$userFolder."/active.txt") and ($userFolder != "default/")) {
					echo "\t\t\t<input type='button' value='Lock' onclick=\"key = '$key'; $.ajax({url:'admin.lockUser_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}}); setTimeout(()=> {location.replace('panel.admin1.php')},500);\">\n";
				}
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

<?php
	if ($super_logged_in == "true") {
?>
<hr width="100%">
<font size='3'>Copy genomes to default user account.</font><br>
<font size='2'>(Function to remove default user projects is lower on the page.)</font><br><br>
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
			echo "<td width='30%'><font size='2'><b>Copy Genome</b></font></td>";
			echo "<td><font size='2'><b>Genome \"name.txt\" Contents</b></font></td>";
			echo "</tr>\n";
			foreach($genomeFolders as $key=>$genome) {
				echo "\t\t<tr style='";
				if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
				echo "'>";
				echo "<td>\n\t\t\t<span id='genome_label_".$key."' style='color:#000000;'>";
				echo "<font size='2'>".($key+1).". ".$genome."</font></span>\n";
				echo "\t\t</td><td>\n";
				echo "\t\t\t<input type='button' value='Copy genome to default user' onclick=\"key = '$key'; $.ajax({url:'admin.copyGenome_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin1.php');\">\n";
				echo "\t\t</td><td>\n";
				$nameFile         = "users/".$user."/genomes/".$genome."name.txt";
				$genomeNameString = file_get_contents($nameFile);
				$genomeNameString = trim($genomeNameString);
				echo "<font size='2'>".$genomeNameString."</font>";

				echo "\t\t</td></tr>\n";
			}
			echo "</table>";
		}
?>
</td><td width="35%" valign="top">
</td></tr></table>


<hr width="100%">
<font size='3'>Copy hapmaps to default user account.</font><br>
<font size='2'>(Function to remove default user projects is lower on the page.)</font><br><br>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
<?php
		//.-----------------------.
		//| Admin account hapmaps |
		//'-----------------------'
		if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
			$hapmapDir     = "users/".$_SESSION['user']."/hapmaps/";
			$hapmapFolders = array_diff(glob($hapmapDir."*\/"), array('..', '.'));

			// Sort directories by date, newest first.
			array_multisort($hapmapFolders, SORT_ASC, $hapmapFolders);
			// Trim path from each folder string.
			foreach($hapmapFolders as $key=>$folder) {
				$hapmapFolders[$key] = str_replace($hapmapDir,"",$folder);
			}
			$hapmapCount = count($hapmapFolders);

			echo "<table width='100%'>";
			echo "<tr><td width='30%'><font size='2'><b>Hapmaps</b></font></td>";
			echo "<td width='30%'><font size='2'><b>Copy Hapmap</b></font></td>";
			echo "<td><font size='2'><b>Hapmapt \"name.txt\" Contents</b></font></td>";
			echo "</tr>\n";
			foreach($hapmapFolders as $key=>$hapmap) {
				echo "\t\t<tr style='";
				if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
				echo "'>";
				echo "<td>\n\t\t\t<span id='hapmap_label_".$key."' style='color:#000000;'>";
				echo "<font size='2'>".($key+1).". ".$hapmap."</font></span>\n";
				echo "\t\t</td><td>\n";
				echo "\t\t\t<input type='button' value='Copy hapmap to default user' onclick=\"key = '$key'; $.ajax({url:'admin.copyHapmap_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin1.php');\">\n";
				echo "\t\t</td><td>\n";
				$nameFile          = "users/".$user."/hapmaps/".$hapmap."name.txt";
				$hapmapNameString = file_get_contents($nameFile);
				$hapmapNameString = trim($hapmapNameString);
				echo "<font size='2'>".$hapmapNameString."</font>";

				echo "\t\t</td></tr>\n";
			}
			echo "</table>";
		}
?>
</td><td width="35%" valign="top">
</td></tr></table>


<hr width="100%">
<font size='3'>Minimize and copy projects to default user account.</font><br>
<font size='2'>(Function to remove default user projects is lower on the page.)</font><br>
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
			echo "<td width='30%'><font size='2'><b>Minimize then Copy Project</b></font></td>";
			echo "<td><font size='2'><b>Project \"name.txt\" Contents</b></font></td>";
			echo "</tr>\n";
			foreach($projectFolders as $key=>$project) {
				echo "\t\t<tr style='";
				if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
				echo "'>";

				echo "<td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
				echo "<font size='2'>".($key+1).". ".$project."</font></span>\n";
				echo "\t\t</td><td>\n";
				if (file_exists("users/".$user."/projects/".$project."/complete.txt") && !file_exists("users/".$user."/projects/".$project."/minimized.txt")) {
					echo "\t\t\t<input type='button' value='Minimize project' onclick=\"key = '$key'; $.ajax({url:'admin.minimizeProject_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin1.php');\">\n";
				}
				if (file_exists("users/".$user."/projects/".$project."/complete.txt") && file_exists("users/".$user."/projects/".$project."/minimized.txt")) {
					echo "\t\t\t<input type='button' value='Copy project to default user' onclick=\"key = '$key'; $.ajax({url:'admin.copyProject_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin1.php');\">\n";
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


<hr width="100%">
<b>
<font size='3'>Delete projects from default user account.</font><br>
<font size='2' color='red'>(There is no way to undo this!)</font><br>
<font size='2' color='red'>(There is no second chance!)</font><br>
<font size='2' color='red'>(On error, you will have to reinstall!)</font><br>
</b>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
<?php
		//.-------------------------------.
		//| Delete admin account projects |
		//'-------------------------------'
		if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
			$projectDir     = "users/default/projects/";
			$projectFolders = array_diff(glob($projectDir."*\/"), array('..', '.'));

			// Sort directories by date, newest first.
			array_multisort($projectFolders, SORT_ASC, $projectFolders);
			// Trim path from each folder string.
			foreach($projectFolders as $key=>$folder) {
				$projectFolders[$key] = str_replace($projectDir,"",$folder);
			}
			$projectCount = count($projectFolders);

			echo "<table width='100%'>";
			echo "<tr><td width='50%'><font size='2'><b>Projects</b></font></td>";
			echo "<td width='10%'><font size='2'><b>Delete Project</b></font></td>";
			echo "<td><font size='2'><b>Project \"name.txt\" Contents</b></font></td>";
			echo "</tr>\n";
			foreach($projectFolders as $key=>$project) {
				echo "\t\t<tr style='";
				if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
				echo "'>";

				echo "<td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
				echo "<font size='2'>".($key+1).". ".$project."</font></span>\n";
				echo "\t\t</td><td>\n";

				echo "\t\t\t<input type='button' value='Delete project' onclick=\"key = '$key'; $.ajax({url:'admin.deleteProject_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin1.php');\">\n";

				echo "\t\t</td><td>\n";
				$nameFile          = "users/default/projects/".$project."name.txt";
				$projectNameString = file_get_contents($nameFile);
				$projectNameString = trim($projectNameString);
				echo "<font size='2'>".$projectNameString."</font>";

				echo "\t\t</td></tr>\n";
			}
			echo "</table>";
		}
?>



<hr width="100%">
<b>
<font size='3'>Delete genomes from default user account.</font><br>
<font size='2' color='red'>(There is no way to undo this!)</font><br>
<font size='2' color='red'>(There is no second chance!)</font><br>
<font size='2' color='red'>(On error, you will have to reinstall!)</font><br>
</b>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
<?php
		//.-------------------------------.
		//| Delete admin account genomes  |
		//'-------------------------------'
		if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
			$genomeDir     = "users/default/genomes/";
			$genomeFolders = array_diff(glob($genomeDir."*\/"), array('..', '.'));

			// Sort directories by date, newest first.
			array_multisort($genomeFolders, SORT_ASC, $genomeFolders);
			// Trim path from each folder string.
			foreach($genomeFolders as $key=>$folder) {
				$genomeFolders[$key] = str_replace($genomeDir,"",$folder);
			}
			$genomeCount = count($genomeFolders);

			echo "<table width='100%'>";
			echo "<tr><td width='50%'><font size='2'><b>Genomes</b></font></td>";
			echo "<td width='10%'><font size='2'><b>Delete Genome</b></font></td>";
			echo "<td><font size='2'><b>Genome \"name.txt\" Contents</b></font></td>";
			echo "</tr>\n";
			foreach($genomeFolders as $key=>$genome) {
				echo "\t\t<tr style='";
				if ($key % 2 == 0) { echo "; background:#DDBBBB;"; }
				echo "'>";

				echo "<td>\n\t\t\t<span id='genome_label_".$key."' style='color:#000000;'>";
				echo "<font size='2'>".($key+1).". ".$genome."</font></span>\n";
				echo "\t\t</td><td>\n";

				echo "\t\t\t<input type='button' value='Delete genome' onclick=\"key = '$key'; $.ajax({url:'admin.deleteGenome_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin1.php');\">\n";

				echo "\t\t</td><td>\n";
				$nameFile          = "users/default/genomes/".$genome."name.txt";
				$genomeNameString = file_get_contents($nameFile);
				$genomeNameString = trim($genomeNameString);
				echo "<font size='2'>".$genomeNameString."</font>";

				echo "\t\t</td></tr>\n";
			}
			echo "</table>";
		}
?>

<hr width="100%">
<b>
<font size='3'>Delete hapmapss from default user account.</font><br>
<font size='2' color='red'>(This is too dangerous.)</font><br>
<font size='2' color='red'>(No function provided until automatic backup of hapmaps can be made.)</font><br>
</b>
<table width="100%" cellpadding="0"><tr>
<td width="100%" valign="top">
<?php
		//.-------------------------------.
		//| Delete admin account hapmapss |
		//'-------------------------------'
?>

<?php
	}
?>
</td><td width="35%" valign="top">
</td></tr></table>
</html>
