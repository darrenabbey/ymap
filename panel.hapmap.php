<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){?> <script type="text/javascript"> parent.reload(); </script> <?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
?>
<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
<font size='3'>Use NGS datasets to construct a haplotype map.</font><br><br>
<script type="text/javascript">
function showColors(colorName,targetToChange,contentString) {
	if (document.getElementById(targetToChange)) {
		var select       = document.getElementById(targetToChange);
		select.innerHTML = '';
		fillerString     = '<div style=\"width:35px; height:20px; overflow:hidden; display:inline-block; background-color:';
		if        (colorName == "deep pink")       { fillerString = fillerString + 'rgb(255,0  ,127)';
		} else if (colorName == "magenta")         { fillerString = fillerString + 'rgb(255,0  ,255)';
		} else if (colorName == "electric indigo") { fillerString = fillerString + 'rgb(127,0  ,255)';
		} else if (colorName == "blue")            { fillerString = fillerString + 'rgb(0  ,0  ,255)';
		} else if (colorName == "dodger blue")     { fillerString = fillerString + 'rgb(0  ,127,255)';
		} else if (colorName == "cyan")            { fillerString = fillerString + 'rgb(0  ,255,255)';
		} else if (colorName == "spring green")    { fillerString = fillerString + 'rgb(0  ,255,127)';
		} else if (colorName == "green")           { fillerString = fillerString + 'rgb(0  ,255,0  )';
		} else if (colorName == "chartreuse")      { fillerString = fillerString + 'rgb(127,255,0  )';
		} else if (colorName == "yellow")          { fillerString = fillerString + 'rgb(255,255,0  )';
		} else if (colorName == "dark orange")     { fillerString = fillerString + 'rgb(255,127,0  )';
		} else if (colorName == "red")             { fillerString = fillerString + 'rgb(255,0  ,0  )';
		} else { fillerString = fillerString + 'rgb(127,127,127)';
		}
		fillerString     = fillerString + '\"><center><b>' + contentString + '</b></center></div>';
		select.innerHTML = fillerString;
	}
}
</script>
<?php
	if (isset($_SESSION['logged_on'])) {
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota = getUserQuota($user);
		// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
		$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
		if ($exceededSpace) {
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (".$quota."G). ";
			echo "Clear space by deleting/minimizing projects or wait until datasets finish processing before building a new hapmap.</span><br><br>";
		}
	}
?>
<table width="100%" cellpadding="0"><tr valign="top">
<td width="50%">
	<?php
	if (isset($_SESSION['user']) != 0) {
		$hapmapsDir    = "users/".$user."/hapmaps/";
		$hapmapFolders = array_diff(glob($hapmapsDir."*"), array('..', '.'));
		// Sort directories by date, newest first.
		array_multisort(array_map('filemtime', $hapmapFolders), SORT_DESC, $hapmapFolders);
		// Trim path from each folder string.
		foreach($hapmapFolders as $key=>$folder) {   $hapmapFolders[$key] = str_replace($hapmapsDir,"",$folder);   }
		// displaying size if it's bigger then 0
		if ($currentSize > 0)
			echo "<b><font size='2'>User generated hapmaps: (currently using " . $currentSize . "G of " . $quota . "G)</font></b>\n\t\t\t\t";
		else
			echo "<div class='hapmap'><b><font size='2' >User generated hapmaps:</font></b><br>\n\t\t";
		// show generate new hapmap button only if user has space
		if (!$exceededSpace) {
			echo "<input name='button_GenerateNewHapmap' type='button' value='Generate New Hapmap' onclick='";
				echo "parent.document.getElementById(\"Hidden_GenerateNewHapmap_Frame\").contentWindow.location.reload(); ";
				echo "parent.show_hidden(\"Hidden_GenerateNewHapmap\"); ";
				echo "parent.update_interface();";
			echo "'>\n\t\t";
		}

		foreach($hapmapFolders as $key=>$hapmap) {
			echo "<div class='tab'><table><tr><td>\n\t\t\t\t";

			// Check status of existing hapmap folders: initial html differs for each.
			if (file_exists("users/".$user."/hapmaps/".$hapmap."/complete.txt")) {
				echo "<span id='h_label_".$key."' style='color:#00AA00;'>";
			} else if (file_exists("users/".$user."/hapmaps/".$hapmap."/working.txt")) {
				echo "<span id='h_label_".$key."' style='color:#BB9900;'>";
			} else if (is_dir("users/".$user."/hapmaps/".$hapmap)) {
				echo "<span id='h_label_".$key."' style='color:#CC0000;'>";
			}

			if (is_dir("users/".$user."/hapmaps/".$hapmap)) {
				echo "<button id='hapmap_delete_".$key."' type='button' onclick=\"parent.deleteHapmapConfirmation('".$user."','".$hapmap."','".$key."')\">Delete</button>\n\t\t";
				echo "<font size='2'>".getHapmapName($user,$hapmap)."</font></span></td><td>\n\t\t\t\t";
				echo "<span id='h_delete_".$key."'></span>\n\t\t\t\t";

				echo "<td><div id='userHapmapA_".$key."'  >[a]</div></td>\n\t\t\t\t";
				echo "<td><div id='userHapmapHET_".$key."'>[ab]</div></td>\n\t\t\t\t";
				echo "<td><div id='userHapmapB_".$key."'  >[b]</div></td>\n\t\t\t\t";
				echo "<td><div id='userHapmapHOM_".$key."'>[hom]</div></td></tr></table>\n\t\t\t\t";
				echo "<div id='frameContainer.h_".$key."'></div></div>\n\t\t\t\t";

				echo "<script type='text/javascript'>\n\t\t\t\t";
				echo "var el_h_".$key." = document.getElementById('frameContainer.h_".$key."');\n\t\t\t\t";
				echo "function hapmap_UI_refresh_1_".$key."() {\n\t\t\t\t";
				echo "    var frameString3 = '<iframe id=\"h_".$key."\" name=\"h_".$key."\" class=\"upload\" style=\"height:38px\" src=\"hapmap.addTo.php?k=".$key."\"';\n\t\t\t\t";
				echo "    var frameString4 = ' marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n\t\t\t\t";
				echo "    var frameString5 = '<iframe id=\"h2_".$key."\" name=\"h2_".$key."\" class=\"upload\" style=\"height:38px\" src=\"hapmap.finalize.php?k=".$key."\"';\n\t\t\t\t";
				echo "    var frameString6 = '  marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n\t\t\t\t";
				echo "    el_h_".$key.".innerHTML = frameString3.concat(frameString4,frameString5,frameString6);\n\t\t\t\t";
				echo "var h_iframe           = document.getElementById('h_".$key."');\n\t\t\t\t";
				echo "var h_js               = h_iframe.contentWindow;\n\t\t\t\t";
				echo "h_js.hapmap            = '".$hapmap."';\n\t\t\t\t";
				echo "h_js.user              = '".$user."';\n\t\t\t\t";
				echo "h_js.key               = 'h_".$key."';\n\t\t\t\t";
				echo "var h2_iframe           = document.getElementById('h2_".$key."');\n\t\t\t\t";
				echo "var h2_js               = h2_iframe.contentWindow;\n\t\t\t\t";
				echo "h2_js.hapmap           = '".$hapmap."';\n\t\t\t\t";
				echo "h2_js.user             = '".$user."';\n\t\t\t\t";
				echo "h2_js.key              = 'h2_".$key."';\n\t\t\t\t";
				echo "}\n\t\t\t\t";
				echo "function hapmap_UI_refresh_2_".$key."() {\n\t\t\t\t";
				echo "    var frameString1 = '<iframe id=\"h_".$key."\" name=\"h_".$key."\" class=\"upload\" src=\"hapmap.working.php\" ';\n\t\t\t\t";
				echo "    var frameString2 = 'marginwidth=\"0\" marginheight=\"0\" vspace=\"0\" hspace=\"0\" width=\"100%\" frameborder=\"0\"></iframe>';\n\t\t\t\t";
				echo "    el_h_".$key.".innerHTML = frameString1.concat(frameString2);\n\t\t\t\t";
				echo "var h_iframe           = document.getElementById('h_".$key."');\n\t\t\t\t";
				echo "var h_js               = h_iframe.contentWindow;\n\t\t\t\t";
				echo "h_js.hapmap            = '".$hapmap."';\n\t\t\t\t";
				echo "h_js.user              = '".$user."';\n\t\t\t\t";
				echo "h_js.key               = 'h_".$key."';\n\t\t\t\t";
				echo "}\n\t\t\t\t";
			} else {
				echo "</tr></table>\n\t\t\t\t";
			}

			// Check status of existing hapmap folders: final html differs for each.
			if (file_exists("users/".$user."/hapmaps/".$hapmap."/complete.txt")) {
				// No user interface required.
			} elseif (file_exists("users/".$user."/hapmaps/".$hapmap."/working.txt")) {
				// The hapmap is being processed.
				// Load 'hapmap.working.php' into an internal frame 'h_$key'.
				echo "hapmap_UI_refresh_2_".$key."();\n\t\t\t\t";
			} else if (is_dir("users/".$user."/hapmaps/".$hapmap)) {
				echo "hapmap_UI_refresh_1_".$key."();\n\t\t\t\t";
			}
			echo "</script>\n\t\t\t\t";
		}
	}?>
	</div>
</td><td width="50%">
	<br>
	<?php
	$hapmapsDir          = "users/default/hapmaps/";
	$systemHapmapFolders = array_diff(glob($hapmapsDir."*"), array('..', '.'));
	// Sort directories by date, newest first.
	array_multisort(array_map('filemtime', $systemHapmapFolders), SORT_DESC, $systemHapmapFolders);
	// Trim path from each folder string.
	foreach($systemHapmapFolders as $key=>$folder) {   $systemHapmapFolders[$key] = str_replace($hapmapsDir,"",$folder);   }
	echo "<div class='hapmap'><b><font size='2'>System hapmaps:</font></b>\n\t\t\t\t";
	foreach ($systemHapmapFolders as $key=>$hapmap) {
		if (is_dir("users/default/hapmaps/".$hapmap)) {
			echo "<div class='tab'><table><tr><td><font size='2'>".getHapmapName($user,$hapmap)."</font></td>\n\t\t\t\t";
			echo "<td><div id='defaultHapmapA_".$key."'  >[a]</div></td>\n\t\t\t\t";
			echo "<td><div id='defaultHapmapHET_".$key."'>[ab]</div></td>\n\t\t\t\t";
			echo "<td><div id='defaultHapmapB_".$key."'  >[b]</div></td>\n\t\t\t\t";
			echo "<td><div id='defaultHapmapHOM_".$key."'>[hom]</div></td></tr></table>\n\t\t\t\t";
			echo "</div>\n\t\t\t\t";
		}
	}

	function getHapmapName($user,$hapmap) {
		// grab name.txt from hapmap.
		if ($hapmap != "") {
			$hapmapName_file1 = "users/".$user."/hapmaps/".$hapmap."/name.txt";
			$hapmapName_file2 = "users/default/hapmaps/".$hapmap."/name.txt";
			if (file_exists($hapmapName_file1)) {
				$handle      = fopen($hapmapName_file1,'r');
				$hapmap_name = trim(fgets($handle));
				fclose($handle);
			} else if (file_exists($hapmapName_file2)) {
				$handle      = fopen($hapmapName_file2,'r');
				$hapmap_name = trim(fgets($handle));
				fclose($handle);
			} else {
				$hapmap_name = $hapmap;
			}
		} else {
			$hapmap_name = "";
		}
		return $hapmap_name;
	}
	?>
</td></tr></table>

<script type="text/javascript">
// javascript which needs to run for the hapmap panel.
<?php
if (isset($_SESSION['user']) != 0) {
	$hapmapsDir    = "users/".$user."/hapmaps/";
	$hapmapFolders = array_diff(glob($hapmapsDir."*"), array('..', '.'));
	// Sort directories by date, newest first.
	array_multisort(array_map('filemtime', $hapmapFolders), SORT_DESC, $hapmapFolders);
	// Trim path from each folder string.
	foreach ($hapmapFolders as $key=>$folder) {
		$hapmapFolders[$key] = str_replace($hapmapsDir,"",$folder);
	}
	foreach ($hapmapFolders as $key=>$hapmap) {
		if ($hapmap != "index.php") {
			$filename = "users/".$user."/hapmaps/".$hapmap."/colors.txt";
			if (!file_exists($filename)) {
				continue;
			}
			$handle       = fopen($filename, 'r');
			$colorString1 = trim(fgets($handle));
			$colorString2 = trim(fgets($handle));
			fclose($handle);
			echo "\t\tshowColors('".$colorString1."','userHapmapA_".$key."','a');\n";
			echo "\t\tshowColors('grey','userHapmapHET_".$key."','ab');\n";
			echo "\t\tshowColors('".$colorString2."','userHapmapB_".$key."','b');\n";
			echo "\t\tshowColors('red','userHapmapHOM_".$key."','hom');\n\n";
		}
	}
}
$hapmapsDir          = "users/default/hapmaps/";
$systemHapmapFolders = array_diff(glob($hapmapsDir."*"), array('..', '.'));
// Sort directories by date, newest first.
array_multisort(array_map('filemtime', $systemHapmapFolders), SORT_DESC, $systemHapmapFolders);
// Trim path from each folder string.
foreach ($systemHapmapFolders as $key=>$folder) {
	$systemHapmapFolders[$key] = str_replace($hapmapsDir,"",$folder);
}
foreach ($systemHapmapFolders as $key=>$hapmap) {
	if ($hapmap != "index.php") {
		$handle       = fopen("users/default/hapmaps/".$hapmap."/colors.txt",'r');
		$colorString1 = trim(fgets($handle));
		$colorString2 = trim(fgets($handle));
		fclose($handle);
		echo "\t\tshowColors('".$colorString1."','defaultHapmapA_".$key."','a');\n";
		echo "\t\tshowColors('grey','defaultHapmapHET_".$key."','ab');\n";
		echo "\t\tshowColors('".$colorString2."','defaultHapmapB_".$key."','b');\n";
		echo "\t\tshowColors('red','defaultHapmapHOM_".$key."','hom');\n\n";
	}
}
?>
</script>
