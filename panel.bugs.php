<?php
	session_start();
	if(!isset($_SESSION['logged_on'])){
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else if ($_SESSION['logged_on'] == 0) {
		?> <script type="text/javascript"> parent.reload(); </script> <?php
	} else {
		if(!isset($_SESSION['user'])){
			$user = "";
		} else {
			$user = $_SESSION['user'];
		}
	}
	if ($user == "") {   unset($_SESSION['logged_on']);   }

        require_once 'constants.php';
        require_once 'sharedFunctions.php';
?>

<style type="text/css">
	html * {
		font-family: arial !important;
	}
</style>
To report bugs, request features, ask for assistance, or otherwise get in touch, please e-mail us at <a href="mailto:<?php print($ADMIN_EMAIL); ?>"><?php print($ADMIN_EMAIL); ?></a>.
