<?php

include 'DBConn.php';

try {
    $conn = OpenCon();
    echo "Connected Successfully";
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}

$res = $conn->query("SELECT * FROM `z5Z7XTD_users` AS u INNER JOIN `z5Z7XTD_bp_xprofile_data` AS d ON u.id=d.user_id WHERE d.field_id=13 AND d.last_updated != d.cron_timecompare");
while ($row = $res->fetch_assoc()) {
    $id = $row['ZTID'];
    $preurl = 'https://my.zerotier.com/api/network/';
    $posturl = $preurl . $id;
    $passcode = $row['value'];
    $userlogin = $row['user_login'];
    $uid = $row['user_id'];

    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $posturl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"description\":\"$passcode\"}");
    curl_setopt($ch, CURLOPT_POST, 1);

    $headers = array();
    $headers[] = 'Content-Type: application/json';
    $headers[] = 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq';
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    $result = curl_exec($ch);
    if (curl_errno($ch)) {
        echo 'Error:' . curl_error($ch);
    }
    curl_close ($ch);

    $ch = curl_init();

    curl_setopt($ch, CURLOPT_URL, $posturl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"rulesSource\":\"drop not ethertype ipv4 and not ethertype arp; drop sport 1-4999; drop dport 1-4999; drop sport 5009-5352; drop dport 5009-5352; drop sport 5354-5960; drop dport 5354-5960; drop sport 5962-5999; drop dport 5962-5999; drop sport 6006-6959; drop dport 6006-6959; drop sport 6961-20807; drop dport 6961-20807; drop sport 20809-49151; drop dport 20809-49151; accept; #$userlogin:$passcode:$id\"}");

    curl_setopt($ch, CURLOPT_POST, 1);

    $headers = array();
    $headers[] = 'Content-Type: application/json';
    $headers[] = 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq';
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    $result = curl_exec($ch);
    if (curl_errno($ch)) {
        echo 'Error:' . curl_error($ch);
    }
    curl_close ($ch);

    $wb = "UPDATE `z5Z7XTD_bp_xprofile_data` SET `cron_timecompare` = `last_updated` WHERE `field_id` = 13 AND `user_id` = \"$uid\"";
    $conn->query($wb);
}
CloseCon($conn);

?>
