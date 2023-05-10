<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ session_destroy(); ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
?>
<html style="background: #FFDDDD;">
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>

<?php
	$super_user_flag_file = "users/".$user."/super.txt";
	if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
		$admin_logged_in = "true";
	} else {
		$admin_logged_in = "false";
	}
?>

<font size='3'>
<?php
if ($admin_logged_in == "true") {
	echo "Your account has been provided with administrator priviledges.";
} else {
	echo "Your account has not been provided with administrator priviledges.<br>";
	log_stuff("",$user,"","","","","CREDENTIAL fail: user attempted to access admin panel?");
}
?>
</font>

<hr width="100%">
User account maintenance.
<table width="100%" cellpadding="0"><tr>
<td width="65%" valign="top">
<script type="text/javascript" src="js/jquery-3.6.3.js"></script>
<script type="text/javascript" src="js/jquery.form.js"></script>
	<?php
	//.---------------.
	//| User Accounts |
	//'---------------'
	if (($admin_logged_in == "true") and isset($_SESSION['logged_on'])) {
		$userDir      = "users/";
		$userFolders  = array_diff(glob($userDir."*\/"), array('..', '.'));
		// Sort directories by date, newest first.
		array_multisort($userFolders, SORT_ASC, $userFolders);
		// Trim path from each folder string.
		foreach($userFolders as $key=>$folder) {   $userFolders[$key] = str_replace($userDir,"",$folder);   }
		$userCount = count($userFolders);

		echo "<table width='100%'>";
		echo "<tr><td width='20%'><font size='2'><b>User Account</b></font></td>";
		echo     "<td><font size='2'><b>Approval Needed</b></font></td>";
		echo     "<td><font size='2'><b>User Name</b></font></td>";
		echo     "<td><font size='2'><b>Email Address</b></font></td>";
		echo "</tr>\n";
		foreach($userFolders as $key=>$user) {
			echo "\t\t<tr><td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$user."</font></span>\n";
			//echo "<span id='u2_".$user."_delete'></span><span id='u_".$user."_type'></span>\n\t\t";
			//echo "<br>\n\t\t";
			//echo "<div id='frameContainer.u1_".$key."'></div>";
			echo "\t\t</td><td>\n";

			if (!file_exists("users/".$user."/super.txt")) {
				if (file_exists("users/".$user."/locked.txt")) {
					echo "\t\t\t<input type='button' value='Approve' onclick=\"key = '$key'; $.ajax({url:'admin.approve_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
					echo "\t\t\t<input type='button' value='Delete'  onclick=\"key = '$key'; $.ajax({url:'admin.delete_server.php' ,type:'post',data:{key:key},success:function(answer){console.log(answer);}});setTimeout(()=> {location.replace('panel.admin.php')},1000);\">\n";
				} else if ($user != "default/") {
					echo "\t\t\t<input type='button' value='Lock user' onclick=\"key = '$key'; $.ajax({url:'admin.lockUser_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
				}
			} else {
				echo "\t\t\t[Admin]\n";
			}

			echo "\t\t</td>\n";
			if (file_exists("users/".$user."/info.txt")) {
				$info_array = explode("\n", file_get_contents("users/".$user."/info.txt"));
				echo "\t\t<td>";
				echo str_replace("Primary Investigator Name: ","",$info_array[1]);
				echo "\t\t</td>";

				echo "\t\t<td>";
				echo str_replace("Primary Investigator Email: ","",$info_array[2]);
				echo "\t\t</td>";
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
Copy genomes/projects to default user account.
<table width="100%" cellpadding="0"><tr>
<td width="65%" valign="top">
	<script type="text/javascript" src="js/jquery-3.6.3.js"></script>
	<script type="text/javascript" src="js/jquery.form.js"></script>
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
		echo "</tr>\n";
		foreach($genomeFolders as $key=>$genome) {
			echo "\t\t<tr><td>\n\t\t\t<span id='genome_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$genome."</font></span>\n";
			echo "\t\t</td><td>\n";
			echo "\t\t\t<input type='button' value='Copy genome' onclick=\"key = '$key'; $.ajax({url:'admin.copyGenome_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			echo "\t\t</td></tr>\n";
		}
		echo "</table>";
	}

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
		echo "</tr>\n";
		foreach($projectFolders as $key=>$project) {
			echo "\t\t<tr><td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$project."</font></span>\n";
			echo "\t\t</td><td>\n";
			echo "\t\t\t<input type='button' value='Copy project' onclick=\"key = '$key'; $.ajax({url:'admin.copyProject_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			echo "\t\t</td></tr>\n";
		}
		echo "</table>";
	}
	?>
</td><td width="35%" valign="top">
</td></tr></table>
</html>
