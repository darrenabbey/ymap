<?php
function process_input_files($ext,$name,$projectPath,$key,$user,$project,$output, $condensedLogOutput,$logOutput) {
require_once 'constants.php';
require_once 'sharedFunctions.php';
fwrite($logOutput, "\tPHP : Process uploaded data files into standard forms for pipeline use.\n");
fwrite($logOutput, "\t\t*========================================================*\n");
fwrite($logOutput, "\t\t| Log of 'process_input_files.php'                       |\n");
fwrite($logOutput, "\t\t*--------------------------------------------------------*\n");
fwrite($logOutput, "\t\t| Before archive decompression.\n");
fwrite($logOutput, "\t\t|\text         = ".$ext."\n");
fwrite($logOutput, "\t\t|\tname        = ".$name."\n");

// Replace all "." in $name with "-" except the final one.
$fragments = explode(".",$name);
$count     = sizeof($fragments);
$name_new  = $fragments[0];
if ($count > 2) {
	for ($i = 1; $i < $count-1; $i++) {
		$name_new .= "-".$fragments[$i];
	}
}
$name_new .= ".".$fragments[$count-1];
$name      = $name_new;

// Initialize name of potential second file from sam/bam file.
$name_new2 = "";

// If uploaded file is wrong file type, delete.
$ext = strtolower($ext);
if (($ext == "tdt") || ($ext == "sam") || ($ext == "bam") || ($ext == "fasta") || ($ext == "fna") || ($ext == "ffn") || ($ext == "faa") || ($ext == "frn") || ($ext == "fa") || ($ext == "fastq") || ($ext == "fq") || ($ext == "zip") || ($ext == "gz")) {
	fwrite($logOutput, "\t\t| Compatible file format uploaded.\n");
} else {
	if (file_exists($projectPath.$name)) {
		unlink($projectPath.$name);
	}
	fwrite($logOutput, "\t\t| Incompatible file format uploaded!!!\n");
}


//==================================================
// Deal with compressed archives and odd extensions.
//--------------------------------------------------
$errorText = '';
$currentDir = getcwd(); // get script's path.
if ($ext == "zip") {
	fwrite($condensedLogOutput, "Decompressing ZIP file : ".$name."\n");
	fwrite($logOutput, "\t\t| This is a ZIP archive of : \n");

	// figure out first/only filename contained in zip archive.
	$null               = shell_exec("unzip -l ".$projectPath.$name." > ".$projectPath."zipTemp.txt");   // generate txt file containing archive contents.
	$zipTempLines       = file($projectPath."zipTemp.txt");
	$zipTempArchiveLine = trim($zipTempLines[3]);
	$columns            = preg_split('/\s+/', $zipTempArchiveLine);
	$oldName            = $columns[3];
	$fileName_parts     = preg_split('/[.]/', $oldName);
	fwrite($logOutput,"\t\t|\t'".$oldName."'.\n");
	fwrite($logOutput,"\t\t| The number of fileName parts = ".count($fileName_parts)."\n");

	// What is the file count in the archive?
	$fileCount          = shell_exec("zipinfo ".$projectPath.$name." |grep Zip|grep -oE '[^ ]+$'");
	$fileCount          = trim($fileCount);
	fwrite($logOutput,"\t\t| Files in zip archive = ".$fileCount."\n");
	if ($fileCount > 1) {
		fwrite($logOutput, "\t\t| Multiple files in .ZIP archive, only examining first file.\n");
		$errorText = $errorText."Multiple files in .ZIP archive, only examining first file. ";
	}

	// Extract archive.
	chdir($projectPath);                   // move to projectDirectory.
	$null = shell_exec("unzip -j ".$name); // unzip archive.
	chdir($currentDir);                    // move back to script's path.

	// If more than one file in archive, delete all but first.
	for ($i = 4; $i < $fileCount+2; $i++) {
		$zipTempArchiveLine = trim($zipTempLines[$i]);
		$columns            = preg_split('/\s+/', $zipTempArchiveLine);
		$fileName           = $columns[3];
		unlink($projectPath.$fileName);
	}

	// Delete original archive.
	unlink($projectPath.$name);

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
	rename($projectPath.$oldName,$projectPath.$name_first);

	// rename decompressed file.
	if ($ext_first == "fq") {
		// if short extension for fastq, fq is found, rename to fastq.
		$rename_target = "datafile_".$key.".fastq";
	} else {
		$rename_target = "datafile_".$key.".".$ext_first;
	}
	rename($projectPath.$name_first,$projectPath.$rename_target);

	fwrite($logOutput, "\t\t| currentDir    = '".$currentDir."'\n");
	fwrite($logOutput, "\t\t| projectPath   = '".$projectPath."'\n");
	fwrite($logOutput, "\t\t| oldName       = '".$oldName."'\n");
	fwrite($logOutput, "\t\t| name_first    = '".$name_first."'\n");
	fwrite($logOutput, "\t\t| rename_target = '".$rename_target."'\n");

	// Hand off decompressed ZIP file to next section.
	$ext_new   = $ext_first;
	$name_new  = $rename_target;
	$name_new2 = "";

	// Is decompressed file a FASTQ?
	if ($ext_new == "fastq") {
		// FASTQ file was found.
	} else {
		// FASTQ file was not found.
		unlink($projectPath.$name_first);
		fwrite($logOutput, "\t\t| FASTQ file not found in ZIP!!!\n");
		$errorText = $errorText."FASTQ file not found first in ZIP archive. ";
		$ext_new  = "none1";
		$name_new = "";
	}
} else if ($ext == "gz") {
	fwrite($condensedLogOutput, "Decompressing GZ file : ".$name."\n");
	fwrite($logOutput, "\t\t| This is a GZ archive of : ".$name."\n");

	// What is the file count in the archive?
	$fileCount          = shell_exec("tar -tzf ".$projectPath.$name." | wc -l 2> /dev/null");
	if ($fileCount > 1) {
		fwrite($logOutput, "\t\t| Multiple files in .TAR.GZ archive, only examining first file.\n");
		$errorText = $errorText."Multiple files in .TAR.GZ archive, only examining first file. ";
	}

        // Extract archive.
	if ($fileCount == 0) {
		// Figure out filename contained in gz archive.
		// If one file, then filename is same as archive, without gz.
		$name_new   = str_replace(".gz","", $name);
		$name_final = str_replace("-fastq",".fastq",$name_new);
		$name_final = str_replace("-FASTQ",".fastq",$name_final);
		$name_final = str_replace("-fq",".fastq",$name_final);
		$name_final = str_replace("-FQ",".fastq",$name_final);

		$name_first = $name_new;
		$name_ext   = pathinfo($name_final, PATHINFO_EXTENSION);

		// Is not a tar.gz, so decompress with gzip.
		chdir($projectPath);                   // move to projectDirectory.
		$null = shell_exec("gzip -dc ".$name." > ".$name_new); // decompress archive while keeping results in case of early file end error.
		chdir($currentDir);                    // move back to script's path.

		// Delete original archive.
		unlink($projectPath.$name);
	} else {
		fwrite($logOutput,"\t\t| Files in tar.gz archive = ".$fileCount.".\n");

		// multiple files found in archive, so is a tar.gz and needs different handling.
		chdir($projectPath);                   // move to projectDirectory.
		$file_list = shell_exec("tar xvzf ".$name);
		chdir($currentDir);                    // move back to script's path.

		// Figure out individual filenames from tar.gz
		$files = explode("\n",$file_list);

		// If more than one file in archive, delete all but first.
		$fileCount = size_of($files);
		if ($fileCount > 1) {
			for ($i = 1; $i < $fileCount; $i++) {
				$fileName = $files[$i];
				unlink($projectPath.$fileName);
			}
		}

		// Delete original archive.
		unlink($projectPath.$name);

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
		rename($projectPath.$files[0],$projectPath.$name_first);
	}
	$oldName = $name_new;

	// rename decompressed file.
	$rename_target = "datafile_".$key.".".$name_ext;
	rename($projectPath.$name_first,$projectPath.$rename_target);
	fwrite($logOutput, "\t\t| oldName = '".$oldName."'\n");
	fwrite($logOutput, "\t\t| rename  = '".$rename_target."'\n");

	// Hand off decompressed GZ file to next section.
	$ext_new   = $name_ext;
	$name_new  = $rename_target;
	$name_new2 = "";

	// Is decompressed file a FASTQ?
	if ($ext_new == "fastq") {
		// FASTQ file was found.
	} else {
		// FASTQ file was not found.
		unlink($projectPath.$name_first);
		fwrite($logOutput, "\t\t| FASTQ file not found in GZ!!!\n");
		$errorText = $errorText."FASTQ file not found first in GZ archive. ";
		$ext_new  = "none1";
		$name_new = "";
	}
} else if (($ext == "sam") || ($ext == "bam")) {
	fwrite($logOutput, "\t\t| This is a SAM/BAM file.\n");

	// The .sh scripts need to be running from Ymap root.
	$absProjectPath = realpath($projectPath) . "/";
	$currentDir = getcwd();
	chdir($projectPath . "../../../../"); // ymap_root/users/user_name/projects/this_project

	// Convert SAM file to FASTQ files.
	fwrite($condensedLogOutput, "Decompressing SAM/BAM file to FASTQ.\n");
	$null       = shell_exec("bash scripts_seqModules/sam2fastq.sh ".$user." ".$project." ".$name_new);

	// Check if file has single or paired read data.
	fwrite($logOutput, "\t\t| SAM/BAM file: ".$absProjectPath.$name_new."\n");
	$SAMheader  = shell_exec("samtools view -H ".$absProjectPath.$name_new);
	$FASTQcount = substr_count($SAMheader,".fastq")+substr_count($SAMheader,".fq");
	//fwrite($logOutput, "\t\t| SAM/BAM header\n");
	//fwrite($logOutput, "\t\t|\t".$SAMheader."\n");
	fwrite($logOutput, "\t\t| Source file count from SAM/BAM header = ".$FASTQcount."\n");

	// Rewrite datafiles.txt depending on contents of SAM/BAM file.
	unlink($absProjectPath."datafiles.txt");
	$datafiles_file = fopen($absProjectPath."datafiles.txt", 'w');

	if ((int)$FASTQcount == 1) {
		fwrite($logOutput, "\t\t| Single-read SAM/BAM file converted to FASTQ file, original deleted.\n");
	} else {
		fwrite($logOutput, "\t\t| Paired-read SAM/BAM file converted to FASTQ file, original deleted.\n");
	}
	// Faster just to treat all SAM/BAM files as single-end reads.
//	if (paired == true) {
//		// Rewrite datafiles.txt file with decomressed sam/bam data.
//		fwrite($datafiles_file, "data_r1.fastq\n");
//		fwrite($datafiles_file, "data_r2.fastq\n");
//		$name_new  = "data_r1.fastq";
//		$name_new2 = "data_r2.fastq";
//		$paired = 1;
//	} else {
		// Rewrite datafiles.txt file with decomressed sam/bam data.
		fwrite($datafiles_file, "data.fastq\n");
		fwrite($datafiles_file, "");
		$name_new  = "data.fastq";
		$name_new2 = "";
		$paired = 0;
//	}
	fclose($datafiles_file);
	$ext_new   = "fastq";

	// delete original archive.
	unlink($absProjectPath.$name);

	chdir($currentDir);
} else if ($ext == "fq") {
	// if short extension for fastq, fq is found, rename to fastq.
	$ext_new   = "fastq";
	$name_new  = $name;
	$name_new2 = "";
} else if (($ext == "fna") || ($ext == "ffn") || ($ext == "faa") || ($ext == "frn") || ($ext == "fa")) {
	// alternate extensions for fasta, rename to fasta.
	$ext_new   = "fasta";
	$name_new  = $name;
	$name_new2 = "";
} else {
	// Not a compressed archive, hand off to next section.
	$ext_new   = $ext;
	$name_new  = $name;
	$name_new2 = "";
}

fwrite($logOutput, "\t\t| After archive decompression.\n");
fwrite($logOutput, "\t\t|\text_new     = ".$ext_new."\n");
if ($name_new2 == "") {
	fwrite($logOutput, "\t\t|\tname_new    = ".$name_new."\n");
} else {
	fwrite($logOutput, "\t\t|\tname_new    = ".$name_new."\n");
	fwrite($logOutput, "\t\t|\tname_new2   = ".$name_new2."\n");
}
fwrite($logOutput, "\t\t|\tprojectPath = ".$projectPath."\n");


//=======================================
// Validate FASTQ, FASTA, and CSV/TDT/TXT files.
//---------------------------------------
if ($ext_new == "fastq") {
	// validate fastq file(s).
	$ext_new = validate_fastq($projectPath,$name_new,$condensedLogOutput,$logOutput,$ext_new);
	if (str_contains($ext_new,"none")) {
		unlink($projectPath."data_r2.fastq");
	} else {
		if ($name_new2 <> "") {
			$ext_new = validate_fastq($projectPath,$name_new2,$condensedLogOutput,$logOutput,$ext_new);
		}
	}
} else if ($ext_new == "fasta") {
	// Looking at first line of text.
	$file_name   = $projectPath.$name_new;
	$file_handle = fopen($file_name,'r');
	$line_1      = fgets($file_handle);
	fclose($file_handle);

	// Is this a fasta file?
	if ($line_1[0] == '>') {
		// It is a FASTA file.
	} else {
		// format is wrong for a FASTA file.
		unlink($projectPath.$name_first);
		fwrite($logOutput, "\t\t| FASTA file format incorrect!!!\n");
		$ext_new = "none2";
	}
} else if ($ext_new == "tdt") {  // Data from custom SnpCgh microarray.
	// Looking at first four lines of text.
	$file_name = $projectPath.$name_new;
	$file_handle = fopen($file_name,'r');
	$line_1      = fgets($file_handle);
	$line_2      = fgets($file_handle);
	$line_3      = fgets($file_handle);
	$line_4      = fgets($file_handle);
	fclose($file_handle);

	// Is this a tdt file with useful information?
	$line_1_words = $parts = preg_split('/\s+/', $line_1);
	if ((strcmp($line_1_words[0],"Ca19-mtDNA") == 0) || (strcmp($line_1_words[0],"Ca21chr1_C_albicans_SC5314") == 0)
	|| (strcmp($line_1_words[0],"Ca21chr2_C_albicans_SC5314") == 0) || (strcmp($line_1_words[0],"Ca21chr3_C_albicans_SC5314") == 0)
	|| (strcmp($line_1_words[0],"Ca21chr4_C_albicans_SC5314") == 0) || (strcmp($line_1_words[0],"Ca21chr5_C_albicans_SC5314") == 0)
	|| (strcmp($line_1_words[0],"Ca21chr6_C_albicans_SC5314") == 0) || (strcmp($line_1_words[0],"Ca21chr7_C_albicans_SC5314") == 0)
	|| (strcmp($line_1_words[0],"Ca21chrR_C_albicans_SC5314") == 0)) {
		// is a TDT file, as defined in the paper.
		fwrite($logOutput, "\t\t| TDT file format correct; custom filtered data.\n");
		$ext_new = "tdt";
	} elseif (strcmp($line_1_words[0],"Created") == 0) {
		// is Tab-delimited-txt (TXT) file, as output from BlueFuse.
		fwrite($logOutput, "\t\t| TDT file format correct; BlueFuse array data.\n");
		$ext_new = "tdt";
	} else {
		unlink($projectPath.$name_first);
		fwrite($logOutput, "\t\t| TDT file format incorrect!!!\n");
		fwrite($logOutput, "\t\t|\t".$line_1_words[0]."\n");
		fwrite($logOutput, "\t\t|\t"."Ca19-mtDNA"."\n");
		$ext_new = "none3";
	}
	$name_new    = $name;

	// rename uploaded file with no extension.
	$rename_target = "datafile_".$key.".".$ext_new;
	rename($projectPath.$name_new,$projectPath.$rename_target);
	$name_new    = $rename_target;
}


//================================================
// Final processing of data files, error logging.
//------------------------------------------------
if ($ext_new == "fastq") {
	fwrite($logOutput, "\t\t| This is a FASTQ file with short-read data, no further pre-processing is needed.\n");
	fwrite($output, $name_new."\n");
	$paired = 0;
} else if ($ext_new == "fastq-l") {
	fwrite($logOutput, "\t\t| This is a FASTQ file with long-read data, pre-process into simulated illumina FASTQ data.\n");

	// Convert FASTQ to simulated-Illumina FASTQ.
	$currentDir = getcwd();
	chdir("../../users/".$user."/projects/".$project."/");
	$newDir = getcwd();

	fwrite($logOutput, "\t\t|\n");
	fwrite($logOutput, "\t\t| calling directory : ".$currentDir."\n");
	fwrite($logOutput, "\t\t| working directory : ".$newDir."/temp\n");
	fwrite($logOutput, "\t\t| data file         : ".$newDir."/".$name_new."\n");
	fwrite($logOutput, "\t\t|\n");
	$null = shell_exec("bash ../../../../scripts_seqModules/FASTQ_to_Illumina.sh ".$newDir."/".$name_new." ".$newDir."/temp");

	// delete original file.
	unlink($newDir."/".$name_new);
	fwrite($logOutput, "\t\t| File converted to simulated-Illumina FASTQ file, original deleted.\n");

	fwrite($output, "output.fastq\n");
	$paired = 0;
	chdir($currentDir);
} else if ($ext_new == "fasta") {
	fwrite($logOutput, "\t\t| This is a FASTA file, pre-process into simulated illumina FASTQ data.\n");

	// Convert FASTA to simulated-Illumina FASTQ.
	$currentDir = getcwd();
	chdir("../../users/".$user."/projects/".$project."/");
	$newDir = getcwd();

	fwrite($logOutput, "\t\t|\n");
	fwrite($logOutput, "\t\t| calling directory : ".$currentDir."\n");
	fwrite($logOutput, "\t\t| working directory : ".$newDir."/temp\n");
	fwrite($logOutput, "\t\t| data file         : ".$newDir."/".$name_new."\n");
	fwrite($logOutput, "\t\t|\n");
	$null = shell_exec("bash ../../../../scripts_seqModules/FASTA_to_Illumina.sh ".$newDir."/".$name_new." ".$newDir."/temp");

	// delete original file.
	unlink($newDir."/".$name_new);
	fwrite($logOutput, "\t\t| File converted to simulated-Illumina FASTQ file, original deleted.\n");

	fwrite($output, "output.fastq\n");
	$paired = 0;
	chdir($currentDir);
} elseif ($ext_new == "tdt") {
	fwrite($logOutput, "\t\t| This is a txt file.\n");
	fwrite($logOutput, "\t\t|\tCurrentDir = ".getcwd()."\n");
	fwrite($logOutput, "\t\t|\tshell_exec string = 'bash ../Gareth2pileups.sh ".$user." ".$project." ".$name_new."'\n");
	$currentDir = getcwd();
	$null       = shell_exec("bash ../Gareth2pileups.sh ".$user." ".$project." ".$name_new);
	// sam2fastq.sh user project main_dir inputFile;
	fwrite($output, "null1\n");
	fwrite($output, "null2\n");
	// delete original archive.
	unlink($projectPath.$name_new);
	fwrite($logOutput, "\t\t| File converted to intermediate pileup files, original deleted.\n");
	$paired = 1;
} elseif ($ext_new == "none1") {
	fwrite($logOutput, "\t\t| This archive did not contain a FASTQ.\n");
	$errorFile = fopen($projectPath."error.txt", 'w');
	fwrite($errorFile, "Archive did not contain FASTQ file.");
	fclose($errorFile);
	chmod($errorFileName,0774);
	log_stuff($user,$project,"","","users/".$user."/projects/".$project."/".$name_new.".".$ext_new,"UPLOAD fail: FASTQ not found in archive.");
	queue_end($user,$project,"","","File validation failed.");
	exit;
} elseif ($ext_new == "none2") {
	fwrite($logOutput, "\t\t| The FASTQ file was not formated properly.\n");
	$errorFile = fopen($projectPath."error.txt", 'w');
	fwrite($errorFile, "FASTQ file formatting improperly.");
	fclose($errorFile);
	chmod($errorFileName,0774);
	log_stuff($user,$project,"","","users/".$user."/projects/".$project."/".$name_new.".".$ext_new,"UPLOAD fail: FASTQ file format errors.");
	queue_end($user,$project,"","","File validation failed.");
	exit;
} elseif ($ext_new == "none3") {
	fwrite($logOutput, "\t\t| The contents of this TDT file did not match expectations.\n");
	$errorFile = fopen($projectPath."error.txt", 'w');
	fwrite($errorFile, "TDT file contents did not match expectations.");
	fclose($errorFile);
	chmod($errorFileName,0774);
	log_stuff($user,$project,"","","users/".$user."/projects/".$project."/".$name_new.".".$ext_new,"UPLOAD fail: TDT file format errors.");
	queue_end($user,$project,"","","File validation failed.");
	exit;
} elseif ($ext_new == "none4") {
	fwrite($logOutput, "\t\t| The FASTQ file contains long-reads.\n");
	$errorFile = fopen($projectPath."error.txt", 'w');
	fwrite($errorFile, "FASTQ file with long reads, unable to process.");
	fclose($errorFile);
	chmod($errorFileName,0774);
	log_stuff($user,$project,"","","users/".$user."/projects/".$project."/".$name_new.".".$ext_new,"UPLOAD fail: FASTQ file has incompatible long-reads..");
	queue_end($user,$project,"","","File validation failed.");
	exit;
} else {
	fwrite($logOutput, "\t\t| This is an unknown file type.\n");
	$errorFile = fopen($projectPath."error.txt", 'w');
	fwrite($errorFile, "Unknown file type as input.\nSee help tab for details of valid file types.");
	fclose($errorFile);
	chmod($errorFileName,0774);
	log_stuff($user,$project,"","","users/".$user."/projects/".$project."/".$name_new.".".$ext_new,"UPLOAD fail: Unknown file format.");
	queue_end($user,$project,"","","File validation failed.");
	exit;
}

fwrite($logOutput, "\t\t*--------------------------------------------------------*\n");
fwrite($logOutput, "\t\t| 'process_input_files.php' has completed.               |\n");
fwrite($logOutput, "\t\t*========================================================*\n");
return $paired;
}


function validate_fastq($projectPath,$name_new,$condensedLogOutput,$logOutput,$ext_new) {
	// Looking at first four lines of text to check basic format requirements are met.
	$file_name   = $projectPath.$name_new;
	$file_handle = fopen($file_name,'r');
	$line_1      = fgets($file_handle);
	$line_2      = fgets($file_handle);
	$line_3      = fgets($file_handle);
	$line_4      = fgets($file_handle);
	fclose($file_handle);

	// Is this a fastq file?
	if (($line_1[0] == '@') && ($line_3[0] == '+')) {
		// This is a FASTQ file.
		// Is this a short-read or long-read fastq file?
		// Determine max read length, read count, length of all reads,
		//awk 'length($0) > 500 && /^>/ {print; exit}' filename


		fwrite($condensedLogOutput, "Calculating FASTQ read length statistics.\n");
		$null            = shell_exec("sed -n '2~4p' ".$projectPath.$name_new." > ".$projectPath.$name_new.".temp");		// Discared FASTQ lines except for sequence.
		$maxReadLength   = (int)explode(" ",trim(shell_exec("wc -L ".$projectPath.$name_new.".temp")))[0];			// Get longest sequence length.
		$totalReadCount  = (int)explode(" ",trim(shell_exec("wc -l ".$projectPath.$name_new.".temp")))[0];			// Get number of reads.
		$totalReadLength = (int)explode(" ",trim(shell_exec("wc -c ".$projectPath.$name_new.".temp")))[0] - $totalReadCount;	// Get total sequence length.
		unlink($projectPath.$name_new.".temp");											// Delete temp file.

		fwrite($logOutput, "\t\t| Preparing readstats.txt file.\n");
		if (!file_exists($projectPath."readStats.txt")) {
			// Make a new readStats.txt file with read length stats.
			$readStatsFile = fopen($projectPath."readStats.txt", 'w');
			fwrite($readStatsFile, $totalReadCount." (reads count)\n".$totalReadLength." (reads total length)\n");
			fclose($readStatsFile);
		} else {
			// Load existing totalReadCount and totalReadLength from readStats.txt file.
			$oldStats_raw        = trim(file_get_contents($projectPath."readStats.txt"));
			$oldStats_lines      = preg_split("/\R/", $oldStats_raw);
			$totalReadCount_old  = (int)$oldStats_lines[0];
			$totalReadLength_old = (int)$oldStats_lines[1];

			// Add the new and old values.
			$totalReadCount      = $totalReadCount  + $totalReadCount_old;
			$totalReadLength     = $totalReadLength + $totalReadLength_old;

			// Make a new readStats.txt file with new values.
			$readStatsFile = fopen($projectPath."readStats.txt", 'w');
			fwrite($readStatsFile, $totalReadCount." (reads count)\n".$totalReadLength." (reads total length)\n");
			fclose($readStatsFile);
		}

		fwrite($logOutput, "\t\t| max read length = ".(string)$maxReadLength."\n");
		if ($maxReadLength <= 500) {
			// short-reads: no problems.
		} else {
			// long-reads: generate error for YMAP1.
			//unlink($projectPath.$name_first);
			//$ext_new = "none4"; //YMAP1 doesn't process long-reads, so error code.

			// long-reads: no problem for YMAP2.
			$ext_new = "fastq-l"; //YMAP2 does process long-reads, so file type.
		}
	} else {
		// format is wrong for a FASTQ file.
		unlink($projectPath.$name_first);
		fwrite($logOutput, "\t\t| FASTQ file format incorrect!!!\n");
		$ext_new = "none2";
	}
	return $ext_new;
}

?>
