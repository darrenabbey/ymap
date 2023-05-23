<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
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
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (".$quota."G) please clear space by deleting and/or minimizing projects and then reload to add new dataset.</span><br><br>";
		}
	}

	// Grab key from GET string.
	$key = sanitizeInt_GET("key");

	//======================
	// Find project folder.
	//----------------------
	$projectsDir      = "users/".$user."/projects/";
	$projectFolders   = array_diff(glob($projectsDir."*"), array('..', '.'));

	// Sort directories by date, newest first.
	array_multisort(array_map('filemtime', $projectFolders), SORT_DESC, $projectFolders);

	// Trim path from each folder string.
	foreach($projectFolders as $key_=>$folder) {   $projectFolders[$key_] = str_replace($projectsDir,"",$folder);   }

	// Split project list into ready/working/starting lists for sequential display.
	$projectFolders_complete = array();
	foreach($projectFolders as $project) {
		if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
			array_push($projectFolders_complete,$project);
		}
	}
	$userProjectCount_complete = count($projectFolders_complete);

	// Sort complete and working projects alphabetically.
	array_multisort($projectFolders_complete, SORT_ASC, $projectFolders_complete);

	// Grab name string from 'name.txt'.
	$project                 = $projectFolders_complete[$key];
	$projectNameString       = file_get_contents("users/".$user."/projects/".$project."/name.txt");
	$name                    = $projectNameString;

	// Grab genome and hapmap names from 'genome.txt'.
	$genomeFileStrings       = file_get_contents("users/".$user."/projects/".$project."/genome.txt");
	$genomeStrings           = preg_split("/\r\n|\n|\r/", $genomeFileStrings);
	$genome                  = $genomeStrings[0];
	$hapmap                  = $genomeStrings[1];

	// Grab ploidy strings from 'ploidy.txt'.
	$ploidyFileStrings       = file_get_contents("users/".$user."/projects/".$project."/ploidy.txt");
	$ploidyStrings           = preg_split("/\r\n|\n|\r/", $ploidyFileStrings);
	$ploidy                  = $ploidyStrings[0];
	$ploidy_baseline         = $ploidyStrings[1];

	// Grab data format numbers from 'dataFormat.txt'.
	$dataFileStrings         = file_get_contents("users/".$user."/projects/".$project."/dataFormat.txt");
	$dataStrings             = explode(":",$dataFileStrings);
	$dataType                = $dataStrings[0];
	$readType                = $dataStrings[1];
	$performIndelRealignment = $dataStrings[2];

	// Figure out parent project name.
	$parent                  = strip_tags(trim(file_get_contents("users/".$user."/projects/".$project."/parent.txt")));
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
	<BODY onload="UpdateForm();">
		<div id="loginControls"><p>
		</p></div>
		<div id="projectCreationInformation"><p>
			<form action="project.update_server.php" onsubmit="parent.document.getElementById('Hidden_UpdateDataset').style.display = 'none'; parent.update_projectsShown_after_new_project();" method="post">
				<table><tr bgcolor="#CCFFCC"><td>
					<label for="project">Dataset Name : </label><input type="text" name="project" id="project" value="<?php echo $project; ?>" readonly style="background-color:#CCFFCC">
				</td><td>
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
					<label for="ploidy">Ploidy of experiment : </label><input type="text" name="ploidy"  id="ploidy" value="<?php echo $ploidy; ?>"><br>
				</td><td>
					A ploidy estimate for the strain being analyzed.
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<label for="ploidy">Baseline ploidy : </label><input type="text" name="ploidyBase"  id="ploidyBase" value="<?php echo $ploidy_baseline; ?>"><br>
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
					<label for="dataFormat">Data type : </label><select name="dataFormat" id="dataFormat" style="background-color:#CCFFCC">
						<option value="<?php echo $dataType; ?>">
						<?php
							if ($dataType == 0)      { echo "SnpCgh microarray"; }
							else if ($dataType == 1) { echo "Whole genome NGS (short-reads)"; }
							else if ($dataType == 2) { echo "ddRADseq"; }
						?>
						</option>
					</select>
				</td><td>
				</td></tr>
				<tr bgcolor="#CCCCFF"><td valign="top">
					<div id="hiddenFormSection1" style="display:inline">
						<label for="readType">Read type : </label><select name="readType" id="readType" style="background-color:#CCCCFF">
							<option value="<?php echo $readType; ?>">
							<?php
								if ($readType == 0)      { echo "single-end short-reads; FASTQ/ZIP/GZ file."; }
								else if ($readType == 1) { echo "paired-end short-reads; FASTQ/ZIP/GZ files."; }
								else if ($readType == 2) { echo "SAM/BAM file."; }
								else if ($readType == 3) { echo "TXT file."; }
							?>
							</option>
						</select><br>
					</div>
				</td><td>
					<div id="hiddenFormSection2" style="display:inline"></div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection2a" style="display:inline">
						<input type="checkbox" name="indelrealign" value="<?php if ($performIndelRealignment == 0) { echo "False"; } else { echo "True"; } ?>" disabled="disabled">Perform Indel-realignment<br>
					</div>
				</td><td>
					<div id="hiddenFormSection2b" style="display:inline"></div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection3" style="display:inline">
						<label for="genome">Reference genome : </label><select name="genome" id="genome" readonly style="background-color:#CCFFCC">
						<?php echo "\n\t\t\t\t\t<option value='".$genome."'>".$genome."</option>"; ?>
						</select><br>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection4" style="display:inline"></div>
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
					<div id="hiddenFormSection10" style="display:none">
						Restriction enzymes :
						<select id="selectRestrictionEnzymes" name="selectRestrictionEnzymes" style="background-color:#CCCCFF">
						<option value="MfeI_MboI">MfeI & MboI</option>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection11" style="display:none"></div>
				</td></tr>
				<tr bgcolor="#CCCCFF"><td>
					<div id="hiddenFormSection5" style="display:inline">
						<label for="hapmap">Haplotype map : </label><select name="hapmap" id="hapmap" readonly style="background-color:#CCCCFF">
						<?php echo "\n\t\t\t\t\t<option value='".$hapmap."'>".$hapmap."</option>"; ?>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection6" style="display:inline"></div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection7" style="display:inline">
						<label for="parent">Parental strain : </label><select id="selectParent" name="selectParent" style="background-color:#CCFFCC">
						<?php echo "\n\t\t\t\t\t<option value='".$parent."'>".$parent."</option>"; ?>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection8a" style="display:inline"></div>
					<div id="hiddenFormSection8b" style="display:none"></div>
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
				a locus and a chromosome end vs in the reference genome. Correcting this bias can lead to confounding copy number artifacts in cases like this.)</font>
				</td></tr></table><br>
				<?php
				if (!$exceededSpace) {
					echo "<input type='submit' value='Regenerate Dataset Figures'>";
				}
				?>
			</form>

			<script type="text/javascript">
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
