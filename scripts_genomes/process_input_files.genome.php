<?php
function process_input_files_genome($ext,$name,$genomePath,$key,$user,$genome,$output, $condensedLogOutput,$logOutput, $output_fileName) {
require_once '../constants.php';
require_once '../sharedFunctions.php';

//$ext				= "zip";
//$name				= "c_albicans_sc5314_version_a21-s02-m09-r10_chromosomes-fasta.zip";
//$genomePath			= "../users/darren2/genomes/test/";
//$key				= "g_0";
//$user				= "darren2";
//$genome			= "test";
//$output			= "Resource id #13";
//$fasta_name			= "test.fasta";
//$logOutputName		= "../users/".$user."/genomes/".$genome."/process_log.txt";
//$logOutput			= fopen($logOutputName, 'w');
//$condensedLogOutputName	= "../users/".$user."/genomes/".$genome."/condensed_log.txt";
//$condensedLogOutput		= fopen($condensedLogOutputName, 'w');


fwrite($logOutput, "*========================================================================*\n");
fwrite($logOutput, "| 'scripts_genomes/process_input_files.genome.php' has initiated.        |\n");
fwrite($logOutput, "*------------------------------------------------------------------------*\n");
fwrite($logOutput, "Before archive decompression.\n");
fwrite($logOutput, "\text         = ".$ext."\n");
fwrite($logOutput, "\tname        = ".$name."\n");
fwrite($logOutput, "\tgenomePath  = ".$genomePath."\n");

// Deal with compressed archives.
$currentDir = getcwd(); // get script's path.
if (strcmp($ext,"zip") == 0) {
	fwrite($condensedLogOutput, "Decompressing ZIP file : ".$name."\n");
	fwrite($logOutput, "This is a ZIP archive of : \n");

	// figure out first/only filename contained in zip archive.
	$null               = shell_exec("unzip -l ".$genomePath.$name." > ".$genomePath."zipTemp.txt");   // generate txt file containing archive contents.
	$zipTempLines       = file($genomePath."zipTemp.txt");
	$zipTempArchiveLine = trim($zipTempLines[3]);
	$columns            = preg_split('/\s+/', $zipTempArchiveLine);
	$oldName            = $columns[3];
	$fileName_parts     = preg_split('/[.]/', $oldName);
	fwrite($logOutput,"\t'".$oldName."'.\n");
	fwrite($logOutput,"\tThe number of fileName parts = ".count($fileName_parts)."\n");

	// What is the file count in the archive?
	$fileCount          = shell_exec("zipinfo ".$genomePath.$name." |grep Zip|grep -oE '[^ ]+$'");
	$fileCount          = trim($fileCount);
	fwrite($logOutput,"\tFiles in zip archive = ".$fileCount."\n");

	// Extract archive.
	chdir($genomePath);                    // move to genome directory.
	$null = shell_exec("unzip -j ".$name); // unzip archive.
	chdir($currentDir);                    // move back to script's path.

	// If more than one file in archive, delete all but first.
	for ($i = 4; $i < $fileCount+2; $i++) {
		$zipTempArchiveLine = trim($zipTempLines[$i]);
		$columns            = preg_split('/\s+/', $zipTempArchiveLine);
		$fileName           = $columns[3];
		unlink($genomePath.$fileName);
	}

	// Delete original archive.
	unlink($genomePath.$name);

	// Sanitize name of first file from archive: Replace all "." in $name with "-" except the final one.
	// Will convert a file with no type to one with an incompatible type. ex "name" to "name.name".
	$fragments  = explode(".",$oldName);
	$count      = sizeof($fragments);
	$name_first = $fragments[0];
	if ($count > 2) {
		for ($i = 1; $i < $count-1; $i++) {
			$name_first .= "-".$fragments[$i];
		}
	}
	$name_first .= ".".$fragments[$count-1];
	$ext_first   = $fragments[$count-1];
	rename($genomePath.$oldName,$genomePath.$name_first);

	// rename decompressed file.
	if (($ext_first == "fna") || ($ext_first == "ffn") || ($ext_first == "faa") || ($ext_first == "frn") || ($ext_first == "fa")) {
		// if alternate extension for fasta is found, rename to fasta.
		$rename_target = "datafile_".$key.".fasta";
	} else {
		$rename_target = "datafile_".$key.".".$ext_first;
	}
	rename($genomePath.$name_first,$genomePath.$rename_target);

	fwrite($logOutput, "\tcurrentDir    = '".$currentDir."'\n");
	fwrite($logOutput, "\tgenomePath    = '".$genomePath."'\n");
	fwrite($logOutput, "\toldName       = '".$oldName."'\n");
	fwrite($logOutput, "\tname_first    = '".$name_first."'\n");
	fwrite($logOutput, "\trename_target = '".$rename_target."'\n");

	// Hand off decompressed ZIP file to next section.
	$ext_new  = $ext_first;
	$name_new = $rename_target;

	// Is decompressed file a FASTA?
	if ($ext_new == "fasta") {
		// FASTA file was found.
	} else {
		// FASTA file was not found.
		unlink($genomePath.$name_first);
		fwrite($logOutput, "\tFASTA file not found in ZIP!!!\n");
		$ext_new  = "none1";
		$name_new = "";
	}
} elseif (strcmp($ext,"gz") == 0) {
	fwrite($condensedLogOutput, "Decompressing GZ file : ".$name."\n");
	fwrite($logOutput, "This is a GZ archive of : ".$name."\n");

	// What is the file count in the archive?
	$fileCount          = shell_exec("tar -tzf ".$genomePath.$name." | wc -l");

	// Extract archive.
	if ($fileCount == 0) {
		// Is not a tar.gz, so decompress with gzip.
		chdir($genomePath);                   // move to genome directory.
		$null = shell_exec("gzip -d ".$name);  // decompress archive.
		chdir($currentDir);                    // move back to script's path.

		// Figure out filename contained in gz archive.
		// If one file, then filename is same as archive, without gz.
		$name_new   = str_replace(".gz","", $name);

		// Standardize fasta file extensions to ".fasta"
		$name_final = str_replace("-fasta",".fasta",$name_new);
		$name_final = str_replace("-FASTA",".fasta",$name_final);
		$name_final = str_replace("-fna",  ".fasta",$name_final);
		$name_final = str_replace("-FNA",  ".fasta",$name_final);
		$name_final = str_replace("-ffn",  ".fasta",$name_final);
		$name_final = str_replace("-FFN",  ".fasta",$name_final);
		$name_final = str_replace("-faa",  ".fasta",$name_final);
		$name_final = str_replace("-FAA",  ".fasta",$name_final);
		$name_final = str_replace("-frn",  ".fasta",$name_final);
		$name_final = str_replace("-FRN",  ".fasta",$name_final);
		$name_final = str_replace("-fa",   ".fasta",$name_final);
		$name_final = str_replace("-FA",   ".fasta",$name_final);

		$name_first = $name_new;
		$name_ext   = pathinfo($name_final, PATHINFO_EXTENSION);
	} else {
		fwrite($logOutput,"\tFiles in tar.gz archive = ".$fileCount.".\n");

		// multiple files found in archive, so is a tar.gz and needs different handling.
		chdir($genomePath);                   // move to genome directory.
		$file_list = shell_exec("tar xvzf ".$name);
		chdir($currentDir);                    // move back to script's path.

		// Figure out individual filenames from tar.gz
		$files = explode("\n",$file_list);

		// If more than one file in archive, delete all but first.
		$fileCount = size_of($files);
		if ($fileCount > 1) {
			for ($i = 1; $i < $fileCount; $i++) {
				$fileName = $files[$i];
				unlink($genomePath.$fileName);
			}
		}

		// Delete original archive.
		unlink($genomePath.$name);

		// Sanitize name of first file from archive: Replace all "." in $name with "-" except the final one.
		// Will convert a file with no type to one with an incompatible type. ex "name" to "name.name".
		$fragments  = explode(".",$files[0]);
		$count      = sizeof($fragments);
		$name_first = $fragments[0];
		if ($count > 2) {
			for ($i = 1; $i < $count-1; $i++) {
				$name_first .= "-".$fragments[$i];
			}
		}
		$name_first .= ".".$fragments[$count-1];
		$name_ext    = $fragments[$count-1];
		rename($genomePath.$files[0],$genomePath.$name_first);
	}
	$oldName = $name_new;

	// rename decompressed file.
	if (($name_ext == "fna") || ($name_ext == "ffn") || ($name_ext == "faa") || ($name_ext == "frn") || ($name_ext == "fa")) {
		// if alternate extension for fasta is found, rename to fasta.
		$rename_target = "datafile_".$key.".fasta";
	} else {
		$rename_target = "datafile_".$key.".".$name_ext;
	}
	rename($genomePath.$name_first,$genomePath.$rename_target);

	fwrite($logOutput, "\toldName = '".$oldName."'\n");
	fwrite($logOutput, "\trename  = '".$rename_target."'\n");

	// Hand off decompressed GZ file to next section.
	$ext_new  = $name_ext;
	$name_new = $rename_target;

	// Is decompressed file a FASTA?
	if ($ext_new == "fasta") {
		// FASTA file was found.
	} else {
		// FASTA file was not found.
		unlink($genomePath.$name_first);
		fwrite($logOutput, "\tFASTA file not found in GZ!!!\n");
		$ext_new  = "none1";
		$name_new = "";
	}
} elseif (($ext == "fasta") || ($ext == "fna") || ($ext == "ffn") || ($ext == "faa") || ($ext == "frn") || ($ext == "fa")) {
	// if short extension for fasta, fa is found, rename to fasta.
	$ext_new  = "fasta";

	// rename file.
	$rename_target = "datafile_".$key.".".$ext_new;
	rename($genomePath.$name,$genomePath.$rename_target);
	fwrite($logOutput, "\toldName     = '".$name."'\n");
	fwrite($logOutput, "\trename      = '".$rename_target."'\n");

	$name_new = $rename_target;
} else {
	// Not a compressed archive, hand off to next section.
	$ext_new  = $ext;
	$name_new = $name;
}

fwrite($logOutput, "After archive decompression.\n");
fwrite($logOutput, "\text_new     = ".$ext_new."\n");
fwrite($logOutput, "\tname_new    = ".$name_new."\n");
fwrite($logOutput, "\tgenomePath  = ".$genomePath."\n");


//=======================================
// Validate FASTA files.
//---------------------------------------
if ($ext_new == "fasta") {
	fwrite($logOutput, "Validating FASTA file format.\n");
	// Correct filename.

	// initialize validity.
	$fasta_valid = true;

	// Looking at all lines in file.
	$file_name   = $genomePath.$name_new;
	fwrite($logOutput, "\tFile name: ".$file_name."\n");
	$file_handle = fopen($file_name,'r');
	if ($file_handle) {
		while (($line = fgets($file_handle)) !== false) {
			// process the line read.
			if ($line[0] == '>') {
				// chromosome header line.
			} else {
				// check if line is composed only of ATCGNKWRYHMS characters.
				if (preg_match('/[^aAtTcCgGnNkKwWrRyYhHmMsSdDvVbB]/', trim($line))) {
					// line contains characters other than ATCGN: not expected.
					$fasta_valid = false;
					fwrite($logOutput, "\terror: ".trim($line)."\n");
				}
			}
		}
		fclose($file_handle);
	}

	// Is this a fasta file?
	if ($fasta_valid == true) {
		// file contents are consistent with FASTA format.
		fwrite($logOutput, "FASTA file format validated.\n");
	} else {
		// format is wrong for a FASTA file.
		unlink($genomePath.$name_first);
		fwrite($logOutput, "FASTA file format did not validate!\n");
		$ext_new = "none2";
	}
}


//================================================
// Final processing of data files, error logging.
//------------------------------------------------
if ($ext_new == "fasta") {
	fwrite($logOutput, "\tThis is a FASTA file, no further pre-processing is needed.\n");
	log_stuff($user,"","",$genome,$genomePath.$name_new.".".$ext_new,"UPLOAD success: FASTA passed validation.");
} elseif ($ext_new == "none1") {
	fwrite($logOutput, "\tThis archive did not contain a FASTA.\n");
	$errorFile = fopen("users/".$user."/genomes/".$genome."/error.txt", 'w');
	fwrite($errorFile, "Error : Archive did not contain FASTA file.");
	fclose($errorFile);
	chmod($errorFileName,0664);
	log_stuff($user,"","",$genome,$genomePath.$name_new.".".$ext_new,"UPLOAD fail: No fasta present.");
	exit;
} elseif ($ext_new == "none2") {
	fwrite($logOutput, "\tThe FASTA file was not formated properly.\n");
	$errorFile = fopen("users/".$user."/genomes/".$genome."/error.txt", 'w');
	fwrite($errorFile, "Error : FASTA file formatting improperly.");
	fclose($errorFile);
	chmod($errorFileName,0664);
	log_stuff($user,"","",$genome,$genomePath.$name_new.".".$ext_new,"UPLOAD fail: FASTA with wrong formatting.");
	exit;
} else {
	fwrite($logOutput, "\tThis is an unknown file type.\n");
	$errorFile = fopen("users/".$user."/genomes/".$genome."/error.txt", 'w');
	fwrite($errorFile, "Error : Unknown file type as input.\nSee help tab for details of valid file types.");
	fclose($errorFile);
	chmod($errorFileName,0664);
	log_stuff($user,"","",$genome,$genomePath.$name_new.".".$ext_new,"UPLOAD fail: unknown file type.");
	exit;
}

fwrite($logOutput, "*------------------------------------------------------------------------*\n");
fwrite($logOutput, "| 'scripts_genomes/process_input_files.genome.php' has completed.        |\n");
fwrite($logOutput, "*========================================================================*\n");
fwrite($logOutput, $name_new."\n");
return $name_new;
}
?>
