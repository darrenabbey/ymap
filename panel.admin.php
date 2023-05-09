<?php
	session_start();
	require_once 'constants.php';
	if (isset($_SESSION['logged_on'])) { $user = $_SESSION['user']; }
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
	echo "Your account has been provided with administrator priviledges.<br><br>";
} else {
	echo "Your account has not been provided with administrator priviledges.<br><br>";
	log_stuff("",$user,"","","","","CREDENTIAL fail: user attempted to access admin panel?");
}
?>
This "Admin" tab will have system troubleshooting tools and/or notes for administrators, but cannot be seen by normal user accounts.
It may be helpful for you to make a second account to view the site as a normal user.<br>
</font>

<hr width="100%">
Newly registered locked accounts, pending approval.
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
		echo "</tr>\n";
		foreach($userFolders as $key=>$user) {
			echo "\t\t<tr><td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$user."</font></span>\n";
			//echo "<span id='u2_".$user."_delete'></span><span id='u_".$user."_type'></span>\n\t\t";
			//echo "<br>\n\t\t";
			//echo "<div id='frameContainer.u1_".$key."'></div>";
			echo "\t\t</td><td>\n";

			if (file_exists("users/".$user."/locked.txt")) {
				echo "\t\t\t<input type='button' value='Approve' onclick=\"key = '$key'; $.ajax({url:'admin.approve_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
				echo "\t\t\t<input type='button' value='Delete'  onclick=\"key = '$key'; $.ajax({url:'admin.delete_server.php' ,type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			} else {
				if ($user != "default/") {
					echo "\t\t\t<input type='button' value='Lock user' onclick=\"key = '$key'; $.ajax({url:'admin.lockUser_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
				}
			}

			echo "\t\t</td></tr>\n";
		}
		echo "</table>";
	} else {
		$userCount = 0;
	}
	?>
</td><td width="35%" valign="top">
</td></tr></table>

<hr width="100%">
Copy genomes to default account.
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
		echo "<tr><td width='30%'><font size='2'><b>Installed Genomes</b></font></td>";
		echo "</tr>\n";
		foreach($genomeFolders as $key=>$genome) {
			echo "\t\t<tr><td>\n\t\t\t<span id='project_label_".$key."' style='color:#000000;'>";
			echo "<font size='2'>".($key+1).". ".$genome."</font></span>\n";
			echo "\t\t</td><td>\n";
			echo "\t\t\t<input type='button' value='Copy genome' onclick=\"key = '$key'; $.ajax({url:'admin.copyGenome_server.php',type:'post',data:{key:key},success:function(answer){console.log(answer);}});location.replace('panel.admin.php');\">\n";
			echo "\t\t</td></tr>\n";
		}
		echo "</table>";
	} else {
		$userCount = 0;
	}
	?>
</td><td width="35%" valign="top">
</td></tr></table>
</html>
