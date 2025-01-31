<?php
	session_start();
	error_reporting(E_ALL);
        require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
        ini_set('display_errors', 1);

        // If the user is not logged on, redirect to login page.
        if(!isset($_SESSION['logged_on'])){
		session_destroy();
                header('Location: .');
        }
	if(isset($_SESSION['user'])) {
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// mini page loaded into frame when two files are to be uploaded.
?>
<!DOCTYPE html>
<!--[if lt IE 7]>      <html class="no-js lt-ie9 lt-ie8 lt-ie7"> <![endif]-->
<!--[if IE 7]>         <html class="no-js lt-ie9 lt-ie8"> <![endif]-->
<!--[if IE 8]>         <html class="no-js lt-ie9"> <![endif]-->
<!--[if gt IE 8]><!--> <html class="no-js"> <!--<![endif]-->
<head>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="css/normalize.css">     <!-- Normalizes cross-browser display differences.  --!>
    <link rel="stylesheet" href="css/style.css">         <!-- Normalizes cross-browser styling.              --!>
    <link rel="stylesheet" href="css/defaultTheme.css">  <!-- --!>
	<style type="text/css">
		.tab {
			margin-left:    1cm;
		}
	</style>
</head>
<BODY class="tab">
<!---------- Main section of User interface ----------!>
	<form id="fileupload" class="HTML5Uploader" method="POST" action="uploader/" enctype="multipart/form-data">
		<div class="upload-wrapper">
			<div id="1-wrapper">
			<table><tr>
			<!========= Initially visible UI element =========!>
			<!---------- Add file to upload button. ----------!>
			<td valign="top">
				<div id="select-wrapper" class="info-wrapper">
					<div id="browsebutton" class="fileinput-button button gray" href="">
						<script type="text/javascript">
							if (typeof genome !== 'undefined') {
								console.log("uploader.2.php : genome         = '"+genome+"'");
							} else {
								console.log("uploader.2.php : project        = '"+project+"'");
								console.log("uploader.2.php : dataFormat     = '"+dataFormat+"'");
							}
							console.log(        "uploader.2.php : key            = '"+key+"'");
							document.write(display_string[0]);
						</script>
						<input type="file" id="fileinput" name="files[]" class="fileinput" single onchange="Show2()">
					</div>
				</div>
			</td>
			<!====== Initially hidden UI elements ======!>
			<!---------- Start upload button. ----------!>
			<td valign="top">
				<div id="info-wrapper-1" class="info-wrapper" style="display: none; font-size: 10px;">
					<button id="start-button" class="button greenish" type="submit">Upload</button>
				</div>
			</td>
			<!---------- Upload name and status. ----------!>
			<td valign="top">
				<div id="info-wrapper-2" class="info-wrapper" style="display: none; font-size: 10px;">
					<ul id="files" class="files">
				</div>
			</td>
			<!---------- Time and Speed of upload. ----------!>
			<td valign="top">
				<div id="info-wrapper-3" class="info-wrapper" style="display: none; font-size: 10px;">
					<div title="Remaining time" class="time-info"><span>00:00:00</span></div>
					<div title="Uploading speed" class="speed-info">0 KB/s</div>
				</div>
			</td>
			</tr></table>
			</div>

			<div id="2-wrapper" style="display:none">
			<table><tr>
			<!---------- Add file to upload button. ----------!>
			<td valign="top">
				<div id="select-wrapper" class="info-wrapper">
					<div id="browsebutton" class="fileinput-button button gray" href="">
						<script type="text/javascript">document.write(display_string[1]);</script>
						<input type="file" id="fileinput" name="files[]" class="fileinput" single onchange="Show3()">
					</div>
				</div>
			</td>
			<!---------- Start upload button. ----------!>
			<td valign="top">
				<div id="info-wrapper-1" class="info-wrapper" style="display: none; font-size: 10px;">
					<button id="start-button" class="button greenish" type="submit">Upload</button>
				</div>
			</td>
			<!---------- Upload name and status. ----------!>
			<td valign="top">
				<div id="info-wrapper-2" class="info-wrapper" style="display: none; font-size: 10px;">
					<ul id="files" class="files">
				</div>
			</td>
			<!---------- Time and Speed of upload. ----------!>
			<td valign="top">
				<div id="info-wrapper-3" class="info-wrapper" style="display: none; font-size: 10px;">
					<div title="Remaining time" class="time-info"><span>00:00:00</span></div>
					<div title="Uploading speed" class="speed-info">0 KB/s</div>
				</div>
			</td>
			</tr></table>
			</div>

			<!---------- Pass along variables to be run once all files are loaded. ----------!>
			<input type="hidden" id="hidden_field2" name="target_genome"  value="">
			<input type="hidden" id="hidden_field3" name="target_project" value="">
			<script type="text/javascript">
				if (typeof genome !== 'undefined') {
					target_genome  = genome;
					target_project = "";
				} else {
					target_genome  = "";
					target_project = project;
				}
				document.getElementById('hidden_field2').value = target_genome;
				document.getElementById('hidden_field3').value = target_project;
				Show2=function() {
					document.getElementById("2-wrapper").style.display = 'inline';
					// hide upload buttons before all files are selected.
					document.getElementById("info-wrapper-1").style.display = 'none';
				}
				Show3=function() {
					document.getElementById("2-wrapper").style.display = 'none';
					// show upload button once all files are selected.
					document.getElementById("info-wrapper-1").style.display = 'inline';
				}
			</script>
		</div>
	</form>

<!---------- Script section ----------!>
	<script id="template-upload" type="text/x-handlebars-template">
		{{#each files}}
			<li class="file-item">
				<div class="first">
					<span class="top">
						<span class="filename">{{shortenName name}}</span>
					</span>
					{{#if error}}
					<div class="error">
						<span>Error: </span>
						<span>{{error}}</span>
					</div>
					{{/if}}
				</div>
				<div class="second">
					<span class="filesize">{{formatFileSize size}}</span>
					<div class="progress-wrap">
						<div class="progress">
							<div class="bar" style="width:0%"></div>
						</div>
					</div>
					<div class="clear"></div>
				</div>
			</li>
		{{/each}}
		document.write
	</script>

	<script>
		window.jQuery || document.write('<script src="js/jquery-3.6.3.js"><\/script>')
	</script>

	<!-- handlebars -->
	<script src="js/handlebars.min.js"></script>

	<!-- HTML5Uploader -->
	<script src="js/jquery.ui.widget.js"></script>
	<script src="js/bootstrap-transition.js"></script>
	<script src="js/jquery.iframe-transport.js"></script>
	<script src="js/jquery.fileupload.js"></script>
	<script src="js/jquery.fileupload-process.js"></script>
	<script src="js/jquery.fileupload-validate.js"></script>
	<script src="js/HTML5Uploader.js"></script>
	<script src="js/main.js"></script>

</body>
</html>
<?php
	}
?>
