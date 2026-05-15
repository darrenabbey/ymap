<?php
	error_reporting(E_ALL);
	ini_set('display_errors', 1);
	require_once '../../constants.php';
	require_once '../../POST_validation.php';
	require_once '../../sharedFunctions.php';
	if (!isset($_SERVER["HTTP_HOST"])) {
		//=============================
		// Script run from commandline.
		//-----------------------------
		$user     = $argv[1];
		$project  = $argv[2];
	} else {
		//===============================
		// Script run from web interface.
		//-------------------------------
		session_start();
	        // If the user is not logged on, redirect to login page.
	        if(!isset($_SESSION['logged_on'])){
			session_destroy();
	                header('Location: ../../');
	        }
		// pull strings from session.
		$user     = $_SESSION['user'];
		$project  = $_SESSION['project'];
	}
	$project_dir = "../../users/".$user."/projects/".$project."/";
?>
<script type="text/javascript">
	parent.update_interface();
</script>
<?php
	// Initialize log files.
	$logOutputName = $project_dir."/process_log.txt";
	$logOutput     = fopen($logOutputName, 'a');
	fwrite($logOutput, "#..............................................................................\n");
	fwrite($logOutput, "Running 'scripts_seqModules/scripts_WGseq/project.WGseq.update_1.php'.\n");
	fwrite($logOutput, "Variables passed :\n");
	fwrite($logOutput, "\tuser     = '".$user."'\n");
	fwrite($logOutput, "\tproject  = '".$project."'\n");
	fwrite($logOutput, "#============================================================================== 1\n");

	$condensedLogOutputName = $project_dir."/condensed_log.txt";
	$condensedLogOutput     = fopen($condensedLogOutputName, 'w');
	fwrite($condensedLogOutput, "Updating.\n");
	fclose($condensedLogOutput);

	$OutputName = $project_dir."/working.txt";
	$Output     = fopen($OutputName, 'w');
	fwrite($Output, date('Y-m-d H:i:s'));
	fclose($Output);

	queue_start($user,$project,"","","from: project.WGseq.update_1.php");

	// Delete pre-existing final output files.
	fwrite($logOutput, "Cleaning up old output files.\n");
	$projectFiles   = preg_grep('~\.(png|eps|bed|gff3)$~', scandir($project_dir));
	foreach ($projectFiles as $file) {
		fwrite($logOutput, "\t".$file."\n");
		unlink($project_dir.$file);
	}

	// Final install functions are in shell script.
	fwrite($logOutput, "Passing control to : 'scripts_seqModules/scripts_WGseq/project.WGseq.update_2.sh'\n");
	fwrite($logOutput, "\t\tCurrent directory = '".getcwd()."'\n" );
	$system_call_string = "bash project.WGseq.update_2.sh ".$user." ".$project." > /dev/null &";
	fwrite($logOutput, "\t\tSystem call string = '".$system_call_string."'\n");

	system($system_call_string);
	fclose($logOutput);
?>
