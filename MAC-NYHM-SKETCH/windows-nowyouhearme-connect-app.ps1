Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "


net start ZeroTierOneService


cls
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " " "Obviously, you'll need an internet connection to run this." "The steps below will join you to your nowyouhear.me network." " " "If you want to exit, press CTRL-C" " "

$email = Read-Host -Prompt 'Please input your email, then press enter'
$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
$ztjoin = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q join "
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
foreach ($network in $response) {
  if ($network.config.name -eq $email) {
    $network.config.id
    $ztid = $network.config.id
  }
}
if ([string]::IsNullOrEmpty($network.config.id)) {
  Write-Output "Email not found. Try again."

}


Write-Output " " "Got it! You will be joined to your NowYouHear.me network from here..." " "

$ztjoinid = $ztjoin + $ztid


Write-Output "Connecting to your nowyouhear.me network..."

powershell -command $ztjoinid


##cls
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "


Write-Output "Connecting to your nowyouhear.me network..."
Start-Sleep -Seconds 2

##cls

Get-NetConnectionProfile |
  Where{ $_.NetWorkCategory -ne 'Private'} |
  ForEach {
    $_
    $_|Set-NetConnectionProfile -NetWorkCategory Private
  }
##Sometimes when connecting to a zerotier network it will be a Public network which the windows firewall blocks. This makes it Private so it isn't an issue.


##cls

Write-Output "*************************************************************************************************" " " "  You are now connected! Keep this window open to stay connected to your NowYouHear.me network.     " " " "*************************************************************************************************" " "
Write-Host " "
Write-Host "You may minimize the console."
Write-Host " "
Write-Host "Press spacebar TWICE to PROPERLY disconnect and exit..." 

C:\Users\Public\Desktop\HowToUse_NowYouHearMe.pdf



while (($host.UI.RawUI.ReadKey()).Character -ne 'x'){

$ztleaveid = $ztleave + $ztid

powershell -command $ztleaveid

Write-Output "Disconnecting from your nowyouhear.me network..." " " " "
Start-Sleep -Seconds 1


net stop ZeroTierOneService

Write-Host "Key Pressed...Disconnecting. Press again to exit..." 
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,AllowCtrlC")
Write-Host "Exiting..." 
exit
 }