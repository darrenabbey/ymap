<?php
	session_start();
	error_reporting(E_ALL);
	require_once '../constants.php';
	require_once '../POST_validation.php';
	ini_set('display_errors', 1);

	// If the user is not logged on, redirect to login page.
	if(!isset($_SESSION['logged_on'])){
		session_destroy();
		header('Location: ../');
	}

	// pull strings from session.
	$user     = $_SESSION['user'];
	$fileName = $_SESSION['fileName'];
	$project  = $_SESSION['project'];
	$key      = $_SESSION['key'];

?>
<script type="text/javascript">
	parent.update_interface();
</script>
<?php

	$project_dir = "../users/".$user."/projects/".$project;

	include_once '../process_input_files.php';
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD>
	<style type="text/css">
		body {font-family: arial;}
		.upload {
			width:          675px;      // 675px;
			border:         0;
			height:         40px;   // 40px;
			vertical-align: middle;
			align:          left;
			margin:         0px;
			overflow:       hidden;
		}
		.tab {
			margin:        40px;
		}
		html, body {
			margin:         0px;
			border:         0;
			overflow:       hidden;
		}
	</style>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<title>Install project into pipeline.</title>
</HEAD>
<?php
// Initialize 'process_log.txt' file.
	$outputLogName   = $project_dir."/process_log.txt";
	$outputLog       = fopen($outputLogName, 'a');
	fwrite($outputLog, "==================================================================================\n");
	fwrite($outputLog, "| Processing via: project.SnpCgh.update.php.\n");

// Initialize 'condensed_log.txt' file.
	$condensedLogOutputName = $project_dir."/condensed_log.txt";
	$condensedLogOutput     = fopen($condensedLogOutputName, 'w');
	fwrite($condensedLogOutput, "Updating figures.\n");
	fclose($condensedLogOutput);

// Generate 'working.txt' file to let pipeline know processing is started.
	$outputName      = $project_dir."/working.txt";
	$output          = fopen($outputName, 'w');
	$startTimeString = date("Y-m-d H:i:s");
	fwrite($output, $startTimeString);
	fclose($output);
	chmod($outputName,0644);
	fwrite($outputLog, "| working.txt generated.\n");

// Delete pre-existing final output files.
	fwrite($outputLog, "| cleaninup up old output files.\n");
	$projectFiles   = preg_grep('~\.(png|eps|bed|gff3)$~', scandir("../users/".$user."/projects/".$project."/"));
	foreach ($projectFiles as $file) {
		fwrite($outputLog, "\t".$file."\n");
		unlink("../users/".$user."/projects/".$project."/".$file);
	}

// Call Matlab to process SnpCgh data file into final figure.
	$designDefinition   = "design1";
	$inputFile          = $project_dir."/".$fileName;
	$headerRows         = 46;
	$colNames           = 1;
	$colCh1             = 4;
	$colCh2             = 5;
	$colRatio           = 6;
	$colLog2ratio       = 7;
	$phasingData        = "cal_paper";
	$ploidyFileContents = file_get_contents($project_dir."/ploidy.txt");
	$ploidyStrings      = explode("\n", $ploidyFileContents);
	$ploidyEstimate     = $ploidyStrings[0];
	$ploidyBase         = $ploidyStrings[1];

	$imageFormat        = "png";
	$projectName        = $project;
	$workingDir         = $project_dir."/";
	$show_MRS           = file_get_contents($project_dir."/showAnnotations.txt");

	$outputName         = $project_dir."/processing.m";
	$dirBase            = $project_dir."/";
	$output             = fopen($outputName, 'w');
	$outputString       =  "function [] = processing()\n";
	$outputString      .= "\tdiary('matlab.process_log.txt');\n";
	$outputString      .= "\tcd ../../../../scripts_SnpCghArray;\n";

	// Log status to process_log.txt file in project directory.
	$outputString      .= "\tnew_fid = fopen('".$project_dir."/process_log.txt','a');\n";
	$outputString      .= "\tfprintf(new_fid,'Starting \"process_main.m\".\\n');\n";

	$outputString      .= "\tprocess_main('".$designDefinition."','".$inputFile."','".$headerRows."','".$colNames."','".$colCh1."','".$colCh2."','".$colRatio."','".$colLog2ratio."','";
	$outputString      .=    $phasingData."','".$ploidyEstimate."','".$ploidyBase."','".$imageFormat."','".$projectName."','".$workingDir."','".$show_MRS."');\n";

	// Log status to process_log.txt file in project directory.
	$outputString      .= "\tfprintf(new_fid,'Starting \"process_main_CNV_only.m\".\\n');\n";

	$outputString      .= "\tprocess_main_CNV_only('".$designDefinition."','".$inputFile."','".$headerRows."','".$colNames."','".$colCh1."','".$colCh2."','".$colRatio."','";
	$outputString      .=    $colLog2ratio."','".$phasingData."','".$ploidyEstimate."','".$ploidyBase."','".$imageFormat."','".$projectName."','".$workingDir."','".$show_MRS."');\n";

	// Log status to process_log.txt file in project directory.
	$outputString      .= "\tfprintf(new_fid,'Starting \"process_main_SNP_only.m\".\\n');\n";

	$outputString      .= "\tprocess_main_SNP_only('".$designDefinition."','".$inputFile."','".$headerRows."','".$colNames."','".$colCh1."','".$colCh2."','".$colRatio."','";
	$outputString      .=    $colLog2ratio."','".$phasingData."','".$ploidyEstimate."','".$ploidyBase."','".$imageFormat."','".$projectName."','".$workingDir."','".$show_MRS."');\n";

	// Log status to process_log.txt file in project directory.
	$outputString      .= "\tfclose(new_fid);\n";

	$outputString      .= "end";
	fwrite($output, $outputString);
	fclose($output);
	chmod($outputName,0644);
	fwrite($outputLog, "| Matlab script generated: processing.m.\n");
	fwrite($outputLog, $outputString."\n");

	// Call matlab
	$system_call_string_2 = '. ../local_installed_programs.sh && $matlab_exec -nosplash -nodesktop -r \'run '.$project_dir.'/processing.m\' > /dev/null &';
	fwrite($outputLog, "|\t\"".$system_call_string_2."\"\n\n");
	fclose($outputLog);
	system($system_call_string_2);
?>
<BODY>
<font size="2" color="red">Upload complete; processing...</font><br>
<script type="text/javascript">
	var user    = "<?php echo $user;    ?>";
	var project = "<?php echo $project; ?>";
	var key     = "<?php echo $key;     ?>";
	var status  = "0";
	// construct and submit form to move on to "../project.working_server.php";
	var autoSubmitForm = document.createElement("form");
		autoSubmitForm.setAttribute("method","post");
		autoSubmitForm.setAttribute("action","../project.working_server.php");
	var input2 = document.createElement("input");
		input2.setAttribute("type","hidden");
		input2.setAttribute("name","key");
		input2.setAttribute("value",key);
		autoSubmitForm.appendChild(input2);
	var input2 = document.createElement("input");
		input2.setAttribute("type","hidden");
		input2.setAttribute("name","user");
		input2.setAttribute("value",user);
		autoSubmitForm.appendChild(input2);
	var input3 = document.createElement("input");
		input3.setAttribute("type","hidden");
		input3.setAttribute("name","project");
		input3.setAttribute("value",project);
		autoSubmitForm.appendChild(input3);
	var input4 = document.createElement("input");
		input4.setAttribute("type","hidden");
		input4.setAttribute("name","status");
		input4.setAttribute("value",status);
	document.body.appendChild(autoSubmitForm);
	autoSubmitForm.submit();
</script>
</BODY>
</HTML>
