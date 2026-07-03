<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else if ($_SESSION['logged_on'] == 0) {
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else {
		$user = $_SESSION['user'];
	}
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	if (isset($_SESSION['logged_on'])) {
		$user = $_SESSION['user'];
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota = getUserQuota($user);
		// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
		$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
		if ($exceededSpace) {
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (".$quota."G). ";
			echo "Clear space by deleting/minimizing projects or wait until datasets finish processing before adding a new dataset.</span><br><br>";
		}
	}
?>
<html lang="en">
	<HEAD>
		<style type="text/css">
			body {font-family: arial;}
			.tab {margin-left:   1cm;}
		</style>
		<meta http-equiv="content-type" content="text/html; charset=utf-8">
		<title>[Needs Title]</title>
	</HEAD>
	<BODY onload="UpdateHapmapList(); UpdateParentList()">
		<div id="loginControls"><p>
		</p></div>
		<div id="projectCreationInformation"><p>
			<form action="project.create_server.php" method="post">
				<table><tr bgcolor="#CCFFCC"><td>
					<label for="project">Dataset Name : </label><input type="text" name="project" id="project">
				</td><td>
					Unique name for this dataset.
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
                                        <label for="displayName">Display Name : </label><input type="text" name="displayName" id="displayName">
                                </td><td>
                                        Name to use in figures for this dataset, defaults to name entered above if left blank.
                                </td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection3" style="display:inline">
					<label for="groupKey">Dataset group : </label><select name="groupKey" id="groupKey">
					<?php
					// Get list of projects.
					$projectsDir    = "users/".$user."/projects/";
					$projectFolders = [];
					$objects        = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($projectsDir), RecursiveIteratorIterator::SELF_FIRST);
					foreach($objects as $name => $object){
						if (is_dir($name)) {
							$name_ = str_replace($projectsDir,"",$name);
							if (str_contains($name_,"..") or str_contains($name_,".")) {
							} else {
								$projectFolders[] = $name_;
							}
						}
					}

					// Get list of project groups.
					$projectFolders_subdir       = array();
					foreach($projectFolders as $key=>$project) {
						if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
						} else if (file_exists("users/".$user."/projects/".$project."/bulk.txt")) {
						} else if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
						} else if (file_exists("users/".$user."/projects/".$project."/name.txt")) {
						} else {
							array_push($projectFolders_subdir,$project);
						}
					}
					sort($projectFolders_subdir);

					// Output selection box options.
					echo "\n\t\t\t\t\t<option value='0'>[none]</option>";
					foreach ($projectFolders_subdir as $key => $group) {
						echo "\n\t\t\t\t\t<option value='".($key+1)."'>".$group. "</option>";
					}
					?>
						</select><br>
					</div>
				</td><td valign="top">
					Dataset group for this dataset to be placed in.
				</td></tr>



				<tr bgcolor="#CCCCFF"><td>
					<label for="ploidy">Ploidy of experiment : </label><input type="text" name="ploidy"  id="ploidy" value="2.0"><br>
				</td><td>
					A ploidy estimate for the strain being analyzed.
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<label for="ploidy">Baseline ploidy : </label><input type="text" name="ploidyBase"  id="ploidyBase" value="2.0"><br>
				</td><td>
					The copy number to use as a baseline in drawing copy number variations.
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
					<label for="showAnnotations">Generate figure with annotations?</label><select name="showAnnotations" id="showAnnotations">
						<option value="1">Yes</option>
						<option value="0">No</option>
					</select>
				</td><td>
					Genome annotations, such as rDNA locus, can be drawn at bottom of figures.
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<label for="dataFormat">Data type : </label><select name="dataFormat" id="dataFormat" onchange="UpdateForm(); UpdateHapmap(); UpdateParentList()">
						<option value="0">SnpCgh microarray                      </option>
						<option value="1" selected>Whole genome NGS (short-reads)</option>
						<option value="2">Whole genome NGS (long-reads)          </option>
						<option value="3">ddRADseq                               </option>
						<option value="4">FASTA                                  </option>
					</select>
				</td><td>
					The type of data to be processed.
				</td></tr>
				<tr bgcolor="#CCCCFF"><td valign="top">
					<div id="hiddenFormSection1a" style="display:inline">
						<label for="readTypeA">Read type : </label><select name="readTypeA" id="readTypeA">
							<option value="0">single-end short-reads; FASTQ/ZIP/GZ file. </option>
							<option value="1">paired-end short-reads; FASTQ/ZIP/GZ files.</option>
							<option value="0">SAM/BAM file.                              </option>
							<option value="3">TXT file.                                  </option>
							</select><br>
					</div>
					<div id="hiddenFormSection1b" style="display:none">
						<label for="readTypeB">Read type : </label><select name="readTypeB" id="readTypeB">
							<option value="0">FASTA; FASTA/ZIP/GZ file. </option>
							</select><br>
					</div>
					<div id="hiddenFormSection1c" style="display:none">
						<label for="readTypeC">Read type : </label><select name="readTypeC" id="readTypeC">
							<option value="0">long-reads; FASTQ/ZIP/GZ file. </option>
							<option value="2">SAM/BAM file.                  </option>
							</select><br>
					</div>
				</td><td>
					<div id="hiddenFormSection2" style="display:inline">
						Single-end or paired-end reads in FASTQ format can be compressed into ZIP or GZ archives or in SAM/BAM alignment files.<br>
						Tab-delimted TXT column format is described in 'About' tab of main page.
					</div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection3" style="display:inline">
						<label for="genome">Reference genome : </label><select name="genome" id="genome" onchange="UpdateHapmap(); UpdateHapmapList(); UpdateParentList()">
					<?php
					$genomesMap = array(); // A mapping of folder names to display names, sorted by folder names.
					foreach (array("default", $user) as $genomeUser) {
						$genomesDir = "users/" . $genomeUser . "/genomes/";
						foreach (array_diff(glob($genomesDir . "*"), array('..', '.')) as $genomeDir) {
							// display genome only if processing finished
							if (file_exists($genomeDir . "/complete.txt")) {
								$genomeDirName = str_replace($genomesDir, "", $genomeDir);
								$genomeDisplayName = file_get_contents($genomeDir . "/name.txt");
								$genomesMap[$genomeDirName] = $genomeDisplayName;
							}
						}
					}

					ksort($genomesMap);
					foreach ($genomesMap as $genomeDirName => $genomeDisplayName) {
						echo "\n\t\t\t\t\t<option value='" . $genomeDirName . "'>" . $genomeDisplayName . "</option>";
					}
					?>
						</select><br>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection4" style="display:inline">
					Reference genomes starting with a "+" have been more intensively tested.<br>
					Those without will work, but resulting figures may have formatting limitations.
					</div>
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
					<?php
					// figure out which hapmaps have been defined for this species, if any.
					$hapmapsDir1       = "users/default/hapmaps/";
					$hapmapsDir2       = "users/".$user."/hapmaps/";
					$hapmapFolders1    = array_diff(glob($hapmapsDir1."*"), array('..', '.'));
					$hapmapFolders2    = array_diff(glob($hapmapsDir2."*"), array('..', '.'));
					$hapmapFolders_raw = array_merge($hapmapFolders1,$hapmapFolders2);
					// Go through each $hapmapFolder and look at 'genome.txt'; build javascript array of hapmapName:genome pairs.
					?>
					<div id="hiddenFormSection5" style="display:none">
						Restriction enzymes :
						<select id="selectRestrictionEnzymes" name="selectRestrictionEnzymes" onchange="UpdateParent();">
						<option value="MfeI_MboI">MfeI & MboI</option>
						<?php // <option value="BamHI_BclI">BamHI & BclI (testing)</option>
						?>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection6" style="display:none">
						Analysis of ddRADseq data is limited to restriction fragments bound by both restriction enzymes.<br>
						If your restriction enzyme pair is not listed, you can contact the system administrators about developing the option as a collaboration.
					</div>
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
					<?php
					// figure out which hapmaps have been defined for this species, if any.
					$hapmapsDir1       = "users/default/hapmaps/";
					$hapmapsDir2       = "users/".$user."/hapmaps/";
					$hapmapFolders1    = array_diff(glob($hapmapsDir1."*"), array('..', '.'));
					$hapmapFolders2    = array_diff(glob($hapmapsDir2."*"), array('..', '.'));
					$hapmapFolders_raw = array_merge($hapmapFolders1,$hapmapFolders2);
					// Go through each $hapmapFolder and look at 'genome.txt'; build javascript array of hapmapName:genome pairs.
					?>
					<div id="hiddenFormSection7" style="display:inline">
						Haplotype map : <select id="selectHapmap" name="selectHapmap" onchange="UpdateParent();"><option>[choose]</option></select>
						<script type="text/javascript">
						var hapmapGenome_entries = [['hapmap','genome']<?php
						foreach ($hapmapFolders_raw as $key=>$folder) {
							$filename = $folder."/genome.txt";
							if (!file_exists($filename)) {
								continue;
							}
							$handle        = fopen($filename, "r");
							$genome_string = trim(fgets($handle));
							fclose($handle);
							$hapmapName    = $folder;
							$hapmapName    = str_replace($hapmapsDir1,"",$hapmapName);
							$hapmapName    = str_replace($hapmapsDir2,"",$hapmapName);
							echo ",['{$hapmapName}','{$genome_string}']";
						}
						?>];
						</script>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection8" style="display:inline">
						A haplotype map defines the phasing of heterozygous SNPs across the genome.<br>
						SNP information from the hapmap will be used for SNP/LOH analsyses.<br>
						The installed hapmap is derived for Candida albicans SC5314, as published in Abbey <i>et al</i>, 2014.
					</div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<?php
					// figure out which projects have been defined for this species, if any.
					$projectsDir1       = "users/default/projects/";
					$projectsDir2       = "users/".$user."/projects/";
					$projectFolders1    = array_diff(glob($projectsDir1."*"), array('..', '.'));
					$projectFolders2    = array_diff(glob($projectsDir2."*"), array('..', '.'));
					$projectFolders_raw = array_merge($projectFolders1,$projectFolders2);
					// Go through each $projectFolder and look at 'genome.txt', 'dataFormat.txt', and 'minimized.txt'; build javascript array of [parent:genome:dataFormat:projectName]s.
					?>
					<div id="hiddenFormSection9" style="display:inline">
						Parental strain : <select id="selectParent" name="selectParent"><option>[choose]</option></select>
						<script type="text/javascript">
						var parentGenomeDataFormat_entries = [
							['parent', 'genome', 'dataFormat', 'projectName'],
						<?php
						foreach ($projectFolders_raw as $key=>$folder) {
							// display project only if processing finished
							if (file_exists($folder . "/complete.txt")) {
								// Figure out genome used.
								$genome_filename = $folder."/genome.txt";
								$genome_string = "";
								if (file_exists($genome_filename)) {
									// Some datasets don't have a reference genome (e.g., SnpCgh arrays).
									$handle1         = fopen($genome_filename, "r");
									$genome_string   = trim(fgets($handle1));
									fclose($handle1);
								}

								// Figure out data format.
						 		$handle2           = fopen($folder."/dataFormat.txt", "r");
								$dataFormat_string = trim(fgets($handle2));
								$dataFormat_string = explode(":",$dataFormat_string);
								$dataFormat_string = $dataFormat_string[0];
								fclose($handle2);

								// Figure out parent project name.
								$parentName        = $folder;
								if (file_exists($folder."/name.txt")) {
									$projectNameString = strip_tags(trim(file_get_contents($folder."/name.txt")));
									$parentName        = trim(str_replace($projectsDir1,"",$parentName));
								} else {
									$projectNameString = strip_tags(trim(file_get_contents($folder."/name.txt")));
								}
								$parentName      = trim(str_replace($projectsDir1,"",$parentName));
								$parentName      = trim(str_replace($projectsDir2,"",$parentName));

								// Output found strings if parent project has usable data.
								//if (!file_exists($folder."/minimized.txt")) {
								if (file_exists($folder."/putative_SNPs_v4.zip")) {
									echo "\t\t\t\t\t\t\t";
									echo "['{$parentName}', '{$genome_string}', {$dataFormat_string}, '{$projectNameString}']";
									echo ",\n";
								}
							}
						}
						?>];
						</script>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection10" style="display:inline">
						This strain will act as the SNP distribution control.<br>
						It is advised to initially process all datasets without changing this setting.<br>
						Later, setting a parental strain will help visualize LOHs.
					</div>
					<div id="hiddenFormSection11" style="display:none">
						<br>
						This strain will act as the CNV normalization control.<br>
						<br>
					</div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection12" style="display:none">
						<!-- SnpCgh array --!>
						<input type="checkbox"      name="0_bias2" value="True" checked>GC-content bias<br>
						<input type="checkbox"      name="0_bias4" value="True"        >chromosome-end bias
					</div>
					<div id="hiddenFormSection13" style="display:inline">
						<!-- WGseq --!>
						<input type="checkbox"      id="1_bias2" name="1_bias2" value="True" checked>GC-content bias<br>
						<input type="checkbox"      id="1_bias4" name="1_bias4" value="True"  onchange="UpdateBiasWG();"      >chromosome-end bias (forces using GC content bias)
					</div>
					<div id="hiddenFormSection14" style="display:none">
						<!-- ddRADseq --!>
						<input type="checkbox"      name="2_bias1" value="True" checked>fragment-length bias<br>
						<input type="checkbox"      name="2_bias2" value="True" checked>GC-content bias<br>
						<input type="checkbox"      name="2_bias4" value="True"        >chromosome-end bias
					</div>
				</td><td>
					<div id="hiddenFormSection15" style="display:inline">
						GC% bias correction is almost always ideal.<br>
						Use chromosome-end correction with care. <font size='2'>(Chr end bias in data can potentially reveal structural changes which alter the distance between<br>
						a locus and a chromosome end vs in the reference genome. Correcting this bias can lead to confounding copy number artifacts in such cases.)</font>
					</div>
				</td></tr></table><br>
				<?php
				if (!$exceededSpace) {
					echo "<input type='submit' value='Create New Dataset'>";
				}
				?>
			</form>

			<script type="text/javascript">
			UpdateParent = function() {
				// if 'selectHapmap' isn't "[None defined]" then hide parental strain row.
				var selectedHapmap = document.getElementById("selectHapmap").value;
				if (selectedHapmap == 'none') {
					document.getElementById("hiddenFormSection9" ).style.display  = 'inline';
					document.getElementById("hiddenFormSection10").style.display  = 'inline';
					document.getElementById("hiddenFormSection11").style.display  = 'none';
				} else {
					if (document.getElementById("dataFormat").value == 3) {    // ddRADseq
						document.getElementById("hiddenFormSection9" ).style.display  = 'inline';
						document.getElementById("hiddenFormSection10").style.display  = 'none';
						document.getElementById("hiddenFormSection11").style.display  = 'inline';
					} else {
						document.getElementById("hiddenFormSection9" ).style.display  = 'none';
						document.getElementById("hiddenFormSection10").style.display  = 'none';
						document.getElementById("hiddenFormSection11").style.display  = 'none';
					}
				}
			}
			UpdateHapmapList=function() {
				var selectedGenome = document.getElementById("genome").value;   // grab genome name.
				var select         = document.getElementById("selectHapmap");   // grab select list.
				select.innerHTML   = '';
				var el             = document.createElement("option");
				el.textContent     = '[None defined]';
				el.value           = 'none';
				select.appendChild(el);
				for (var i = 1; i < hapmapGenome_entries.length; i++) {
					var item = hapmapGenome_entries[i];
					if (selectedGenome == item[1]) {
						var el         = document.createElement("option");
						el.textContent = item[0];
						el.value       = item[0];
						select.appendChild(el);
					}
				}
			}
			UpdateParentList=function() {
				var selectedGenome     = document.getElementById("genome").value;     // grab genome name.
				var selectedDataFormat = document.getElementById("dataFormat").value; // grab dataset type.
				var select             = document.getElementById("selectParent");     // grab select list.
				select.innerHTML       = '';
				var el                 = document.createElement("option");
				el.textContent         = '[No parent strain for comparison.]';
				el.value               = 'none';
				select.appendChild(el);
				for (var i = 1; i < parentGenomeDataFormat_entries.length; i++) {
					var item = parentGenomeDataFormat_entries[i];
					if (selectedGenome == item[1] && selectedDataFormat == item[2]) {
						if (item[3] != "") {
							var el         = document.createElement("option");
							el.textContent = item[3];
							el.value       = item[0];
							select.appendChild(el);
						}
					}
				}
			}
			UpdateForm=function() {
				// Manages hiding and displaying form sections during user interaction.
				if (document.getElementById("dataFormat").value == 0) { // 0: SnpCgh Microarray
					document.getElementById("hiddenFormSection1a").style.display = 'none';		// input file types selection, at left.
					document.getElementById("hiddenFormSection1b").style.display = 'none';		// input file types selection, at left. [FASTA only]
					document.getElementById("hiddenFormSection1c").style.display = 'none';		// input file types selection, at left. [WGseq, long-reads only]
					document.getElementById("hiddenFormSection2").style.display  = 'none';		//	description of input file types, at right.
					document.getElementById("hiddenFormSection3").style.display  = 'none';		// reference genome selection, at left.
					document.getElementById("hiddenFormSection4").style.display  = 'none';		//	description of reference genomes, at right.
					document.getElementById("hiddenFormSection5").style.display  = 'none';		// restriction enzyme selection, at left.
					document.getElementById("hiddenFormSection6").style.display  = 'none';		//	description of restriction enzymes, at right. [ddRADseq only]
					document.getElementById("hiddenFormSection7").style.display  = 'none';		// hapmap selection, at left.
					document.getElementById("hiddenFormSection8").style.display  = 'none';		//	description of hapmap, at right.
					document.getElementById("hiddenFormSection9").style.display  = 'none';		// parent selection, at right.
					document.getElementById("hiddenFormSection10").style.display = 'none';		//	description of parent as SNP control, at right.
					document.getElementById("hiddenFormSection11").style.display = 'none';		//	description of parent as CNV control, at right. [ddRADseq only]
					document.getElementById("hiddenFormSection12").style.display = 'inline';	// checkbox for normalization options. [SnpCGH only]
					document.getElementById("hiddenFormSection13").style.display = 'none';		// checkbox for normalization options. [WGseq, FASTA]
					document.getElementById("hiddenFormSection14").style.display = 'none';		// checkbox for normalization options. [ddRADseq only]
					document.getElementById("hiddenFormSection15").style.display = 'none';		//	description of normalization options, at right.
				} else if (document.getElementById("dataFormat").value == 4) { // 4: FASTA
					document.getElementById("hiddenFormSection1a").style.display = 'none';		// input file types selection, at left.
					document.getElementById("hiddenFormSection1b").style.display = 'inline';	// input file types selection, at left. [FASTA only]
					document.getElementById("hiddenFormSection1c").style.display = 'none';          // input file types selection, at left. [WGseq, long-reads only]
					document.getElementById("hiddenFormSection2").style.display  = 'none';		//      description of input file types, at right.
					document.getElementById("hiddenFormSection3").style.display  = 'inline';	// reference genome selection, at left.
					document.getElementById("hiddenFormSection4").style.display  = 'inline';	//      description of reference genomes, at right.
					document.getElementById("hiddenFormSection5").style.display  = 'none';		// restriction enzyme selection, at left. [ddRADseq only]
					document.getElementById("hiddenFormSection6").style.display  = 'none';		//      description of restriction enzymes, at right. [ddRADseq only]
					document.getElementById("hiddenFormSection7").style.display  = 'inline';	// hapmap selection, at left.
					document.getElementById("hiddenFormSection8").style.display  = 'inline';	//      description of hapmap, at right.
					document.getElementById("hiddenFormSection9").style.display  = 'inline';	// parent selection, at right.
					document.getElementById("hiddenFormSection10").style.display = 'inline';	//      description of parent as SNP control, at right.
					document.getElementById("hiddenFormSection11").style.display = 'none';		//      description of parent as CNV control, at right. [ddRADseq only]
					document.getElementById("hiddenFormSection12").style.display = 'none';		// checkbox for normalization options. [SnpCGH only]
					document.getElementById("hiddenFormSection13").style.display = 'none';		// checkbox for normalization options. [WGseq, FASTA]
					document.getElementById("hiddenFormSection14").style.display = 'none';		// checkbox for normalization options. [ddRADseq only]
					document.getElementById("hiddenFormSection15").style.display = 'none';		//      description of normalization options, at right.
				} else if (document.getElementById("dataFormat").value == 2) { // 2: WGseq (long-read)
					document.getElementById("hiddenFormSection1a").style.display = 'none';          // input file types selection, at left.
					document.getElementById("hiddenFormSection1b").style.display = 'none';		// input file types selection, at left. [FASTA only]
					document.getElementById("hiddenFormSection1c").style.display = 'inline';	// input file types selection, at left. [WGseq, long-reads only]
					document.getElementById("hiddenFormSection2").style.display  = 'inline';	//      description of input file types, at right.
					document.getElementById("hiddenFormSection3").style.display  = 'inline';	// reference genome selection, at left.
					document.getElementById("hiddenFormSection4").style.display  = 'inline';	//      description of reference genomes, at right.
					document.getElementById("hiddenFormSection5").style.display  = 'none';		// restriction enzyme selection, at left. [ddRADseq only]
					document.getElementById("hiddenFormSection6").style.display  = 'none';		//      description of restriction enzymes, at right. [ddRADseq only]
					document.getElementById("hiddenFormSection7").style.display  = 'inline';	// hapmap selection, at left.
					document.getElementById("hiddenFormSection8").style.display  = 'inline';	//      description of hapmap, at right.
					document.getElementById("hiddenFormSection9").style.display  = 'inline';	// parent selection, at right.
					document.getElementById("hiddenFormSection10").style.display = 'inline';	//      description of parent as SNP control, at right.
					document.getElementById("hiddenFormSection11").style.display = 'none';		//      description of parent as CNV control, at right. [ddRADseq only]
					document.getElementById("hiddenFormSection12").style.display = 'none';		// checkbox for normalization options. [SnpCGH only]
					document.getElementById("hiddenFormSection13").style.display = 'inline';	// checkbox for normalization options. [WGseq, FASTA]
					document.getElementById("hiddenFormSection14").style.display = 'none';		// checkbox for normalization options. [ddRADseq only]
					document.getElementById("hiddenFormSection15").style.display = 'inline';	//      description of normalization options, at right.
				} else { // 1,3: WGseq or ddRADseq (short-reads)
					document.getElementById("hiddenFormSection1a").style.display = 'inline';		// input file types selection, at left.
					document.getElementById("hiddenFormSection1b").style.display = 'none';			// input file types selection, at left. [FASTA only]
					document.getElementById("hiddenFormSection1c").style.display = 'none';			// input file types selection, at left. [WGseq, long-reads only]
					document.getElementById("hiddenFormSection2").style.display  = 'inline';		//      description of input file types, at right.
					document.getElementById("hiddenFormSection3").style.display  = 'inline';		// reference genome selection, at left.
					document.getElementById("hiddenFormSection4").style.display  = 'inline';		//      description of reference genomes, at right.
					if (document.getElementById("dataFormat").value == 1) { // 1: WGseq
						document.getElementById("hiddenFormSection5").style.display  = 'none';		// restriction enzyme selection, at left. [ddRADseq only]
						document.getElementById("hiddenFormSection6").style.display  = 'none';		//      description of restriction enzymes, at right. [ddRADseq only]
					} else if (document.getElementById("dataFormat").value == 2) { // 2: ddRADseq
						document.getElementById("hiddenFormSection5").style.display  = 'inline';
						document.getElementById("hiddenFormSection6").style.display  = 'inline';
					}
					document.getElementById("hiddenFormSection7").style.display  = 'inline';		// hapmap selection, at left.
					document.getElementById("hiddenFormSection8").style.display  = 'inline';		//      description of hapmap, at right.
					document.getElementById("hiddenFormSection9").style.display  = 'inline';		// parent selection, at right.
					document.getElementById("hiddenFormSection10").style.display = 'inline';		//      description of parent as SNP control, at right.
					if (document.getElementById("dataFormat").value == 1) { // 1: WGseq
						document.getElementById("hiddenFormSection11").style.display = 'none';          //      description of parent as CNV control, at right. [ddRADseq only]
					} else if (document.getElementById("dataFormat").value == 2) { // 2: ddRADseq
						document.getElementById("hiddenFormSection11").style.display = 'inline';
					}
					document.getElementById("hiddenFormSection12").style.display = 'none';			// checkbox for normalization options. [SnpCGH only]
					if (document.getElementById("dataFormat").value == 1) { // 1: WGseq
						document.getElementById("hiddenFormSection13").style.display = 'inline';	// checkbox for normalization options. [WGseq, FASTA]
						document.getElementById("hiddenFormSection14").style.display = 'none';		// checkbox for normalization options. [ddRADseq only]
					} else if (document.getElementById("dataFormat").value == 3) { // 2: ddRADseq
						document.getElementById("hiddenFormSection13").style.display = 'none';
						document.getElementById("hiddenFormSection14").style.display = 'inline';
					}
					document.getElementById("hiddenFormSection15").style.display = 'inline';		//      description of normalization options, at right.
				}
			}
			UpdateHapmap=function() {
				if (document.getElementById("dataFormat").value == 0) {			// SnpCgh microarray.
					document.getElementById("hiddenFormSection10").style.display = 'none';
					document.getElementById("hiddenFormSection11").style.display = 'none';
				} else if (document.getElementById("dataFormat").value == 3) {		// ddRADseq.
					document.getElementById("hiddenFormSection10").style.display = 'none';
					document.getElementById("hiddenFormSection11").style.display = 'inline';
				} else {								// WGseq or FASTA.
					document.getElementById("hiddenFormSection10").style.display = 'inline';
					document.getElementById("hiddenFormSection11").style.display = 'none';
				}
			}
			UpdateBiasWG=function() {
				if (document.getElementById("1_bias4").checked)
				{
					document.getElementById("1_bias2").disabled = true;
					document.getElementById("1_bias2").checked = true;
				}
				else
				{
					document.getElementById("1_bias2").disabled = false;
					document.getElementById("1_bias2").checked = true;
				}
			}
			</script>
		</p></div>
	</body>
</html>
