<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	if (isset($_SESSION['logged_on'])) {
		$user = $_SESSION['user'];
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota_ = getUserQuota($user);
		if ($quota_ > $quota) {   $quota = $quota_;   }
		// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
		$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
		if ($exceededSpace) {
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (".$quota."G) please clear space and then reload to add new genome.</span><br><br>";
		}
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
	<body>
		<div id="genomeCreationInformation"><p>
			<form action="genome.create_server.php" method="post">
				<label for="newGenomeName">Genome Name: </label><input type="text" name="newGenomeName" id="newGenomeName" size="100"><br>
				<br>
				<?php
				if (!$exceededSpace) {
					echo "<input type='submit' value='Create New Genome'>";
				}
				?>
			</form>
		</p></div>
		Once data file has been selected, this window will close.<br>
		Reload the main page, then select "Finalize" button to setup the genome.<br>
		The finalize window will allow you to define which parts of the FASTA file are used in YMAP.<br><br>
		Once you submit your selections, YMAP will then process the genome in the background.<br>
		You can reload the page and use other functions, but the new genome will not be available until processing has completed.
	</body>
</html>
