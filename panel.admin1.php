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
		echo "<font size='4'><b>YMAP administrative functions: User account approval/lock/deletion.<b></font><br>";
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
</html>
