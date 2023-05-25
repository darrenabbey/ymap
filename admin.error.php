<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	// If the user is not logged on, redirect to login page.
	if(!isset($_SESSION['logged_on'])) {
		session_destroy();
		header('Location: .');
	}

	// Ensure admin user is logged in.
	$user = $_SESSION['user'];
	$super_user_flag_file = "users/".$user."/super.txt";
	if (file_exists($super_user_flag_file)) {  // Super-user privilidges.
		$admin_logged_in = "true";
	} else {
		$admin_logged_in = "false";
		session_destroy();
		log_stuff($user,"","","","","CREDENTIAL fail: user attempted to use admin function to add error to project!");
		header('Location: .');
	}
?>
<html lang="en">
	<head>
		<style type="text/css">
			body {font-family: arial;}
		</style>
		<meta http-equiv="content-type" content="text/html; charset=utf-8">
		<title>[Needs Title]</title>
	</head>
	<body style="background-color:#FFCCCC">
		<div id="genomeCreationInformation"><p>
			<form id="errorSend" action="admin.error_server.php" method="post">
				User: <script type="text/javascript">
					user = localStorage.getItem("user");
					document.write(user);
				</script><br>
				Project: <script type="text/javascript">
					projectKey = localStorage.getItem("projectKey");
					projectName = localStorage.getItem("projectName");
					document.write(projectName + " (key=" + projectKey + ")");
				</script><br>
				<label for="newGenomeName">Error text: </label><input type="text" name="errorText" id="errorText" size="100"><br>
				<br>
				<?php
				if (!$exceededSpace) {
					echo "<input type='submit' value='Push error to project.' onclick='";
					echo "parent.hide_hidden(\"Hidden_Admin\"); ";
					//echo "parent.update_interface();";
					echo "'>";
				}
				?>
				<script type="text/javascript">
					var input1 = document.createElement("input");
					input1.setAttribute("type", "hidden");
					input1.setAttribute("name", "user");
					input1.setAttribute("value", user);
					document.getElementById("errorSend").appendChild(input1);

					var input2 = document.createElement("input");
					input2.setAttribute("type", "hidden");
					input2.setAttribute("name", "key");
					input2.setAttribute("value", projectKey);
					document.getElementById("errorSend").appendChild(input2);
				</script>
			</form>
		</p></div>
		Add an "<b>error.txt</b>" file to stalled project directory after investigating via server access.<br>
		Error text will be displayed to user when next they check the dataset's status.<br>
		Will overwrite an existing error file.<br><br>
		<b>[Not yet functional.]</b>
	</body>
</html>
