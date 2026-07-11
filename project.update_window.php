<?php
	session_start();
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
	if(!isset($_SESSION['logged_on'])){
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else if ($_SESSION['logged_on'] == 0) {
		?> <script type="text/javascript"> parent.reload(); </script> <?php
        } else {
		$user = $_SESSION['user'];
	}
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';

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

		//======================
		// Find project folder.
		//----------------------
		$projectsDir      = "users/".$user."/projects/";
		$projectFolders = [];
                $objects = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($projectsDir), RecursiveIteratorIterator::SELF_FIRST);
                foreach($objects as $entry => $object){
                        if (is_dir($entry)) {
                                $name_ = str_replace($projectsDir,"",$entry);
                                if (str_contains($name_,"..") or str_contains($name_,".")) {
                                } else {
                                        $projectFolders[] = $name_;
                                }
                        }
                }
		sort($projectFolders);

		// Trim path from each folder string.
		foreach($projectFolders as $key_=>$folder) {   $projectFolders[$key_] = str_replace($projectsDir,"",$folder);   }

		// Split project list into ready/working/starting lists for sequential display.
		$projectFolders_subdir   = array();
		$projectFolders_starting = array();
		$projectFolders_working  = array();
		$projectFolders_complete = array();
		foreach($projectFolders as $project) {
			if (file_exists("users/".$user."/projects/".$project."/complete.txt")) {
				array_push($projectFolders_complete,$project);
			} else if (file_exists("users/".$user."/projects/".$project."/working.txt")) {
				array_push($projectFolders_working, $project);
			} else if (file_exists("users/".$user."/projects/".$project."/name.txt")) {
				array_push($projectFolders_starting,$project);
			} else {
				array_push($projectFolders_subdir,$project);
			}
		}
		sort($projectFolders_subdir);
		sort($projectFolders_starting);
		sort($projectFolders_working);
		sort($projectFolders_complete);

		// Figure out which projects are in subdirs.
		$displayed_entries = [];
		foreach($projectFolders_subdir as $key1_=>$subdir) {
			// bulk projects being worked on to user interface.
			foreach($projectFolders_working as $key_=>$project) {   if (str_contains($project,$subdir)) {   $displayed_entries[] = $project;   }   }

			// projects not yet started to user interface.
			foreach($projectFolders_starting as $key_=>$project) {   if (str_contains($project,$subdir)) {   $displayed_entries[] = $project;   }   }

			// completed projects to user interface.
			foreach($projectFolders_complete as $key_=>$project) {   if (str_contains($project,$subdir)) {   $displayed_entries[] = $project;   }   }
		}

		// Grab key from GET string.
		$key = sanitizeInt_GET("key");
		$key = intval($key);

		// Grab name string from 'name.txt'.
		$project                 = $projectFolders[$key];
		$projectNameString       = file_get_contents("users/".$user."/projects/".$project."/name.txt");
		$name                    = $projectNameString;

		// Grab old project group name.
		if (str_contains($project,'/')) {
			$pos   = strpos($project, '/');
			$group = substr($project, 0, $pos);
		} else {
			$group = "";
		}

		// Determine group key.
		sort($projectFolders_subdir);
		if (in_array($group, $projectFolders_subdir)) {
			$groupKey = array_search($group, $projectFolders_subdir)+1;
		} else {
			$groupKey = 0;
		}

		// Get group directory name, if selected.
		if ($groupKey == 0) {
			$group = "";
		} else {
			// Get list of projects.
			$projectsDir    = "users/".$user."/projects/";
			$projectFolders = [];
			$objects        = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($projectsDir), RecursiveIteratorIterator::SELF_FIRST);
			foreach($objects as $entry => $object){
				if (is_dir($entry)) {
					$name_ = str_replace($projectsDir,"",$entry);
					if (str_contains($name_,"..") or str_contains($name_,".")) {
					} else {
						$projectFolders[] = $name_;
					}
				}
			}
			sort($projectFolders);

                        // Get list of project groups.
                        $projectFolders_subdir = array();
                        foreach($projectFolders as $key=>$projectName) {
                                if (file_exists("users/".$user."/projects/".$projectName."/complete.txt")) {
                                } else if (file_exists("users/".$user."/projects/".$projectName."/bulk.txt")) {
                                } else if (file_exists("users/".$user."/projects/".$projectName."/working.txt")) {
                                } else if (file_exists("users/".$user."/projects/".$projectName."/name.txt")) {
                                } else {
                                        array_push($projectFolders_subdir,$projectName);
                                }
                        }
                        sort($projectFolders_subdir);

                        $group = $projectFolders_subdir[$groupKey-1]."/";
                }


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

		// Figure out parent project name.
		$parent                  = strip_tags(trim(file_get_contents("users/".$user."/projects/".$project."/parent.txt")));

		// Load existing bias correction options.
		//	False		fragment_length_bias (ddRADseq)
		//	True		GC-content_bias (WGseq, ddRADseq)
		//	False		[not used, leftover from previous?]
		//	True		chromosome_end_bias (WGseq, ddRADseq)
		if (file_exists("users/".$user."/projects/".$project."/dataBiases.txt")) {
			$array = file("users/".$user."/projects/".$project."/dataBiases.txt");
			foreach($array as $key => $line) {
				$dataBiasSelections[$key] = trim($line);
			}
			if ($dataBiasSelections[0] == "True") {   $bias1 = "checked";   } else {   $bias1 = "";   }
			if ($dataBiasSelections[1] == "True") {   $bias2 = "checked";   } else {   $bias2 = "";   }
			if ($dataBiasSelections[2] == "True") {   $bias3 = "checked";   } else {   $bias3 = "";   }
			if ($dataBiasSelections[3] == "True") {   $bias4 = "checked";   } else {   $bias4 = "";   }
		} else {
			$bias1 = "";
			$bias2 = "checked";
			$bias3 = "";
			$bias4 = "";
		}

		// Load existing figure selection options.
		//	Figures	[header]
		//	True		GC content bias figure.
		//	True		Chromosome end bias figure.
		//	False		Linear CNV map figure.
		//	False		Full CNV map figure.
		//	True		Linear high-top CNV map figure.
		//	False		Linear SNP/LOH map figure.
		//	False		Full SNP/LOH map figure.
		//	False		Linear alleleic ratio (fire-plot) map figure.
		//	True		Linear CNV/SNP/LOH map figure.
		//	True		Full CNV/SNP/LOH map figure.
		//	False		Linear CNV/SNP/LOH map figure with alternate color scheme.
		//	False		Full CNV/SNP/LOH map figure with alternate color scheme.
		if (file_exists("users/".$user."/projects/".$project."/figure_options.txt")) {
			$array = file("users/".$user."/projects/".$project."/figure_options.txt");
			foreach($array as $key => $line) {
				$figureOptionSelections[$key] = trim($line);
			}
			if ($figureOptionSelections[ 1] == "True") {   $fig_A1 = "checked";   } else {   $fig_A1 = "";   }
			if ($figureOptionSelections[ 2] == "True") {   $fig_A2 = "checked";   } else {   $fig_A2 = "disabled";   }
			if ($figureOptionSelections[ 3] == "True") {   $fig_B1 = "checked";   } else {   $fig_B1 = "";   }
			if ($figureOptionSelections[ 4] == "True") {   $fig_B2 = "checked";   } else {   $fig_B2 = "";   }
			if ($figureOptionSelections[ 5] == "True") {   $fig_C  = "checked";   } else {   $fig_C  = "";   }
			if ($figureOptionSelections[ 6] == "True") {   $fig_D1 = "checked";   } else {   $fig_D1 = "";   }
			if ($figureOptionSelections[ 7] == "True") {   $fig_D2 = "checked";   } else {   $fig_D2 = "";   }
			if ($figureOptionSelections[ 8] == "True") {   $fig_E  = "checked";   } else {   $fig_E  = "";   }
			if ($figureOptionSelections[ 9] == "True") {   $fig_F1 = "checked";   } else {   $fig_F1 = "";   }
			if ($figureOptionSelections[10] == "True") {   $fig_F2 = "checked";   } else {   $fig_F2 = "";   }
			if ($figureOptionSelections[11] == "True") {   $fig_G1 = "checked";   } else {   $fig_G1 = "";   }
			if ($figureOptionSelections[12] == "True") {   $fig_G2 = "checked";   } else {   $fig_G2 = "";   }
		} else {
			$fig_A1 = "";
			if ($bias4 == "") {	$fig_A2 = "disabled";	} else {	$fig_A2 = "";	}
			$fig_B1 = "";
			$fig_B2 = "";
			$fig_C  = "";
			$fig_D1 = "";
			$fig_D2 = "";
			$fig_E  = "";
			$fig_F1 = "";
			$fig_F2 = "";
			$fig_G1 = "";
			$fig_G2 = "";
		}
	} else {
		$genome				= "";
		$project			= "";
		$hapmap				= "";
		$parent				= "";
		$dataType			= 99;
		$readType			= 99;
		$exceededSpace			= true;
		$ploidy				= "2.0";
		$ploidy_baseline		= "2.0";
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
	<BODY onload="UpdateForm(); UpdateBiasWG();">
		<div id="loginControls"><p>
		</p></div>
		<div id="projectCreationInformation"><p>
			<form action="project.update_server.php" method="post">
				<table><tr bgcolor="#CCCCFF"><td>
					<label for="project">Dataset Name : </label><input type="text" name="project" id="project" value="<?php echo $project; ?>" readonly style="background-color:#CCFFCC">
				</td><td>
					Initial project name.
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<label for="name">Display Name : </label><input type="text" name="name"  id="name" value="<?php echo $name; ?>"><br>
				</td><td>
					Version of the project name to be used in figures.
				</td></tr>

				<tr bgcolor="#CCFFCC"><td>
                                        <div id="hiddenFormSection3" style="display:inline">
                                        <label for="groupKey">Dataset group : </label><select name="groupKey" id="groupKey">
                                        <?php
                                        // Output selection box options.
					if ($groupKey == 0) {
						echo "\n\t\t\t\t\t<option value='0' selected>[none]</option>";
					} else {
	                                        echo "\n\t\t\t\t\t<option value='0'>[none]</option>";
					}
                                        foreach ($projectFolders_subdir as $key => $groupName) {
						if ($key+1 == $groupKey) {
							echo "\n\t\t\t\t\t<option value='".($key+1)."' selected>".$groupName."</option>";
						} else {
							echo "\n\t\t\t\t\t<option value='".($key+1)."'>".$groupName."</option>";
						}
                                        }
                                        ?>
                                                </select><br>
                                        </div>
                                </td><td valign="top">
                                        Dataset group for this dataset to be placed in.
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
							else if ($dataType == 2) { echo "Whole genome NGS (long-reads)"; }
							else if ($dataType == 3) { echo "ddRADseq"; }
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
								if ($dataType == 2) {
									echo "long-reads; FASTQ/ZIP/GZ file.";
								} else {
									if ($readType == 0)      { echo "single-end short-reads; FASTQ/ZIP/GZ file."; }
									else if ($readType == 1) { echo "paired-end short-reads; FASTQ/ZIP/GZ files."; }
									else if ($readType == 2) { echo "SAM/BAM file."; }
									else if ($readType == 3) { echo "TXT file."; }
								}
							?>
							</option>
						</select><br>
					</div>
				</td><td>
					<div id="hiddenFormSection2" style="display:inline"></div>
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
						<label for="hapmap">Haplotype map : </label><select id="hapmap" name="hapmap" onchange="UpdateParent();">
						<option value="none">[None selected]</option>
						<?php
						// figure out which hapmaps have been defined, if any.
						$hapmapsDir1       = "users/default/hapmaps/";
						$hapmapsDir2       = "users/".$user."/hapmaps/";
						$hapmapFolders1    = array_diff(glob($hapmapsDir1."*"), array('..', '.'));
						$hapmapFolders2    = array_diff(glob($hapmapsDir2."*"), array('..', '.'));
						$hapmapFolders_raw = array_merge($hapmapFolders1,$hapmapFolders2);

						foreach ($hapmapFolders_raw as $key=>$folder) {
							$filename = $folder."/genome.txt";
							if (!file_exists($filename)) {
								continue;
							}
							$handle        = fopen($filename, "r");
							$genome_string = trim(fgets($handle));
							fclose($handle);
							if ($genome_string == $genome) {
								// only include hapmap if defined for current species.
								$hapmapName    = $folder;
								$hapmapName    = str_replace($hapmapsDir1,"",$hapmapName);
								$hapmapName    = str_replace($hapmapsDir2,"",$hapmapName);
								if ($hapmapName == $hapmap) {
									echo "\n\t\t\t\t\t<option value='".$hapmapName."' selected>".$hapmapName."</option>";
								} else {
									echo "\n\t\t\t\t\t<option value='".$hapmapName."'>".$hapmapName."</option>";
								}
							}
						}
						?>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection6" style="display:none"></div>
				</td></tr>
				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection7">
						<label for="parent">Parental strain : </label><select id="parent" name="parent" style="background-color:#CCFFCC">
						<?php
						echo "\n\t\t\t\t\t<option value='".$parent."'>".$parent."</option>";
						?>
						</select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection8a" style="display:inline"></div>
					<div id="hiddenFormSection8b" style="display:none"></div>
				</td></tr>

				<tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection9a" style="display:none">
						<!-- SnpCgh array --!>
						<input type="checkbox"      name="0_bias2" value="True" onchange="UpdateFigureSelections();" <?php echo $bias2; ?>>GC-content bias<br>
						<input type="checkbox"      name="0_bias4" value="True" onchange="UpdateBiasWG(); UpdateFigureSelections();" <?php echo $bias4; ?>>chromosome-end bias
					</div>
					<div id="hiddenFormSection9b" style="display:inline">
						<!-- WGseq --!>
						<input type="checkbox"      id="1_bias2" name="1_bias2" value="True" onchange="UpdateFigureSelections();" <?php echo $bias2; ?>>GC-content bias<br>
						<input type="checkbox"      id="1_bias4" name="1_bias4" value="True" onchange="UpdateBiasWG(); UpdateFigureSelections();" <?php echo $bias4; ?>>chromosome-end bias (forces using GC content bias)
					</div>
					<div id="hiddenFormSection9c" style="display:none">
						<!-- ddRADseq --!>
						<input type="checkbox"      name="2_bias1" value="True" <?php echo $bias1; ?>>fragment-length bias<br>
						<input type="checkbox"      name="2_bias2" value="True" onchange="UpdateFigureSelections();" <?php echo $bias2; ?>>GC-content bias<br>
						<input type="checkbox"      name="2_bias4" value="True" onchange="UpdateBiasWG(); UpdateFigureSelections();" <?php echo $bias4; ?>>chromosome-end bias
					</div>
				</td><td>
				GC% bias correction is almost always ideal.<br>
				Use chromosome-end correction with care. <font size='2'>(Chr end bias in data can potentially reveal structural changes which alter the distance between<br>
				a locus and a chromosome end vs in the reference genome. Correcting this bias can lead to confounding copy number artifacts in cases like this.)</font>
				</td></tr>
				<tr bgcolor="#FFFFCC"><td>
				<div id="hiddenFormSection9" style="display:inline">
					<input type="checkbox" id="fig_bias_1"      name="fig_A1" value="True" <?php echo $fig_A1; ?>><span id="label_bias_1" style="color:black">GC-content bias figure.</span><br>
					<input type="checkbox" id="fig_bias_2"      name="fig_A2" value="True" <?php echo $fig_A2; ?>><span id="label_bias_2" style="color:<?php if ($fig_A2 == "disabled") { echo "grey"; } else { echo "black"; } ?>">Chromosome-end bias figure.</span><br><br>

					<input type="checkbox" id="fig_Cnv_1"       name="fig_B1" value="True" <?php echo $fig_B1; ?>>Linear CNV map figure.<br>
					<input type="checkbox" id="fig_Cnv_2"       name="fig_B2" value="True" <?php echo $fig_B2; ?>>Full CNV map figure.<br>
					<input type="checkbox" id="fig_CnvHigh"     name="fig_C"  value="True" <?php echo $fig_C; ?>>Linear high-top CNV map figure.<br><br>

					<input type="checkbox" id="fig_Snp_1"       name="fig_D1" value="True" <?php echo $fig_D1; ?>>Linear SNP/LOH map figure.<br>
					<input type="checkbox" id="fig_Snp_2"       name="fig_D2" value="True" <?php echo $fig_D2; ?>>Full SNP/LOH map figure.<br>
					<input type="checkbox" id="fig_fireplot_2"  name="fig_E"  value="True" <?php echo $fig_E; ?>>Linear alleleic ratio (fire-plot) map figure.<br><br>

					<input type="checkbox" id="fig_CnvSnp_1"    name="fig_F1" value="True" <?php echo $fig_F1; ?>>Linear CNV/SNP/LOH map figure.<br>
					<input type="checkbox" id="fig_CnvSnp_2"    name="fig_F2" value="True" <?php echo $fig_F2; ?>>Full CNV/SNP/LOH map figure.<br>
					<input type="checkbox" id="fig_CnvSnpAlt_1" name="fig_G1" value="True" <?php echo $fig_G1; ?>>Linear CNV/SNP/LOH map figure with alternate color scheme.<br>
					<input type="checkbox" id="fig_CnvSnpAlt_2" name="fig_G2" value="True" <?php echo $fig_G2; ?>>Full CNV/SNP/LOH map figure with alternate color scheme.
				</div>
				</td><td>
				Select which figure types you would like generated for your dataset.
				</td></tr>

				</table><br>
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
					//document.getElementById("hiddenFormSection2a").style.display = 'none';
				//	document.getElementById("hiddenFormSection2b").style.display = 'none';
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
					//document.getElementById("hiddenFormSection2a").style.display = 'inline';
					//document.getElementById("hiddenFormSection2b").style.display = 'inline';
					document.getElementById("hiddenFormSection3").style.display  = 'inline';
					document.getElementById("hiddenFormSection4").style.display  = 'inline';
					document.getElementById("hiddenFormSection5").style.display  = 'inline';
					document.getElementById("hiddenFormSection6").style.display  = 'inline';
					document.getElementById("hiddenFormSection7").style.display  = '<?php echo ($hapmap == "" || $hapmap == "none") ? "inline" : "none"; ?>';
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
			UpdateParent=function() {
				if (document.getElementById("dataFormat").value != 0) {
					const hapmapEl = document.getElementById("hapmap");
					const sectionEl = document.getElementById("hiddenFormSection7");
					if (!hapmapEl || !sectionEl) return;

					if (hapmapEl.value === "none") {
						sectionEl.style.display = 'inline';
					} else {
						sectionEl.style.display = 'none';
					}
				}
			}
			UpdateBiasWG=function() {
				if (document.getElementById("1_bias4").checked) {
					document.getElementById("1_bias2").disabled = true;
					document.getElementById("1_bias2").checked = true;
				} else {
					document.getElementById("1_bias2").disabled = false;
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
