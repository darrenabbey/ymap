
<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
	$user     = $_SESSION['user'];
	$genome   = $_SESSION['genome'];
	$key      = $_SESSION['key'];
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
			echo "</tr>";
			echo "<tr>";
				echo "<th><font size=\"2\">start bp</font></th>";
				echo "<th><font size=\"2\">end bp</font></th>";
			echo "</tr>";

		// if the chr_count is above $MAX_CHROM_SELECTION sorting and getting the size of the $MAX_CHROM_SELECTION chromosome to use as a reference whether to check or uncheck chromosomes
		// also getting the size of the
		if ($chr_count > $MAX_CHROM_SELECTION) {
			$chr_lengthsTemp = $chr_lengths;
			rsort($chr_lengthsTemp);
			// getting cutoff value for the $MAX_CHROM_SELECTION longest chromsomes
			$lowestSize = $chr_lengthsTemp[$MAX_CHROM_SELECTION - 1];
			if ($chr_count > $MAX_CHROM_POOL) {
				$lowestSizeDisplay = $chr_lengthsTemp[$MAX_CHROM_POOL - 1];
			}
			unset($chr_lengthsTemp);
			$countUsed = $MAX_CHROM_SELECTION; // will decrease for each checked chromosome
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
			echo "\t\t\t<td><input type=\"text\"     name=\"short_{$chrID}\"    value=\"Chr{$chrID}\" size=\"6\"maxlength=\"6\" ></td>\n";
			echo "\t\t\t<td><input type=\"text\"     name=\"cenStart_{$chrID}\" value=\"0\"           size=\"6\"></td>\n";
			echo "\t\t\t<td><input type=\"text\"     name=\"cenEnd_{$chrID}\"   value=\"0\"           size=\"6\"></td>\n";
			echo "\t\t\t<td align=\"middle\" ><input type=\"radio\"    name=\"rDNAchr\"      value=\"{$chrID}\"></td>\n";
			echo "\t\t\t<td><font size=\"2\">{$chr_lengths[$chr]}</font></td>\n";
			echo "\t\t</tr>\n";
		}

		echo "</table><br>";
		echo "<font size=\"2\">";
		echo "Ploidy = <input type=\"text\" name=\"ploidy\" value=\"2.0\" size=\"6\"><br>";
		echo "rDNA (start = <input type=\"text\" name=\"rDNAstart\" value=\"0\" size=\"6\">; end = <input type=\"text\" name=\"rDNAend\" value=\"0\" size=\"6\">)<br>";
		echo "Futher annotations to add to the genome? <input type=\"text\" name=\"annotation_count\" value=\"0\" size=\"6\"><br>";
		echo "Select <input type=\"checkbox\" name=\"expression_regions\"> if a tab-delimited-text file listing ORF coordinates is available.<br>";
		echo "</font>";
		echo "<br>";
		echo "<input type=\"submit\" value=\"Save genome details...\" onclick=\"parent.hide_hidden('Hidden_InstallNewGenome2')\">";
		echo "<input type=\"hidden\" id=\"key\" name=\"key\" value=\"".  $key . "\">";
		echo "</form>";
	}
?>
		</p></div>
	</body>
</html>
