<?php
	session_start();
	$user = $_SESSION['user'];

	require_once '../constants.php';
	error_reporting(E_ALL | E_STRICT);

	$project     = filter_input(INPUT_POST, "project",    FILTER_SANITIZE_STRING);
	$dataFormat  = filter_input(INPUT_POST, "dataFormat", FILTER_SANITIZE_STRING);
	$key         = filter_input(INPUT_POST, "key",        FILTER_SANITIZE_STRING);


	// Determine target_dir from safely passed data.
	$target_dir        = '../../users/'+user+'/projects/'+project+'/';

	// Determine conclusion_script from safely passed data.
	$conclusion_script = "";
	switch ($dataFormat) {
		case "SnpSghArray":
			$conclusion_script = "scripts_SnpCghArray/project.SnpCgh.install.php";
			break;
		case "WGseq_single":
			$conclusion_script = "scripts_seqModules/scripts_WGseq/project.single_WGseq.install_1.php";
			break;
		case "WGseq_paired":
			$conclusion_script = "scripts_seqModules/scripts_WGseq/project.paired_WGseq.install_1.php";
			break;
		case "ddRADseq_single":
			$conclusion_script = "scripts_seqModules/scripts_ddRADseq/project.single_ddRADseq.install_1.php";
			break;
		case "ddRADseq_paired":
			$conclusion_script = "scripts_seqModules/scripts_ddRADseq/project.paired_ddRADseq.install_1.php";
			break;
		case "RNAseq_single":
			$conclusion_script = "scripts_seqModules/scripts_RNAseq/project.single_RNAseq.install_1.php";
			break;
		case "RNAseq_paired":
			$conclusion_script = "scripts_seqModules/scripts_RNAseq/project.paired_RNAseq.install_1.php";
			break;
		case "IonExpressSeq_single":
			$conclusion_script = "scripts_seqModules/scripts_IonExpressSeq/project.single_IonExpressSeq.install_1.php";
			break;
		case "IonExpressSeq_paired":
			$conclusion_script = "scripts_seqModules/scripts_IonExpressSeq/project.paired_IonExpressSeq.install_1.php";
			break;
	}

	//============================================================================
	// HTML5Uploader ::  Adam Filkor : http://filkor.org
	// Licensed under the MIT license : http://www.opensource.org/licenses/MIT
	//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	// non-MySQL version.
	//----------------------------------------------------------------------------
	require('UploadHandler.php');
	$upload_handler = new UploadHandler($target_dir, $conclusion_script, $key);
?>
