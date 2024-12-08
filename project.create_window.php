<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	if (isset($_SESSION['logged_on'])) {
		$user = $_SESSION['user'];
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota_ = getUserQuota($user);
		if ($quota_ > $quota) {   $quota = $quota_;   }
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
						<option value="2">ddRADseq                               </option>
					<!--	<option value="5">RADseq                                 </option> --!>
					</select>
				</td><td>
					The type of data to be processed.
				</td></tr>
				<tr bgcolor="#CCCCFF"><td valign="top">
					<div id="hiddenFormSection1" style="display:inline">
						<label for="readType">Read type : </label><select name="readType" id="readType">
							<option value="0">single-end short-reads; FASTQ/ZIP/GZ file.</option>
							<option value="1">paired-end short-reads; FASTQ/ZIP/GZ files.</option>
							<option value="2">SAM/BAM file.</option>
							<option value="3">TXT file.</option>
							</select><br>
					</div>
				</td><td>
					<div id="hiddenFormSection2" style="display:inline">
						Single-end or paired-end reads in FASTQ format can be compressed into ZIP or GZ archives or in SAM/BAM alignment files.<br>
						Tab-delimted TXT column format is described in 'About' tab of main page.
					</div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
                                        <div id="hiddenFormSection2a" style="display:inline">
                                                <input type="checkbox" name="indelrealign" value="False" disabled="disabled">Perform Indel-realignment <font color="red" size="2"><b>(Disabled, pending testing.)</b></font><br>
                                        </div>
				</td><td>
					<div id="hiddenFormSection2b" style="display:inline">
						Enable only if required, after testing without.<br>
						Disabled resulted in 1% spurious SNPs in test case, with no visual impact, but shortened analysis by ~3 hours.
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
					<div id="hiddenFormSection10" style="display:none">
						Restriction enzymes :
						<select id="selectRestrictionEnzymes" name="selectRestrictionEnzymes" onchange="UpdateParent();">
						<option value="MfeI_MboI">MfeI & MboI</option>
						<?php // <option value="BamHI_BclI">BamHI & BclI (testing)</option>
						?>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection11" style="display:none">
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
					<div id="hiddenFormSection5" style="display:inline">
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
					<div id="hiddenFormSection6" style="display:inline">
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
					<div id="hiddenFormSection7" style="display:inline">
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

								// Output found strings if parent project isn't minimized.
								if (!file_exists($folder."/minimized.txt")) {
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
					<div id="hiddenFormSection8a" style="display:inline">
						This strain will act as the SNP distribution control.<br>
						It is advised to initially process all datasets without changing this setting.<br>
						Later, setting a parental strain will help visualize LOHs.
					</div>
					<div id="hiddenFormSection8b" style="display:none">
						This strain will act as the CNV normalization control.
					</div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection9a" style="display:none">
						<!-- SnpCgh array --!>
						<input type="checkbox"      name="0_bias2" value="True" checked>GC-content bias<br>
						<input type="checkbox"      name="0_bias4" value="True"        >chromosome-end bias
					</div>
					<div id="hiddenFormSection9b" style="display:inline">
						<!-- WGseq --!>
						<input type="checkbox"      id="1_bias2" name="1_bias2" value="True" checked>GC-content bias<br>
						<input type="checkbox"      id="1_bias4" name="1_bias4" value="True"  onchange="UpdateBiasWG();"      >chromosome-end bias (forces using GC content bias)
					</div>
					<div id="hiddenFormSection9c" style="display:none">
						<!-- ddRADseq --!>
						<input type="checkbox"      name="2_bias1" value="True" checked>fragment-length bias<br>
						<input type="checkbox"      name="2_bias2" value="True" checked>GC-content bias<br>
						<input type="checkbox"      name="2_bias4" value="True"        >chromosome-end bias
					</div>
				</td><td>
				GC% bias correction is almost always ideal.<br>
				Use chromosome-end correction with care. <font size='2'>(Chr end bias in data can potentially reveal structural changes which alter the distance between<br>
				a locus and a chromosome end vs in the reference genome. Correcting this bias can lead to confounding copy number artifacts in such cases.)</font>
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
					document.getElementById("hiddenFormSection7" ).style.display  = 'inline';
					document.getElementById("hiddenFormSection8a").style.display  = 'inline';
					document.getElementById("hiddenFormSection8b").style.display  = 'none';
				} else {
					if (document.getElementById("dataFormat").value == 2) {    // ddRADseq.
						document.getElementById("hiddenFormSection7" ).style.display  = 'inline';
						document.getElementById("hiddenFormSection8a").style.display  = 'none';
						document.getElementById("hiddenFormSection8b").style.display  = 'inline';
					} else {
						document.getElementById("hiddenFormSection7" ).style.display  = 'none';
						document.getElementById("hiddenFormSection8a").style.display  = 'none';
						document.getElementById("hiddenFormSection8b").style.display  = 'none';
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
				if (document.getElementById("dataFormat").value == 0) { // SnpCgh Microarray.
					document.getElementById("hiddenFormSection1").style.display  = 'none';
					document.getElementById("hiddenFormSection2").style.display  = 'none';
					document.getElementById("hiddenFormSection2a").style.display = 'none';
					document.getElementById("hiddenFormSection2b").style.display = 'none';
					document.getElementById("hiddenFormSection3").style.display  = 'none';
					document.getElementById("hiddenFormSection4").style.display  = 'none';
					document.getElementById("hiddenFormSection5").style.display  = 'none';
					document.getElementById("hiddenFormSection6").style.display  = 'none';
					document.getElementById("hiddenFormSection7").style.display  = 'none';
					document.getElementById("hiddenFormSection9a").style.display = 'inline';
					document.getElementById("hiddenFormSection9b").style.display = 'none';
					document.getElementById("hiddenFormSection9c").style.display = 'none';
					document.getElementById("hiddenFormSection10").style.display = 'none';
					document.getElementById("hiddenFormSection11").style.display = 'none';
				} else { // WGseq or ddRADseq.
					document.getElementById("hiddenFormSection1").style.display  = 'inline';
					document.getElementById("hiddenFormSection2").style.display  = 'inline';
					document.getElementById("hiddenFormSection2a").style.display = 'inline';
					document.getElementById("hiddenFormSection2b").style.display = 'inline';
					document.getElementById("hiddenFormSection3").style.display  = 'inline';
					document.getElementById("hiddenFormSection4").style.display  = 'inline';
					document.getElementById("hiddenFormSection5").style.display  = 'inline';
					document.getElementById("hiddenFormSection6").style.display  = 'inline';
					document.getElementById("hiddenFormSection7").style.display  = 'inline';
					document.getElementById("hiddenFormSection10").style.display = 'none';
					document.getElementById("hiddenFormSection11").style.display = 'none';
					if (document.getElementById("dataFormat").value == 1) { // WGseq
						document.getElementById("hiddenFormSection9a").style.display = 'none';
						document.getElementById("hiddenFormSection9b").style.display = 'inline';
						document.getElementById("hiddenFormSection9c").style.display = 'none';
					} else if (document.getElementById("dataFormat").value == 2) { // ddRADseq
						document.getElementById("hiddenFormSection9a").style.display = 'none';
						document.getElementById("hiddenFormSection9b").style.display = 'none';
						document.getElementById("hiddenFormSection9c").style.display = 'inline';
						document.getElementById("hiddenFormSection10").style.display = 'inline';
						document.getElementById("hiddenFormSection11").style.display = 'inline';
					}
				}
			}
			UpdateHapmap=function() {
				if (document.getElementById("dataFormat").value == 0) {			// SnpCgh microarray.
					document.getElementById("hiddenFormSection8a").style.display = 'none';
					document.getElementById("hiddenFormSection8b").style.display = 'none';
				} else if (document.getElementById("dataFormat").value == 2) {	// ddRADseq.
					document.getElementById("hiddenFormSection8a").style.display = 'none';
					document.getElementById("hiddenFormSection8b").style.display = 'inline';
				} else {								// WGseq
					document.getElementById("hiddenFormSection8a").style.display = 'inline';
					document.getElementById("hiddenFormSection8b").style.display = 'none';
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
