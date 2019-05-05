<?php

include 'DBConn.php';

try {
    $conn = OpenCon();
    echo "Connected Successfully";
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}

$res = $conn->query("SELECT * FROM `z5Z7XTD_users` AS u INNER JOIN `z5Z7XTD_bp_xprofile_data` AS d ON u.id=d.user_id WHERE d.field_id=12 AND u.flag_EmailChange != 0");
while ($row = $res->fetch_assoc()) {
    $userid = $row['ID'];
    $id = $row['ZTID'];
    $preurl = 'https://my.zerotier.com/api/network/';
    $posturl = $preurl . $id;
    
    if ($row['flag_EmailChange'] == 1) {
        $email = $row['value'];

        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, $posturl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"config\":{\"name\":\"$email\"}}");
        curl_setopt($ch, CURLOPT_POST, 1);

        $headers = array();
        $headers[] = 'Accept: application/json';
        $headers[] = 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq';
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        $result = curl_exec($ch);
        if (curl_errno($ch)) {
            echo 'Error:' . curl_error($ch);
        }
        curl_close ($ch);

        $wb = "UPDATE `z5Z7XTD_users` SET `user_email` = \"$email\", `flag_EmailChange` = 0 WHERE `ID` = \"$userid\"";
        $conn->query($wb);
    }
    if ($row['flag_EmailChange'] == 2) {
        $email = $row['user_email'];

        $ch = curl_init();

        curl_setopt($ch, CURLOPT_URL, $posturl);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"config\":{\"name\":\"$email\"}}");
        curl_setopt($ch, CURLOPT_POST, 1);

        $headers = array();
        $headers[] = 'Accept: application/json';
        $headers[] = 'Authorization: Bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq';
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        $result = curl_exec($ch);
        if (curl_errno($ch)) {
            echo 'Error:' . curl_error($ch);
        }
        curl_close ($ch);

        $wb = "UPDATE `z5Z7XTD_bp_xprofile_data` SET `value` = \"$email\" WHERE `user_id` = \"$userid\" AND `field_id` = 12";
        $conn->query($wb);
        $wb = "UPDATE `z5Z7XTD_users` SET `flag_EmailChange` = 0 WHERE `ID` = \"$userid\"";
        $conn->query($wb);
    }
}
CloseCon($conn);

?>
