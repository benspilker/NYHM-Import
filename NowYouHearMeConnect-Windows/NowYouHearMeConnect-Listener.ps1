function Test-Administrator
{  
    [OutputType([bool])]
    param()
    process {
        [Security.Principal.WindowsPrincipal]$user = [Security.Principal.WindowsIdentity]::GetCurrent();
        return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
    }
}
if(-not (Test-Administrator))
{
    Write-Error "THIS MUST BE RAN AS ADMINISTRATOR. CLOSING IN 5 SECONDS...";
    sleep 5
    exit 1;
}
$console = $host.ui.rawui
$console.backgroundcolor = "DarkGray"
$console.foregroundcolor = "white"
$colors = $host.privatedata
clear-host
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
function Set-WindowStyle {
param(
    [Parameter()]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE', 
                 'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED', 
                 'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    $Style = 'SHOW',
    [Parameter()]
    $MainWindowHandle = (Get-Process -Id $pid).MainWindowHandle
)
    $WindowStates = @{
        FORCEMINIMIZE   = 11; HIDE            = 0
        MAXIMIZE        = 3;  MINIMIZE        = 6
        RESTORE         = 9;  SHOW            = 5
        SHOWDEFAULT     = 10; SHOWMAXIMIZED   = 3
        SHOWMINIMIZED   = 2;  SHOWMINNOACTIVE = 7
        SHOWNA          = 8;  SHOWNOACTIVATE  = 4
        SHOWNORMAL      = 1
    }
    Write-Verbose ("Set Window Style {1} on handle {0}" -f $MainWindowHandle, $($WindowStates[$style]))

    $Win32ShowWindowAsync = Add-Type –memberDefinition @” 
    [DllImport("user32.dll")] 
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

    $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, $WindowStates[$Style]) | Out-Null
}
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
$ServiceName = 'ZeroTierOneService'
$arrService = Get-Service -Name $ServiceName
echo "Starting services..."
echo " "
if ($arrService.Status -eq 'Running'){
echo "Service already started."
}
if ($arrService.Status -ne 'Running'){
    Start-Service $ServiceName
    echo "Service started."
	echo " "
    Start-Sleep -seconds 1
}
$test=(Test-Connection www.google.com -Count 1 ) 2> $null
if (!$test){
$FormOnline = New-Object System.Windows.Forms.Form
$FormOnline.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOnline.width = 600
$FormOnline.height = 200
$FormOnline.backcolor = [System.Drawing.Color]::Gainsboro
$FormOnline.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOnline.Text = "NowYouHearMe Connect"
$FormOnline.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOnline.maximumsize = New-Object System.Drawing.Size(600,200)
$FormOnline.startposition = "centerscreen"
$FormOnline.KeyPreview = $True
$FormOnline.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOnline.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormOnline.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'You are not connected to the Internet, or at least NowYouHearMe Connect 
could not ping Google.

Check your connection or reboot your computer...'
$FormOnline.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Exit"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormOnline.Dispose()})
$FormOnline.Topmost = $True
$FormOnline.MaximizeBox = $Formalse
$FormOnline.MinimizeBox = $Formalse
#Add them to form and active it
$FormOnline.Controls.Add($Button1)
$FormOnline.Add_Shown({$FormOnline.Activate()})
$FormOnline.ShowDialog()
Start-Sleep -Seconds 0.5
stop-process -Id $PID
}
$job = Start-Job -ScriptBlock {
zerotier-cli listnetworks | Select-String -Pattern "ethernet" | %{$_ -replace "200"} | %{$_ -replace "listnetworks "} | %{$_ -replace '(.+?) .+','$1'} | %{$_ -replace " "} | select-object -first 1 >"C:\Program Files (x86)\nowyouhearme\oldztid.txt"
Start-Sleep -Seconds 1
}
# Wait for job to complete with timeout (in seconds)
$job | Wait-Job -Timeout 1
# Check to see if any jobs are still running and stop them
$job | Where-Object {$_.State -ne "Completed"} | Stop-Job
$oldnetwork=(get-content "C:\Program Files (x86)\nowyouhearme\oldztid.txt")
sleep 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt" >$null 2>&1
if ($oldnetwork) {
Function DisconnectOldZT{
$FormOldZT.Dispose() | out-null
while ( $oldnetwork ){
zerotier-cli leave $oldnetwork
sleep 0.5
$job = Start-Job -ScriptBlock {
zerotier-cli listnetworks | Select-String -Pattern "ethernet" | %{$_ -replace "200"} | %{$_ -replace "listnetworks "} | %{$_ -replace '(.+?) .+','$1'} | %{$_ -replace " "} | select-object -first 1 >"C:\Program Files (x86)\nowyouhearme\oldztid.txt"
Start-Sleep -Seconds 1
}
# Wait for job to complete with timeout (in seconds)
$job | Wait-Job -Timeout 1
# Check to see if any jobs are still running and stop them
$job | Where-Object {$_.State -ne "Completed"} | Stop-Job
$oldnetwork=(get-content "C:\Program Files (x86)\nowyouhearme\oldztid.txt")
}
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt" >$null 2>&1
cls
}
$FormOldZT = New-Object System.Windows.Forms.Form
$FormOldZT.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOldZT.width = 500
$FormOldZT.height = 300
$FormOldZT.backcolor = [System.Drawing.Color]::Gainsboro
$FormOldZT.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOldZT.Text = "NowYouHearMe Connect"
$FormOldZT.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOldZT.maximumsize = New-Object System.Drawing.Size(500,300)
$FormOldZT.startposition = "centerscreen"
$FormOldZT.KeyPreview = $True
$FormOldZT.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOldZT.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormCheckUpdate.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,150)
$label.Text = '***************************************************

                         Welcome to NowYouHear.me Connect     

***************************************************

NowYouHearMe has detected either there is a previous session 
open or that you did not PROPERLY exit from the last one.

Click Continue to close out of the previous session.'
$FormOldZT.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,200)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Continue"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({DisconnectOldZT})
$FormOldZT.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOldZT.Topmost = $True
$FormOldZT.MaximizeBox = $Formalse
$FormOldZT.MinimizeBox = $Formalse
#Add them to form and active it
$FormOldZT.Controls.Add($Button1)
$FormOldZT.Add_Shown({$FormOldZT.Activate()})
$FormOldZT.ShowDialog()
}
cls
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "
$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
$ztjoin = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q join "
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$i=0
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function CloseDialogspeedtestcancel{
sleep 0.5
$Formspeedtest.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
cls
}
Function CloseDialogspeedtest{
sleep 0.5
$Formspeedtest.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
start 'https://nowyouhearme.speedtestcustom.com'
sleep 44
cls
$Formpostspeedtest = New-Object System.Windows.Forms.Form
$Formpostspeedtest.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Formpostspeedtest.width = 575
$Formpostspeedtest.height = 180
$Formpostspeedtest.backcolor = [System.Drawing.Color]::Gainsboro
$Formpostspeedtest.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Formpostspeedtest.Text = "NowYouHearMe Connect"
$Formpostspeedtest.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Formpostspeedtest.maximumsize = New-Object System.Drawing.Size(575,180)
$Formpostspeedtest.startposition = "centerscreen"
$Formpostspeedtest.KeyPreview = $True
$Formpostspeedtest.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Formpostspeedtest.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(575,60)
$label.Text = 'Download speed should be at least 10 Mbps.
    
If it is less, try a wired connection if possible or moving closer to your router.'
$Formpostspeedtest.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(220,95)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$Formpostspeedtest.Dispose()})
$Formpostspeedtest.Topmost = $True
$Formpostspeedtest.MaximizeBox = $Formalse
$Formpostspeedtest.MinimizeBox = $Formalse
#Add them to form and active it
$Formpostspeedtest.Controls.Add($Button1)
$Formpostspeedtest.Add_Shown({$Formspeedtest.Activate()})
$Formpostspeedtest.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$Formspeedtest = New-Object System.Windows.Forms.Form
$Formspeedtest.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Formspeedtest.width = 500
$Formspeedtest.height = 240
$Formspeedtest.backcolor = [System.Drawing.Color]::Gainsboro
$Formspeedtest.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Formspeedtest.Text = "NowYouHearMe Connect"
$Formspeedtest.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Formspeedtest.maximumsize = New-Object System.Drawing.Size(500,240)
$Formspeedtest.startposition = "centerscreen"
$Formspeedtest.KeyPreview = $True
$Formspeedtest.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Formspeedtest.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,125)
$label.Text = 'Your Internet must be a certain speed to avoid choppy audio.

For Listeners, DOWNLOAD speed should be at least 10 Mbps.
This test takes about a minute.

You may click cancel to skip this test.

Click OK to open browser to run a SpeedTest, then click GO.'
$Formspeedtest.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(130,155)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogspeedtest})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(245,155)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Cancel"
$Button2.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogspeedtestcancel})
$Formspeedtest.Topmost = $True
$Formspeedtest.MaximizeBox = $Formalse
$Formspeedtest.MinimizeBox = $Formalse
#Add them to form and active it
$Formspeedtest.Controls.Add($Button1)
$Formspeedtest.Controls.Add($Button2)
$Formspeedtest.Add_Shown({$Formspeedtest.Activate()})
$Formspeedtest.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function CloseDialogCallFriend{
$FormCallFriend.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
cls
}
$FormCallFriend = New-Object System.Windows.Forms.Form
$FormCallFriend.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormCallFriend.width = 500
$FormCallFriend.height = 225
$FormCallFriend.backcolor = [System.Drawing.Color]::Gainsboro
$FormCallFriend.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormCallFriend.Text = "NowYouHearMe Connect"
$FormCallFriend.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormCallFriend.maximumsize = New-Object System.Drawing.Size(500,225)
$FormCallFriend.startposition = "centerscreen"
$FormCallFriend.KeyPreview = $True
$FormCallFriend.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormCallFriend.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,110)
$label.Text = 'Call your NowYouHear.me friend over the phone and confirm they 
are available to join you in a session.

Yes, Macs can talk to PCs and vise-versa.

The next few steps will guide you through how to join a session.'
$FormCallFriend.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(100,135)
$Button1.Size = new-object System.Drawing.Size(280,30)
$Button1.Text = "Yes, we're ready to start a session"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogCallFriend})
$FormCallFriend.Topmost = $True
$FormCallFriend.MaximizeBox = $Formalse
$FormCallFriend.MinimizeBox = $Formalse
#Add them to form and active it
$FormCallFriend.Controls.Add($Button1)
$FormCallFriend.Add_Shown({$FormCallFriend.Activate()})
$FormCallFriend.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 1
Write-Host "The steps below will guide you through your NowYouHear.me session."
Write-Host " "
function emailuser1 ($title, $WF, $TF) {
###################Load Assembly for creating form & button######
[void][System.Reflection.Assembly]::LoadWithPartialName( “System.Windows.Forms”)
[void][System.Reflection.Assembly]::LoadWithPartialName( “Microsoft.VisualBasic”)
#####Define the form size & placement
$form1 = New-Object “System.Windows.Forms.Form”;
$Form1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$form1.Width = 600;
$form1.Height = 230;
$Form1.backcolor = [System.Drawing.Color]::Gainsboro
$Form1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$form1.Text = $title;
$form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;
##############Define text label1
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,10)
$label.Size = New-Object System.Drawing.Size(600,80)
$label.Text = 'As a Listener you are considered a guest. You do not need your own account.

However, the account holder (Host) could potentially swap roles to be a Listener.

LISTENER AND HOST MUST SIGN IN WITH THE SAME ACCOUNT.'
$Form1.Controls.Add($label)
##############Define text label2
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,115)
$label2.Size = New-Object System.Drawing.Size(185,40)
$label2.Text = 'Enter email or username:'
$Form1.Controls.Add($label2)
############Define text box1 for input
$textBox1 = New-Object “System.Windows.Forms.TextBox”;
$textBox1.Left = 195;
$textBox1.Top = 115;
$textBox1.width = 360;
#############Define default values for the input boxes
$defaultValue = “”
$textBox1.Text = $defaultValue;
#############define OK button
$button = New-Object “System.Windows.Forms.Button”;
$button.Left = 225;
$button.Top = 150;
$button.Width = 100;
$button.Text = “Next”;
############# This is when you have to close the form after getting values
$eventHandler = [System.EventHandler]{
$textBox1.Text;
$form1.Close();};
$button.Add_Click($eventHandler) ;
#############Add controls to all the above objects defined
$form1.Controls.Add($button);
$form1.Controls.Add($textLabel1);
$form1.Controls.Add($textBox1);
$form1.Topmost = $True
$form1.MaximizeBox = $Formalse
$form1.MinimizeBox = $Formalse
$ret = $form1.ShowDialog();
#################return values
return $textBox1.Text
}
$email = emailuser1 “NowYouHear.me Connect Sign-in”
Start-Sleep -Seconds 0.5
if ($email){
foreach ($network in $response) {
    if ($network.config.name -eq $email) {
        $ztid = $network.config.id
		$devicelimit1more=$network.config.ipAssignmentPools | %{$_ -replace "172.22.172"} | %{$_ -replace "@{ipRangeStart=.1; ipRangeEnd=."} | %{$_ -replace "}"}
        $devicelimit=$devicelimit1more-1
        $emailcheck = "yes"
     }
}
if (! $ztid) { $userstring=(echo $response.rulesSource | %{$_ -replace "drop not ethertype ipv4 and not ethertype arp; drop sport 1-4999; drop dport 1-4999; drop sport 5009-5352; drop dport 5009-5352; drop sport 5354-5960; drop dport 5354-5960; drop sport 5962-5999; drop dport 5962-5999; drop sport 6006-6959; drop dport 6006-6959; drop sport 6961-20807; drop dport 6961-20807; drop sport 20809-49151; drop dport 20809-49151; accept;"} | Select-String -Pattern $email) }
$user=(echo $userstring | %{$_ -replace " #"} | %{$_ -replace '(.+?):.+','$1'})
if ($email -eq $user) {$emailcheck = "yes"}
}
if ($emailcheck -ne "yes"){Write-Output "Account not found, please try again." ""}
Start-Sleep -Seconds 0.5
if (! $ztid) {
if ($email -ne $user) {$email = emailuser1 “NowYouHear.me Connect Sign-in”}
}
if ($email){
foreach ($network in $response) {
    if ($network.config.name -eq $email) {
        $ztid = $network.config.id
		$devicelimit1more=$network.config.ipAssignmentPools | %{$_ -replace "172.22.172"} | %{$_ -replace "@{ipRangeStart=.1; ipRangeEnd=."} | %{$_ -replace "}"}
        $devicelimit=$devicelimit1more-1
        $emailcheck = "yes"
     }
}
if (! $ztid) { $userstring=(echo $response.rulesSource | %{$_ -replace "drop not ethertype ipv4 and not ethertype arp; drop sport 1-4999; drop dport 1-4999; drop sport 5009-5352; drop dport 5009-5352; drop sport 5354-5960; drop dport 5354-5960; drop sport 5962-5999; drop dport 5962-5999; drop sport 6006-6959; drop dport 6006-6959; drop sport 6961-20807; drop dport 6961-20807; drop sport 20809-49151; drop dport 20809-49151; accept;"} | Select-String -Pattern $email) }
$user=(echo $userstring | %{$_ -replace " #"} | %{$_ -replace '(.+?):.+','$1'})
if ($email -eq $user) {$emailcheck = "yes"}
}
if ($emailcheck -ne "yes"){Write-Output "Account not found, please try again." ""}
if (! $ztid) {
if ($email -ne $user) {$email = emailuser1 “NowYouHear.me Connect Sign-in”}
}
if ($email){
foreach ($network in $response) {
    if ($network.config.name -eq $email) {
        $ztid = $network.config.id
		$devicelimit1more=$network.config.ipAssignmentPools | %{$_ -replace "172.22.172"} | %{$_ -replace "@{ipRangeStart=.1; ipRangeEnd=."} | %{$_ -replace "}"}
        $devicelimit=$devicelimit1more-1
        $emailcheck = "yes"
     }
}
if (! $ztid) { $userstring=(echo $response.rulesSource | %{$_ -replace "drop not ethertype ipv4 and not ethertype arp; drop sport 1-4999; drop dport 1-4999; drop sport 5009-5352; drop dport 5009-5352; drop sport 5354-5960; drop dport 5354-5960; drop sport 5962-5999; drop dport 5962-5999; drop sport 6006-6959; drop dport 6006-6959; drop sport 6961-20807; drop dport 6961-20807; drop sport 20809-49151; drop dport 20809-49151; accept;"} | Select-String -Pattern $email) }
$user=(echo $userstring | %{$_ -replace " #"} | %{$_ -replace '(.+?):.+','$1'})
if ($email -eq $user) {$emailcheck = "yes"}
}
if ($emailcheck -ne "yes"){Write-Output "Have the account holder check their account at www.nowyouhear.me and confirm their subscription is valid." ""
pause
} 
Else {
if ($ztid) {
$uri2 = "https://my.zerotier.com/api/network/"
$uri3 = $uri2 + $ztid
$response2 = Invoke-RestMethod -Uri $uri3 -Headers $headers
$count=$response2.totalMemberCount
$p=0
}
if (! $ztid) {
$user=(echo $userstring | %{$_ -replace " #"} | %{$_ -replace '(.+?):.+','$1'})
if ($email -eq $user){
$ztpasscode=(echo $userstring | %{$_ -replace "$email"} | %{$_ -replace "#:"} | %{$_ -replace ' '} | %{$_ -replace '(.+?):.+','$1'})
}
}
while ($passcheck -ne "yes" -And $p -lt 3){
function button2 ($title2, $WF, $TF) {
###################Load Assembly for creating form & button######
[void][System.Reflection.Assembly]::LoadWithPartialName( “System.Windows.Forms”)
[void][System.Reflection.Assembly]::LoadWithPartialName( “Microsoft.VisualBasic”)
#####Define the form size & placement
$form2 = New-Object “System.Windows.Forms.Form”;
$Form2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$form2.Width = 375;
$form2.Height = 175;
$Form2.backcolor = [System.Drawing.Color]::Gainsboro
$Form2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$form2.Text = $title2;
$form2.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;
##############Define text label1
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,10)
$label2.Size = New-Object System.Drawing.Size(375,30)
$label2.Text = 'What is the 4 Digit NowYouHear.me passcode?'
$Form2.Controls.Add($label2)
############Define text box1 for input
$textBox2 = New-Object “System.Windows.Forms.TextBox”;
$textBox2.Left = 125;
$textBox2.Top = 50;
$textBox2.width = 100;
$textbox2.PasswordChar = '*'
#############Define default values for the input boxes
$defaultValue = “”
$textBox2.Text = $defaultValue;
$textbox2.PasswordChar = '*'
#############define OK button
$button2 = New-Object “System.Windows.Forms.Button”;
$button2.Left = 235;
$button2.Top = 90;
$button2.Width = 100;
$button2.Text = “Next”;
############# This is when you have to close the form after getting values
$eventHandler = [System.EventHandler]{
$textBox2.Text;
$form2.Close();};
$button2.Add_Click($eventHandler) ;
#############Add controls to all the above objects defined
$form2.Controls.Add($button2);
$form2.Controls.Add($textLabel2);
$form2.Controls.Add($textBox2);
$form2.Topmost = $True
$form2.MaximizeBox = $Formalse
$form2.MinimizeBox = $Formalse
$ret = $form2.ShowDialog();
#################return values
return $textBox2.Text
}
$passcode = button2 “NowYouHear.me Connect Sign-in Passcode”
Start-Sleep -Seconds 1
if ($ztid) {
foreach ($network2 in $response2) {
if ($network2.description -eq $passcode){
$passcheck = "yes"
}
}
if ($passcheck -ne "yes"){Write-Output "Incorrect passcode, please try again." ""}
}
if (! $ztid) {
if ($passcode -eq $ztpasscode) {
$passcheck = "yes"
}
if ($passcheck -eq "yes"){
$ztid=(echo $userstring | %{$_ -replace "$email"} | %{$_ -replace "#:"} | %{$_ -replace ' '} | %{$_ -replace '^[^\\]*:', ''})
$uridevice = "https://my.zerotier.com/api/network/$ztid"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$responsedevice = Invoke-RestMethod -Uri $uridevice -Headers $headers
$devicelimit1more=$responsedevice.config.ipAssignmentPools | %{$_ -replace "172.22.172"} | %{$_ -replace "@{ipRangeStart=.1; ipRangeEnd=."} | %{$_ -replace "}"}
$devicelimit=$devicelimit1more-1
$count=$responsedevice.totalMemberCount
sleep 2
}
}
$p++
}
if ($p -gt 2){Write-Output "Have the account holder check their account at www.nowyouhear.me and confirm their subscription is valid." ""
pause
} Else {
Write-Output " " "Got it! You will be joined to the NowYouHear.me network from here..." " "
$ztjoinid = $ztjoin + $ztid
Write-Output "Connecting to the nowyouhear.me network..."
Write-Output " "
powershell -command $ztjoinid
echo $ztid | Out-File "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
Remove-Item -path "C:\Program Files (x86)\nowyouhearme\firstuse-nyhm.txt" >$null 2>&1
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
echo " "
echo "Looking for NowYouHear.me network address..."
echo " "
sleep 1
echo " "
sleep 2
echo "This may take up to a minute to detect..."
sleep 2
echo " "
sleep 2
$ip=ipconfig | Select-String -Pattern "172.22.172."
if (!$ip) {
sleep 2
echo " "
sleep 2
echo " "
echo "Looking for NowYouHear.me network address...2nd Try."
sleep 2
echo "Please be patient..."
sleep 2
$ip=ipconfig | Select-String -Pattern "172.22.172."
}
if (!$ip) {
echo " "
sleep 2
echo "Looking for NowYouHear.me network address...3rd Try."
sleep 2
echo " "
sleep 2
$ip=ipconfig | Select-String -Pattern "172.22.172."
}
$count1=$count
if ($count -eq 0 ){ $count1=1 }
if (( $count1 -gt $devicelimit ) -and ( !$ip )){
Function CloseExceededLimit{
$FormExceededLimit.Dispose() | out-null
cls
Write-Host "Opening website in default browser..."
Start-Sleep -Seconds 2
start 'https://nowyouhear.me/'
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
net stop ZeroTierOneService >$null 2>&1
stop-process -Id $PID
}
$FormExceededLimit = New-Object System.Windows.Forms.Form
$FormExceededLimit.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormExceededLimit.width = 600
$FormExceededLimit.height = 250
$FormExceededLimit.backcolor = [System.Drawing.Color]::Gainsboro
$FormExceededLimit.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormExceededLimit.Text = "NowYouHearMe Connect"
$FormExceededLimit.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormExceededLimit.maximumsize = New-Object System.Drawing.Size(600,250)
$FormExceededLimit.startposition = "centerscreen"
$FormExceededLimit.KeyPreview = $True
$FormExceededLimit.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormExceededLimit.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,120)
$label.Text = 'Well there is good news and bad news...

The good news is that the account holder has used NowYouHear.me on several devices, 
which is really rad. So good job!

The bad news is the $devicelimit device limit has been exceeded on this account. 
Have the account holder contact NowYouHear.me support to clear unused devices.'
$FormExceededLimit.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(190,160)
$Button1.Size = new-object System.Drawing.Size(175,30)
$Button1.Text = "Exit, Go to Website"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseExceededLimit})
$FormExceededLimit.Topmost = $True
$FormExceededLimit.MaximizeBox = $Formalse
$FormExceededLimit.MinimizeBox = $Formalse
#Add them to form and active it
$FormExceededLimit.Controls.Add($Button1)
$FormExceededLimit.Add_Shown({$FormExceededLimit.Activate()})
$FormExceededLimit.ShowDialog()
}
if ( !$ip ){
Function CloseNoIP1{
$FormNoIP.Dispose() | out-null
cls
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
net stop ZeroTierOneService >$null 2>&1
& "C:\Program Files (x86)\nowyouhearme\scripts\NowYouHearMeConnect-Listener.lnk"
Start-Sleep -Seconds 0.5
stop-process -Id $PID
}
Function CloseNoIP2{
$FormNoIP.Dispose() | out-null
cls
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
Start-Sleep -Seconds 0.5
net stop ZeroTierOneService >$null 2>&1
stop-process -Id $PID
}
$FormNoIP = New-Object System.Windows.Forms.Form
$FormNoIP.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormNoIP.width = 500
$FormNoIP.height = 200
$FormNoIP.backcolor = [System.Drawing.Color]::Gainsboro
$FormNoIP.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormNoIP.Text = "NowYouHearMe Connect"
$FormNoIP.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormNoIP.maximumsize = New-Object System.Drawing.Size(500,200)
$FormNoIP.startposition = "centerscreen"
$FormNoIP.KeyPreview = $True
$FormNoIP.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormNoIP.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,85)
$label.Text = 'Well Crap! This can happen sometimes...

You computer could not find a NowYouHear.me network address.

Click Try Again to sign in again. Or try rebooting your computer.'
$FormNoIP.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(130,115)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Try Again"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseNoIP1})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(240,115)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Exit"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseNoIP2})
$FormNoIP.Topmost = $True
$FormNoIP.MaximizeBox = $Formalse
$FormNoIP.MinimizeBox = $Formalse
#Add them to form and active it
$FormNoIP.Controls.Add($Button1)
$FormNoIP.Controls.Add($Button2)
$FormNoIP.Add_Shown({$FormNoIP.Activate()})
$FormNoIP.ShowDialog()
}
Function CloseDialogCount{
$FormCount.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormCount = New-Object System.Windows.Forms.Form
$FormCount.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormCount.width = 535
$FormCount.height = 250
$FormCount.backcolor = [System.Drawing.Color]::Gainsboro
$FormCount.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormCount.Text = "NowYouHearMe Connect"
$FormCount.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormCount.maximumsize = New-Object System.Drawing.Size(535,250)
$FormCount.startposition = "centerscreen"
$FormCount.KeyPreview = $True
$FormCount.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormCount.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,140)
$label.Text = "You are now connected to the NowYouHear.me network of:
$email

Up to $devicelimit devices can be added to this NowYouHear.me account.

Contact NowYouHear.me support to remove unused devices.

This account has previously used $count1 out of $devicelimit available devices."
$FormCount.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(155,160)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "I Understand, Continue"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogCount})
$FormCount.Topmost = $True
$FormCount.MaximizeBox = $Formalse
$FormCount.MinimizeBox = $Formalse
#Add them to form and active it
$FormCount.Controls.Add($Button1)
$FormCount.Add_Shown({$FormCount.Activate()})
$FormCount.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
##Sometimes when connecting to a zerotier network it will be a Public network which the windows firewall blocks. This makes it Private so it isn't an issue.
Get-NetConnectionProfile | Where{ ($_.NetWorkCategory -eq 'Public') -and ( $_.InterfaceAlias -ne "Wi-Fi" )} |
  ForEach {
    $_
    $_|Set-NetConnectionProfile -NetWorkCategory Private
  }
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 1
Function CloseDialogHostReady{
$FormHostReady.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function FormHostReady{
$FormHostReady = New-Object System.Windows.Forms.Form
$FormHostReady.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormHostReady.width = 550
$FormHostReady.height = 330
$FormHostReady.backcolor = [System.Drawing.Color]::Gainsboro
$FormHostReady.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormHostReady.Text = "NowYouHearMe Connect"
$FormHostReady.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormHostReady.maximumsize = New-Object System.Drawing.Size(550,330)
$FormHostReady.startposition = "centerscreen"
$FormHostReady.KeyPreview = $True
$FormHostReady.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormHostReady.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(550,62)
$label.Text = "You must now wait until the Host is ready to Broadcast sound...

You will know the HOST is ready when THEY see a dialog box that says....
(You are now Broadcasting sound, with a stop sign icon.)
"
$FormHostReady.Controls.Add($label)
$img = [System.Drawing.Image]::Fromfile('C:\Program Files (x86)\nowyouhearme\images\stop.png')
$pictureBox = new-object Windows.Forms.PictureBox
$pictureBox.Width = $img.Size.Width
$pictureBox.Height = $img.Size.Height
$pictureBox.Image = $img
$FormHostReady.controls.add($pictureBox)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,245)
$Button1.Size = new-object System.Drawing.Size(225,30)
$Button1.Text = "Yes, we are both Ready"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogHostReady})
$FormHostReady.Topmost = $True
$FormHostReady.MaximizeBox = $Formalse
$FormHostReady.MinimizeBox = $Formalse
#Add them to form and active it
$FormHostReady.Controls.Add($Button1)
$FormHostReady.Add_Shown({$FormHostReady.Activate()})
$FormHostReady.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
if (-NOT (Test-Path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt")){
FormHostReady
}
$date=(Get-Date -UFormat "%Y-%m-%d")
xcopy "$ENV:UserProfile\AppData\Roaming\obs-studio" "$ENV:UserProfile\AppData\Roaming\obs-studio-$date" /s /i /q /y
TASKKILL /F /IM OBS64.exe >$null 2>&1
Start-Process "C:\Program Files (x86)\nowyouhearme\ndi\ndiscan.bat" -NoNewWindow
Start-Sleep -Seconds 1
taskkill /f /im dns-sd.exe >$null 2>&1
$ndipresearch = (get-content "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt" | Select-String -Pattern "OBS" | %{$_ -replace "Add"} | %{$_ -replace "_ndi._tcp."})
$ndipresearch=(echo $ndipresearch | select-object -first 1)
if ($ndipresearch){
$bullshit1=$ndipresearch.subString(0,15) 
$bullshit2=$ndipresearch.subString(16,31)
}
$ndisearch=($ndipresearch | %{$_ -replace "$bullshit1"} | %{$_ -replace "$bullshit2"} | %{$_ -replace "OBS"} | %{$_ -replace '[()]',''} | %{$_ -replace '(^\s+|\s+$)',''} | %{$_ -replace '\s+',' '})
$ndisourcetxt='"ndi_source_name": "'
$obs=' (OBS)"'
$ndistring=$ndisourcetxt+$ndisearch+$obs
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt"
Function CloseDialogOpenOBS{
$FormOpenOBS.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
& "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OBS Studio\OBS Studio (64bit).lnk"
}
Function FormOpenOBS{
$FormOpenOBS = New-Object System.Windows.Forms.Form
$FormOpenOBS.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOpenOBS.width = 535
$FormOpenOBS.height = 210
$FormOpenOBS.backcolor = [System.Drawing.Color]::Gainsboro
$FormOpenOBS.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOpenOBS.Text = "NowYouHearMe Connect"
$FormOpenOBS.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOpenOBS.maximumsize = New-Object System.Drawing.Size(535,250)
$FormOpenOBS.startposition = "centerscreen"
$FormOpenOBS.KeyPreview = $True
$FormOpenOBS.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOpenOBS.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,100)
$label.Text = "NowYouHear.me Connect detected Host computer name:
$ndisearch

Your OBS preferences are set to receive audio from that Host.

Click Next to automatically open OBS."
$FormOpenOBS.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(200,125)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Next"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogOpenOBS})
$FormOpenOBS.Topmost = $True
$FormOpenOBS.MaximizeBox = $Formalse
$FormOpenOBS.MinimizeBox = $Formalse
#Add them to form and active it
$FormOpenOBS.Controls.Add($Button1)
$FormOpenOBS.Add_Shown({$FormOpenOBS.Activate()})
$FormOpenOBS.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function SetOBSPrefs{
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\listener\global.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio" /s /i /q /y
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
$basejson=(Get-Content -path "C:\Program Files (x86)\nowyouhearme\OBSconfigs\listener\base.json")
Add-Content $basejson -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json" 
Add-Content $ndistring -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
$endjson=(Get-Content -path "C:\Program Files (x86)\nowyouhearme\OBSconfigs\listener\end.json")
Add-Content $endjson -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
Remove-Item -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\profiles\Untitled\basic.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\basic.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\profiles\Untitled\" /s /i /q /y
cls
}
if ($ndisearch){
SetOBSPrefs
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
if (!$OBSOpen){FormOpenOBS}
$OBSOpen="yes"
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 2
}
if (!$ndisearch) {
Function CloseDialogNoHost1{
$FormNoHost1.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
TASKKILL /F /IM OBS64.exe >$null 2>&1
Start-Process "C:\Program Files (x86)\nowyouhearme\ndi\ndiscan.bat" -NoNewWindow
Start-Sleep -Seconds 1
taskkill /f /im dns-sd.exe >$null 2>&1
$ndipresearch = (get-content "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt" | Select-String -Pattern "OBS" | %{$_ -replace "Add"} | %{$_ -replace "_ndi._tcp."})
$ndipresearch=(echo $ndipresearch | select-object -first 1)
if ($ndipresearch){
$bullshit1=$ndipresearch.subString(0,15) 
$bullshit2=$ndipresearch.subString(16,31)
}
$ndisearch=($ndipresearch | %{$_ -replace "$bullshit1"} | %{$_ -replace "$bullshit2"} | %{$_ -replace "OBS"} | %{$_ -replace '[()]',''} | %{$_ -replace '(^\s+|\s+$)',''} | %{$_ -replace '\s+',' '})
$ndisourcetxt='"ndi_source_name": "'
$obs=' (OBS)"'
$ndistring=$ndisourcetxt+$ndisearch+$obs
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt"
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormNoHost1 = New-Object System.Windows.Forms.Form
$FormNoHost1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormNoHost1.width = 535
$FormNoHost1.height = 210
$FormNoHost1.backcolor = [System.Drawing.Color]::Gainsboro
$FormNoHost1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormNoHost1.Text = "NowYouHearMe Connect"
$FormNoHost1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormNoHost1.maximumsize = New-Object System.Drawing.Size(535,250)
$FormNoHost1.startposition = "centerscreen"
$FormNoHost1.KeyPreview = $True
$FormNoHost1.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormNoHost1.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,100)
$label.Text = "No NowYouHear.me peers Broadcasting OBS were discovered.

Ask Host over the phone if THEY are running OBS and they see
something that says... (You Are the Host)?"
$FormNoHost1.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,125)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Retry Discovery"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogNoHost1})
$FormNoHost1.Topmost = $True
$FormNoHost1.MaximizeBox = $Formalse
$FormNoHost1.MinimizeBox = $Formalse
#Add them to form and active it
$FormNoHost1.Controls.Add($Button1)
$FormNoHost1.Add_Shown({$FormNoHost1.Activate()})
$FormNoHost1.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
if ($ndisearch){
if (!$OBSOpen){SetOBSPrefs}
$OBSOpen="yes"
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
if (!$OBSOpen){FormOpenOBS}
$OBSOpen="yes"
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 2
}
if (!$ndisearch) {
if (-NOT (Test-Path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt")){
Function CloseDialogNoHost2{
$FormNoHost2.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
echo 'Listener could not autodetect and is signing out and back in.' >"C:\Program Files (x86)\nowyouhearme\failedlistener.txt"
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
net stop ZeroTierOneService >$null 2>&1
& "C:\Program Files (x86)\nowyouhearme\scripts\NowYouHearMeConnect-Listener.lnk"
Start-Sleep -Seconds 0.5
stop-process -Id $PID
}
$FormNoHost2 = New-Object System.Windows.Forms.Form
$FormNoHost2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormNoHost2.width = 535
$FormNoHost2.height = 300
$FormNoHost2.backcolor = [System.Drawing.Color]::Gainsboro
$FormNoHost2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormNoHost2.Text = "NowYouHearMe Connect"
$FormNoHost2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormNoHost2.maximumsize = New-Object System.Drawing.Size(535,300)
$FormNoHost2.startposition = "centerscreen"
$FormNoHost2.KeyPreview = $True
$FormNoHost2.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormNoHost2.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,195)
$label.Text = "Well crap. This can happen sometimes...
Still no NowYouHear.me peers Broadcasting OBS were discovered.

There are 3 potential problems.

1. Confirm the Host has OBS open and it says (THEY) You Are the Host?

2. If it is the 1st time (You) the Listener signed into an account, 
it takes longer the 1st time.

3. YOU AND THE HOST MUST USE THE SAME EMAIL OR USERNAME."
$FormNoHost2.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,215)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Sign Out and Sign Back In"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogNoHost2})
$FormNoHost2.Topmost = $True
$FormNoHost2.MaximizeBox = $Formalse
$FormNoHost2.MinimizeBox = $Formalse
#Add them to form and active it
$FormNoHost2.Controls.Add($Button1)
$FormNoHost2.Add_Shown({$FormNoHost2.Activate()})
$FormNoHost2.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
if (Test-Path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt"){
Function CloseDialogNoHost3{
$FormNoHost3.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormNoHost3 = New-Object System.Windows.Forms.Form
$FormNoHost3.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormNoHost3.width = 535
$FormNoHost3.height = 300
$FormNoHost3.backcolor = [System.Drawing.Color]::Gainsboro
$FormNoHost3.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormNoHost3.Text = "NowYouHearMe Connect"
$FormNoHost3.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormNoHost3.maximumsize = New-Object System.Drawing.Size(535,300)
$FormNoHost3.startposition = "centerscreen"
$FormNoHost3.KeyPreview = $True
$FormNoHost3.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormNoHost3.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,195)
$label.Text = "Well, crap!! It happened again…
Listener could not autodetect the Host, even the 2nd time around…

1. Confirm that you and the Host are using the same account to sign in.

2. Confirm the HOST has OBS open and it says (THEY) You Are the Host?

3. If you have confirmed 1 and 2, then the Host may not actually be on 
the NowYouHear.me network (even though it says they are)

The Host will need to sign out and sign back in."
$FormNoHost3.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,215)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Wait for Host"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogNoHost3})
$FormNoHost3.Topmost = $True
$FormNoHost3.MaximizeBox = $Formalse
$FormNoHost3.MinimizeBox = $Formalse
#Add them to form and active it
$FormNoHost3.Controls.Add($Button1)
$FormNoHost3.Add_Shown({$FormNoHost3.Activate()})
$FormNoHost3.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 2
FormHostReady
sleep 2
TASKKILL /F /IM OBS64.exe >$null 2>&1
Start-Process "C:\Program Files (x86)\nowyouhearme\ndi\ndiscan.bat" -NoNewWindow
Start-Sleep -Seconds 1
taskkill /f /im dns-sd.exe >$null 2>&1
$ndipresearch = (get-content "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt" | Select-String -Pattern "OBS" | %{$_ -replace "Add"} | %{$_ -replace "_ndi._tcp."})
$ndipresearch=(echo $ndipresearch | select-object -first 1)
if ($ndipresearch){
$bullshit1=$ndipresearch.subString(0,15) 
$bullshit2=$ndipresearch.subString(16,31)
}
$ndisearch=($ndipresearch | %{$_ -replace "$bullshit1"} | %{$_ -replace "$bullshit2"} | %{$_ -replace "OBS"} | %{$_ -replace '[()]',''} | %{$_ -replace '(^\s+|\s+$)',''} | %{$_ -replace '\s+',' '})
$ndisourcetxt='"ndi_source_name": "'
$obs=' (OBS)"'
$ndistring=$ndisourcetxt+$ndisearch+$obs
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt"
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
}
if (Test-Path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt"){
if ($ndisearch){
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt"
if (!$OBSOpen){SetOBSPrefs}
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
if (!$OBSOpen){FormOpenOBS}
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 2
}
if (!$ndisearch) {
Function CloseDialogNoHost1{
$FormNoHost1.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
TASKKILL /F /IM OBS64.exe >$null 2>&1
Start-Process "C:\Program Files (x86)\nowyouhearme\ndi\ndiscan.bat" -NoNewWindow
Start-Sleep -Seconds 1
taskkill /f /im dns-sd.exe >$null 2>&1
$ndipresearch = (get-content "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt" | Select-String -Pattern "OBS" | %{$_ -replace "Add"} | %{$_ -replace "local."} | %{$_ -replace "_ndi._tcp."})
$ndipresearch=(echo $ndipresearch | select-object -first 1)
if ($ndipresearch){
$bullshit1=$ndipresearch.subString(0,15) 
$bullshit2=$ndipresearch.subString(16,31)
}
$ndisearch=($ndipresearch | %{$_ -replace "$bullshit1"} | %{$_ -replace "$bullshit2"} | %{$_ -replace "OBS"} | %{$_ -replace '[()]',''} | %{$_ -replace '(^\s+|\s+$)',''} | %{$_ -replace '\s+',' '})
$ndisourcetxt='"ndi_source_name": "'
$obs=' (OBS)"'
$ndistring=$ndisourcetxt+$ndisearch+$obs
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\ndi\ndi.txt"
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormNoHost1 = New-Object System.Windows.Forms.Form
$FormNoHost1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormNoHost1.width = 535
$FormNoHost1.height = 210
$FormNoHost1.backcolor = [System.Drawing.Color]::Gainsboro
$FormNoHost1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormNoHost1.Text = "NowYouHearMe Connect"
$FormNoHost1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormNoHost1.maximumsize = New-Object System.Drawing.Size(535,250)
$FormNoHost1.startposition = "centerscreen"
$FormNoHost1.KeyPreview = $True
$FormNoHost1.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormNoHost1.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,100)
$label.Text = "No NowYouHear.me peers Broadcasting OBS were discovered.

Ask Host over the phone if THEY are running OBS and they see
something that says... (You Are the Host)?"
$FormNoHost1.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,125)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Retry Discovery"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogNoHost1})
$FormNoHost1.Topmost = $True
$FormNoHost1.MaximizeBox = $Formalse
$FormNoHost1.MinimizeBox = $Formalse
#Add them to form and active it
$FormNoHost1.Controls.Add($Button1)
$FormNoHost1.Add_Shown({$FormNoHost1.Activate()})
$FormNoHost1.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
}
if (Test-Path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt"){
if ($ndisearch){
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt"
if (!$OBSOpen){SetOBSPrefs}
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
if (!$OBSOpen){FormOpenOBS}
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 2
}
if (!$ndisearch){
Function CloseDialogNoHost4{
$FormNoHost4.Dispose() | out-null
Write-Host "Well, crap..."
Write-Host " " 
Write-Host "Signing out. Exiting..."
Write-Host " " 
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\failedlistener.txt"
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
net stop ZeroTierOneService >$null 2>&1
TASKKILL /F /IM OBS64.exe >$null 2>&1
Start-Sleep -Seconds 0.5
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\listener\global-nondi-controls\global.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio\" /s /i /q /y
stop-process -Id $PID
}
$FormNoHost4 = New-Object System.Windows.Forms.Form
$FormNoHost4.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormNoHost4.width = 535
$FormNoHost4.height = 200
$FormNoHost4.backcolor = [System.Drawing.Color]::Gainsboro
$FormNoHost4.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormNoHost4.Text = "NowYouHearMe Connect"
$FormNoHost4.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormNoHost4.maximumsize = New-Object System.Drawing.Size(535,200)
$FormNoHost4.startposition = "centerscreen"
$FormNoHost4.KeyPreview = $True
$FormNoHost4.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormNoHost4.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,95)
$label.Text = "Hmmm, today is just not your day.

Listener and Host Computers still could not autodetect each other.

Try you and the Host rebooting both your computers?"
$FormNoHost4.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,115)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Well, crap...Exit"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogNoHost4})
$FormNoHost4.Topmost = $True
$FormNoHost4.MaximizeBox = $Formalse
$FormNoHost4.MinimizeBox = $Formalse
#Add them to form and active it
$FormNoHost4.Controls.Add($Button1)
$FormNoHost4.Add_Shown({$FormNoHost4.Activate()})
$FormNoHost4.ShowDialog()
cls
Write-Host "Well, crap..."
Write-Host " " 
Write-Host "Signing out. Exiting..."
Write-Host " " 
}
}
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\listener\global-nondi-controls\global.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio\" /s /i /q /y
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function CloseDialogOpenTVYes{
$FormOpenTV.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
& "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
sleep 2
Function CloseDialogUseTV{
$FormUseTV.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
$FormUseTV = New-Object System.Windows.Forms.Form
$FormUseTV.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormUseTV.width = 520
$FormUseTV.height = 200
$FormUseTV.backcolor = [System.Drawing.Color]::Gainsboro
$FormUseTV.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormUseTV.Text = "NowYouHearMe Connect"
$FormUseTV.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormUseTV.maximumsize = New-Object System.Drawing.Size(520,200)
$FormUseTV.startposition = "centerscreen"
$FormUseTV.KeyPreview = $True
$FormUseTV.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormUseTV.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(520,85)
$label.Text = '(Control Remote Computer) Have the Host give THEIR TeamViewer ID 
and TeamViewer password over the phone.

The TeamViewer password will change each session.'
$FormUseTV.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(195,110)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogUseTV})
$FormUseTV.Topmost = $True
$FormUseTV.MaximizeBox = $Formalse
$FormUseTV.MinimizeBox = $Formalse
#Add them to form and active it
$FormUseTV.Controls.Add($Button1)
$FormUseTV.Add_Shown({$FormUseTV.Activate()})
$FormUseTV.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 20
Function CloseDialogTVInfo{
$FormTVInfo.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
$FormTVInfo = New-Object System.Windows.Forms.Form
$FormTVInfo.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormTVInfo.width = 500
$FormTVInfo.height = 150
$FormTVInfo.backcolor = [System.Drawing.Color]::Gainsboro
$FormTVInfo.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormTVInfo.Text = "NowYouHearMe Connect"
$FormTVInfo.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormTVInfo.maximumsize = New-Object System.Drawing.Size(500,150)
$FormTVInfo.startposition = "centerscreen"
$FormTVInfo.KeyPreview = $True
$FormTVInfo.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormTVInfo.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,35)
$label.Text = 'Once you are connected to the Host, you should now be able to hear 
and see the Host computer.'
$FormTVInfo.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(135,65)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "NowYouHearMe!"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogTVInfo})
$FormTVInfo.Topmost = $True
$FormTVInfo.MaximizeBox = $Formalse
$FormTVInfo.MinimizeBox = $Formalse
#Add them to form and active it
$FormTVInfo.Controls.Add($Button1)
$FormTVInfo.Add_Shown({$FormTVInfo.Activate()})
$FormTVInfo.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 1
}
Function CloseDialogOpenTVNo{
$FormOpenTV.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
Function CloseDialogCommercial1{
$FormCommercial1.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
}
$FormCommercial1 = New-Object System.Windows.Forms.Form
$FormCommercial1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormCommercial1.width = 500
$FormCommercial1.height = 440
$FormCommercial1.backcolor = [System.Drawing.Color]::Gainsboro
$FormCommercial1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormCommercial1.Text = "NowYouHearMe Connect"
$FormCommercial1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormCommercial1.maximumsize = New-Object System.Drawing.Size(500,440)
$FormCommercial1.startposition = "centerscreen"
$FormCommercial1.KeyPreview = $True
$FormCommercial1.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormCommercial1.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormCommercial1.Close()}})
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(190,350)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Close Dialog"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogCommercial1})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'Commercial use:

In this session as the Listener, you are remoting to the Host.
Usually only one of you would need to buy a TeamViewer license.

View the cost of TeamViewer or view a list of free trial alternatives.

Here are a few good ones to choose from...'
$FormCommercial1.Controls.Add($label)
$LinkLabel1 = New-Object System.Windows.Forms.LinkLabel 
$LinkLabel1.Location = New-Object System.Drawing.Size(20,125) 
$LinkLabel1.Size = New-Object System.Drawing.Size(300,50) 
$LinkLabel1.LinkColor = "BLUE" 
$LinkLabel1.ActiveLinkColor = "DarkMagenta" 
$LinkLabel1.Text = "Buy TeamViewer www.teamviewer.com/en-us/buy-now" 
$LinkLabel1.add_Click({[system.Diagnostics.Process]::start("https://teamviewer.com/en-us/buy-now")}) 
$FormCommercial1.Controls.Add($LinkLabel1)
$LinkLabel2 = New-Object System.Windows.Forms.LinkLabel 
$LinkLabel2.Location = New-Object System.Drawing.Size(20,185) 
$LinkLabel2.Size = New-Object System.Drawing.Size(250,50) 
$LinkLabel2.LinkColor = "BLUE" 
$LinkLabel2.ActiveLinkColor = "DarkMagenta" 
$LinkLabel2.Text = "Mikogo Free Trial www.mikogo.com/download" 
$LinkLabel2.add_Click({[system.Diagnostics.Process]::start("https://mikogo.com/download")}) 
$FormCommercial1.Controls.Add($LinkLabel2)
$LinkLabel3 = New-Object System.Windows.Forms.LinkLabel 
$LinkLabel3.Location = New-Object System.Drawing.Size(20,245) 
$LinkLabel3.Size = New-Object System.Drawing.Size(250,50) 
$LinkLabel3.LinkColor = "BLUE" 
$LinkLabel3.ActiveLinkColor = "DarkMagenta" 
$LinkLabel3.Text = "Zoom 40 min Free Trial www.zoom.us/download" 
$LinkLabel3.add_Click({[system.Diagnostics.Process]::start("https://zoom.us/download")}) 
$FormCommercial1.Controls.Add($LinkLabel3)
$LinkLabel4 = New-Object System.Windows.Forms.LinkLabel 
$LinkLabel4.Location = New-Object System.Drawing.Size(20,305) 
$LinkLabel4.Size = New-Object System.Drawing.Size(450,35) 
$LinkLabel4.LinkColor = "BLUE" 
$LinkLabel4.ActiveLinkColor = "DarkMagenta" 
$LinkLabel4.Text = "Screenleap.com 40 min Free Trial (Screeshare Only)" 
$LinkLabel4.add_Click({[system.Diagnostics.Process]::start("https://screenleap.com")}) 
$FormCommercial1.Controls.Add($LinkLabel4)
$FormCommercial1.Topmost = $True
$FormCommercial1.MaximizeBox = $Formalse
$FormCommercial1.MinimizeBox = $Formalse
#Add them to form and active it
$FormCommercial1.Controls.Add($Button1)
$FormCommercial1.Add_Shown({$FormCommercial1.Activate()})
$FormCommercial1.ShowDialog()
}
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 4
$FormOpenTV = New-Object System.Windows.Forms.Form
$FormOpenTV.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOpenTV.width = 530
$FormOpenTV.height = 270
$FormOpenTV.backcolor = [System.Drawing.Color]::Gainsboro
$FormOpenTV.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOpenTV.Text = "NowYouHearMe Connect"
$FormOpenTV.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOpenTV.maximumsize = New-Object System.Drawing.Size(530,270)
$FormOpenTV.startposition = "centerscreen"
$FormOpenTV.KeyPreview = $True
$FormOpenTV.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOpenTV.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(530,145)
$label.Text = 'Finally, you as the Listener need to see and control the Hosts screen.

However, is this session either for personal or commercial use?

Personal is between musicians on their home computers.
Click to open TeamViewer (it is free for personal use).

Commercial is between studios OR when offering private lessons.
Click to buy TeamViewer or open a list of alternative programs.'
$FormOpenTV.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,180)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Personal"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogOpenTVYes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(265,180)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Commercial"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogOpenTVNo})
$FormOpenTV.Topmost = $True
$FormOpenTV.MaximizeBox = $Formalse
$FormOpenTV.MinimizeBox = $Formalse
#Add them to form and active it
$FormOpenTV.Controls.Add($Button1)
$FormOpenTV.Controls.Add($Button2)
$FormOpenTV.Add_Shown({$FormOpenTV.Activate()})
$FormOpenTV.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 2
function Show-Process($Process, [Switch]$Maximize)
{
  $sig = '
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
  '
  if ($Maximize) { $Mode = 3 } else { $Mode = 4 }
  $type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
  $hwnd = $process.MainWindowHandle
  $null = $type::ShowWindowAsync($hwnd, $Mode)
  $null = $type::SetForegroundWindow($hwnd) 
}
Show-Process -Process (Get-Process -Id $PID) -Maximize
Show-Process -Process (Get-Process -Id $PID)
sleep 1
Function CloseDialogWOOHOO{
$FormWOOHOO.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
cls
}
$FormWOOHOO = New-Object System.Windows.Forms.Form
$FormWOOHOO.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormWOOHOO.width = 620
$FormWOOHOO.height = 250
$FormWOOHOO.backcolor = [System.Drawing.Color]::Gainsboro
$FormWOOHOO.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormWOOHOO.Text = "NowYouHearMe Connect"
$FormWOOHOO.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormWOOHOO.maximumsize = New-Object System.Drawing.Size(620,250)
$FormWOOHOO.startposition = "centerscreen"
$FormWOOHOO.KeyPreview = $True
$FormWOOHOO.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormWOOHOO.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(620,125)
$label.Text = 'You did it!

Once you have connected to screen share, you are all setup and ready to collaborate!

DO NOT CLOSE THE COMMAND TERMINAL WINDOW.

You may minimize this Command Terminal window.
BUT DO NOT CLOSE IT.'
$FormWOOHOO.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(240,165)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "WOOHOO!"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogWOOHOO})
$FormWOOHOO.Topmost = $True
$FormWOOHOO.MaximizeBox = $Formalse
$FormWOOHOO.MinimizeBox = $Formalse
#Add them to form and active it
$FormWOOHOO.Controls.Add($Button1)
$FormWOOHOO.Add_Shown({$FormWOOHOO.Activate()})
$FormWOOHOO.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host "Your OBS preferences are set to receive audio from:"
Write-Host "$ndisearch"
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Listener within this session." 
Write-Host " "
sleep 1
Write-Host " "
Write-Host " "
Write-Host "You may minimize this Command Terminal window. BUT DO NOT CLOSE IT."
Write-Host " "
Write-Host " "
sleep 1
Write-Host "When you are done hosting this session and want to exit..."
Write-Host "TO PROPERLY disconnect and exit. Press SPACEBAR."
Write-Host " " 
function Show-Process($Process, [Switch]$Maximize)
{
  $sig = '
    [DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern int SetForegroundWindow(IntPtr hwnd);
  '
  if ($Maximize) { $Mode = 3 } else { $Mode = 4 }
  $type = Add-Type -MemberDefinition $sig -Name WindowAPI -PassThru
  $hwnd = $process.MainWindowHandle
  $null = $type::ShowWindowAsync($hwnd, $Mode)
  $null = $type::SetForegroundWindow($hwnd) 
}
Show-Process -Process (Get-Process -Id $PID) -Maximize
Show-Process -Process (Get-Process -Id $PID)
sleep 1
Function CloseDialogForSureMyDude{
$FormForSureMyDude.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
cls
}
$FormForSureMyDude = New-Object System.Windows.Forms.Form
$FormForSureMyDude.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormForSureMyDude.width = 520
$FormForSureMyDude.height = 200
$FormForSureMyDude.backcolor = [System.Drawing.Color]::Gainsboro
$FormForSureMyDude.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormForSureMyDude.Text = "NowYouHearMe Connect"
$FormForSureMyDude.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormForSureMyDude.maximumsize = New-Object System.Drawing.Size(520,200)
$FormForSureMyDude.startposition = "centerscreen"
$FormForSureMyDude.KeyPreview = $True
$FormForSureMyDude.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormForSureMyDude.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(520,95)
$label.Text = 'Remember, when you are done hosting this session and want to exit,
YOU MUST PROPERLY EXIT.

TO PROPERLY exit, make the Command Terminal the focus window,
then press SPACEBAR.'
$FormForSureMyDude.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(170,115)
$Button1.Size = new-object System.Drawing.Size(150,30)
$Button1.Text = "For Sure My Dude"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogForSureMyDude})
$FormForSureMyDude.Topmost = $True
$FormForSureMyDude.MaximizeBox = $Formalse
$FormForSureMyDude.MinimizeBox = $Formalse
#Add them to form and active it
$FormForSureMyDude.Controls.Add($Button1)
$FormForSureMyDude.Add_Shown({$FormForSureMyDude.Activate()})
$FormForSureMyDude.ShowDialog()
cls
Write-Host " "
Write-Host " "
Write-Host "You may minimize this Command Terminal window. BUT DO NOT CLOSE IT."
Write-Host " "
Write-Host " "
sleep 1
Write-Host "When you are done Listening to this session and want to exit..."
Write-Host "TO PROPERLY disconnect and exit. Press SPACEBAR."
Write-Host " "
sleep 1
$spacekey = 32  
while (($host.UI.RawUI.ReadKey()).Character -ne '32'){
$key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp")
      if ($key.VirtualKeyCode -eq $spacekey)
       {
Write-Host " "
Write-Host "Spacebar pressed. Once disconnected, this window will automatically close."
Write-Host "Disconnecting from your NowYouhHear.me network. Please wait..."
Write-Host " "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Write-Output "Disconnecting from your NowYouHear.me network..." " " " "
Start-Sleep -Seconds 1
net stop ZeroTierOneService >$null 2>&1
Write-Host "Exiting..." 
Start-Sleep -Seconds 1
Function CloseDialogExitReminder{
$FormExitReminder.Dispose() | out-null
cls
Write-Host "Exiting NowYouHear.me..."
Write-Host " "
}
cls
Write-Host "Exiting NowYouHear.me"
Write-Host " "
$FormExitReminder = New-Object System.Windows.Forms.Form
$FormExitReminder.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormExitReminder.width = 520
$FormExitReminder.height = 220
$FormExitReminder.backcolor = [System.Drawing.Color]::Gainsboro
$FormExitReminder.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormExitReminder.Text = "NowYouHearMe Connect"
$FormExitReminder.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormExitReminder.maximumsize = New-Object System.Drawing.Size(520,220)
$FormExitReminder.startposition = "centerscreen"
$FormExitReminder.KeyPreview = $True
$FormExitReminder.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormExitReminder.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(520,115)
$label.Text = 'You are now disconnected from your NowYouHear.me network. 
The Command Terminal, OBS, and TeamViewer now close.

Thanks for using NowYouHear.me!'
$FormExitReminder.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(200,135)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "WOOHOO!"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogExitReminder})
$FormExitReminder.Topmost = $True
$FormExitReminder.MaximizeBox = $Formalse
$FormExitReminder.MinimizeBox = $Formalse
#Add them to form and active it
$FormExitReminder.Controls.Add($Button1)
$FormExitReminder.Add_Shown({$FormExitReminder.Activate()})
$FormExitReminder.ShowDialog()
TASKKILL /F /IM OBS64.exe >$null 2>&1
TASKKILL /F /IM TeamViewer.exe >$null 2>&1
sleep 1
Remove-Item -path "$ENV:UserProfile\AppData\Roaming\obs-studio" -recurse
xcopy "$ENV:UserProfile\AppData\Roaming\obs-studio-$date" "$ENV:UserProfile\AppData\Roaming\obs-studio" /s /i /q /y
Remove-Item -path "$ENV:UserProfile\AppData\Roaming\obs-studio-$date" -recurse
cls
Write-Host "Exiting NowYouHear.me"
Write-Host " "
sleep 1
exit
}
}
}
}