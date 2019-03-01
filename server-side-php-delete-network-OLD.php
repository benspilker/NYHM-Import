<?php

$id - getopt("i:");
//$id = '83048a06327b807f';
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

?>
