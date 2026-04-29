<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){ ?> <script type="text/javascript"> parent.reload(); </script> <?php }
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	echo "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";

	if (isset($_SESSION['logged_on'])) {
		if(isset($_SESSION['user'])) {
			$user   = $_SESSION['user'];
		} else {
			$user = "";
		}
		// getting the current size of the user folder in Gigabytes
		$currentSize = getUserUsageSize($user);
		// getting user quota in Gigabytes
		$quota_ = getUserQuota($user);
		if ($quota_ > $quota) {   $quota = $quota_;   }
		// Setting boolean variable that will indicate whether the user has exceeded it's allocated space, if true the button to add new dataset will not appear
		$exceededSpace = $quota > $currentSize ? FALSE : TRUE;
		if ($exceededSpace) {
			echo "<span style='color:#FF0000; font-weight: bold;'>You have exceeded your quota (".$quota."G). ";
			echo "Clear space by deleting/minimizing projects or wait until datasets finish processing before building a new hapmap.</span><br><br>";
		}
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
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
	<BODY onload="UpdateProjectList()">
		<div id="hapmapCreationInformation"><p>
			<form action="scripts_seqModules/scripts_hapmaps/hapmap.install_1.php" method="post">
				<table><tr bgcolor="#CCFFCC"><td>
					<label for="hapmap">Hapmap Name : </label><input type="text" name="hapmap" id="hapmap">
				</td><td>
					Unique name for this hapmap.
				</td></tr><tr bgcolor="#CCCCFF"><td>
					<label for="genome">Reference Diploid Genome : </label><select name="genome" id="genome" onchange="UpdateProjectList()">
		<?php
	if (!$user == "") {
		$genomesDir1    = "users/default/genomes/";
		$genomesDir2    = "users/".$user."/genomes/";
		$genomeFolders1 = array_diff(glob($genomesDir1."*"), array('..', '.'));
		$genomeFolders2 = array_diff(glob($genomesDir2."*"), array('..', '.'));
		foreach($genomeFolders1 as $key=>$folder) {   $genomeFolders1[$key] = str_replace($genomesDir1,"",$folder);   }
		foreach($genomeFolders2 as $key=>$folder) {   $genomeFolders2[$key] = str_replace($genomesDir2,"",$folder);   }
		$genomeFolders  = array_merge($genomeFolders1,$genomeFolders2);
		sort($genomeFolders);   //sort alphabetical.
		foreach ($genomeFolders as $key=>$genome) {
			echo "\n\t\t\t\t\t<option value='".$genome."'>".$genome."</opction>";
		}
	}
		?>
					</select><br>
				</td><td valign="top">
					Reference genome used to construct hapmap.
				</td></tr><tr bgcolor="#CCCCFF"><td>
					<label for="HapmapSetupOption">Construct a hapmap from </label>
					<select name="HapmapSetupOption" id="HapmapSetupOption" onchange="UpdateForm();">
					<option value="2">one diploid</option>
					<option value="1">two haploid</option>
					</select>
					<label for="HapmapSetupOption"> strain(s).</label>
				</td><td>
					Two options to define the SNPs of a hapmap.<br>
					1. One heterozygous diploid and derived strains with homozygous regions.<br>
					2. Two haploids (or homozygous diploids).<br>
				</td></tr><tr bgcolor="#CCFFCC"><td>
					<div id="hiddenFormSection1" style="display:inline">
<?php
	if (!$user == "") {
		// figure out which projects have been defined for this species, if any.
		$projectsDir1       = "users/default/projects/";
		$projectsDir2       = "users/".$user."/projects/";
		$projectFolders1    = array_diff(glob($projectsDir1."*"), array('..', '.'));
		$projectFolders2    = array_diff(glob($projectsDir2."*"), array('..', '.'));
		$projectFolders_raw = array_merge($projectFolders1,$projectFolders2);
		// Go through each $projectFolder and look at 'genome.txt' and 'dataFormat.txt'; build javascript array of projectName:genome:dataFormat triplets.

		// figure out which hapmaps have been defined for this species, if any.
		$hapmapsDir1       = "users/default/hapmaps/";
		$hapmapsDir2       = "users/".$user."/hapmaps/";
		$hapmapFolders1    = array_diff(glob($hapmapsDir1."*"), array('..', '.'));
		$hapmapFolders2    = array_diff(glob($hapmapsDir2."*"), array('..', '.'));
		$hapmapFolders_raw = array_merge($hapmapFolders1,$hapmapFolders2);
		// Go through each $hapmapFolder and look at 'genome.txt'; build javascript array of hapmapName:genome doublets.
	}
?>


<script type="text/javascript">
var projectGenomeDataFormat_entries = [['project','genome','dataFormat']<?php
	if (!$user == "") {
		foreach ($projectFolders_raw as $key=>$folder) {
			if (!str_contains($folder, "index.php")) {
				$genome_filename = $folder."/genome.txt";
				$genome_string = "";
				if (file_exists($genome_filename)) {
					// Some datasets don't have a reference genome (e.g., SnpCgh arrays).
					$handle1         = fopen($genome_filename, "r");
					$genome_string   = trim(fgets($handle1));
					fclose($handle1);
				}
				$handle2         = fopen($folder."/dataFormat.txt", "r");
				$dataFormat_string = trim(fgets($handle2));
				$dataFormat_string = explode(":",$dataFormat_string);
				$dataFormat_string = $dataFormat_string[0];
				fclose($handle2);
				$projectName     = $folder;
				$projectName     = str_replace($projectsDir1,"",$projectName);
				$projectName     = str_replace($projectsDir2,"",$projectName);
				echo ",['{$projectName}','{$genome_string}',{$dataFormat_string}]";
			}
		}
	}
?>];
var hapmapGenomeDataFormat_entries = [['hapmap','genome']<?php
	if (!$user == "") {
		foreach ($hapmapFolders_raw as $key=>$folder) {
			if (!str_contains($folder, "index.php")) {
				$genome_filename = $folder."/genome.txt";
				$genome_string = "";
				if (file_exists($genome_filename)) {
					$handle1         = fopen($genome_filename, "r");
					$genome_string   = trim(fgets($handle1));
					fclose($handle1);
				}
				$hapmapName     = $folder;
				$hapmapName     = str_replace($hapmapsDir1,"",$hapmapName);
				$hapmapName     = str_replace($hapmapsDir2,"",$hapmapName);
				echo ",['{$hapmapName}','{$genome_string}']";
			}
		}
	}
?>];
function UpdateProjectList() {
	var selectedGenome   = document.getElementById("genome").value;		// grab genome.
	var select           = document.getElementById("parent");		// grab select_list to add entries to.
	select.innerHTML     = '';
	for (var i = 1; i < projectGenomeDataFormat_entries.length; i++) {
		var item = projectGenomeDataFormat_entries[i];
		if ((item[1] == selectedGenome) && (item[2] == 1 || item[2] == 2 || item[2] == 4)) {
			var el         = document.createElement("option");
			el.textContent = item[0];
			el.value       = item[0];
			select.appendChild(el);
		}
	}

	var select           = document.getElementById("child");
	select.innerHTML     = '';
	for (var i = 1; i < projectGenomeDataFormat_entries.length; i++) {
		var item = projectGenomeDataFormat_entries[i];
		if ((item[1] == selectedGenome) && (item[2] == 1 || item[2] == 2 || item[2] == 4)) {
			var el         = document.createElement("option");
			el.textContent = item[0];
			el.value       = item[0];
			select.appendChild(el);
		}
	}

	var select           = document.getElementById("parentHaploid1");
	select.innerHTML     = '';
	for (var i = 1; i < projectGenomeDataFormat_entries.length; i++) {
		var item = projectGenomeDataFormat_entries[i];
		if ((item[1] == selectedGenome) && (item[2] == 1 || item[2] == 2 || item[2] == 4)) {
			var el         = document.createElement("option");
			el.textContent = item[0];
			el.value       = item[0];
			select.appendChild(el);
		}
	}

	var select           = document.getElementById("parentHaploid2");
	select.innerHTML     = '';
	for (var i = 1; i < projectGenomeDataFormat_entries.length; i++) {
		var item = projectGenomeDataFormat_entries[i];
		if ((item[1] == selectedGenome) && (item[2] == 1 || item[2] == 2 || item[2] == 4)) {
			var el         = document.createElement("option");
			el.textContent = item[0];
			el.value       = item[0];
			select.appendChild(el);
		}
	}

	var select           = document.getElementById("parentHapmap");
	select.innerHTML     = '';
	for (var i = 1; i < hapmapGenomeDataFormat_entries.length; i++) {
		var item = hapmapGenomeDataFormat_entries[i];
		if (selectedGenome == item[1]) {
			var el         = document.createElement("option");
			el.textContent = item[0];
			el.value       = item[0];
			select.appendChild(el);
		}
	}

	var select           = document.getElementById("derived");
	select.innerHTML     = '';
	for (var i = 1; i < projectGenomeDataFormat_entries.length; i++) {
		var item = projectGenomeDataFormat_entries[i];
		if ((item[1] == selectedGenome) && (item[2] == 1 || item[2] == 2 || item[2] == 4)) {
			var el         = document.createElement("option");
			el.textContent = item[0];
			el.value       = item[0];
			select.appendChild(el);
		}
	}
}
</script>
						Parental strain : <select id="parent" name="parent"><option>[choose]</option></select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection2" style="display:inline">
						Only whole genome sequence datasets are used in constructing hapmaps.
					</div>
				</td></tr><tr bgcolor="#CCCCFF"><td valign="top">
					<div id="hiddenFormSection3" style="display:inline">
						First strain : <select id="child" name="child"><option>[choose]</option></select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection4" style="display:inline">
						The first dataset used to construct the hapmap. (Others can be added later...)<br>
						Each strain used to construct the hapmap should have large loss of heterozygosity regions.
					</div>
<!-- second option. -->
				</td></tr><tr bgcolor="#CCFFCC"><td valign="top">
					<div id="hiddenFormSection5" style="display:none">
						Parental strain 1 : <select id="parentHaploid1" name="parentHaploid1"><option>[choose]</option></select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection6" style="display:none">
						Only whole genome sequence datasets are used in constructing hapmaps.<br>
						This strain will form haplotype 'a'.
					</div>
				</td></tr><tr bgcolor="#CCCCFF"><td valign="top">
					<div id="hiddenFormSection7" style="display:none">
						Parental strain 2 : <select id="parentHaploid2" name="parentHaploid2"><option>[choose]</option></select>
					</div>
				</td><td valign="top">
					<div id="hiddenFormSection8" style="display:none">
						This strain will form haplotype 'b'.
					</div>

				</td></tr></table><br>
	<?php
	if (!$user == "") {
		if (!$exceededSpace) {
			echo "<input type='submit' value='Create New Hapmap'>";
		}
	}
	?>
			</form>
		</p></div>
	</body>
</html>

<script type="text/javascript">
function UpdateForm() {
	if (document.getElementById("HapmapSetupOption").value == 2) {
		// One diploid parent strain and one or more derived strains with homozygous regions.
		document.getElementById("hiddenFormSection1").style.display   = 'inline';
		document.getElementById("hiddenFormSection2").style.display   = 'inline';
		document.getElementById("hiddenFormSection3").style.display   = 'inline';
		document.getElementById("hiddenFormSection4").style.display   = 'inline';
		document.getElementById("hiddenFormSection5").style.display   = 'none';
		document.getElementById("hiddenFormSection6").style.display   = 'none';
		document.getElementById("hiddenFormSection7").style.display   = 'none';
		document.getElementById("hiddenFormSection8").style.display   = 'none';
		document.getElementById("hiddenFormSection9").style.display   = 'none';
		document.getElementById("hiddenFormSection10").style.display  = 'none';
		document.getElementById("hiddenFormSection11").style.display  = 'none';
		document.getElementById("hiddenFormSection12").style.display  = 'none';
	} else if (document.getElementById("HapmapSetupOption").value == 1) {
		// Two haploid strains.
		document.getElementById("hiddenFormSection1").style.display   = 'none';
		document.getElementById("hiddenFormSection2").style.display   = 'none';
		document.getElementById("hiddenFormSection3").style.display   = 'none';
		document.getElementById("hiddenFormSection4").style.display   = 'none';
		document.getElementById("hiddenFormSection5").style.display   = 'inline';
		document.getElementById("hiddenFormSection6").style.display   = 'inline';
		document.getElementById("hiddenFormSection7").style.display   = 'inline';
		document.getElementById("hiddenFormSection8").style.display   = 'inline';
		document.getElementById("hiddenFormSection9").style.display   = 'none';
		document.getElementById("hiddenFormSection10").style.display  = 'none';
		document.getElementById("hiddenFormSection11").style.display  = 'none';
		document.getElementById("hiddenFormSection12").style.display  = 'none';
	}
}
</script>
