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
$localpath=(Get-Content "$ENV:UserProfile\AppData\Local\Temp\localpath.txt")
Remove-Item -path "$ENV:UserProfile\AppData\Local\Temp\localpath.txt"
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
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$test=(Test-Connection www.google.com -Count 1 ) 2> $null
if (!$test){
$FormOnline = New-Object System.Windows.Forms.Form
$FormOnline.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$localpath\nowyouhearme\images\smallicon.ico")
$FormOnline.width = 600
$FormOnline.height = 200
$FormOnline.backcolor = [System.Drawing.Color]::Gainsboro
$FormOnline.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOnline.Text = "NowYouHearMe Installation"
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
$label.Text = 'You are not connected to the Internet, or at least NowYouHearMe 
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
$FormWelcome = New-Object System.Windows.Forms.Form
$FormWelcome.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$localpath\nowyouhearme\images\smallicon.ico")
$FormWelcome.width = 600
$FormWelcome.height = 200
$FormWelcome.backcolor = [System.Drawing.Color]::Gainsboro
$FormWelcome.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormWelcome.Text = "NowYouHearMe Installation"
$FormWelcome.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormWelcome.maximumsize = New-Object System.Drawing.Size(600,200)
$FormWelcome.startposition = "centerscreen"
$FormWelcome.KeyPreview = $True
$FormWelcome.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormWelcome.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormWelcome.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'Welcome to the NowYouHearMe Installation!

This process to install all needed programs will take about 5 minutes to complete
and take up about 500MB of disk space.'
$FormWelcome.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormWelcome.Dispose()})
$FormWelcome.Topmost = $True
$FormWelcome.MaximizeBox = $Formalse
$FormWelcome.MinimizeBox = $Formalse
#Add them to form and active it
$FormWelcome.Controls.Add($Button1)
$FormWelcome.Add_Shown({$FormWelcome.Activate()})
$FormWelcome.ShowDialog()
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
if (!(Test-Path "C:\Program Files (x86)\nowyouhearme\images\nowyouhearme_icon.ico")){
xcopy /y /E $localpath\nowyouhearme "C:\Program Files (x86)\nowyouhearme\" >$null 2>&1
echo " "
echo "Copied nowyouhearme files to C:\Program Files (x86)\nowyouhearme\"
sleep 2
}
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 1 of 8. Installing Chocolately.org framework. Please wait..."
echo " "
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) >$null 2>&1
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Installed chocolately.org framework to install programs from the chocolatey repository." 
echo " "
if (Test-Path "C:\Users\ben\AppData\Roaming\obs-studio\global.ini"){xcopy "C:\Users\ben\AppData\Roaming\obs-studio" "C:\Users\ben\AppData\Roaming\obs-studio-before-nyhm\"}
if (!(Test-Path "C:\Program Files\obs-studio\bin\64bit\obs64.exe")){
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 2 of 8. Installing OBS (Open Broadcaster Software)...please wait..."
echo "This may take up to 2 minutes to download and install."
echo " "
choco install obs-studio -y >$null 2>&1
echo " "
echo "Installed OBS (Open Broadcaster Software)"
xcopy /y /E "C:\Program Files (x86)\nowyouhearme\OBSconfigs\original\obs-studio" "$ENV:UserProfile\AppData\Roaming\obs-studio\" >$null 2>&1
}
if (!(Test-Path "C:\Program Files (x86)\ZeroTier\One\ZeroTier One.exe")){
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 3 of 8. Installing ZeroTier VPN. Please Wait..."
echo " "
choco install zerotier-one -y >$null 2>&1
echo " "
echo "Installed ZeroTier VPN."
echo " "
net stop ZeroTierOneService 
echo " " 
echo "Stopped the Zero Tier Service."
echo " "
Set-Service ZeroTierOneService -StartupType Manual
echo " "
echo "Made Zero Tier Service Manual Start, made it not auto start."
echo " "
}
if (!(Test-Path "C:\Program Files (x86)\ASIO4ALL v2\asio4all.dll")) {
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 4 of 8. Installing ASIO4ALL. Please wait..."
echo " "
choco install asio4all -y >$null 2>&1
echo " "
echo "Installed ASIO4ALL."
echo " "
}
if (!(Test-Path "C:\Program Files (x86)\TeamViewer\TeamViewer.exe")) {
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 5 of 8. Installing TeamViewer. Please wait..."
echo " "
choco install teamviewer -y >$null 2>&1
echo " "
echo "Installed TeamViewer."
}
if (!(Test-Path C:\Windows\system32\dns-sd.exe)){
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 6 of 8. Installing Apple Bonjour. Please wait..."
echo " "
choco install bonjour -y >$null 2>&1
sleep 8
if (!(Test-Path C:\Windows\system32\dns-sd.exe)){
sleep 8
choco install bonjour -y >$null 2>&1
sleep 8
if (!(Test-Path C:\Windows\system32\dns-sd.exe)){
sleep 8
choco install bonjour -y >$null 2>&1
}
}
if (Test-Path C:\Windows\system32\dns-sd.exe){
echo " "
echo "Installed Apple Bonjour for peer-to-peer discovery."
sleep 2
}
}
xcopy /y "C:\Program Files (x86)\nowyouhearme\scripts\nyhm-update.ps1" "C:\ProgramData\nowyouhearme\" >$null 2>&1
Remove-Item -path "C:\Program Files (x86)\nowyouhearme\scripts\nyhm-update.ps1"
xcopy /y "C:\Program Files (x86)\nowyouhearme\NowYouHearMeConnect.lnk" C:\Users\Public\Desktop\ >$null 2>&1
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
$preid=(Get-WmiObject Win32_PnPEntity | Select Name,DeviceID | Select-String -Pattern "VB-Audio" | Select-String -Pattern "0.0.1" | %{$_ -replace "@{Name=CABLE Output "} | %{$_ -replace "(VB-Audio Virtual Cable)"}) | %{$_ -replace "@{Name=Hi-Fi Cable Output "}
if (!$preid){
echo "Step 7 of 8. Downloading and extracting vb-audio cable..."
echo " "
if (!(Test-Path C:\Windows\system32\dns-sd.exe)){
Start-Process "$localpath\installbonjour.bat" -NoNewWindow
}
Invoke-WebRequest -Uri https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip -OutFile "C:\Program Files (x86)\nowyouhearme\download\VBCABLE_Driver_Pack43.zip"
expand-archive -path 'C:\Program Files (x86)\nowyouhearme\download\VBCABLE_Driver_Pack43.zip' -destinationpath 'C:\Program Files (x86)\nowyouhearme\download\vbcable'
Remove-Item -path "C:\Program Files (x86)\nowyouhearme\download\VBCABLE_Driver_Pack43.zip"
& "C:\Program Files (x86)\nowyouhearme\download\vbcable\VBCABLE_Setup_x64.exe"
sleep 15
start https://www.vb-audio.com/Services/licensing.htm
sleep 3
$FormVB = New-Object System.Windows.Forms.Form
$FormVB.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$localpath\nowyouhearme\images\smallicon.ico")
$FormVB.width = 600
$FormVB.height = 200
$FormVB.backcolor = [System.Drawing.Color]::Gainsboro
$FormVB.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormVB.Text = "VB-CABLE Reminder"
$FormVB.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormVB.maximumsize = New-Object System.Drawing.Size(600,200)
$FormVB.startposition = "centerscreen"
$FormVB.KeyPreview = $True
$FormVB.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormVB.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormVB.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'VB-CABLE is a virtual audio device and an audio cable between 2 applications.

VB-CABLE is donationware, all participations are welcome. 
Check out their website at www.vb-cable.com'
$FormVB.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormVB.Dispose()})
$FormVB.Topmost = $True
$FormVB.MaximizeBox = $Formalse
$FormVB.MinimizeBox = $Formalse
#Add them to form and active it
$FormVB.Controls.Add($Button1)
$FormVB.Add_Shown({$FormVB.Activate()})
$FormVB.ShowDialog()
}
sleep 5
if (!(Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll")){
Invoke-WebRequest -Uri https://github.com/Palakis/obs-ndi/releases/download/4.6.0/obs-ndi-4.6.0-Windows-Installer.exe -OutFile "C:\Program Files (x86)\nowyouhearme\download\obs-ndi-4.6.0-Windows-Installer.exe"
$FormOBSNDI = New-Object System.Windows.Forms.Form
$FormOBSNDI.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$localpath\nowyouhearme\images\smallicon.ico")
$FormOBSNDI.width = 600
$FormOBSNDI.height = 200
$FormOBSNDI.backcolor = [System.Drawing.Color]::Gainsboro
$FormOBSNDI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOBSNDI.Text = "VB-CABLE Reminder"
$FormOBSNDI.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOBSNDI.maximumsize = New-Object System.Drawing.Size(600,200)
$FormOBSNDI.startposition = "centerscreen"
$FormOBSNDI.KeyPreview = $True
$FormOBSNDI.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOBSNDI.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormOBSNDI.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'Step 8 of 8. Click OK to install the OBS-NDI plugin.

OBS-NDI is from the developer, Palakis. It also installs the NDI runtime.

https://github.com/Palakis/obs-ndi'
$FormOBSNDI.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormOBSNDI.Dispose()})
$FormOBSNDI.Topmost = $True
$FormOBSNDI.MaximizeBox = $Formalse
$FormOBSNDI.MinimizeBox = $Formalse
#Add them to form and active it
$FormOBSNDI.Controls.Add($Button1)
$FormOBSNDI.Add_Shown({$FormOBSNDI.Activate()})
$FormOBSNDI.ShowDialog()
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 8 of 8. Installing OBS-NDI plugin..."
echo " "
& "C:\Program Files (x86)\nowyouhearme\download\obs-ndi-4.6.0-Windows-Installer.exe"
sleep 5
New-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\ -Value "C:\Program Files (x86)\nowyouhearme\NowYouHearMePostInstallation.pdf" -Force >$null 2>&1
New-NetFirewallRule -DisplayName "obs64" -Direction Inbound -Program "C:\Program Files\obs-studio\bin\64bit\obs64.exe" -Profile Private -Protocol UDP -RemoteAddress Any -Action Allow >$null 2>&1
New-NetFirewallRule -DisplayName "obs64" -Direction Inbound -Program "C:\Program Files (x86)\obs-studio\bin\64bit\obs64.exe" -Profile Private -Protocol UDP -RemoteAddress Any -Action Allow >$null 2>&1
New-NetFirewallRule -DisplayName "obs64" -Direction Inbound -Program "C:\Program Files (x86)\obs-studio\bin\64bit\obs64.exe" -Profile Private -Protocol TCP -RemoteAddress Any -Action Allow >$null 2>&1
New-NetFirewallRule -DisplayName "obs64" -Direction Inbound -Program "C:\Program Files\obs-studio\bin\64bit\obs64.exe" -Profile Private -Protocol TCP -RemoteAddress Any -Action Allow >$null 2>&1
New-NetFirewallRule -DisplayName "OBS Studio" -Direction Inbound -Program "C:\program files\obs-studio\bin\64bit\obs64.exe" -Profile Public -Protocol TCP -RemoteAddress Any -Action Allow >$null 2>&1
New-NetFirewallRule -DisplayName "OBS Studio" -Direction Inbound -Program "C:\program files\obs-studio\bin\64bit\obs64.exe" -Profile Public -Protocol UDP -RemoteAddress Any -Action Allow >$null 2>&1
sleep 45
if (Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll"){
$reboot="yes"
echo "Installed the OBS-NDI plugins + the NDI runtime."
echo "Please reboot your computer after installation..."
}
if (!(Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll")){
sleep 10
if (Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll"){
$reboot="yes"
echo "Installed the OBS-NDI plugins + the NDI runtime."
echo "Please reboot your computer after installation..."
}
}
if (!(Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll")){
sleep 5
$FormOBSNDI = New-Object System.Windows.Forms.Form
$FormOBSNDI.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$localpath\nowyouhearme\images\smallicon.ico")
$FormOBSNDI.width = 600
$FormOBSNDI.height = 200
$FormOBSNDI.backcolor = [System.Drawing.Color]::Gainsboro
$FormOBSNDI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOBSNDI.Text = "VB-CABLE Reminder"
$FormOBSNDI.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOBSNDI.maximumsize = New-Object System.Drawing.Size(600,200)
$FormOBSNDI.startposition = "centerscreen"
$FormOBSNDI.KeyPreview = $True
$FormOBSNDI.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOBSNDI.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormOBSNDI.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,85)
$label.Text = 'Waiting for user to install. Step 8 of 8. Click OK.

OBS-NDI is from the developer, Palakis. It also installs the NDI runtime.

https://github.com/Palakis/obs-ndi'
$FormOBSNDI.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,105)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "OK"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormOBSNDI.Dispose()})
$FormOBSNDI.Topmost = $True
$FormOBSNDI.MaximizeBox = $Formalse
$FormOBSNDI.MinimizeBox = $Formalse
#Add them to form and active it
$FormOBSNDI.Controls.Add($Button1)
$FormOBSNDI.Add_Shown({$FormOBSNDI.Activate()})
$FormOBSNDI.ShowDialog()
cls
echo "*************************************************"
echo "*                                               *"
echo "* Welcome to the NowYouHear.me installation...  *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
echo "Step 8 of 8. Installing OBS-NDI plugin..."
echo " "
sleep 15
if (Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll"){
$reboot="yes"
echo "Installed the OBS-NDI plugins + the NDI runtime."
echo "Please reboot your computer after installation..."
}
if (!(Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll")){
sleep 10
if (Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll"){
$reboot="yes"
echo "Installed the OBS-NDI plugins + the NDI runtime."
echo "Please reboot your computer after installation..."
}
}
}
if (Test-Path "C:\Program Files\obs-studio\obs-plugins\64bit\obs-ndi.dll"){$reboot="yes"}
echo " "
}
cls
if (!$reboot){
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
$FormDone = New-Object System.Windows.Forms.Form
$FormDone.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormDone.width = 500
$FormDone.height = 160
$FormDone.backcolor = [System.Drawing.Color]::Gainsboro
$FormDone.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormDone.Text = "NowYouHearMe Installation"
$FormDone.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormDone.maximumsize = New-Object System.Drawing.Size(500,160)
$FormDone.startposition = "centerscreen"
$FormDone.KeyPreview = $True
$FormDone.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormDone.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,50)
$label.Text = 'Thanks for installing NowYouHearMe! Installation is complete. 

You may now open NowYouHearMe from the Desktop icon.'
$FormDone.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(180,75)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "WOOHOO"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormDone.Dispose()})
$FormDone.Topmost = $True
$FormDone.MaximizeBox = $Formalse
$FormDone.MinimizeBox = $Formalse
#Add them to form and active it
$FormDone.Controls.Add($Button1)
$FormDone.Add_Shown({$FormDone.Activate()})
$FormDone.ShowDialog()
start "C:\Program Files (x86)\nowyouhearme\NowYouHearMePostInstallation.pdf"
cls
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
sleep 4
}
if ($reboot){
$preid=(Get-WmiObject Win32_PnPEntity | Select Name,DeviceID | Select-String -Pattern "VB-Audio" | Select-String -Pattern "0.0.1" | %{$_ -replace "@{Name=CABLE Output "} | %{$_ -replace "(VB-Audio Virtual Cable)"}) | %{$_ -replace "@{Name=Hi-Fi Cable Output "}
if (!$preid){
sleep 5
start https://www.vb-audio.com/Services/licensing.htm
sleep 3
}
Function CloseFormRebootYes{
$FormReboot.Dispose()
cls
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
shutdown /r /c "Your computer will restart in less that a minute. NowYouHear.me installation is complete."
}
Function CloseFormRebootNo{
$FormReboot.Dispose()
cls
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
$FormRebootRemind = New-Object System.Windows.Forms.Form
$FormRebootRemind.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormRebootRemind.width = 500
$FormRebootRemind.height = 160
$FormRebootRemind.backcolor = [System.Drawing.Color]::Gainsboro
$FormRebootRemind.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormRebootRemind.Text = "NowYouHearMe Installation"
$FormRebootRemind.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormRebootRemind.maximumsize = New-Object System.Drawing.Size(500,160)
$FormRebootRemind.startposition = "centerscreen"
$FormRebootRemind.KeyPreview = $True
$FormRebootRemind.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormRebootRemind.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,50)
$label.Text = 'You may reboot later, however you must reboot before 
running NowYouHearMe.'
$FormRebootRemind.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(160,75)
$Button1.Size = new-object System.Drawing.Size(150,30)
$Button1.Text = "I Understand"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormRebootRemind.Dispose()})
$FormRebootRemind.Topmost = $True
$FormRebootRemind.MaximizeBox = $Formalse
$FormRebootRemind.MinimizeBox = $Formalse
#Add them to form and active it
$FormRebootRemind.Controls.Add($Button1)
$FormRebootRemind.Add_Shown({$FormRebootRemind.Activate()})
$FormRebootRemind.ShowDialog()
cls
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
sleep 4
}
cls
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
$FormReboot = New-Object System.Windows.Forms.Form
$FormReboot.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormReboot.width = 500
$FormReboot.height = 160
$FormReboot.backcolor = [System.Drawing.Color]::Gainsboro
$FormReboot.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormReboot.Text = "NowYouHearMe Installation"
$FormReboot.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormReboot.maximumsize = New-Object System.Drawing.Size(500,160)
$FormReboot.startposition = "centerscreen"
$FormReboot.KeyPreview = $True
$FormReboot.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormReboot.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,50)
$label.Text = 'AFTER YOU HAVE INSTALLED OBS-NDI, YOU MUST REBOOT.

Otherwise NowYouHear.me will not work. Reboot now?'
$FormReboot.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(130,75)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Yes"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({CloseFormRebootYes})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(240,75)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "No"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({CloseFormRebootNo})
$FormReboot.Topmost = $True
$FormReboot.MaximizeBox = $Formalse
$FormReboot.MinimizeBox = $Formalse
#Add them to form and active it
$FormReboot.Controls.Add($Button1)
$FormReboot.Controls.Add($Button2)
$FormReboot.Add_Shown({$FormReboot.Activate()})
$FormReboot.ShowDialog()
cls
echo "*************************************************"
echo "*                                               *"
echo "*     Thanks for installing NowYouHear.me       *"
echo "*                                               *"
echo "*************************************************"
echo " "
echo " "
sleep 4
}