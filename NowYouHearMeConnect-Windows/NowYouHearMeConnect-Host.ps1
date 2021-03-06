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
$label.Text = 'Upload speed should be at least 7 Mbps. (The one on the bottom)
    
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

For Hosts, UPLOAD speed should be at least 7 Mbps.
(The one on the bottom). This test takes about a minute.

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
Write-Output "******************************************" " " "         Welcome to NowYouHear.me     " " " "******************************************" " " " "
Write-Output "The steps below will join you to your NowYouHear.me network." " "
$uri = "https://my.zerotier.com/api/network"
$headers = @{"Authorization" = "bearer HnHCtFFh6RPE9av7ZMETfUmaKAXpHJBq"}
$response = Invoke-RestMethod -Uri $uri -Headers $headers
$ztjoin = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q join "
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$i=0
function GoToSite{
$Form1.Dispose() | out-null
Start-Sleep -Seconds 1
Write-Host "NowYouHearMe Connect will now close so you can create your own account."
Write-Host " "
Write-Host "Opening website in default browser..."
Start-Sleep -Seconds 3
start 'https://nowyouhear.me/membership-account/membership-levels/'
Start-Sleep -Seconds 3
stop-process -Id $PID
}
Function CloseDialogCloseDAW2{
$FormCloseDAW2.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormCloseDAW2 = New-Object System.Windows.Forms.Form
$FormCloseDAW2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormCloseDAW2.width = 500
$FormCloseDAW2.height = 180
$FormCloseDAW2.backcolor = [System.Drawing.Color]::Gainsboro
$FormCloseDAW2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormCloseDAW2.Text = "Welcome to NowYouHearMe Connect!"
$FormCloseDAW2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormCloseDAW2.maximumsize = New-Object System.Drawing.Size(500,180)
$FormCloseDAW2.startposition = "centerscreen"
$FormCloseDAW2.KeyPreview = $True
$FormCloseDAW2.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormCloseDAW2.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,60)
$label.Text = 'Have you first closed out your DAW (music prodution software)?

This Application will not work unless your DAW is closed first.'
$FormCloseDAW2.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(140,90)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Yes, I closed my DAW"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogCloseDAW2})
$FormCloseDAW2.Topmost = $True
$FormCloseDAW2.MaximizeBox = $Formalse
$FormCloseDAW2.MinimizeBox = $Formalse
#Add them to form and active it
$FormCloseDAW2.Controls.Add($Button1)
$FormCloseDAW2.Add_Shown({$FormCloseDAW2.Activate()})
$FormCloseDAW2.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 3
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

The next few steps will guide you through how to create a session.'
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
$form1.Width = 450;
$form1.Height = 200;
$Form1.backcolor = [System.Drawing.Color]::Gainsboro
$Form1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$form1.Text = $title;
$form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen;
##############Define text label1
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,10)
$label.Size = New-Object System.Drawing.Size(450,55)
$label.Text = 'What is your NowYouHear.me account email or username?
HOST AND LISTENER MUST USE THE SAME ACCOUNT.'
$Form1.Controls.Add($label)
############Define text box1 for input
$textBox1 = New-Object “System.Windows.Forms.TextBox”;
$textBox1.Left = 15;
$textBox1.Top = 75;
$textBox1.width = 400;
#############Define default values for the input boxes
$defaultValue = “”
$textBox1.Text = $defaultValue;
#############define OK button
$button = New-Object “System.Windows.Forms.Button”;
$button.Left = 70;
$button.Top = 115;
$button.Width = 100;
$button.Text = “Next”;
$button1 = New-Object “System.Windows.Forms.Button”;
$button1.Left = 185;
$button1.Top = 115;
$button1.Width = 225;
$button1.Text = “No Account? Create One Here”;
############# This is when you have to close the form after getting values
$eventHandler = [System.EventHandler]{
$textBox1.Text;
$form1.Close();};
$button.Add_Click($eventHandler) ;
$button1.Add_Click({GoToSite}) ;
#############Add controls to all the above objects defined
$form1.Controls.Add($button);
$form1.Controls.Add($button1);
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
if ($emailcheck -ne "yes"){Write-Output "Please check your account at www.nowyouhear.me and confirm your subscription is valid." ""
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
$label2.Text = 'What is your 4 Digit NowYouHear.me passcode?'
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
if (!$ztid) {
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
if ($p -gt 2){Write-Output "Please check your account at www.nowyouhear.me and confirm your subscription is valid." ""
pause
} Else {
Write-Output " " "Got it! You will be joined to your NowYouHear.me network from here..." " "
$ztjoinid = $ztjoin + $ztid
Write-Output "Connecting to your nowyouhear.me network..."
Write-Output " "
powershell -command $ztjoinid
echo $ztid | Out-File "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
Remove-Item -path "C:\Program Files (x86)\nowyouhearme\firstuse-nyhm.txt" >$null 2>&1
TASKKILL /F /IM OBS64.exe >$null 2>&1
$date=(Get-Date -UFormat "%Y-%m-%d")
xcopy "$ENV:UserProfile\AppData\Roaming\obs-studio" "$ENV:UserProfile\AppData\Roaming\obs-studio-$date" /s /i /q /y
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\host\global.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio" /s /i /q /y
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
$quote='"'
$devicetxt='"device_id": '
$preid=(Get-WmiObject Win32_PnPEntity | Select Name,DeviceID | Select-String -Pattern "VB-Audio" | Select-String -Pattern "0.0.1" | %{$_ -replace "@{Name=CABLE Output "} | %{$_ -replace "(VB-Audio Virtual Cable)"} | %{$_ -replace "@{Name=Hi-Fi Cable Output "})
$deviceid=$preid.subString(26,55)
$deviceid = $deviceid.ToLower() 
$stringid=$devicetxt+$quote+$deviceid+$quote
$basejson=(Get-Content -path "C:\Program Files (x86)\nowyouhearme\OBSconfigs\host\base.json")
Add-Content $basejson -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
Add-Content $stringid -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
$endjson=(Get-Content -path "C:\Program Files (x86)\nowyouhearme\OBSconfigs\host\end.json")
Add-Content $endjson -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\scenes\Untitled.json"
Remove-Item -path "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\profiles\Untitled\basic.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\basic.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio\basic\profiles\Untitled\" /s /i /q /y
Remove-Item -Path "C:\Program Files (x86)\nowyouhearme\asio\asio_current.reg"
reg export "HKCU\Software\ASIO4ALL v2 by Wuschel" "C:\Program Files (x86)\nowyouhearme\asio\asio_current.reg"
Remove-Item -Path "HKCU:\Software\ASIO4ALL v2 by Wuschel\" -Recurse >$null 2>&1
reg import "C:\Program Files (x86)\nowyouhearme\asio\vbaudio_default-route.reg" >$null 2>&1
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

The good news is that you have used NowYouHear.me on several devices, which 
is really rad. So good job!

The bad news is that you have exceeded the $devicelimit device limit on this account. 
To fix this, you must contact NowYouHear.me support to clear unused devices.'
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
& "C:\Program Files (x86)\nowyouhearme\scripts\NowYouHearMeConnect-Host.lnk"
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

You can add up to $devicelimit devices to your own NowYouHear.me account.

Contact NowYouHear.me support if you need to remove unused devices.

Your account has previously used $count1 out of $devicelimit available devices."
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
Function CloseDialogOpenDAW{
$FormOpenDAW.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormOpenDAW = New-Object System.Windows.Forms.Form
$FormOpenDAW.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOpenDAW.width = 500
$FormOpenDAW.height = 150
$FormOpenDAW.backcolor = [System.Drawing.Color]::Gainsboro
$FormOpenDAW.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOpenDAW.Text = "NowYouHearMe Connect"
$FormOpenDAW.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOpenDAW.maximumsize = New-Object System.Drawing.Size(500,150)
$FormOpenDAW.startposition = "centerscreen"
$FormOpenDAW.KeyPreview = $True
$FormOpenDAW.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOpenDAW.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,35)
$label.Text = 'You may now open your DAW (music prodution software):
Ableton Live, FL Studio, ProTools, Reason, etc).'
$FormOpenDAW.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(185,65)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Next"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogOpenDAW})
$FormOpenDAW.Topmost = $True
$FormOpenDAW.MaximizeBox = $Formalse
$FormOpenDAW.MinimizeBox = $Formalse
#Add them to form and active it
$FormOpenDAW.Controls.Add($Button1)
$FormOpenDAW.Add_Shown({$FormOpenDAW.Activate()})
$FormOpenDAW.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Write-Host "Waiting for user to open DAW (music production software)."
sleep 18
cls
Write-Host "******************************************" 
Write-Host " "
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " "
Write-Host " "
Function CloseDialogPickASIO{
$FormPickASIO.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogPickASIOWithGIF{
$FormPickASIO.Dispose() | out-null
cls
Write-Host "Opening website in default browser..."
start 'https://nowyouhear.me/how-to-asio4all'
Start-Sleep -Seconds 15
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
$FormPickASIO = New-Object System.Windows.Forms.Form
$FormPickASIO.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormPickASIO.width = 600
$FormPickASIO.height = 220
$FormPickASIO.backcolor = [System.Drawing.Color]::Gainsboro
$FormPickASIO.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormPickASIO.Text = "NowYouHearMe Connect"
$FormPickASIO.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormPickASIO.maximumsize = New-Object System.Drawing.Size(600,220)
$FormPickASIO.startposition = "centerscreen"
$FormPickASIO.KeyPreview = $True
$FormPickASIO.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormPickASIO.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,105)
$label.Text = 'Open your DAWs Audio Preferences.

In your DAW, change audio Driver Type to ASIO and Audio Device to ASIO4ALL.

DO NOT change any settings in the ASIO4ALL panel.'
$FormPickASIO.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,125)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Next"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogPickASIO})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(260,125)
$Button2.Size = new-object System.Drawing.Size(150,30)
$Button2.Text = "Show me how?"
$Button2.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogPickASIOWithGIF})
$FormPickAsio.Topmost = $True
$FormPickASIO.MaximizeBox = $Formalse
$FormPickASIO.MinimizeBox = $Formalse
#Add them to form and active it
$FormPickASIO.Controls.Add($Button1)
$FormPickASIO.Controls.Add($Button2)
$FormPickASIO.Add_Shown({$FormPickASIO.Activate()})
$FormPickASIO.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function PickASIO{
$FormPickASIO = New-Object System.Windows.Forms.Form
$FormPickASIO.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormPickASIO.width = 600
$FormPickASIO.height = 220
$FormPickASIO.backcolor = [System.Drawing.Color]::Gainsboro
$FormPickASIO.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormPickASIO.Text = "NowYouHearMe Connect"
$FormPickASIO.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormPickASIO.maximumsize = New-Object System.Drawing.Size(600,220)
$FormPickASIO.startposition = "centerscreen"
$FormPickASIO.KeyPreview = $True
$FormPickASIO.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormPickASIO.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,105)
$label.Text = 'Open your DAWs Audio Preferences.

In your DAW, change audio Driver Type to ASIO and Audio Device to ASIO4ALL.

DO NOT change any settings in the ASIO4ALL panel.'
$FormPickASIO.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(150,125)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Next"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogPickASIO})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(260,125)
$Button2.Size = new-object System.Drawing.Size(150,30)
$Button2.Text = "Show me how?"
$Button2.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogPickASIOWithGIF})
$FormPickAsio.Topmost = $True
$FormPickASIO.MaximizeBox = $Formalse
$FormPickASIO.MinimizeBox = $Formalse
#Add them to form and active it
$FormPickASIO.Controls.Add($Button1)
$FormPickASIO.Controls.Add($Button2)
$FormPickASIO.Add_Shown({$FormPickASIO.Activate()})
$FormPickASIO.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
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
sleep 1
}
Function CloseDialogWaitASIO{
$FormOpenOBS.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
PickASIO
}
sleep 2
$FormOpenOBS = New-Object System.Windows.Forms.Form
$FormOpenOBS.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOpenOBS.width = 550
$FormOpenOBS.height = 190
$FormOpenOBS.backcolor = [System.Drawing.Color]::Gainsboro
$FormOpenOBS.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOpenOBS.Text = "NowYouHearMe Connect"
$FormOpenOBS.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOpenOBS.maximumsize = New-Object System.Drawing.Size(550,190)
$FormOpenOBS.startposition = "centerscreen"
$FormOpenOBS.KeyPreview = $True
$FormOpenOBS.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOpenOBS.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(550,70)
$label.Text = 'After you have set your DAW to ASIO4ALL close your DAW preferences,
Then click Next to automatically open OBS.

OBS is the application that will transmit your DAWs Audio.'
$FormOpenOBS.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(80,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Next"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogOpenOBS})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(195,105)
$Button2.Size = new-object System.Drawing.Size(250,30)
$Button2.Text = "Wait, I'm still picking ASIO4ALL"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogWaitASIO})
$FormOpenOBS.Topmost = $True
$FormOpenOBS.MaximizeBox = $Formalse
$FormOpenOBS.MinimizeBox = $Formalse
#Add them to form and active it
$FormOpenOBS.Controls.Add($Button1)
$FormOpenOBS.Controls.Add($Button2)
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
sleep 2
}
Write-Host "In your DAW's Audio Preferences, change Audio Driver Type to ASIO and Audio Device to ASIO4ALL."
Write-Host " "
Write-Host "DO NOT change any settings in the ASIO4ALL panel." " "
sleep 15
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
sleep 1
}
Function CloseDialogWaitASIO{
$FormOpenOBS.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
PickASIO
}
$FormOpenOBS = New-Object System.Windows.Forms.Form
$FormOpenOBS.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOpenOBS.width = 550
$FormOpenOBS.height = 190
$FormOpenOBS.backcolor = [System.Drawing.Color]::Gainsboro
$FormOpenOBS.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOpenOBS.Text = "NowYouHearMe Connect"
$FormOpenOBS.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOpenOBS.maximumsize = New-Object System.Drawing.Size(550,190)
$FormOpenOBS.startposition = "centerscreen"
$FormOpenOBS.KeyPreview = $True
$FormOpenOBS.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOpenOBS.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(550,70)
$label.Text = 'After you have set your DAW to ASIO4ALL, close your DAW preferences.
Then click Next to automatically open OBS.

OBS is the application that will transmit your DAWs Audio.'
$FormOpenOBS.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(80,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Next"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogOpenOBS})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(195,105)
$Button2.Size = new-object System.Drawing.Size(250,30)
$Button2.Text = "Wait, I'm still picking ASIO4ALL"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogWaitASIO})
$FormOpenOBS.Topmost = $True
$FormOpenOBS.MaximizeBox = $Formalse
$FormOpenOBS.MinimizeBox = $Formalse
#Add them to form and active it
$FormOpenOBS.Controls.Add($Button1)
$FormOpenOBS.Controls.Add($Button2)
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
Function CloseSoundCheck1Yes{
$FormSoundCheck1.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function CloseSound1Yes{
$FormSound1Yes.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
sleep 2
$FormSound1Yes = New-Object System.Windows.Forms.Form
$FormSound1Yes.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSound1Yes.width = 600
$FormSound1Yes.height = 200
$FormSound1Yes.backcolor = [System.Drawing.Color]::Gainsboro
$FormSound1Yes.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSound1Yes.Text = "NowYouHearMe Connect"
$FormSound1Yes.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSound1Yes.maximumsize = New-Object System.Drawing.Size(600,200)
$FormSound1Yes.startposition = "centerscreen"
$FormSound1Yes.KeyPreview = $True
$FormSound1Yes.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSound1Yes.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,75)
$label.Text = 'OBS plays sound through the default sound device set in Windows.

You can change your Windows system audio to whatever you want.

Also note: In this session, when OBS is closed, you will not hear your DAW.'
$FormSound1Yes.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,115)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "I Understand, Continue"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSound1Yes})
$FormSound1Yes.Topmost = $True
$FormSound1Yes.MaximizeBox = $Formalse
$FormSound1Yes.MinimizeBox = $Formalse
#Add them to form and active it
$FormSound1Yes.Controls.Add($Button1)
$FormSound1Yes.Add_Shown({$FormSound1Yes.Activate()})
$FormSound1Yes.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseSoundCheck1No{
$FormSoundCheck1.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
start "C:\Program Files (x86)\nowyouhearme\nyhm-windows-sound.pdf"
sleep 3
Function CloseSound1No{
$FormSound1No.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function CloseSoundCheck2Yes{
$FormSoundCheck2.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseSoundCheck2No{
$FormSoundCheck2.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 1
Function CloseSound2{
$FormSound2.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
start "C:\Program Files (x86)\nowyouhearme\nyhm-asio-panel.pdf"
}
$FormSound2 = New-Object System.Windows.Forms.Form
$FormSound2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSound2.width = 600
$FormSound2.height = 200
$FormSound2.backcolor = [System.Drawing.Color]::Gainsboro
$FormSound2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSound2.Text = "NowYouHearMe Connect"
$FormSound2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSound2.maximumsize = New-Object System.Drawing.Size(600,200)
$FormSound2.startposition = "centerscreen"
$FormSound2.KeyPreview = $True
$FormSound2.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSound2.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'Open your DAWs audio preferences. Open the ASIO4ALL Panel (Hardware Setup).

Click wrench icon in the ASIO4ALL panel. Confirm VB-Audio is the ONLY OUTPUT.

If there are other OUTPUT devices on in the ASIO4ALL panel, toggle them off.'
$FormSound2.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(200,115)
$Button1.Size = new-object System.Drawing.Size(150,30)
$Button1.Text = "Open 2nd PDF"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSound2})
$FormSound2.Topmost = $True
$FormSound2.MaximizeBox = $Formalse
$FormSound2.MinimizeBox = $Formalse
#Add them to form and active it
$FormSound2.Controls.Add($Button1)
$FormSound2.Add_Shown({$FormSound2.Activate()})
$FormSound2.ShowDialog()
sleep 2
Function CloseSoundCheck3Yes{
$FormSoundCheck3.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseSoundCheck3No{
$FormSoundCheck3.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
Function CloseSound3{
$FormSound3.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
start 'https://nowyouhear.me/'
}
sleep 1
$FormSound3 = New-Object System.Windows.Forms.Form
$FormSound3.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSound3.width = 500
$FormSound3.height = 200
$FormSound3.backcolor = [System.Drawing.Color]::Gainsboro
$FormSound3.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSound3.Text = "NowYouHearMe Connect"
$FormSound3.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSound3.maximumsize = New-Object System.Drawing.Size(500,200)
$FormSound3.startposition = "centerscreen"
$FormSound3.KeyPreview = $True
$FormSound3.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSound3.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,85)
$label.Text = 'If you still do not hear sound after the troubleshooting steps...

Check your cables. Make sure your sound is not muted.

Contact NowYouHear.me support if you are stuck.'
$FormSound3.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,115)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSound3})
$FormSound3.Topmost = $True
$FormSound3.MaximizeBox = $Formalse
$FormSound3.MinimizeBox = $Formalse
#Add them to form and active it
$FormSound3.Controls.Add($Button1)
$FormSound3.Add_Shown({$FormSound3.Activate()})
$FormSound3.ShowDialog()
}
sleep 15
$FormSoundCheck3 = New-Object System.Windows.Forms.Form
$FormSoundCheck3.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSoundCheck3.width = 600
$FormSoundCheck3.height = 220
$FormSoundCheck3.backcolor = [System.Drawing.Color]::Gainsboro
$FormSoundCheck3.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSoundCheck3.Text = "NowYouHearMe Connect"
$FormSoundCheck3.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSoundCheck3.maximumsize = New-Object System.Drawing.Size(600,220)
$FormSoundCheck3.startposition = "centerscreen"
$FormSoundCheck3.KeyPreview = $True
$FormSoundCheck3.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSoundCheck3.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,105)
$label.Text = 'You can move this dialog box wherever you want on your screen.

With your DAW correctly setup in ASIO4ALL, with OBS open, and with 
Windows audio set to the correct device...

Play something in your DAW. Do you hear sound and is it metering in OBS?'
$FormSoundCheck3.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,135)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSoundCheck3Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,135)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseSoundCheck3No})
$FormSoundCheck3.Topmost = $True
$FormSoundCheck3.MaximizeBox = $Formalse
$FormSoundCheck3.MinimizeBox = $Formalse
#Add them to form and active it
$FormSoundCheck3.Controls.Add($Button1)
$FormSoundCheck3.Controls.Add($Button2)
$FormSoundCheck3.Add_Shown({$FormSoundCheck3.Activate()})
$FormSoundCheck3.ShowDialog()
}
sleep 14
$FormSoundCheck2 = New-Object System.Windows.Forms.Form
$FormSoundCheck2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSoundCheck2.width = 600
$FormSoundCheck2.height = 220
$FormSoundCheck2.backcolor = [System.Drawing.Color]::Gainsboro
$FormSoundCheck2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSoundCheck2.Text = "NowYouHearMe Connect"
$FormSoundCheck2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSoundCheck2.maximumsize = New-Object System.Drawing.Size(600,220)
$FormSoundCheck2.startposition = "centerscreen"
$FormSoundCheck2.KeyPreview = $True
$FormSoundCheck2.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSoundCheck2.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,105)
$label.Text = 'You can move this dialog box wherever you want on your screen.

With your DAW set to ASIO4ALL, with OBS open, and with Windows audio set to 
the correct device...

Play something in your DAW. Do you hear sound and is it metering in OBS?'
$FormSoundCheck2.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,135)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSoundCheck2Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,135)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseSoundCheck2No})
$FormSoundCheck2.Topmost = $True
$FormSoundCheck2.MaximizeBox = $Formalse
$FormSoundCheck2.MinimizeBox = $Formalse
#Add them to form and active it
$FormSoundCheck2.Controls.Add($Button1)
$FormSoundCheck2.Controls.Add($Button2)
$FormSoundCheck2.Add_Shown({$FormSoundCheck2.Activate()})
$FormSoundCheck2.ShowDialog()
}
$FormSound1No = New-Object System.Windows.Forms.Form
$FormSound1No.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSound1No.width = 600
$FormSound1No.height = 220
$FormSound1No.backcolor = [System.Drawing.Color]::Gainsboro
$FormSound1No.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSound1No.Text = "NowYouHearMe Connect"
$FormSound1No.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSound1No.maximumsize = New-Object System.Drawing.Size(600,220)
$FormSound1No.startposition = "centerscreen"
$FormSound1No.KeyPreview = $True
$FormSound1No.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSound1No.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,90)
$label.Text = 'OBS plays sound through the default sound device set in Windows.

Read through the steps in the PDF to change your Windows system audio.
You can change your Windows system audio to whatever you want

Also note: In this session, when OBS is closed, you will not hear your DAW.'
$FormSound1No.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,135)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "I Will Read the PDF"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSound1No})
$FormSound1No.Topmost = $True
$FormSound1No.MaximizeBox = $Formalse
$FormSound1No.MinimizeBox = $Formalse
#Add them to form and active it
$FormSound1No.Controls.Add($Button1)
$FormSound1No.Add_Shown({$FormSound1No.Activate()})
$FormSound1No.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
sleep 6
$FormSoundCheck1 = New-Object System.Windows.Forms.Form
$FormSoundCheck1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormSoundCheck1.width = 600
$FormSoundCheck1.height = 200
$FormSoundCheck1.backcolor = [System.Drawing.Color]::Gainsboro
$FormSoundCheck1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormSoundCheck1.Text = "NowYouHearMe Connect"
$FormSoundCheck1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormSoundCheck1.maximumsize = New-Object System.Drawing.Size(600,200)
$FormSoundCheck1.startposition = "centerscreen"
$FormSoundCheck1.KeyPreview = $True
$FormSoundCheck1.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormSoundCheck1.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'You can move this dialog box wherever you want on your screen.

With your DAW set to ASIO4ALL as the Audio Device and with OBS open...

Play something in your DAW. Do you hear sound and is it metering in OBS?'
$FormSoundCheck1.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,115)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseSoundCheck1Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,115)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseSoundCheck1No})
$FormSoundCheck1.Topmost = $True
$FormSoundCheck1.MaximizeBox = $Formalse
$FormSoundCheck1.MinimizeBox = $Formalse
#Add them to form and active it
$FormSoundCheck1.Controls.Add($Button1)
$FormSoundCheck1.Controls.Add($Button2)
$FormSoundCheck1.Add_Shown({$FormSoundCheck1.Activate()})
$FormSoundCheck1.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
cls
sleep 3
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
$label.Size = New-Object System.Drawing.Size(550,50)
$label.Text = "Now that you hear your DAWs audio, tell the Listener over the phone that:

You (The HOST) are now Broadcasting sound."
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
$Button1.Text = "I Told The Listener I'm Ready"
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
cls
sleep 0.5
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
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
sleep 2
if (-NOT (Test-Path "C:\Program Files (x86)\nowyouhearme\failedhost.txt")){
Function CloseDialogConnectCheck1Yes{
$FormConnectCheck1.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogConnectCheck1No{
$FormConnectCheck1.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
Function CloseDialogConnectCheck2Yes{
$FormConnectCheck2.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogConnectCheck2No{
$FormConnectCheck2.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
Function CloseDialogConnectCheck3{
$FormConnectCheck3.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
Function CloseDialogConnectCheck4Yes{
$FormConnectCheck4.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogConnectCheck4No{
$FormConnectCheck4.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
Function CloseDialogConnectCheck5Yes{
$FormConnectCheck5.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogConnectCheck5No{
$FormConnectCheck5.Dispose() | out-null
cls
Write-Host " " 
Write-Host "Signing out and back in. Exiting..."
Write-Host " " 
echo 'Host is signing out and back in.' >"C:\Program Files (x86)\nowyouhearme\failedhost.txt"
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
net stop ZeroTierOneService >$null 2>&1
TASKKILL /F /IM OBS64.exe >$null 2>&1
& "C:\Program Files (x86)\nowyouhearme\scripts\NowYouHearMeConnect-Host.lnk"
Start-Sleep -Seconds 0.5
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\host\global-withndi-controls\global.ndi" "$ENV:UserProfile\AppData\Roaming\obs-studio\" /s /i /q /y
stop-process -Id $PID
}
sleep 4
$FormConnectCheck5 = New-Object System.Windows.Forms.Form
$FormConnectCheck5.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck5.width = 600
$FormConnectCheck5.height = 200
$FormConnectCheck5.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck5.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck5.Text = "NowYouHearMe Connect"
$FormConnectCheck5.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck5.maximumsize = New-Object System.Drawing.Size(600,200)
$FormConnectCheck5.startposition = "centerscreen"
$FormConnectCheck5.KeyPreview = $True
$FormConnectCheck5.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck5.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,75)
$label.Text = 'Was the Listener computer able to connect to discover your computer?

If not, you (the Host) will have to Sign Out and Sign Back In.

MAKE SURE YOU AND THE LISTENER ARE USING THE SAME EMAIL OR USERNAME.'
$FormConnectCheck5.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(130,115)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck5Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(240,115)
$Button2.Size = new-object System.Drawing.Size(220,30)
$Button2.Text = "No, Sign Out and Back In"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogConnectCheck5No})
$FormConnectCheck5.Topmost = $True
$FormConnectCheck5.MaximizeBox = $Formalse
$FormConnectCheck5.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck5.Controls.Add($Button1)
$FormConnectCheck5.Controls.Add($Button2)
$FormConnectCheck5.Add_Shown({$FormConnectCheck5.Activate()})
$FormConnectCheck5.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
sleep 5
$FormConnectCheck4 = New-Object System.Windows.Forms.Form
$FormConnectCheck4.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck4.width = 600
$FormConnectCheck4.height = 170
$FormConnectCheck4.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck4.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck4.Text = "NowYouHearMe Connect"
$FormConnectCheck4.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck4.maximumsize = New-Object System.Drawing.Size(600,170)
$FormConnectCheck4.startposition = "centerscreen"
$FormConnectCheck4.KeyPreview = $True
$FormConnectCheck4.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck4.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,55)
$label.Text = 'How about now?

Was the Listener computer able to connect to discover your computer?'
$FormConnectCheck4.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,80)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck2Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,80)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No, Retry"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogConnectCheck4No})
$FormConnectCheck4.Topmost = $True
$FormConnectCheck4.MaximizeBox = $Formalse
$FormConnectCheck4.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck4.Controls.Add($Button1)
$FormConnectCheck4.Controls.Add($Button2)
$FormConnectCheck4.Add_Shown({$FormConnectCheck4.Activate()})
$FormConnectCheck4.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
}
sleep 10
$FormConnectCheck3 = New-Object System.Windows.Forms.Form
$FormConnectCheck3.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck3.width = 500
$FormConnectCheck3.height = 190
$FormConnectCheck3.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck3.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck3.Text = "NowYouHearMe Connect"
$FormConnectCheck3.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck3.maximumsize = New-Object System.Drawing.Size(500,190)
$FormConnectCheck3.startposition = "centerscreen"
$FormConnectCheck3.KeyPreview = $True
$FormConnectCheck3.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck3.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,75)
$label.Text = 'Waiting for Listener to reconnect...

Click Try Again only AFTER the Listener has signed back in and is 
ready to discover your computer.'
$FormConnectCheck3.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,100)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Try Again"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck3})
$FormConnectCheck3.Topmost = $True
$FormConnectCheck3.MaximizeBox = $Formalse
$FormConnectCheck3.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck3.Controls.Add($Button1)
$FormConnectCheck3.Add_Shown({$FormConnectCheck3.Activate()})
$FormConnectCheck3.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
}
sleep 3
$FormConnectCheck2 = New-Object System.Windows.Forms.Form
$FormConnectCheck2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck2.width = 600
$FormConnectCheck2.height = 170
$FormConnectCheck2.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck2.Text = "NowYouHearMe Connect"
$FormConnectCheck2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck2.maximumsize = New-Object System.Drawing.Size(600,170)
$FormConnectCheck2.startposition = "centerscreen"
$FormConnectCheck2.KeyPreview = $True
$FormConnectCheck2.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck2.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,55)
$label.Text = 'Was the Listener computer able to connect to discover your computer?

If not, the Listener will have to Sign Out and Sign Back In.'
$FormConnectCheck2.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(140,80)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck2Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(250,80)
$Button2.Size = new-object System.Drawing.Size(200,30)
$Button2.Text = "No, Wait for Listener"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogConnectCheck2No})
$FormConnectCheck2.Topmost = $True
$FormConnectCheck2.MaximizeBox = $Formalse
$FormConnectCheck2.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck2.Controls.Add($Button1)
$FormConnectCheck2.Controls.Add($Button2)
$FormConnectCheck2.Add_Shown({$FormConnectCheck2.Activate()})
$FormConnectCheck2.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
}
sleep 5
$FormConnectCheck1 = New-Object System.Windows.Forms.Form
$FormConnectCheck1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck1.width = 600
$FormConnectCheck1.height = 150
$FormConnectCheck1.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck1.Text = "NowYouHearMe Connect"
$FormConnectCheck1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck1.maximumsize = New-Object System.Drawing.Size(600,150)
$FormConnectCheck1.startposition = "centerscreen"
$FormConnectCheck1.KeyPreview = $True
$FormConnectCheck1.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck1.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,35)
$label.Text = 'Was the Listener computer able to connect to discover your computer?'
$FormConnectCheck1.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,60)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck1Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,60)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No, Retry"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogConnectCheck1No})
$FormConnectCheck1.Topmost = $True
$FormConnectCheck1.MaximizeBox = $Formalse
$FormConnectCheck1.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck1.Controls.Add($Button1)
$FormConnectCheck1.Controls.Add($Button2)
$FormConnectCheck1.Add_Shown({$FormConnectCheck1.Activate()})
$FormConnectCheck1.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
}
if (Test-Path "C:\Program Files (x86)\nowyouhearme\failedhost.txt"){
Function CloseDialogConnectCheck6Yes{
$FormConnectCheck6.Dispose() | out-null
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\failedhost.txt"
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogConnectCheck6No{
$FormConnectCheck6.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
Function CloseDialogConnectCheck7Yes{
$FormConnectCheck7.Dispose() | out-null
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\failedhost.txt"
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseDialogConnectCheck7No{
$FormConnectCheck7.Dispose() | out-null
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
Function CloseDialogConnectCheck8{
$FormConnectCheck8.Dispose() | out-null
cls
Write-Host "Well, crap..."
Write-Host " " 
Write-Host "Signing out. Exiting..."
Write-Host " " 
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\failedhost.txt"
$ztleave = "C:\ProgramData\ZeroTier\One\zerotier-one_x64.exe -q leave "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Start-Sleep -Seconds 0.5
Remove-Item –path "C:\Program Files (x86)\nowyouhearme\oldztid.txt"
net stop ZeroTierOneService >$null 2>&1
TASKKILL /F /IM OBS64.exe >$null 2>&1
Start-Sleep -Seconds 0.5
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\host\global-withndi-controls\global.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio\" /s /i /q /y
cls
stop-process -Id $PID
}
sleep 1
$FormConnectCheck8 = New-Object System.Windows.Forms.Form
$FormConnectCheck8.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck8.width = 600
$FormConnectCheck8.height = 250
$FormConnectCheck8.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck8.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck8.Text = "NowYouHearMe Connect"
$FormConnectCheck8.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck8.maximumsize = New-Object System.Drawing.Size(600,250)
$FormConnectCheck8.startposition = "centerscreen"
$FormConnectCheck8.KeyPreview = $True
$FormConnectCheck8.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck8.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,135)
$label.Text = 'Hmmm, today is just not your day.
Listener and Host Computers could not autodetect each other.

Try you and the Listener rebooting both your computers?

Try again later. For now, change your DAW audio output preferences back
to your internal speakers or audio interface (setting it back to normal).'
$FormConnectCheck8.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(190,160)
$Button1.Size = new-object System.Drawing.Size(200,30)
$Button1.Text = "Well, crap...Exit"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck8})
$FormConnectCheck8.Topmost = $True
$FormConnectCheck8.MaximizeBox = $Formalse
$FormConnectCheck8.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck8.Controls.Add($Button1)
$FormConnectCheck8.Add_Shown({$FormConnectCheck8.Activate()})
$FormConnectCheck8.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
}
sleep 3
$FormConnectCheck7 = New-Object System.Windows.Forms.Form
$FormConnectCheck7.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck7.width = 600
$FormConnectCheck7.height = 150
$FormConnectCheck7.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck7.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck7.Text = "NowYouHearMe Connect"
$FormConnectCheck7.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck7.maximumsize = New-Object System.Drawing.Size(600,170)
$FormConnectCheck7.startposition = "centerscreen"
$FormConnectCheck7.KeyPreview = $True
$FormConnectCheck7.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck7.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,35)
$label.Text = 'Again, was the Listener computer able to connect to discover your computer?'
$FormConnectCheck7.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,60)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck7Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,60)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogConnectCheck7No})
$FormConnectCheck7.Topmost = $True
$FormConnectCheck7.MaximizeBox = $Formalse
$FormConnectCheck7.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck7.Controls.Add($Button1)
$FormConnectCheck7.Controls.Add($Button2)
$FormConnectCheck7.Add_Shown({$FormConnectCheck7.Activate()})
$FormConnectCheck7.ShowDialog()
cls
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
}
sleep 5
$FormConnectCheck6 = New-Object System.Windows.Forms.Form
$FormConnectCheck6.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormConnectCheck6.width = 600
$FormConnectCheck6.height = 150
$FormConnectCheck6.backcolor = [System.Drawing.Color]::Gainsboro
$FormConnectCheck6.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormConnectCheck6.Text = "NowYouHearMe Connect"
$FormConnectCheck6.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormConnectCheck6.maximumsize = New-Object System.Drawing.Size(600,150)
$FormConnectCheck6.startposition = "centerscreen"
$FormConnectCheck6.KeyPreview = $True
$FormConnectCheck6.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormConnectCheck6.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,35)
$label.Text = 'Was the Listener computer able to connect to discover your computer?'
$FormConnectCheck6.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,60)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogConnectCheck6Yes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(290,60)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No, Retry"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseDialogConnectCheck6No})
$FormConnectCheck6.Topmost = $True
$FormConnectCheck6.MaximizeBox = $Formalse
$FormConnectCheck6.MinimizeBox = $Formalse
#Add them to form and active it
$FormConnectCheck6.Controls.Add($Button1)
$FormConnectCheck6.Controls.Add($Button2)
$FormConnectCheck6.Add_Shown({$FormConnectCheck6.Activate()})
$FormConnectCheck6.ShowDialog()
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
sleep 1
$sig = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
Add-Type -MemberDefinition $sig -name NativeMethods -namespace Win32
$hwnd = @(Get-Process OBS64)[0].MainWindowHandle
# Minimize window
[Win32.NativeMethods]::ShowWindowAsync($hwnd, 2)
# Restore window
[Win32.NativeMethods]::ShowWindowAsync($hwnd, 4)
sleep 2
Function CloseInputRouteNo{
$FormInputRoute.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
}
Function CloseInputRouteYes{
$FormInputRoute.Dispose() | out-null
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
start "C:\Program Files (x86)\nowyouhearme\nyhm-optional-asio-panel.pdf"
sleep 18
}
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 10
$FormInputRoute = New-Object System.Windows.Forms.Form
$FormInputRoute.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormInputRoute.width = 500
$FormInputRoute.height = 200
$FormInputRoute.backcolor = [System.Drawing.Color]::Gainsboro
$FormInputRoute.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormInputRoute.Text = "NowYouHearMe Connect"
$FormInputRoute.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormInputRoute.maximumsize = New-Object System.Drawing.Size(500,200)
$FormInputRoute.startposition = "centerscreen"
$FormInputRoute.KeyPreview = $True
$FormInputRoute.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormInputRoute.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,85)
$label.Text = '(Advanced Users) Optionally you can route an input in ASIO4ALL
such as an instrument or mic to your DAW for streaming.

Would you like to open the guide to see how to do that?'
$FormInputRoute.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(130,115)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "No"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseInputRouteNo})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(240,115)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Yes"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseInputRouteYes})
$FormInputRoute.Topmost = $True
$FormInputRoute.MaximizeBox = $Formalse
$FormInputRoute.MinimizeBox = $Formalse
#Add them to form and active it
$FormInputRoute.Controls.Add($Button1)
$FormInputRoute.Controls.Add($Button2)
$FormInputRoute.Add_Shown({$FormInputRoute.Activate()})
$FormInputRoute.ShowDialog()
Remove-Item –path "$ENV:UserProfile\AppData\Roaming\obs-studio\global.ini"
xcopy "C:\Program Files (x86)\nowyouhearme\OBSconfigs\host\global-withndi-controls\global.ini" "$ENV:UserProfile\AppData\Roaming\obs-studio\" /s /i /q /y
cls
Write-Host "******************************************"
Write-Host " " 
Write-Host "         Welcome to NowYouHear.me     "
Write-Host " "
Write-Host "******************************************"
Write-Host " " 
Write-Host " "
sleep 2
Function CloseDialogOpenTV{
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
(Get-Process -Name OBS64).MainWindowHandle | foreach { Set-WindowStyle MINIMIZE $_ }
sleep 0.5
& "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
sleep 7
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
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
$label.Text = '(Allow Remote Control) Give the Listener your TeamViewer ID 
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
$label.Text = 'Once the Listener is connected, they should now be able to hear 
and see your computer.'
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
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

In this session as the Host, the Listener would be remoting to you.
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
sleep 4
$FormOpenTV = New-Object System.Windows.Forms.Form
$FormOpenTV.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOpenTV.width = 550
$FormOpenTV.height = 270
$FormOpenTV.backcolor = [System.Drawing.Color]::Gainsboro
$FormOpenTV.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOpenTV.Text = "NowYouHearMe Connect"
$FormOpenTV.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOpenTV.maximumsize = New-Object System.Drawing.Size(550,270)
$FormOpenTV.startposition = "centerscreen"
$FormOpenTV.KeyPreview = $True
$FormOpenTV.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOpenTV.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(550,145)
$label.Text = 'Finally, the Listener needs to be able to see and control the Hosts (your) screen.

However, is this session either for personal or commercial use?

Personal is between musicians on their home computers.
Click to open TeamViewer (it is free for personal use).

Commercial is between studios OR when offering private lessons.
Click to buy TeamViewer or open a list of alternative programs.'
$FormOpenTV.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(160,180)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Personal"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogOpenTVYes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(275,180)
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
Write-Host " "
sleep 1
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
BUT DO NOT CLOSE lT.'
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
Write-Host " "
Write-Host "Your computer's name is $env:computername"
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host " "
Write-Host "Your OBS preferences are setup to send audio from your computer."
Write-Host " "
Write-Host " "
Write-Host "NowYouHearMe Connect."
Write-Host " "
Write-Host " "
Write-Host " " 
Write-Host "You are the Host within this session. Play some audio through your DAW." 
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
Write-Host "******************************************************************************"
Write-Host " " 
Write-Host "You are connected to $email's NowYouHear.me network!"
Write-Host " " 
Write-Host "Keep this window open." 
Write-Host " " 
Write-Host "******************************************************************************"
Write-Host " "
Write-Host " "
Write-Host "You may minimize this Command Terminal window. BUT DO NOT CLOSE IT."
Write-Host " "
Write-Host " "
sleep 1
Write-Host "When you are done hosting this session and want to exit..."
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
Write-Host "Disconnecting from your NowYouHear.me network. Please wait..."
Write-Host " "
$ztleaveid = $ztleave + $ztid
powershell -command $ztleaveid
Write-Output "Disconnecting from your NowYouHear.me network..." " " " "
Start-Sleep -Seconds 1
net stop ZeroTierOneService >$null 2>&1
Write-Host "Exiting..." 
TASKKILL /F /IM OBS64.exe >$null 2>&1
TASKKILL /F /IM TeamViewer.exe >$null 2>&1
Start-Sleep -Seconds 1
Remove-Item -path "$ENV:UserProfile\AppData\Roaming\obs-studio" -recurse
xcopy "$ENV:UserProfile\AppData\Roaming\obs-studio-$date" "$ENV:UserProfile\AppData\Roaming\obs-studio" /s /i /q /y
Remove-Item -path "$ENV:UserProfile\AppData\Roaming\obs-studio-$date" -recurse
cls
Function CloseDialogDAWReminder{
$FormDAWReminder.Dispose() | out-null
cls
Write-Host "Exiting NowYouHear.me..."
Write-Host " "
}
cls
Write-Host "Exiting NowYouHear.me"
Write-Host " "
$FormDAWReminder = New-Object System.Windows.Forms.Form
$FormDAWReminder.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormDAWReminder.width = 520
$FormDAWReminder.height = 220
$FormDAWReminder.backcolor = [System.Drawing.Color]::Gainsboro
$FormDAWReminder.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormDAWReminder.Text = "NowYouHearMe Connect"
$FormDAWReminder.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormDAWReminder.maximumsize = New-Object System.Drawing.Size(520,220)
$FormDAWReminder.startposition = "centerscreen"
$FormDAWReminder.KeyPreview = $True
$FormDAWReminder.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormDAWReminder.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(520,115)
$label.Text = 'You may also want to change your DAWs audio output preferences 
back to your internal speakers or audio interface.

(setting it back to normal).

Thanks for using NowYouHear.me!'
$FormDAWReminder.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(200,135)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "WOOHOO!"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseDialogDAWReminder})
$FormDAWReminder.Topmost = $True
$FormDAWReminder.MaximizeBox = $Formalse
$FormDAWReminder.MinimizeBox = $Formalse
#Add them to form and active it
$FormDAWReminder.Controls.Add($Button1)
$FormDAWReminder.Add_Shown({$FormDAWReminder.Activate()})
$FormDAWReminder.ShowDialog()
cls
Write-Host "Exiting NowYouHear.me"
Write-Host " "
sleep 1
exit
}
}
}
}