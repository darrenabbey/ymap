<?php
session_start();
require_once 'constants.php';
require_once 'sharedFunctions.php';

$user = $_SESSION['user'];
log_stuff("",$user,"","","","","LOGOUT success");

session_destroy();
?>
<script type="text/javascript">
    parent.update_interface_after_logout();
	parent.location.reload();
</script>
