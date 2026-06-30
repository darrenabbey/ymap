<?php
	session_start();
	if(!isset($_SESSION['logged_on'])) {
		echo "<script type=\"text/javascript\"> parent.reload(); </script>";
	} else if ($_SESSION['logged_on'] == 0) {
		echo "<script type=\"text/javascript\"> parent.reload(); </script>";
	} else {
		$user = $_SESSION['user'];
	}
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
?>
<html lang="en">
<head>
	<style type="text/css">
		body {font-family: arial;}
	</style>
	<meta http-equiv="content-type" content="text/html; charset=utf-8">
	<title>[Needs Title]</title>
</head>
<body>
	<div id="genomeCreationInformation"><p>
<?php
	if (isset($_SESSION['logged_on']) and isset($_SESSION['user'])) {
		$user     = $_SESSION['user'];

		// Check if logged in user has admin rights.
		$admin_user_flag_file = "users/".$user."/admin.txt";
		if (file_exists($admin_user_flag_file)) {
			$admin = "true";
		} else {
			$admin = "false";
		}

		if (isset($_SESSION['genome']) and isset($_SESSION['key'])) {
			$genome   = $_SESSION['genome'];
			$key      = $_SESSION['key'];

			echo "<font color=\"black\" size=\"2\">The most recently uploaded genome is: <b>".$genome."</b><br> If you want to install multiple genomes at once, click a finalize button after each file upload.</font>";

			// Load chromosome count from genome directory;
			$chr_lengths_json = file_get_contents('users/'.$user.'/genomes/'.$genome.'/chr_lengths.json');
			$chr_names_json   = file_get_contents('users/'.$user.'/genomes/'.$genome.'/chr_names.json');
			$chr_lengths      = json_decode($chr_lengths_json, TRUE);
			$chr_names        = json_decode($chr_names_json, TRUE);
			$chr_count        = count($chr_names);

			// Some warning messages for genomes with many chromosomes/scaffolds.
			if (($chr_count > $MAX_CHROM_SELECTION) && ($chr_count <= $MAX_CHROM_POOL)) {
				echo "<font color=\"black\" size=\"2\">Ymap can only display up to " . $MAX_CHROM_SELECTION . " scaffolds.<br>The longest " . $MAX_CHROM_SELECTION ." have been automatically selected, though you can change the selection.</font>";
			} elseif ($chr_count > $MAX_CHROM_POOL) {
				echo "<font color=\"black\" size=\"2\">Ymap can only work with up to " . $MAX_CHROM_SELECTION . " scaffolds, and visualize only up to ". $MAX_CHROM_SELECTION .". The reference you uploaded had " . $chr_count . " scaffolds. The longest " . $MAX_CHROM_POOL . " are available for choosing and the longest " . $MAX_CHROM_SELECTION . " have been automatically selected, though you can change the selection in the form below.</font>";
			}

			// Check to see if "working2.txt" file exists. If so, don't generate form.
			if (file_exists('users/'.$user.'/genomes/'.$genome.'/working2.txt')) {
				echo "<br><br><font color=\"black\" size=\"2\">The most recently uploaded genome file is currently being finalized.</font><br>";
			} else {
				// Form to setup genome details.
				echo "<form name=\"chromSelect\" action=\"scripts_genomes/genome.install_2.php\" method=\"post\">";
				echo "<table border=\"0\">";
				echo "<tr>";
					echo "<th rowspan=\"2\"><font size=\"2\">Use</font></th>";
					echo "<th rowspan=\"2\"><font size=\"2\">FASTA entry name</font></th>";
					echo "<th rowspan=\"2\"><font size=\"2\">Label</font></th>";
					echo "<th colspan=\"2\"><font size=\"2\">Centromere</font></th>";
					echo "<th rowspan=\"2\"><font size=\"2\">rDNA</font></th>";
					echo "<th rowspan=\"2\"><font size=\"2\">Size(BP)</font></th>";
					echo "<th rowspan=\"2\"><font size=\"2\">Fig Order</font></th>";
					echo "<th rowspan=\"2\"><font size=\"2\">Reversed</font></th>";
				echo "</tr>";
				echo "<tr>";
					echo "<th><font size=\"2\">start bp</font></th>";
					echo "<th><font size=\"2\">end bp</font></th>";
				echo "</tr>";

				// If '$chr_count' is above $MAX_CHROM_SELECTION, sorting and returning the largest $MAX_CHROM_SELECTION chromosome sizes. To use as a reference whether to check or uncheck chromosomes also getting the size of the...?
				if ($chr_count > $MAX_CHROM_SELECTION) {
					$chr_lengthsTemp = $chr_lengths;
					rsort($chr_lengthsTemp);
					// getting cutoff value for the first $MAX_CHROM_SELECTION longest chromsomes
					$lowestSize = $chr_lengthsTemp[$MAX_CHROM_SELECTION - 1];
					if ($chr_count > $MAX_CHROM_POOL) {
						$lowestSizeDisplay = $chr_lengthsTemp[$MAX_CHROM_POOL - 1];
					}
					unset($chr_lengthsTemp);
					$countUsed = $MAX_CHROM_SELECTION;
				}
				for ($chr=0; $chr<$chr_count; $chr+=1) {
					$chrID = $chr+1;
					// in case we have to many chromsomes dispaying only the $MAX_CHROM_SELECTION longest ones, so jumping lower size chromosomes
					if ($chr_count > $MAX_CHROM_POOL && $chr_lengths[$chr] < $lowestSizeDisplay) {
						continue;
					}
					echo "\t\t<tr>\n";
					// disabling chromosomes with length of 0 from been checked
					if ($chr_lengths[$chr] == 0) {
						echo "\t\t\t<td align=\"middle\"><input type=\"checkbox\" class=\"draw_disabled\" name=\"draw_{$chrID}\" disabled></td>\n";
					} else if ($chr_count <= $MAX_CHROM_SELECTION) {
						echo "\t\t\t<td align=\"middle\"><input type=\"checkbox\" class=\"draw\" name=\"draw_{$chrID}\" checked></td>\n";
					} else {
						// checking only the $MAX_CHROM_SELECTION longest
						if ($chr_lengths[$chr] >= $lowestSize && $countUsed >= 1) {
							echo "\t\t\t<td align=\"middle\"><input type=\"checkbox\" class=\"draw\" name=\"draw_{$chrID}\" onchange=\"chromosomeCheck()\" checked></td>\n";
							// reduce the count of used to avoid checking more then $MAX_CHROM_SELECTION if multiple have the same size
							$countUsed -= 1;
						} else {
							echo "\t\t\t<td align=\"middle\"><input type=\"checkbox\" class=\"draw\" onchange=\"chromosomeCheck()\" name=\"draw_{$chrID}\" disabled></td>\n";
						}
				}
					echo "\t\t\t<td><font size=\"2\">{$chr_names[$chr]}</font></td>\n";
					echo "\t\t\t<td><input type=\"text\"     name=\"short_{$chrID}\"    value=\"Chr{$chrID}\" size=\"15\"maxlength=\"15\" ></td>\n";
					echo "\t\t\t<td><input type=\"text\"     name=\"cenStart_{$chrID}\" value=\"0\"           size=\"6\"></td>\n";
					echo "\t\t\t<td><input type=\"text\"     name=\"cenEnd_{$chrID}\"   value=\"0\"           size=\"6\"></td>\n";
					echo "\t\t\t<td align=\"middle\" ><input type=\"radio\"    name=\"rDNAchr\"      value=\"{$chrID}\"></td>\n";
					echo "\t\t\t<td><font size=\"2\">{$chr_lengths[$chr]}</font></td>\n";
					echo "\t\t\t<td><input type=\"text\"     name=\"chrFigOrder_{$chrID}\"   value=\"{$chrID}\"      size=\"4\"></td>\n";
					echo "\t\t\t<td align=\"middle\"><input type=\"checkbox\" class=\"draw\" name=\"reversed_{$chrID}\" unchecked></td>\n";
					echo "\t\t</tr>\n";
				}
				echo "</table><br>";
				echo "<font size=\"2\">";
				echo "Ploidy = <input type=\"text\" name=\"ploidy\" value=\"2.0\" size=\"6\"><br>";
				echo "rDNA (start = <input type=\"text\" name=\"rDNAstart\" value=\"0\" size=\"6\">; end = <input type=\"text\" name=\"rDNAend\" value=\"0\" size=\"6\">)<br>";
				echo "Further annotations to add to the genome? <input type=\"text\" name=\"annotation_count\" value=\"0\" size=\"6\"><br>";
				echo "</font><br>";

				// Optional figure types.
				if ($admin == "true") {
?>
<div style="background-color:#FFDDDD;">
<font color="black" size="2">
<b>ADMIN functions</b>
YMAP2 can generate a few different figures by analyzing the reference sequence.<br>
These do not depend on later uploading sequencing datasets; they characterize the reference sequence itself.<br>
Reduce figures to be generated for faster processing for general use.</font><br>
<table>
<tr bgcolor="#DDBBBB"><td>
<div id="hiddenFormSection9" style="display:inline">
<font color="black" size="2">
<input type="checkbox" id="fig_1" name="fig_1" value="True" checked><span id="label_fig_1" style="color:#000000">Repetitiveness map.</span><br>
<input type="checkbox" id="fig_2" name="fig_2" value="True" checked><span id="label_fig_2" style="color:#000000">GC-skew map.</span><br>
</font>
</div>
</td></tr></table></div><br>
<?php
				}

				echo "<input type=\"submit\" value=\"Save genome details...\">";
				echo "<input type=\"hidden\" id=\"key\" name=\"key\" value=\"".  $key . "\">";
				echo "</form>";
			}
		} else {
			echo "\t\tNot logged in.\n";
		}
	}
?>
	</p></div>
</body>
</html>

