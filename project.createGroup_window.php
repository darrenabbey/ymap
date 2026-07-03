<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else if ($_SESSION['logged_on'] == 0) {
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else {
		$user = $_SESSION['user'];
	}
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	if (isset($_SESSION['logged_on'])) {
		$user = $_SESSION['user'];
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
<html lang="en">
	<HEAD>
		<style type="text/css">
			body {font-family: arial;}
			.tab {margin-left:   1cm;}
		</style>
		<meta http-equiv="content-type" content="text/html; charset=utf-8">
		<title>[Needs Title]</title>
	</HEAD>
	<BODY>
		<div id="loginControls"><p>
		</p></div>
		<div id="groupCreationInformation"><p>
			<form action="project.createGroup_server.php" method="post">
				<table width="100%"><tr bgcolor="#CCFFCC"><td>
					<label for="group">Project group name : </label><input type="text" name="group" id="group">
				</td><td>
					Unique name for a folder to organize datasets into.
				</td></tr></table><br>
				<?php
				if (!$exceededSpace) {
					echo "<input type='submit' value='Create New Dataset Group'>";
				}
				?>
			</form>
		</p></div>
	</body>
</html>
