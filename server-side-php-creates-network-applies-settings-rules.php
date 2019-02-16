#!/usr/bin/env php
<?php

$email = 'test15';
$passcode ='1234';

$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, 'https://my.zerotier.com/api/network');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"id\":\"\" , \"description\":\"$passcode\" , \"config\":{\"name\":\"$email\"}}");
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

$resultdec = json_decode($result,true);
$id = $resultdec['id'];
$preurl = 'https://my.zerotier.com/api/network/';
$posturl = $preurl . $id;

$ch = curl_init();

curl_setopt($ch, CURLOPT_URL, $posturl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"config\": {\"enableBroadcast\":true, \"ipAssignmentPools\":[{\"ipRangeStart\":\"172.22.172.1\" , \"ipRangeEnd\":\"172.22.172.5\"}] , \"tags\":[] , \"v4AssignMode\":{\"zt\":true},\"v6AssignMode\":{\"6plane\":false,\"rfc4193\":false,\"zt\":false}}}");
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
curl_setopt($ch, CURLOPT_POSTFIELDS, "{\"rulesSource\":\"drop not ethertype ipv4 and not ethertype arp; drop sport 1-4999; drop dport 1-4999; drop sport 5009-5352; drop dport 5009-5352; drop sport 5354-5960; drop dport 5354-5960; drop sport 5962-5999; drop dport 5962-5999; drop sport 6006-20807; drop dport 6006-20807; drop sport 20809-49151; drop dport 20809-49151; accept;\"}");

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

?>