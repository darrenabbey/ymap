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
	<BODY onload="UpdateHapmapList(); UpdateParentList();" bgcolor="FFCCCC">
		<div id="loginControls"><p>
		</p></div>
			<b>Bulk data has to have been previously loaded into a "bulkdata/" directory in the admin user account.<br>
			Once data processing settings have been made here, YMAP will automatically process through the datsets iteratively.</b>
		<div id="projectCreationInformation"><p>
			<form id="bulk_submit" action="project_bulk.create_server.php" method="post">

				<table><tr bgcolor="#FFFFCC"><td>
					<label for="project">Dataset Names : [automatic from filenames]</label>
				</td><td>
					Unique name for datasets are determined from file names found in the user's bulk data directory.
				</td></tr>
				<tr bgcolor="#FFCCFF"><td>
					<label for="ploidy">Ploidy of experiment : </label><input type="text" name="ploidy"  id="ploidy" value="2.0"><br>
				</td><td>
					A ploidy estimate for the strains being analyzed. Ploidy estimates can be updated per dataste later.
				</td></tr>
				<tr bgcolor="#FFFFCC"><td>
					<label for="ploidy">Baseline ploidy : </label><input type="text" name="ploidyBase"  id="ploidyBase" value="2.0"><br>
				</td><td>
					The copy number to use as a baseline in drawing copy number variations. Baseline copy number can be updated per dataset later.
				</td></tr>
				<tr bgcolor="#FFCCFF"><td>
					<label for="showAnnotations">Generate figure with annotations?</label><select name="showAnnotations" id="showAnnotations">
						<option value="1">Yes</option>
						<option value="0">No</option>
					</select>
				</td><td>
					Genome annotations, such as rDNA locus, can be drawn at bottom of figures.
				</td></tr>
				<tr bgcolor="#FFFFCC"><td>
					<label for="dataFormat">Data type : </label><select name="dataFormat" id="dataFormat" onchange="UpdateForm();">
						<option value="1" selected>Whole genome NGS (short-reads)</option>
					</select>
				</td><td>
					The type of data to be processed.
				</td></tr>
				<tr bgcolor="#FFCCFF"><td valign="top">
					<div id="hiddenFormSection1" style="display:inline">
						<label for="readType">Read type : [automatic from below types]<br>
							&emsp;&emsp;* single-end short-reads; FASTQ/ZIP/GZ file.<br>
							&emsp;&emsp;* paired-end short-reads; FASTQ/ZIP/GZ files.<br>
							&emsp;&emsp;* SAM/BAM file.<br>
					</div>
				</td><td>
					<div id="hiddenFormSection2" style="display:inline">
						Single-end or paired-end reads in FASTQ format can be compressed into ZIP or GZ archives or in SAM/BAM alignment files.<br>
						Paired-end data files must be compressed separately and must end with "_R1" and "_R2".
					</div>
				</td></tr>
				<tr bgcolor="#FFFFCC"><td>
					<div id="hiddenFormSection3" style="display:inline">
						<label for="genome">Reference genome : </label><select name="genome" id="genome" onchange="UpdateHapmapList();">
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
				<tr bgcolor="#FFCCFF"><td>
					<?php
					// figure out which hapmaps have been defined for this species, if any.
					$hapmapsDir1       = "users/default/hapmaps/";
					$hapmapsDir2       = "users/".$user."/hapmaps/";
					$hapmapFolders1    = array_diff(glob($hapmapsDir1."*"), array('..', '.'));
					$hapmapFolders2    = array_diff(glob($hapmapsDir2."*"), array('..', '.'));
					$hapmapFolders_raw = array_merge($hapmapFolders1,$hapmapFolders2);
					// Go through each $hapmapFolder and look at 'genome.txt'; build javascript array of hapmapName:genome pairs.
					?>
				</td></tr>
				<tr bgcolor="#FFCCFF"><td>
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
				<tr bgcolor="#FFFFCC"><td>
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
						Parental strain : [No parent strain for comparison.]
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
					Parental strain selection is not available for bulk analysis.<br>
					Initially process all datasets without, then later analyze individual datasets vs a parental strain will help visualize LOHs.
				</td></tr>
				<tr bgcolor="#FFCCFF"><td>
					<div id="hiddenFormSection8" style="display:inline">
						<input type="checkbox" id="1_bias2" name="1_bias2" value="True" onchange="UpdateFigureSelections();" checked        >GC-content bias<br>
						<input type="checkbox" id="1_bias4" name="1_bias4" value="True" onchange="UpdateBiasWG(); UpdateFigureSelections();">chromosome-end bias (forces using GC content bias)
					</div>
				</td><td>
				GC% bias correction is almost always ideal.<br>
				Use chromosome-end correction with care. <font size='2'>(Chr end bias in data can potentially reveal structural changes which alter the distance between<br>
				a locus and a chromosome end vs in the reference genome. Correcting this bias can lead to confounding copy number artifacts in cases like this.)</font>
				</td></tr>
				<tr bgcolor="#FFFFCC"><td>
					<div id="hiddenFormSection9" style="display:inline">
						<input type="checkbox" id="fig_bias_1"      name="fig_A1" value="True"><span id="label_bias_1" style="color:black">GC-content bias figure.</span><br>
						<input type="checkbox" id="fig_bias_2"      name="fig_A2" value="True" disabled><span id="label_bias_2" style="color:grey">Chromosome-end bias figure.</span><br><br>

						<input type="checkbox" id="fig_Cnv_1"       name="fig_B1" value="True">Linear CNV map figure.<br>
						<input type="checkbox" id="fig_Cnv_2"       name="fig_B2" value="True">Full CNV map figure.<br>
						<input type="checkbox" id="fig_CnvHigh"     name="fig_C"  value="True">Linear high-top CNV map figure.<br><br>

						<input type="checkbox" id="fig_Snp_1"       name="fig_D1" value="True">Linear SNP/LOH map figure.<br>
						<input type="checkbox" id="fig_Snp_2"       name="fig_D2" value="True">Full SNP/LOH map figure.<br>
						<input type="checkbox" id="fig_fireplot_2"  name="fig_E"  value="True">Linear alleleic ratio (fire-plot) map figure.<br><br>

						<input type="checkbox" id="fig_CnvSnp_1"    name="fig_F1" value="True" checked>Linear CNV/SNP/LOH map figure.<br>
						<input type="checkbox" id="fig_CnvSnp_2"    name="fig_F2" value="True">Full CNV/SNP/LOH map figure.<br>
						<input type="checkbox" id="fig_CnvSnpAlt_1" name="fig_G1" value="True">Linear CNV/SNP/LOH map figure with alternate color scheme.<br>
						<input type="checkbox" id="fig_CnvSnpAlt_2" name="fig_G2" value="True">Full CNV/SNP/LOH map figure with alternate color scheme.
					</div>
				</td><td>
				Select which figure types you would like generated for each of your datasets.<br><br>
				Reduce the number of figures to be generated to allow bulk processing to complete more quicklt.<br>
				Individual datasets can be reprocessed later to regenerate additional figures.
				</td></tr>
				</table><br>
				<?php
				if (!$exceededSpace) {
					echo "<input type='button' value='Initiate Bulk Dataset Processing' onclick='submit_func();'><br>";
					echo "<b>Form window will close when button is pressed.</b><br>";
					echo "<b>Main user interface will pause while projects are setup, but will then refresh.</b>";
				}
				?>
			</form>
			<script type="text/javascript">
				function submit_func(form) {
					parent.document.getElementById('Hidden_InstallBulkDataset').style.display = 'none';
					document.forms["bulk_submit"].submit();
				}
			</script>

			<script type="text/javascript">
			UpdateParent = function() {
				var selectedHapmap = document.getElementById("selectHapmap").value;
				if (selectedHapmap == 'none') {
					// If a hapmap is not selected, show the "parental strain" row of form.
					document.getElementById("hiddenFormSection7").style.display  = 'inline';
				} else {
					// If a hapmap is selected, hide the "parental strain" row of form.
					document.getElementById("hiddenFormSection7").style.display  = 'none';
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
				document.getElementById("hiddenFormSection1").style.display = 'inline';
				document.getElementById("hiddenFormSection2").style.display = 'inline';
				document.getElementById("hiddenFormSection3").style.display = 'inline';
				document.getElementById("hiddenFormSection4").style.display = 'inline';
				document.getElementById("hiddenFormSection5").style.display = 'inline';
				document.getElementById("hiddenFormSection6").style.display = 'inline';
				document.getElementById("hiddenFormSection7").style.display = 'inline';
				document.getElementById("hiddenFormSection8").style.display = 'inline';
				document.getElementById("hiddenFormSection9").style.display = 'inline';
			}
			UpdateBiasWG=function() {
				if (document.getElementById("1_bias4").checked)	{
					document.getElementById("1_bias2").disabled = true;
					document.getElementById("1_bias2").checked = true;
				} else 	{
					document.getElementById("1_bias2").disabled = false;
					document.getElementById("1_bias2").checked = true;
				}
			}
			UpdateFigureSelections=function() {
				if (document.getElementById("1_bias2").checked) {
					document.getElementById("fig_bias_1").disabled = false;
					document.getElementById("fig_bias_1").checked  = false;
					document.getElementById("label_bias_1").style.color="black";
				} else {
					document.getElementById("fig_bias_1").disabled = true;
					document.getElementById("fig_bias_1").checked  = false;
					document.getElementById("label_bias_1").style.color="grey";
				}
				if (document.getElementById("1_bias4").checked) {
					document.getElementById("fig_bias_2").disabled = false;
					document.getElementById("fig_bias_2").checked  = false;
					document.getElementById("label_bias_2").style.color="black";
				} else {
					document.getElementById("fig_bias_2").disabled = true;
					document.getElementById("fig_bias_2").checked  = false;
					document.getElementById("label_bias_2").style.color="grey";
				}
			}
			</script>
		</p></div>
	</body>
</html>
