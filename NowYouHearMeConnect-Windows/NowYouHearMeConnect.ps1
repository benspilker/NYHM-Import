Add-Type -AssemblyName System.Windows.Forms
$woot = New-Object system.Windows.Forms.Form
$woot.Text = "NowYouHearMe Connect"
$woot.TopMost = $True
$woot.TopLevel = $true;
$woot.TopMost = $true;
$woot.MaximizeBox = $Formalse
$woot.MinimizeBox = $Formalse
$woot.ShowInTaskbar = $Formalse
$woot.FormBorderStyle = "FixedDialog"
$woot.startposition = "centerscreen"
$woot.BackgroundImage = [system.drawing.image]::FromFile("C:\Program Files (x86)\nowyouhearme\images\nyhm-welcome.png")
$woot.Width = 800
$woot.Height = 185
[void]$woot.Show()
reg add "HKCU\Console" /f /v "QuickEdit" /t REG_DWORD /d "0" >$null 2>&1
Set-Itemproperty -path 'HKCU:\Console\%SystemRoot%_SysWOW64_WindowsPowerShell_v1.0_powershell.exe\' -Name 'QuickEdit' -value '0'
Set-Itemproperty -path 'HKCU:\Console\%SystemRoot%_System32_WindowsPowerShell_v1.0_powershell.exe\' -Name 'QuickEdit' -value '0'
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
$console = $host.ui.rawui
$console.backgroundcolor = "DarkGray"
$console.foregroundcolor = "white"
$colors = $host.privatedata
clear-host
sleep 1
if (Test-Path "$env:windir\System32\drivers\etc\hosts-prenyhm"){
Remove-Item -path "$env:windir\System32\drivers\etc\hosts"
Rename-Item -path "$env:windir\System32\drivers\etc\hosts-prenyhm" -NewName "$env:windir\System32\drivers\etc\hosts"
}
$woot.Dispose()
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$test=(Test-Connection www.google.com -Count 1 ) 2> $null
if (!$test){
$FormOnline = New-Object System.Windows.Forms.Form
$FormOnline.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormOnline.width = 600
$FormOnline.height = 185
$FormOnline.backcolor = [System.Drawing.Color]::Gainsboro
$FormOnline.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormOnline.Text = "NowYouHearMe Connect"
$FormOnline.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormOnline.maximumsize = New-Object System.Drawing.Size(600,185)
$FormOnline.startposition = "centerscreen"
$FormOnline.KeyPreview = $True
$FormOnline.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormOnline.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormOnline.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,80)
$label.Text = 'You are not connected to the Internet, or at least NowYouHearMe Connect 
could not ping Google.

Check your connection or reboot your computer...'
$FormOnline.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,100)
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
Function UpdateScript{
$FormCheckUpdate.Dispose()
PowerShell -NoProfile -ExecutionPolicy Unrestricted -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Unrestricted -File "C:\ProgramData\nowyouhearme\nyhm-update.ps1"' -Verb RunAs}"
}
Function Map1.1{
$Form.Dispose()
$Form1 = New-Object System.Windows.Forms.Form
$Form1.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Form1.width = 650
$Form1.height = 195
$Form1.backcolor = [System.Drawing.Color]::Gainsboro
$Form1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form1.Text = "NowYouHearMe Connect"
$Form1.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Form1.maximumsize = New-Object System.Drawing.Size(650,195)
$Form1.startposition = "centerscreen"
$Form1.KeyPreview = $True
$Form1.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Form1.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form1.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(650,90)
$label.Text = 'You Picked Host.

You will be the Music Producer, HOSTING a session.

You will be guided how to setup your computer for this session in the next few steps.'
$Form1.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(190,110)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Continue"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({Map1})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(315,110)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Exit"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({$Form1.Dispose()})
$Form1.Topmost = $True
$Form1.MaximizeBox = $Formalse
$Form1.MinimizeBox = $Formalse
#Add them to form and active it
$Form1.Controls.Add($Button1)
$Form1.Controls.Add($Button2)
$Form1.Add_Shown({$Form1.Activate()})
$Form1.ShowDialog()
}
Function Map1{
& "C:\Program Files (x86)\nowyouhearme\scripts\NowYouHearMeConnect-Host.lnk"
$Form1.Dispose()
}
Function Map2{
& "C:\Program Files (x86)\nowyouhearme\scripts\NowYouHearMeConnect-Listener.lnk"
$Form2.Dispose()
}
#Map
Function Map2.1{
$Form.Dispose()
$Form2 = New-Object System.Windows.Forms.Form
$Form2.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Form2.width = 650
$Form2.height = 195
$Form2.backcolor = [System.Drawing.Color]::Gainsboro
$Form2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form2.Text = "NowYouHearMe Connect"
$Form2.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Form2.maximumsize = New-Object System.Drawing.Size(650,195)
$Form2.startposition = "centerscreen"
$Form2.KeyPreview = $True
$Form2.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Form2.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,90)
$label.Text = 'You picked Listener.

You will be the Music Producer, LISTENING to a session.

You will be guided how to setup your computer for this session in the next few steps.'
$Form2.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(190,110)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Continue"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({Map2})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(315,110)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Exit"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({$Form2.Dispose()})
$Form2.Topmost = $True
$Form2.MaximizeBox = $Formalse
$Form2.MinimizeBox = $Formalse
#Add them to form and active it
$Form2.Controls.Add($Button1)
$Form2.Controls.Add($Button2)
$Form2.Add_Shown({$Form2.Activate()})
$Form2.ShowDialog()
}
Function Map3.1{
$Form.Dispose()
$Form3 = New-Object System.Windows.Forms.Form
$Form3.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Form3.width = 600
$Form3.height = 180
$Form3.backcolor = [System.Drawing.Color]::Gainsboro
$Form3.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form3.Text = "NowYouHearMe Connect"
$Form3.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Form3.maximumsize = New-Object System.Drawing.Size(600,180)
$Form3.startposition = "centerscreen"
$Form3.KeyPreview = $True
$Form3.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Form3.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,70)
$label.Text = 'This feature is coming soon!

In this mode, the musician and the remote studio would both be acting as Hosts.'
$Form3.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(235,95)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Exit"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$Form3.Dispose()})
$Form3.Topmost = $True
$Form3.MaximizeBox = $Formalse
$Form3.MinimizeBox = $Formalse
#Add them to form and active it
$Form3.Controls.Add($Button1)
$Form3.Add_Shown({$Form3.Activate()})
$Form3.ShowDialog()
}
Function Skipped{
$FormCheckUpdate.Dispose()
#Draw form
$Form = New-Object System.Windows.Forms.Form
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Form.width = 535
$Form.height = 435
$Form.backcolor = [System.Drawing.Color]::Gainsboro
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form.Text = "NowYouHearMe Connect"
$Form.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Form.maximumsize = New-Object System.Drawing.Size(535,435)
$Form.startposition = "centerscreen"
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,330)
$label.Text = '*******************************************************

                                Welcome to NowYouHear.me Connect     

*******************************************************

                               -Select an Option Below to Begin-


Host: I am a Music Producer wanting to HOST a session.
(Someone else will be listening to sound from my DAW)


Listener: I am a Music Producer, but want to LISTEN to someones DAW.
(I will be listening to someone elses computer)


2-Way: (Advanced Users) I am a Musician wanting to stream my 
instrument to a remote studio and have the studio talk-back. 
(This requires you to also have local recording software such as 
Ableton, FL Studio, ProTools, etc)'
$form.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(90,350)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Host"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({Map1.1})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(210,350)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Listener"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({Map2.1})
$Button3 = new-object System.Windows.Forms.Button
$Button3.Location = new-object System.Drawing.Size(330,350)
$Button3.Size = new-object System.Drawing.Size(100,30)
$Button3.Text = "2-Way"
$Button3.Add_MouseHover({$Button3.backcolor = [System.Drawing.Color]::Azure})
$Button3.Add_MouseLeave({$Button3.backcolor = [System.Drawing.Color]::Gainsboro})
$Button3.Add_Click({Map3.1})
$Form.Topmost = $True
$Form.MaximizeBox = $Formalse
$Form.MinimizeBox = $Formalse
#Add them to form and active it
$Form.Controls.Add($Button1)
$Form.Controls.Add($Button2)
$Form.Controls.Add($Button3)
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
}
if (!(Test-Path "C:\Program Files (x86)\nowyouhearme\firstuse-nyhm.txt")) {
$FormCheckUpdate = New-Object System.Windows.Forms.Form
$FormCheckUpdate.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormCheckUpdate.width = 500
$FormCheckUpdate.height = 285
$FormCheckUpdate.backcolor = [System.Drawing.Color]::Gainsboro
$FormCheckUpdate.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormCheckUpdate.Text = "NowYouHearMe Connect"
$FormCheckUpdate.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormCheckUpdate.maximumsize = New-Object System.Drawing.Size(500,285)
$FormCheckUpdate.startposition = "centerscreen"
$FormCheckUpdate.KeyPreview = $True
$FormCheckUpdate.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormCheckUpdate.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormCheckUpdate.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(500,165)
$label.Text = '***************************************************

                         Welcome to NowYouHear.me Connect     

***************************************************

This program is still in Beta and will need to frequently check 
for updates to properly work.

Click Update to download the latest version.
Updating should take less than 30 seconds.'
$FormCheckUpdate.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(125,200)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Update"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({UpdateScript})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(250,200)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Skip"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({Skipped})
$FormCheckUpdate.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormCheckUpdate.Topmost = $True
$FormCheckUpdate.MaximizeBox = $Formalse
$FormCheckUpdate.MinimizeBox = $Formalse
#Add them to form and active it
$FormCheckUpdate.Controls.Add($Button1)
$FormCheckUpdate.Controls.Add($Button2)
$FormCheckUpdate.Add_Shown({$FormCheckUpdate.Activate()})
$FormCheckUpdate.ShowDialog()
}
if ((Test-Path "C:\Program Files (x86)\nowyouhearme\firstuse-nyhm.txt")) {
#Draw form
$Form = New-Object System.Windows.Forms.Form
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$Form.width = 535
$Form.height = 435
$Form.backcolor = [System.Drawing.Color]::Gainsboro
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$Form.Text = "NowYouHearMe Connect"
$Form.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$Form.maximumsize = New-Object System.Drawing.Size(535,435)
$Form.startposition = "centerscreen"
$Form.KeyPreview = $True
$Form.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$Form.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$Form.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(535,330)
$label.Text = '********************************************************

                             Welcome to NowYouHear.me Connect     

********************************************************

                               -Select an Option Below to Begin-


Host: I am a Music Producer wanting to HOST a session.
(Someone else will be listening to sound from my DAW)


Listener: I am a Music Producer, but want to LISTEN to someones DAW.
(I will be listening to someone elses computer)


2-Way: (Advanced Users) I am a Musician wanting to stream my 
instrument to a remote studio and have the studio talk-back. 
(This requires you to also have local recording software such as 
Ableton, FL Studio, ProTools, etc)'
$form.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(90,350)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Host"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({Map1.1})
$Button2 = new-object System.Windows.Forms.Button
$Button2.Location = new-object System.Drawing.Size(210,350)
$Button2.Size = new-object System.Drawing.Size(100,30)
$Button2.Text = "Listener"
$Button2.Add_MouseHover({$Button2.backcolor = [System.Drawing.Color]::Azure})
$Button2.Add_MouseLeave({$Button2.backcolor = [System.Drawing.Color]::Gainsboro})
$Button2.Add_Click({Map2.1})
$Button3 = new-object System.Windows.Forms.Button
$Button3.Location = new-object System.Drawing.Size(330,350)
$Button3.Size = new-object System.Drawing.Size(100,30)
$Button3.Text = "2-Way"
$Button3.Add_MouseHover({$Button3.backcolor = [System.Drawing.Color]::Azure})
$Button3.Add_MouseLeave({$Button3.backcolor = [System.Drawing.Color]::Gainsboro})
$Button3.Add_Click({Map3.1})
$Form.Topmost = $True
$Form.MaximizeBox = $Formalse
$Form.MinimizeBox = $Formalse
#Add them to form and active it
$Form.Controls.Add($Button1)
$Form.Controls.Add($Button2)
$Form.Controls.Add($Button3)
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
}