<?php
	session_start();
	error_reporting(E_ALL);
	require_once 'constants.php';
	require_once 'sharedFunctions.php';
	require_once 'POST_validation.php';
	ini_set('display_errors', 1);

	// Sanitize input strings.
	$user    = sanitize_POST("user");
	$pw_in   = stripHTML_POST("pw");

	// Delays login processing if prior login failure.
	if (isset($_SESSION['delay'])) {
		sleep(intval($_SESSION['delay']));
	}

	// Define delay after loging processing.
	$delay_interval = "2000";

	// Validate login.
	$login_success = validateLogin($user, $pw_in);

	// Delay before page reload.
	if ($login_success == 0) {
		// login failed.
		$_SESSION['delay'] = 5;
		echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
		echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
	} else {
		// login succeded.

		// check if user is active before logging stuff.
		if (file_exists($users_dir.$user."locked.txt")) {
			$_SESSION['delay'] = 0;
			echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
			echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
		} else if (file_exists($users_dir.$user."active.txt")) {
			$_SESSION['delay'] = 0;
			echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
			echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
		} else {
			// Error state.
			$_SESSION['delay'] = 0;
			echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
			echo "var intervalID = window.setInterval(reload_page, 1000);\n</script>\n";
		}
	}


//=========================================================
// Functions used to validate login credentials.
//---------------------------------------------------------
	function validateLogin($user, $pw_in){
		global $pepper;
		if (file_exists("users/".$user."/")) {
			// User exists, so we check password.

			// Check if user account is locked.
			if (file_exists("users/".$user."/locked.txt")) {
				log_stuff($user,"","","","","LOGIN fail: locked account.");
				// Account is locked pending admin approval.
				$_SESSION['error'] = "<font color=\"red\"><b>ERROR: Account is temporarily locked pending admin approval.</b></font><br>\n";
				$_SESSION['delay'] = 5;
				echo "<font color=\"red\"><b>ERROR: Account is temporarily locked pending admin approval.</b></font><br>\n";
				echo "This may happen because account was newly registered or other issues.</br>\n";
				echo "(Main page will reload shortly...)<br>\n";
				echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
				echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";

				// Set login_success to 1 to prevent password failure delay.
				$login_success = 1;
			} else if (file_exists("users/".$user."/active.txt")) {
				// Account is active.

				// Load stored password hash.
				$pwFile         = "users/".$user."/pw.txt";
				$pw_stored_hash = file_get_contents($pwFile);

				// Compare peppered input password to stored hash.
				$checked = password_verify($pw_in.$pepper, $pw_stored_hash);
				if ($checked) {
					log_stuff($user,"","","","","LOGIN success: logged in.");
					$_SESSION['logged_on'] = 1;
					$_SESSION['user']      = $user;
					echo "<font color=\"green\"><b>SUCCESS: User is now logged in.</b></font><br>\n";
					echo "(Main page will reload shortly...)<br>\n";
					echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
					echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
					$login_success = 1;
				} else {
					log_stuff($user,"","","","","LOGIN fail: wrong password.");
					//password mismatch.
					$_SESSION['error'] = "<font color=\"red\" size=\"2\"><b>ERROR: Input did not match a registered username & password combination.</b></font><br>\n";
					$_SESSION['delay'] = 5;
					echo "<font color=\"red\"><b>ERROR: Input did not match a registered username & password combination.</b></font><br>\n";
					echo "(Main page will reload shortly...)<br>\n";
					echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
					echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
					$login_success = 0;
				}
			} else {
				// error state.
				log_stuff($user,"","","","","LOGIN fail: user account missing both locked.txt and active.txt files.");
				//password mismatch.
				$_SESSION['error'] = "<font color=\"red\" size=\"2\"><b>ERROR: Input did not match a registered username & password combination.</b></font><br>\n";
				$_SESSION['delay'] = 5;
				echo "<font color=\"red\"><b>ERROR: Input did not match a registered username & password combination.</b></font><br>\n";
				echo "(Main page will reload shortly...)<br>\n";
				echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
				echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
				$login_success = 0;
			}
		} else {
			log_stuff($user,"","","","","LOGIN fail: unregistered user.");
			//User doesn't exist
			$_SESSION['error'] = "<font color=\"red\" size=\"2\"><b>ERROR: Input did not match a registered username & password combination.</b></font><br>\n";
			$_SESSION['delay'] = 5;
			echo "<font color=\"red\"><b>ERROR: Input did not match a registered username & password combination.</b></font><br>\n";
			echo "(Main page will reload shortly...)<br>\n";
			echo "<script type=\"text/javascript\">\nreload_page=function() {\n\tlocation.replace(\"panel.user.php\");\nparent.update_interface();\n}\n";
			echo "var intervalID = window.setInterval(reload_page, ".$delay_interval.");\n</script>\n";
			$login_success = 0;
		}
		return $login_success;
	}
?>
