<?php

function OpenCon()
 {
 $dbhost = "localhost:3306";
 $dbuser = "NYHM_admin";
 $dbpass = "Ch@ng3M3N0wP1s!!";
 $db = "unctrlablemusic_wordpress_6";
 $conn = new mysqli($dbhost, $dbuser, $dbpass,$db) or die("Connect failed: %s\n". $conn -> error);
 
 return $conn;
 }
 
function CloseCon($conn)
 {
 $conn -> close();
 }

?>