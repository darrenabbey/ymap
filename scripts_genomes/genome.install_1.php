<?php
	session_start();
        $user     = $_SESSION['user'];
        $fileName = $_SESSION['fileName'];
        $genome   = $_SESSION['genome'];
        $key      = $_SESSION['key'];

// current directory
	require_once '../constants.php';
	include_once 'process_input_files.genome.php';

// Initialize log files.
	$logOutputName = "../users/".$user."/genomes/".$genome."/process_log.txt";
	$logOutput     = fopen($logOutputName, 'w');
	fwrite($logOutput, "*========================================================================*\n");
	fwrite($logOutput, "| Log file initalized in 'scripts_genomes/genome.install_1.php'.         |\n");
	fwrite($logOutput, "*------------------------------------------------------------------------*\n");
	fwrite($logOutput, "Variables passed :\n");
	fwrite($logOutput, "\tuser     = '".$user."'\n");
	fwrite($logOutput, "\tfileName = '".$fileName."'\n");
	fwrite($logOutput, "\tgenome   = '".$genome."'\n");
	fwrite($logOutput, "\tkey      = '".$key."'\n");
	fwrite($logOutput, "#----------------------------------------------------------------------- 1\n");

	$condensedLogOutputName = "../users/".$user."/genomes/".$genome."/condensed_log.txt";
	$condensedLogOutput     = fopen($condensedLogOutputName, 'w');
	fwrite($condensedLogOutput, "Initializing.\n");
	fclose($condensedLogOutput);
	chmod($condensedLogOutputName,0744);

	// Generate 'working.txt' file to let pipeline know processing is started.
	$outputName      = "../users/".$user."/genomes/".$genome."/working.txt";
	$output          = fopen($outputName, 'w');
	$startTimeString = date("Y-m-d H:i:s");
	fwrite($output, $startTimeString);
	fclose($output);
	chmod($outputName,0755);
	fwrite($logOutput, "\tGenerated 'working.txt' file.\n");

	// Generate 'reference.txt' file containing:
	//      one line; file name of reference FASTA file.
	$fasta_name = $genome.".fasta";
	fwrite($logOutput, "\tGenerating 'reference.txt' file.\n");
	$outputName       = "../users/".$user."/genomes/".$genome."/reference.txt";
	$output           = fopen($outputName, 'w');
	if (file_exists($outputName)) {
		$fileContents = file_get_contents($outputName);
		unlink($outputName);
		$output       = fopen($outputName, 'w');
		fwrite($output, $fasta_name);
	} else {
		$output       = fopen($outputName, 'w');
		fwrite($output, $fasta_name);
	}
	fclose($output);
	unset($outputName);
	unset($output);

	// Generate 'name.txt' file containing:
	//	one line; name of genome.
	fwrite($logOutput, "\tGenerating 'name.txt' file.\n");
	$outputName       = "../users/".$user."/genomes/".$genome."/name.txt";
	$output           = fopen($outputName, 'w');
	if (file_exists($outputName)) {
		$fileContents = file_get_contents($outputName);
		unlink($outputName);
		$output       = fopen($outputName, 'w');
		fwrite($output, str_replace("_"," ",$genome));
	} else {
		$output       = fopen($outputName, 'w');
		fwrite($output, str_replace("_"," ",$genome));
	}
	fclose($output);
	unset($outputName);
	unset($output);

	// Generate 'upload_size.txt' file to contain the size of the uploaded file (irrespective of format) for display in "Manage Datasets" tab.
	$genomePath      = "../users/".$user."/genomes/".$genome."/";
	$outputName      = $genomePath."upload_size_1.txt";
	$output          = fopen($outputName, 'w');
	$fileSizeString  = filesize($genomePath.$fileName);
	fwrite($output, $fileSizeString);
	fclose($output);
	chmod($outputName,0755);
	fwrite($logOutput, "\tGenerated 'upload_size_1.txt' file.\n");

	// Rename uploaded file to lower-case, accounting for file name change by uploader script.
	$name  = str_replace("\\", ",", $fileName);
	$name1 = str_replace(".","-",pathinfo($name, PATHINFO_FILENAME)).".".pathinfo($name, PATHINFO_EXTENSION);
	$name2 = strtolower($name1);
	rename(getcwd()."/".$genomePath.$name1,getcwd()."/".$genomePath.$name2);

	// Process uploaded file.
	$name        = $name2;
	$ext         = strtolower(pathinfo($name, PATHINFO_EXTENSION));
	$filename    = strtolower(pathinfo($name, PATHINFO_FILENAME));
	fwrite($logOutput, "\tKey         : ".$key."\n");
	fwrite($logOutput, "\tDatafile    : '".$name."'.\n");
	fwrite($logOutput, "\tFilename    : '".$filename."'.\n");
	fwrite($logOutput, "\tExtension   : '".$ext."'.\n");
	fwrite($logOutput, "\tScript_path : '".getcwd()."'.\n");
	fwrite($logOutput, "\tPath        : '".$genomePath."'.\n");

	// Process the uploaded file into format usable by later steps.
	$condensedLogOutput = fopen($condensedLogOutputName, 'w');
	fwrite($condensedLogOutput, "Processing uploaded file.\n");

	fwrite($logOutput, "Variables passing to function:\n");
	fwrite($logOutput, "\text                : ".$ext."\n");
	fwrite($logOutput, "\tname               : ".$name."\n");
	fwrite($logOutput, "\tgenomePath         : ".$genomePath."\n");
	fwrite($logOutput, "\tkey                : ".$key."\n");
	fwrite($logOutput, "\tuser               : ".$user."\n");
	fwrite($logOutput, "\tgenome             : ".$genome."\n");
	fwrite($logOutput, "\toutput             : ".$output."\n");
	fwrite($logOutput, "\tcondensedLogOutput : ".$coundensedLogOutput."\n");
	fwrite($logOutput, "\tlogOutput          : ".$logOutput."\n");
	fwrite($logOutput, "\tfasta_name         : ".$fasta_name."\n");
	process_input_files_genome($ext,$name,$genomePath,$key,$user,$genome,$output, $condensedLogOutput,$logOutput, $fasta_name);
	$fileName = $fasta_name;
	$file_path  = "../users/".$user."/genomes/".$genome."/".$fileName;
	fwrite($logOutput, "\n\tFile name & path: ".$file_path."\n");
	fclose($condensedLogOutput);

	// Process FASTA file for chromosome count, names, and lengths.
	fwrite($logOutput, "\n\tReading chromosome count, names, and lengths from FASTA.\n");
	$chr_count   = 0;
	$chr_names   = array();
	$chr_lengths = array();
	$chr_length = 0;
	$fileHandle = fopen($file_path, "r") or die("Couldn't open fasta file after first reformat");
	$firstLine = true;
	if ($fileHandle) {
		while (!feof($fileHandle)) {
			$buffer = fgets($fileHandle, 4096);
			if ($buffer[0] == '>') {
				if ($chr_length != 0) {
					fwrite($logOutput, "\t" . 'finished processing chromosome "' . $chr_name . '" length: ' . $chr_length . PHP_EOL);
				}
				// chromosome name is the header string (starting with ">"), after trimming trailing whitespace characters.
				$line_parts = explode(" ",$buffer);
				$chr_name   = str_replace(array("\r","\n"),"",$line_parts[0]);
				$chr_name   = substr($chr_name,1,strlen($chr_name)-1);
				array_push($chr_names, $chr_name);
				$chr_count  += 1;
				// pushing chromosome length only if it's not the first line to avoid pushing 0
				if ($firstLine == false) {
					// pushing latest chromosome length and reseting count
					array_push($chr_lengths, $chr_length);
					$chr_length = 0;
				}
				else {
					$firstLine = false;
				}
			}
			else {
				// adding char count without line end or whitespaces at start
				$chr_length += strlen(trim($buffer));
			}
		}
		// adding last chr_length, pushing zero if it doesn't exist
		if ($chr_length > 0)
		{
			array_push($chr_lengths, $chr_length);
			fwrite($logOutput, "\t" . 'finished processing chromosome "' . $chr_name . '" length: ' . $chr_length . PHP_EOL);
		}
		fclose($fileHandle);
	}
	fwrite($logOutput, "\tnum chrs    : '$chr_count'.\n");

	fwrite($logOutput, "\tGenome uploaded.\n");
	$condensedLogOutput = fopen($condensedLogOutputName, 'w');
	fwrite($condensedLogOutput, "Genome uploaded.\n");
	fclose($condensedLogOutput);

	// Store variables of interest into $_SESSION.
	fwrite($logOutput, "\tStoring PHP session variables.\n");
	$_SESSION['genome_'.$key]      = $genome;
	$_SESSION['fileName_'.$key]    = $fileName;
	$_SESSION['chr_count_'.$key]   = $chr_count;

// Information saved into file format not used by other pipeline modules. Why?
	// saving all chr details in files to avoid overloading $_SESSION
	file_put_contents("../users/".$user."/genomes/".$genome."/chr_names.json",json_encode($chr_names));
	file_put_contents("../users/".$user."/genomes/".$genome."/chr_lengths.json",json_encode($chr_lengths));

//============================================================================================================
// The following section should be loaded into iframe ID="Hidden_InstallNewGenome_Frame" defined in index.php
//------------------------------------------------------------------------------------------------------------
// dragon
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
<script>
	// will return the number of checked draw check boxes
	function getCheckedNumber(checkBoxes) {
		// getting the checkboxes
		var i = 0; // loop variable
		var count = 0; // will count the number of checked checkboxes
		for (i = 0; i < checkBoxes.length; i++) {
			if (checkBoxes[i].checked) {
				count += 1;
			}
		}
		return count;
	}
	function chromosomeCheck() {
		// getting the checkboxes
		var MAX_CHROM_SELECTION = <?php echo $MAX_CHROM_SELECTION; ?>; // the limit of chromosomes that can be displayed
		var checkBoxes = document.getElementsByClassName("draw");
		var count = getCheckedNumber(checkBoxes);
		var i = 0; // loop variable
		// disable all unchecked boxes if we have reached limit
		if (count == MAX_CHROM_SELECTION) {
			for (i = 0; i < checkBoxes.length; i++) {
				if (!checkBoxes[i].checked) {
					checkBoxes[i].disabled = true;
				}
			}
		} else { // enable checkboxes
			for (var i = 0; i < checkBoxes.length; i++) {
				checkBoxes[i].disabled = false;
			}
		}
	}
</script>
<BODY onload = "parent.parent.resize_genome('<?php echo $key; ?>', 0); <?php
	$sizeFile_1   = "../users/".$user."/genomes/".$genome."/upload_size_1.txt";
	$handle       = fopen($sizeFile_1,'r');
	$sizeString_1 = trim(fgets($handle));
	fclose($handle);
	if ($sizeString_1 !== "") {
		echo "parent.parent.update_genome_file_size('".$key."','".$sizeString_1."');";
	}
?> top.frames.location.href = top.frames.location.href;">
</BODY>
</HTML>
<?php
	fwrite($logOutput, "\t'scripts_genomes/genome.install_1.php' has completed.\n");
	fclose($logOutput);
?>
