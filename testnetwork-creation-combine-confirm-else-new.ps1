$email = Read-Host -Prompt 'Please input your email, then press enter'
$email2 = Read-Host -Prompt 'Thanks, please input your email a 2nd time to confirm, then press enter'

If ($email -eq $email2){
Write-Output "Great, next step..."} Else {
Write-Output "Email entered does not match, please try again." ""}

While ($email -ne $email2) {
$email = Read-Host -Prompt 'Please input your email, then press enter'
$email2 = Read-Host -Prompt 'Thanks, please input your email a 2nd time to confirm, then press enter'

If ($email -eq $email2){
Write-Output "Great, next step..."} Else {
Write-Output "Email entered does not match, please try again." ""}
}


$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
foreach ($network in $response) {
    While ($network.config.name -eq $email) {
Write-Output "Sorry, the email you entered already has an existing account here, please enter a new email." ""

$email = Read-Host -Prompt 'Please input your email, then press enter'
$email2 = Read-Host -Prompt 'Thanks, please input your email a 2nd time to confirm, then press enter'

If ($email -eq $email2){
Write-Output "Great, next step..."} Else {
Write-Output "Email entered does not match, please try again." ""}


While ($email -ne $email2) {
$email = Read-Host -Prompt 'Please input your email, then press enter'
$email2 = Read-Host -Prompt 'Thanks, please input your email a 2nd time to confirm, then press enter'

If ($email -eq $email2){
Write-Output "Great, next step..."} Else {
Write-Output "Email entered does not match, please try again." ""}
}



}
} 

$pass= Read-Host -Prompt 'Create a 4 digit passcode. Something you can remember. Then press enter' -AsSecureString


 if ($pass.Length -eq 4) {
$proceed = "yes"
$passcompare = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
}


while ($proceed -ne "yes"){
Write-Output "Invalid entry..." ""
$pass= Read-Host -Prompt 'Create a 4 digit passcode. Something you can remember. Then press enter' -AsSecureString

    if ($pass.Length -eq 4) {
$proceed = "yes"
$passcompare = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
}
    }



$pass2= Read-Host -Prompt 'Thanks, please enter your 4 digit passcode again to confirm, then press enter' -AsSecureString
$passcompare2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass2))

 if ($pass2.Length -eq 4 -And $passcompare -eq $passcompare2) {
$proceed2 = "yes"
Write-Output "Awesome, now to create your network."
}


while ($proceed2 -ne "yes"){
Write-Output "Invalid entry..." ""
$pass= Read-Host -Prompt 'Starting over with the passcode...Create a 4 digit passcode. Something you can remember. Then press enter' -AsSecureString


    if ($pass.Length -eq 4) {
$proceed = "yes"
$passcompare = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))


while ($proceed -ne "yes"){
Write-Output "Invalid entry..." ""
$pass= Read-Host -Prompt 'Create a 4 digit passcode. Something you can remember. Then press enter' -AsSecureString

    if ($pass.Length -eq 4) {
$proceed = "yes"
$passcompare = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))
}
    }



$pass2= Read-Host -Prompt 'Thanks, please enter your 4 digit passcode again to confirm, then press enter' -AsSecureString
$passcompare2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass2))

 if ($pass2.Length -eq 4 -And $passcompare -eq $passcompare2) {
$proceed2 = "yes"
Write-Output "Awesome, now to create your network."
}


}

    }



$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$body = @{
id = "";
     config = @{ name = $email2};
  description = $passcompare2
}| ConvertTo-Json

Invoke-RestMethod -Uri $uri -Method 'Post' -Body $body -Headers $headers -ContentType 'application/json'



$response = Invoke-RestMethod -Uri $uri -Headers $headers
foreach ($network in $response) {
    if ($network.config.name -eq $email) {
	$network.config.id
        $ztid = $network.config.id
     }
 }

$uri2 = "https://my.zerotier.com/api/network/" 
$uri3 = $uri2 + $ztid
$body2 = '{
 "config": {
        "enableBroadcast": true,
"ipAssignmentPools":[{"ipRangeStart":"172.22.172.1","ipRangeEnd":"172.22.172.4"}],
"tags":[],"v4AssignMode":{"zt":true},"v6AssignMode":{"6plane":false,"rfc4193":false,"zt":false}},
"rulesSource":"drop not ethertype ipv4 and not ethertype arp; \ndrop sport 1-4999; \ndrop dport 1-4999; \ndrop sport 5009-5352; \ndrop dport 5009-5352; \ndrop sport 5354-5960; \ndrop dport 5354-5960; \ndrop sport 5962-5999; \ndrop dport 5962-5999; \ndrop sport 6006-20807; \ndrop dport 6006-20807; \ndrop sport 20809-49151; \ndrop dport 20809-49151; \naccept;"
}'

Invoke-RestMethod -Uri $uri3 -Method 'Post' -Body $body2 -Headers $headers -ContentType 'application/json'

pause