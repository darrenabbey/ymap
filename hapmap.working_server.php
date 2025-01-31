<?php
	session_start();
	error_reporting(E_ALL);
        require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
        ini_set('display_errors', 1);

        // If the user is not logged on, redirect to login page.
        if(!isset($_SESSION['logged_on'])){
		session_destroy();
                header('Location: .');
        }

	// Load user string from session.
	if(isset($_SESSION['user'])) {
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// Sanitize input strings.
		$hapmap = sanitize_POST("hapmap");
		$key    = sanitize_POST("key");
		$status = (int)sanitize_POST("status");

		// Confirm if requested genome exists.
		$hapmap_dir = "users/".$user."/hapmaps/".$hapmap;
		if (!is_dir($hapmap_dir)) {
			// Hapmap doesn't exist, should never happen: Force logout.
			session_destroy();
			header('Location: .');
		}

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	"http://www.w3.org/TR/html4/loose.dtd">
<head>
<style type="text/css">
	body {font-family: arial;}
	.tab {margin-left:   1cm;}
	.clock {
		float:          left;
		margin-right:   0.25cm;
	}
</style>
</head>
<?php
		// increment clock animation...
		$status   = ($status + 1) % 12;
		if ($status == 0) {          $clock = "<img src=\"images/12.png\" alt-text=\"12\" class=\"clock\" >";
		} else if ($status == 1) {   $clock = "<img src=\"images/01.png\" alt-text=\"01\" class=\"clock\" >";
		} else if ($status == 2) {   $clock = "<img src=\"images/02.png\" alt-text=\"02\" class=\"clock\" >";
		} else if ($status == 3) {   $clock = "<img src=\"images/03.png\" alt-text=\"03\" class=\"clock\" >";
		} else if ($status == 4) {   $clock = "<img src=\"images/04.png\" alt-text=\"04\" class=\"clock\" >";
		} else if ($status == 5) {   $clock = "<img src=\"images/05.png\" alt-text=\"05\" class=\"clock\" >";
		} else if ($status == 6) {   $clock = "<img src=\"images/06.png\" alt-text=\"06\" class=\"clock\" >";
		} else if ($status == 7) {   $clock = "<img src=\"images/07.png\" alt-text=\"07\" class=\"clock\" >";
		} else if ($status == 8) {   $clock = "<img src=\"images/08.png\" alt-text=\"08\" class=\"clock\" >";
		} else if ($status == 9) {   $clock = "<img src=\"images/09.png\" alt-text=\"09\" class=\"clock\" >";
		} else if ($status == 10) {  $clock = "<img src=\"images/10.png\" alt-text=\"10\" class=\"clock\" >";
		} else if ($status == 11) {  $clock = "<img src=\"images/11.png\" alt-text=\"11\" class=\"clock\" >";
		} else {                     $clock = "[ * ]";
		}

		if (file_exists($hapmap_dir."/complete.txt")) {
?>
		<html>
		<body onload = "parent.parent.update_hapmap_label_color('<?php echo $key; ?>','#00AA00','#FFFFFF'); parent.parent.resize_hapmap('<?php echo $key; ?>', 0);" >
		</body>
		</html>
<?php
		} else if (file_exists($hapmap_dir."/error.txt")) {
			// Load error.txt from hapmap folder.
			$errorFile = $dirFigureBase."error.txt";
			$error     = trim(file_get_contents($errorFile));
			$errorLineCount = substr_count($error,"<br>")+1;
?>
		<html>
		<body onload = "parent.parent.update_hapmap_label_color('<?php echo $key; ?>','#AA0000','#FFFFFF'); parent.parent.resize_project('<?php echo $key; ?>', '<?php echo $errorLineCount*18; ?>');" >
			<font color="red"><b>[Error]</b></font>
			<?php echo $error; ?>
		</body>
		</html>
<?php
		} else if (file_exists($hapmap_dir."/working.txt")) {
			// Load start time from 'working.txt'
			$startTimeStamp = file_get_contents($hapmap_dir."/working.txt");
			$startTime      = strtotime($startTimeStamp);
			$currentTime    = time();
			$intervalTime   = $currentTime - $startTime;
			if ($intervalTime > 60*60*3) { // likely error.
?>
			<BODY onload = "parent.parent.resize_hapmap('<?php echo $key; ?>', 100);" class="tab">
				<font color="red" size="2"><b>[Error]</b></font><?php echo " &nbsp; &nbsp; ".$clock; ?>
				<font size="2">Processing of hapmap data has taken longer than expected and might be stalled.<br>Contact the admin through the "System" tab with details and they will check on the job.</font>
			</BODY>
			</HTML>
<?php
			} else {
				// Load last line from "condensed_log.txt" file.
				$condensedLog      = explode("\n", trim(file_get_contents($hapmap_dir."/condensed_log.txt")));
				$condensedLogEntry = $condensedLog[count($condensedLog)-1];
?>
			<script type="text/javascript">
			var hapmap  = "<?php echo $hapmap; ?>";
			var key     = "<?php echo $key; ?>";
			var status  = "<?php echo $status; ?>";
			reload_page=function() {
<?php
				// Make a form to generate a form to POST information to pass along to page reloads, auto-triggered by form submit.
				echo "\tvar autoSubmitForm = document.createElement('form');\n";
				echo "\t\tautoSubmitForm.setAttribute('method','post');\n";
				echo "\t\tautoSubmitForm.setAttribute('action','hapmap.working_server.php');\n";
				echo "\tvar input2 = document.createElement('input');\n";
				echo "\t\tinput2.setAttribute('type','hidden');\n";
				echo "\t\tinput2.setAttribute('name','key');\n";
				echo "\t\tinput2.setAttribute('value',key);\n";
				echo "\t\tautoSubmitForm.appendChild(input2);\n";
				echo "\tvar input3 = document.createElement('input');\n";
				echo "\t\tinput3.setAttribute('type','hidden');\n";
				echo "\t\tinput3.setAttribute('name','hapmap');\n";
				echo "\t\tinput3.setAttribute('value',hapmap);\n";
				echo "\t\tautoSubmitForm.appendChild(input3);\n";
				echo "\tvar input4 = document.createElement('input');\n";
				echo "\t\tinput4.setAttribute('type','hidden');\n";
				echo "\t\tinput4.setAttribute('name','status');\n";
				echo "\t\tinput4.setAttribute('value',status);\n";
				echo "\t\tautoSubmitForm.appendChild(input4);\n";
				echo "\t\tdocument.body.appendChild(autoSubmitForm);\n";
				echo "\tautoSubmitForm.submit();\n";
?>
			}
			// Initiate recurrent call to reload_page function, which depends upon hapmap status.
			var internalIntervalID = window.setInterval(reload_page, 3000);
			</script>
			<HTML>
			<BODY onload = "parent.parent.resize_hapmap('<?PHP echo $key; ?>', 38);" class="tab">
				<font color="red"><b>[Processing selected data.]</b></font>
<?php
				echo $clock."<br>";
				echo "Haplotype analysis in process.";
				echo "\n";
?>
			</BODY>
			</HTML>
<?php
			}
		} else {
?>
		<html>
		<body onload = "parent.parent.update_hapmap_label_color('<?php echo $key; ?>','#00AA00','#FFFFFF'); parent.hapmap_UI_refresh_1_<?php echo str_replace('h_','',$key); ?>();">
		</body>
		</html>
<?php
		}
	}
?>
