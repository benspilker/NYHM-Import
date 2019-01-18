Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " " "Obviously, you'll need an internet connection to run this." "The steps below will join you to your nowyouhear.me network." " "




$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
$ztjoin = "zerotier-cli join "
$ztleave = "zerotier-cli leave "
$i=0

while ($emailcheck -ne "yes" -And $i -lt 3){
$email = Read-Host -Prompt 'Please input your email, then press enter'

foreach ($network in $response) {
    if ($network.config.name -eq $email) {
        $ztid = $network.config.id
        $emailcheck = "yes"
     }
}
$i++
if ($emailcheck -ne "yes"){Write-Output "Email not found, please try again." ""}

}
if ($i -gt 2){Write-Output "Please check your account at www.nowyouhear.me and confirm your subscription is valid." ""
pause
} Else {


$uri2 = "https://my.zerotier.com/api/network/"
$uri3 = $uri2 + $ztid
$response2 = Invoke-RestMethod -Uri $uri3 -Headers $headers
$p=0

while ($passcheck -ne "yes" -And $p -lt 3){
$pass = Read-Host -Prompt 'Please input your 4 digit passcode, then press enter' -AsSecureString
$passcompare = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))

foreach ($network2 in $response2) {
if ($network2.description -eq $passcompare){
$passcheck = "yes"
}
}
$p++ 
if ($passcheck -ne "yes"){Write-Output "Incorrect passcode, please try again." ""}

}
if ($p -gt 2){Write-Output "Please check your account at www.nowyouhear.me and confirm your subscription is valid." ""
pause
} Else {



Write-Output " " "Got it! You will be joined to your NowYouHear.me network from here..." " "


Write-Output "Connecting to your nowyouhear.me network..."

zerotier-cli join $ztid


cls
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "


Write-Output "Connecting to your nowyouhear.me network..."
Start-Sleep -Seconds 2


cls

Write-Output "******************************************************************************" " " "You are now connected to your NowYouHear.me network! Keep this window open.     " " " "******************************************************************************" " "

Write-Host " "
Write-Host "Your computer's name is $(networksetup -getcomputername)."
Write-Host " "
Write-Host "Tell the Listener to find $(networksetup -getcomputername)"
"Listed on their computer's NDI-Studio-Monitor Menu."
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "You may minimize the console."
Write-Host " "
Write-Host "Press spacebar to PROPERLY disconnect and exit..." 

##C:\Users\Public\Desktop\HowToSend_NowYouHearMe.pdf



while (($host.UI.RawUI.ReadKey()).Character -ne 'x'){


zerotier-cli leave $ztid

Write-Output "Disconnecting from your nowyouhear.me network..." " " " "
Start-Sleep -Seconds 1
Write-Output "Disconnected. You may now close this window."
 
exit 0
}
}
}
exit 0