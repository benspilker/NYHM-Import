<?php

include 'DBConn.php';

try {
    $conn = OpenCon();
    echo "Connected Successfully";
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}

$res = $conn->query("SELECT * FROM `z5Z7XTD_users` where `flag_DeleteNetwork` = 1");
while ($row = $res->fetch_assoc()) {
    $id = $row['ZTID'];
    $preurl = 'https://my.zerotier.com/api/network/';
    $posturl = $preurl . $id;
        
    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $posturl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');


    $headers = array();
    $headers[] = 'Accept: application/json';
    $headers[] = 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq';
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    $result = curl_exec($ch);
    if (curl_errno($ch)) {
        echo 'Error:' . curl_error($ch);
    }
    curl_close ($ch);

    $wb = "SELECT `id` FROM `z5Z7XTD_users` WHERE `ZTID` = \"$id\"";
    $res2 = $conn->query($wb);
    $row2 = $res2->fetch_assoc();
    $uid = $row2['id'];
    $wb = "DELETE FROM `z5Z7XTD_bp_xprofile_data` WHERE `user_id` = \"$uid\" AND `field_id` = 13";
    $conn->query($wb);
    $wb = "UPDATE `z5Z7XTD_users` SET `ZTID` = NULL, `flag_NetworkCreated` = 0, `flag_DeleteNetwork` = 0 WHERE `ZTID` = \"$id\"";
    $conn->query($wb);
}
CloseCon($conn);
/*
$id = '83048a06327b807f';
$preurl = 'https://my.zerotier.com/api/network/';
$posturl = $preurl . $id;
    
$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, $posturl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');


$headers = array();
$headers[] = 'Accept: application/json';
$headers[] = 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq';
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

$result = curl_exec($ch);
if (curl_errno($ch)) {
    echo 'Error:' . curl_error($ch);
}
curl_close ($ch);
*/
?>
