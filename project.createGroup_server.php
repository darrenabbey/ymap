<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	ini_set('display_errors', 1);

	// If the user is not logged on, redirect to login page.
	if (!isset($_SESSION['logged_on'])) {
		session_destroy();
		header('Location: .');
	} else if ($_SESSION['logged_on'] == 0) {
		session_destroy();
		header('Location: .');
	}

	// Load user string from session.
	if(isset($_SESSION['user'])) {
		$user   = $_SESSION['user'];
	} else {
		$user = "";
	}

	if ($user == "") {
		log_stuff("","","","","","user:VALIDATION failure, session expired.");
		header('Location: .');
	} else {
		// Validate input strings.
		$group           = sanitize_POST("group");

		// Define some directories for later use.
		$projects_dir  = "users/".$user."/projects";
		$group_dir1    = "users/".$user."/projects/".$group;
		$group_dir2    = "users/default/projects/".$group;

		// Deals with accidental deletion of user/projects dir.
		if (!file_exists($projects_dir)){
			mkdir($projects_dir);
			secureNewDirectory($projects_dir);
			chmod($projects_dir,0777);
		}

		if (file_exists($group_dir1) || file_exists($group_dir2)) {
			//=================================================
			// Project group directory already exists, so exit.
			//-------------------------------------------------
			echo "Project '".$group."' directory already exists.";

			log_stuff($user,$group,"","","","projectGroup:CREATE failure, group already exists.");
?>
	<html>
	<body>
	<script type="text/javascript">
	var el1 = parent.document.getElementById('Hidden_MakeNewFolder');
	el1.style.display = 'none';

	var el2 = parent.document.getElementById('panel_manageDataset_iframe').contentDocument.getElementById('name_error_comment');
	el2.style.visibility = 'visible';

	window.location = "project.createGroup_window.php";
	</script>
	</body>
	</html>
<?php
		} else {
			//=============================================================
			// Project group directory doesn't exist, go about creating it.
			//-------------------------------------------------------------

			// Create the project folder inside the user's projects directory
			mkdir($group_dir1);
			secureNewDirectory($group_dir1);
			chmod($group_dir1,0777);
			log_stuff($user,$group,"","","","projectGroup:CREATE success");
?>
	<html>
	<body>
	<script type="text/javascript">

	var el3 = parent.document.getElementById('panel_manageDataset_iframe').contentDocument.getElementById('name_error_comment');
        el3.style.visibility = 'hidden';

	var el4 = parent.document.getElementById('Hidden_MakeNewFolder');
	el4.style.display = 'none';

	window.location = "project.createGroup_window.php";

	// Refresh "projectsShown" string;
	parent.update_projectsShown_after_new_project();
	</script>
	</body>
	</html>
<?php
		}
	}
?>
