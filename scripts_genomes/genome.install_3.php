<?php
	error_reporting(E_ALL);
        require_once '../constants.php';
	require_once '../sharedFunctions.php';
	require_once '../POST_validation.php';
        ini_set('display_errors', 1);

	$calledBy = php_sapi_name();
	if ($calledBy === "cli") {
		//
		// Script run from commandline interface.
		//
		$user               = $argv[1];
		$key                = "g_0";
		$expression_regions = "";
		$genome             = $argv[2];
		$rDNA_chr           = $argv[3];
		$rDNA_start         = $argv[4];
		$rDNA_end           = $argv[5];
		$annotation_count   = $argv[6];
	} else {
		//
		// Script run from web interface.
		//
		session_start();

	        // If the user is not logged on, redirect to login page.
	        if(!isset($_SESSION['logged_on'])){
			session_destroy();
	                header('Location: ../');
	        }

		// Load user string from session.
		$user   = $_SESSION['user'];

		// Sanitize input strings.
		$key                = sanitize_POST("key");
		$expression_regions = sanitize_POST("expression_regions");

		$genome             = $_SESSION['genome_'.$key];
		$rDNA_chr           = $_SESSION['rDNA_chr_'.$key];
		$rDNA_start         = $_SESSION['rDNA_start_'.$key];
		$rDNA_end           = $_SESSION['rDNA_end_'.$key];
		$annotation_count   = $_SESSION['annotation_count_'.$key];
	}
	$genome_dir = "../users/".$user."/genomes/".$genome;


	if (!($calledBy === "cli")) {
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
		html, body {
			margin:         0px;
			border:         0;
			overflow:       hidden;
		}
	</style>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<title>Install genome into pipeline.</title>
</HEAD>
<?php
	}

	$annotation_chrs       = array();
	$annotation_shapes     = array();
	$annotation_starts     = array();
	$annotation_ends       = array();
	$annotation_names      = array();
	$annotation_fillColors = array();
	$annotation_edgeColors = array();
	$annotation_sizes      = array();

// Open 'process_log.txt' file.
	$condensedLogOutputName = $genome_dir."/condensed_log.txt";
	$logOutputName = $genome_dir."/process_log.txt";
	$logOutput     = fopen($logOutputName, 'a');
	fwrite($logOutput, "Running 'scripts_genomes/genome.install_3.php'.\n");

// process POST data.
	fwrite($logOutput, "\tProcessing POST data containing annotation specifications.\n");
	if ($annotation_count > 0) {
		if ($calledBy === "cli") {
			$annotation_chr        = $argv[7];
			$annotation_shape      = $argv[8];
			$annotation_start      = $argv[9];
			$annotation_end        = $argv[10];
			$annotation_name       = $argv[11];
			$annotation_fillColor  = $argv[12];
			$annotation_edgeColor  = $argv[13];
			$annotation_size       = $argv[14];
			$annotation_chrs       = explode(",", $annotation_chr      );
			$annotation_shapes     = explode(",", $annotation_shape    );
			$annotation_starts     = explode(",", $annotation_start    );
			$annotation_ends       = explode(",", $annotation_end      );
			$annotation_names      = explode(",", $annotation_name     );
			$annotation_fillColors = explode(",", $annotation_fillColor);
			$annotation_edgeColors = explode(",", $annotation_edgeColor);
			$annotation_sizes      = explode(",", $annotation_size     );
		} else {
			for ($annotation_key=0; $annotation_key<$annotation_count; $annotation_key += 1) {
				$annotation_chr       = sanitize_POST("annotation_chr_".$annotation_key);
		                $annotation_shape     = sanitize_POST("annotation_shape_".$annotation_key);
		                $annotation_start     = sanitizeInt_POST("annotation_start_".$annotation_key);
		                $annotation_end       = sanitizeInt_POST("annotation_end_".$annotation_key);
		                $annotation_name      = sanitize_POST("annotation_name_".$annotation_key);
		                $annotation_fillColor = sanitize_POST("annotation_fillColor_".$annotation_key);
		                $annotation_edgeColor = sanitize_POST("annotation_edgeColor_".$annotation_key);
		                $annotation_size      = sanitizeInt_POST("annotation_size_".$annotation_key);
				$annotation_chrs[$annotation_key]       = $annotation_chr;
				$annotation_shapes[$annotation_key]     = $annotation_shape;
				$annotation_starts[$annotation_key]     = $annotation_start;
				$annotation_ends[$annotation_key]       = $annotation_end;
				$annotation_names[$annotation_key]      = $annotation_name;
				$annotation_fillColors[$annotation_key] = $annotation_fillColor;
				$annotation_edgeColors[$annotation_key] = $annotation_edgeColor;
				$annotation_sizes[$annotation_key]      = $annotation_size;
			}
		}
	}

	// Generate 'annotations.txt' :
	fwrite($logOutput, "\tGenerating 'annotations.txt' file.\n");
	$outputName       = $genome_dir."/annotations.txt";
	if (file_exists($outputName)) {
		$fileContents = file_get_contents($outputName);
		unlink($outputName);
		$output       = fopen($outputName, 'w');
		fwrite($output, $fileContents);
	} else {
		$output       = fopen($outputName, 'w');
		fwrite($output, "# Chr\tType\tstart(bp)\tend(bp)\tName\tFillColor\tEdgeColor\tSize\n");
		if ($rDNA_chr != "null") {
			$rDNA_chrs   = explode(",", $rDNA_chr  );
			$rDNA_starts = explode(",", $rDNA_start);
			$rDNA_ends   = explode(",", $rDNA_end  );
			foreach ($rDNA_chrs as $rDNA_key => $rDNA_chr) {
				fwrite($output, $rDNA_chr."\tdot\t".$rDNA_starts[$rDNA_key]."\t".$rDNA_ends[$rDNA_key]."\trDNA\tb\tb\t5\n");
			}
		}
		for ($annotation=0; $annotation<$annotation_count; $annotation += 1) {
			fwrite($output, $annotation_chrs[$annotation]."\t".$annotation_shapes[$annotation]."\t".$annotation_starts[$annotation]."\t".$annotation_ends[$annotation]."\t".$annotation_names[$annotation]."\t".$annotation_fillColors[$annotation]."\t".$annotation_edgeColors[$annotation]."\t".$annotation_sizes[$annotation]."\n");
		}
	}
	fclose($output);

// Debugging output of all variables.
//	print_r($GLOBALS);

	if ($calledBy === "cli") {
		fwrite($logOutput, "\t'scripts_genomes/genome_install_3.php' has completed.\n");
		fwrite($logOutput, "Skipping 'scripts_genomes/genome.install_4.php'.\n");
		make_salt($user,"",$genome,"");
		queue_init($user,"",$genome,"","from: genome.install_3.php");
	} else {
		if ($expression_regions == "on") {
			//
			// Chromosome features file available, so request user input about file format.
			//
			echo "<BODY>\n";
			echo "    <font color='red' size='2'>Enter ORF description file details:</font>\n";
			//echo "    <form name='processing_form' id='processing_form' action='genome.install_4.php' method='post'>\n";
			//echo "    <font size='2'>\n";
			//echo "    Number of header lines  = <input type='text' name='headerLineCount' value='0' size='6'><br>\n";
			//echo "    Chromosome ID column    = <input type='text' name='col_chrID'       value='0' size='6'><br>\n";
			//echo "    Start coordinate column = <input type='text' name='col_startBP'     value='0' size='6'><br>\n";
			//echo "    End coordinate column   = <input type='text' name='col_endBP'       value='0' size='6'><br>\n";
			//echo "    </font><br>\n";
			//echo "    <input type='submit' id='form_submit' name='form_submit' value='Save genome feature description details...'>\n";
			//echo "    <input type='hidden' id='key' name='key' value='".$key."'>\n";
			//echo "    </form>\n";
			echo "</BODY>\n";
			echo "</HTML>";
			fwrite($logOutput, "\t'scripts_genomes/genome_install_3.php' has completed.\n");
			make_salt($user,"",$genome,"");
			queue_init($user,"",$genome,"","Started from: genome.install_3.php");
		} else {
			//
			// Chromosome features file is not available, so go directly to "genome.install_5.php".
			//
			echo "<BODY onload = \"parent.parent.resize_genome('".$key."', 100);\">\n";
			//  document.processing_form.submit();\">\n";
			//echo "    <form name='processing_form' id='processing_form' action='genome.install_5.php' method='post'>\n";
			//echo "    <input type='submit' id='form_submit' name='form_submit' value='Continue to processing...' style='visibility:hidden' disabled>\n";
			//echo "    <input type='hidden' id='key'      name='key'      value='".$key."'>\n";
			//echo "    <input type='hidden' id='fileName' name='fileName' value=''>\n";
			//echo "    </form>\n";
			echo "    <font color='red'>[Installation in process.]</font><br>\n";
			echo "</BODY>\n";
			echo "</HTML>";
			fwrite($logOutput, "\t'scripts_genomes/genome_install_3.php' has completed.\n");
			fwrite($logOutput, "Skipping 'scripts_genomes/genome.install_4.php'.\n");
			make_salt($user,"",$genome,"");
			queue_init($user,"",$genome,"","Started from: genome.install_3.php");
		}
	}
	// Generate 'bulk.txt' file to let pipeline know genome has been finalized and ready for processing.
	$outputName      = "../users/".$user."/genomes/".$genome."/bulk.txt";
	$output          = fopen($outputName, 'w');
	$startTimeString = date("Y-m-d H:i:s");
	fwrite($output, $startTimeString);
	fclose($output);
	chmod($outputName,0774);
	fwrite($logOutput, "\tGenerated 'bulk.txt' file.\n");
	fclose($logOutput);

	// Generate 'working2.txt' to tell main page that genome installation is in process.
	$outputName      = $genome_dir."/working2.txt";
	$output          = fopen($outputName, 'w');
	$startTimeString = date("Y-m-d H:i:s");
	fwrite($output, $startTimeString);
	fclose($output);


	$condensedLogOutput = fopen($condensedLogOutputName, 'w');
	fwrite($condensedLogOutput, "Genome added to processing queue.\n");
	fclose($condensedLogOutput);
?>
