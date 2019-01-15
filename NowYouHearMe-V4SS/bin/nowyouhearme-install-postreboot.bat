@echo *************************************************
@echo *                                               *
@echo * Hello, Resuming NowYouHear.me installation... *
@echo *                                               *
@echo *************************************************
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.

choco install zerotier-one -y 

@echo Installing ZeroTier

@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.
net stop ZeroTierOneService 

cls 
@echo Stopped the Zero Tier Service


sc config ZeroTierOneService start= demand 

cls
@echo Made Zero Tier Serice Manual Start, made it not auto start
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.

choco install teamviewer -y 

cls
@echo Installed Teamviewer
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.

choco install asio4all -y 

cls
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.
@echo Installed Asio4all 


xcopy /y %~dp0obs-ndi.dll "C:\Program Files\obs-studio\obs-plugins\64bit"

cls
@echo Copied the OBS-NDI plugin to the OBS Plugin Folder
 

echo f | xcopy /s/y "%~dp0obs-ndi" "C:\Program Files\obs-studio\data\obs-plugins\obs-ndi"

cls
@echo Copied the OBS-NDI plugin languages folder to the OBS Plugin Folder


import reg "C:\NYHM_Temp\defaultSmartScreen.reg"

cls
@echo re-enabled the Windows blue run-don't-run popup, putting it back to the way it was


del "C:\Users\%USERNAME%\ASIO4ALL v2 Instruction Manual.lnk" /s /f /q 

cls
@echo deleted the asio4all shortcut on the desktop to avoid instructions confusion


@RD /S /Q "C:\NYHM_Temp"

cls
@echo deleted the C:\NYHM_temp folder needed for install


xcopy /y %~dp0nowyouhearme "C:\Program Files\nowyouhearme\"

cls
@echo copied the nowyouhearme folder to Program Files


xcopy /y %~dp0nowyouhearme\nowyouhearme-connect.lnk C:\Users\Public\Desktop

cls
@echo copied the connect exe shortcut to the Public Desktop


start cmd /k echo "Installation Complete. Now opening the HowToUse Instructions on the Desktop..."
timeout 3

"C:\Users\Public\Desktop\HowToSignInto_NowYouHearMe.pdf"

start cmd /k taskkill /IM cmd.exe
@echo Closing out all cmd windows
