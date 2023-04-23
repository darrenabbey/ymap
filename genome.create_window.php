<?php
    session_start();
    if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
    require_once 'constants.php';
    echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
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
				<input type="submit" value="Create New Genome">
			</form>
		</p></div>
		Once data file has been selected, this window will close.<br>
		Reload the main page, then select "Finalize" button to setup the genome.<br>
		The finalize window will allow you to define which parts of the FASTA file are used in YMAP.<br><br>
		Once you submit your selections, YMAP will then process the genome in the background.<br>
		You can reload the page and use other functions, but the new genome will not be available until processing has completed.
	</body>
</html>
