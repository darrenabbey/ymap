<?php
	session_start();
	require_once 'constants.php';
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">

<html lang="en">
	<head>
		<style type="text/css">
			body {font-family:  arial;}
			.tab { margin-left: 1cm;  }
		</style>
		<meta http-equiv="content-type" content="text/html; charset=utf-8">
		<title>Ymap | New User Registration</title>
	</head>
	<body>
		<b>New user registration.</b>
		<div class='tab' style='font-size:10pt'>
		</div>
		<div style='font-size:10pt'>
		<form action="user.register_server.php" method="post">
			<label for="primaryInvestigator_email">Email address: </label>              <input type="text"     id="primaryInvestigator_email" name="primaryInvestigator_email"><br>
			<label for="primaryInvestigator_name">Contact name: </label>                <input type="text"     id="primaryInvestigator_name"  name="primaryInvestigator_name"><br>
			<label for="researchInstitution">Institution: </label>                      <input type="text"     id="researchInstitution"       name="researchInstitution"><br>
			<div class='tab' style='font-size:10pt'>
			This information will only be used for system administration tasks, such as resetting passwords.<br>
			</div>
			<br>
			<label for="user">Username: </label>                                        <input type="text"     id="user"                      name="user"><br>
			<label for="pw1">Password: </label>                                         <input type="password" id="pwOrig"                    name="pwOrig"><br>
			<label for="pw2">Retype Password: </label>                                  <input type="password" id="pwCopy"                    name="pwCopy"><br>
			<input type="submit" value="Register User">
			<input type="button" value="Cancel" onclick="location.replace('panel.user.php');">
			<div class='tab' style='font-size:10pt'>
			User name must be between 6 and 24 alphanumeric characters only.<br>
			Password must meet the following criteria:<br>
			<div class='tab' style='font-size:10pt'>
			* Length between 8 and 64.<br>
			* Must include characters in at least three of the following categories:<br>
			<div class='tab' style='font-size:10pt'>
			1. Uppercase letters of European languages.<br>
			2. Lowercase letters of European languages.<br>
			3. Base 10 digis.<br>
			4. Non-alphanumeri characters: ~!@#$%^&*_-+=`|\(){}[]:;"'<>,.?/<br>
			</div>
			*  Must not include the user name or email.<br>
			</div>
			</div>
		</form>
		</div>
	</body>
</html>
