$email = Read-Host -Prompt 'Please input email account that you want to delete, then press enter'
$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
foreach ($network in $response) {
    if ($network.config.name -eq $email) {
	$network.config.id
        $ztid = $network.config.id
     }
 }

$uri1 = "https://my.zerotier.com/api/network/"
$uri2 = $uri1 + $ztid
Invoke-RestMethod -Uri $uri2 -Method delete -Headers $headers