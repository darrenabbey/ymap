<?php
	session_start();
	require_once 'constants.php';
	if(!isset($_SESSION['logged_on'])){?><script type="text/javascript"> parent.reload(); </script><?php } else { $user = $_SESSION['user']; }
	require_once 'constants.php';

	// Call the bulk data processer and disconnect it from the browser.
	// php bulk_processer.php user=darren ymaps=5 > /dev/null 2>&1 &
	$system_call_string = "php bulk_processer.php user=".$user." ymaps=".$MAX_BULK_PARALLEL." > /dev/null 2>&1 &";
	echo getcwd();
	echo "<br>\n";
	echo $system_call_string;
	echo "<br>\n";
//	system($system_call_string, $null);

//	system("php bulk_processer.php", $retval);
//	val_dump($retval);
?>
<html>
<body onload="parent.reload();">
</body>
</html>