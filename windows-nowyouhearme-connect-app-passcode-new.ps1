Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "

##This code below disables the X close window button. This makes the user keep this window open in order to make the user properly exit out of the program by disconnecting from the network first. Ghetto I know, eventually I would like a prompt that asks, are you sure you want to exit? Then runs the disconnect commands when Yes is clicked, then closes out.

$code = @'
using System;
using System.Runtime.InteropServices;
 
namespace CloseButtonToggle {
  internal static class WinAPI {
    [DllImport("kernel32.dll")]
    internal static extern IntPtr GetConsoleWindow();
 
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool DeleteMenu(IntPtr hMenu,
                           uint uPosition, uint uFlags);
 
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool DrawMenuBar(IntPtr hWnd);
 
    [DllImport("user32.dll")]
    internal static extern IntPtr GetSystemMenu(IntPtr hWnd,
               [MarshalAs(UnmanagedType.Bool)]bool bRevert);
 
    const uint SC_CLOSE     = 0xf060;
    const uint MF_BYCOMMAND = 0;
 
    internal static void ChangeCurrentState(bool state) {
      IntPtr hMenu = GetSystemMenu(GetConsoleWindow(), state);
      DeleteMenu(hMenu, SC_CLOSE, MF_BYCOMMAND);
      DrawMenuBar(GetConsoleWindow());
    }
  }
 
  public static class Status {
    public static void Disable() {
      WinAPI.ChangeCurrentState(false); //its 'true' if need to enable


    }
  }
}


'@

 
Add-Type $code
[CloseButtonToggle.Status]::Disable()

##End of code that disables the X close window button

net start ZeroTierOneService


cls
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " " "Obviously, you'll need an internet connection to run this." "The steps below will join you to your nowyouhear.me network." " " "If you want to exit, press CTRL-C" " "




$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
$ztjoin = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q join "
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
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

$ztjoinid = $ztjoin + $ztid


Write-Output "Connecting to your nowyouhear.me network..."

powershell -command $ztjoinid


cls
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "


Write-Output "Connecting to your nowyouhear.me network..."
Start-Sleep -Seconds 2

cls

Get-NetConnectionProfile |
  Where{ $_.NetWorkCategory -ne 'Private'} |
  ForEach {
    $_
    $_|Set-NetConnectionProfile -NetWorkCategory Private
  }
##Sometimes when connecting to a zerotier network it will be a Public network which the windows firewall blocks. This makes it Private so it isn't an issue.


cls

Write-Output "*************************************************************************************************" " " "  You are now connected! Keep this window open to stay connected to your NowYouHear.me network.     " " " "*************************************************************************************************" " "

Write-Host " "
Write-Host "Your computer's name is $env:computername."
Write-Host " "
Write-Host "Tell the Listener to find $env:computername listed in their NDI-Studio-Monitor Menu."
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "You may minimize the console."
Write-Host " "
Write-Host "Press spacebar TWICE to PROPERLY disconnect and exit..." 

C:\Users\Public\Desktop\HowToSend_NowYouHearMe.pdf



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
}
}