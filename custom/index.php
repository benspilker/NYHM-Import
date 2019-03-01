<?php

include 'DBConn.php';

try {
    $conn = OpenCon();
    echo "Connected Successfully";
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}

$res = $conn->query("SELECT ZTID FROM `z5Z7XTD_users` WHERE user_login = 'rpowell20'");
echo "Result set order...\n";
while ($row = $res->fetch_assoc()) {
    echo " id = " . $row['ZTID'] . "\n";
}
CloseCon($conn);

?>