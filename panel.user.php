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
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
?>
<style type="text/css">
html * {
	font-family: arial !important;
}
</style>
<span id="firefox_error_span"></span>
<script type="text/javascript">
if (navigator.userAgent.toLowerCase().indexOf('firefox') > -1) {
	// Do Firefox-related activities
	var FFerror       = document.getElementById("firefox_error_span");
	ErrorString       = '<font color="red"><b>';
	ErrorString      += 'Some features of this website require a web-browser based on the Blink (Chrome, Opera, etc.) or WebKit (Safari, etc.) rendering engines.<br><br>';
	ErrorString      += 'Firefox is based on the Gecko rendering engine. YMAP has an error when rendered with this engine, resulting in datasets not processing after data upload.';
	ErrorString      += '</b></font><br><br>';
	FFerror.innerHTML = ErrorString;
}
</script>

<table width="100%"><tr><td width="30%" valign="top">
<font size='3'>Log into a preexisting user account or create a new user account.</font><br>
<?php

if (!isset($_SESSION['logged_on'])) {
	$delay = $_SESSION['delay'];
	if (isset($_SESSION['error'])) { echo $_SESSION['error']; }
	if ($delay != 0) {
		echo "<font size='2' color='Red'>(There will be a short delay after hitting 'Log In' button due to prior log in failure.)</font><br>";
	}
}
echo "<br>";

if (isset($_SESSION['logged_on'])) {
	echo "User '<b>".$user."</b>' logged in. \n";
	// provide logout button.
	echo "<button type='button' onclick=\"window.location.href='user.logout_server.php'\">Logout</button>\n";
	// provide delete-user button.
	echo "<span id='u_".$user."_delete'></span>\n";
	echo "<button type='button' onclick=\"window.location.href='user.delete.php'\">Delete User.</button>\n";
	echo "<br><br>\n";
	echo "<font size='2'>\n\t";
	echo "You can navigate through the above menu and show/close projects while new datafiles are uploading.\n\t";
	echo "A page reload or project/genome/hapmap creation/deletion, however, will interrupt file transfer.<br><br>\n\t";
	echo "Depending on system load, tasks may take some time to start being processed by the queue.\n\t";
	echo "Reload page and select 'projects' tab periodically to check for newly completed projects.\n";
	echo "</font>\n";

	if (isset($_SESSION['reload_once'])) {
		echo "<script type=\"text/javascript\"> parent.location.reload(); </script>\n";
		unset($_SESSION['reload_once']);
	}
} else {
	// provide login button.
	echo "<script type=\"text/javascript\">\n\t\n\t</script>\n\t";
	echo "<form action='user.login_server.php' method='post'>\n\t";
	echo "<label for='user'>Username: </label><input type='text' id='user' name='user'><br>\n\t";
	echo "<label for='pw'>Password: </label><input type='password' id='pw' name='pw'><br>\n\t";
	echo "<button type='submit'>Log In</button>\n\t";
	echo "</form>\n\t";
	echo "<font size='2'>";
	echo "If you don't have a user account, you may make one by clicking below.<br>Your account will initially remain locked until it has been approved by an admin.<br>\n\t";
	echo "<button type='button' onclick=\"window.location.href='user.register.php'\">Register new user.</button>\n\t";
	echo "</font>\n\t";
	$_SESSION['reload_once'] = "true";
}
?>
</td><td width="70%" style="border:1px solid black; border-radius:10px; padding:10px;" valign="top">
<b>YMAP news!</b><br><br>
2026-05-14
<ul>
<li>YMAP is back! While we were offline, I took the opportunity to do some major system updates.</li>
	<ol>
	<li><b>YMAP now can process long-read sequence data!</b></li>
	<li>Uploaded data is now added to a queue that will process your data while keeping system demaind under control.</li>
	<li>Queue status and expected time until next uploaded dataset can start processing is shown in the "Manage Datasets" tab.</li>
	<li>A warning is presented if less than 50% of uploaded sequence reads map to the reference genome.</li>
	<li>Fewer process hangs/crashes due to better error management.</i>
	<li>If a process crashes, a useful error message will be generated, allowing easier code troubleshooting.</li>
	<li>The install process has been greatly simplified if you want to setup your own local YMAP server. This option will give you the opportunity to use a bulk data processing module that isn't available on the public server.</li>
	<li>The web interface of YMAP includes several admin tabs for user and analysis management.</li>
	<li>There is a new commandline admin interface ("YMAPcl.sh") that can use most features of the web interface of YMAP. </li>
	</ol>
<br>
<li>There have been user interface and final output figure improvements.</li>
	<ol>
	<li>Chromosome cartoons have a more polished look.</li>
	<li>The combined figure command now produces a figure with dataset names added above each subfigure.</li>
	<li>Some buttons have been repositioned to help avoid accidental deletion of data.</li>
	</ol>
<br>
<li>Additional functions are planned to be added at the time of a planned paper where the name will transition to YMAP2.</li>
	<ol>
	<li>Natively handling diploid reference genomes.</li>
	<li>Processing data for much larger genomes?</li>
	<li>...</li>
	<li><b><font color="red">What feature immprovements would you like to see?</font></b></li>
	</ol>
</td></tr></table>
