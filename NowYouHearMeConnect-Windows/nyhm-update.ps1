[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
Write-Host "Please wait a few seconds while NowYouHear.me downloads the latest update..."
Write-Host " "
Write-Host " "
Invoke-WebRequest -Uri "https://www.dropbox.com/s/9g6gc8ohe66x53x/nowyouhearme.zip?dl=1" -OutFile "$ENV:UserProfile\AppData\Local\Temp\nowyouhearme.zip"
expand-archive -path "$ENV:UserProfile\AppData\Local\Temp\nowyouhearme.zip" -destinationpath "$ENV:UserProfile\AppData\Local\Temp\nyhm-update\"
Remove-Item -path "$ENV:UserProfile\AppData\Local\Temp\nowyouhearme.zip"
xcopy /y /E "$ENV:UserProfile\AppData\Local\Temp\nyhm-update" "C:\Program Files (x86)\" >$null 2>&1
Remove-Item -path "$ENV:UserProfile\AppData\Local\Temp\nyhm-update" -recurse
xcopy /y "C:\Program Files (x86)\nowyouhearme\scripts\nyhm-update.ps1" "C:\ProgramData\nowyouhearme\" >$null 2>&1
Remove-Item -path "C:\Program Files (x86)\nowyouhearme\scripts\nyhm-update.ps1"
sleep 1
$FormUpdate = New-Object System.Windows.Forms.Form
$FormUpdate.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon('C:\Program Files (x86)\nowyouhearme\images\smallicon.ico')
$FormUpdate.width = 600
$FormUpdate.height = 175
$FormUpdate.backcolor = [System.Drawing.Color]::Gainsboro
$FormUpdate.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$FormUpdate.Text = "NowYouHearMe Connect"
$FormUpdate.Font = New-Object System.Drawing.Font("Verdana",9,[System.Drawing.FontStyle]::Bold)
$FormUpdate.maximumsize = New-Object System.Drawing.Size(600,175)
$FormUpdate.startposition = "centerscreen"
$FormUpdate.KeyPreview = $True
$FormUpdate.Add_KeyDown({if ($_.KeyCode -eq "Enter") {}})
$FormUpdate.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$FormUpdate.Close()}})
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(600,70)
$label.Text = 'NowYouHearMe Connect Successfully updated.

Re-Open NowYouHearMe Connect from the Icon on your Desktop.'
$FormUpdate.Controls.Add($label)
#Draw buttons 
$Button1 = new-object System.Windows.Forms.Button
$Button1.Location = new-object System.Drawing.Size(230,90)
$Button1.Size = new-object System.Drawing.Size(100,30)
$Button1.Text = "Exit"
$Button1.Add_MouseHover({$Button1.backcolor = [System.Drawing.Color]::Azure})
$Button1.Add_MouseLeave({$Button1.backcolor = [System.Drawing.Color]::Gainsboro})
$Button1.Add_Click({$FormUpdate.Dispose()})
$FormUpdate.Topmost = $True
$FormUpdate.MaximizeBox = $Formalse
$FormUpdate.MinimizeBox = $Formalse
#Add them to form and active it
$FormUpdate.Controls.Add($Button1)
$FormUpdate.Add_Shown({$FormUpdate.Activate()})
$FormUpdate.ShowDialog()