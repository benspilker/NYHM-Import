@echo *************************************************
@echo *                                               *
@echo * Welcome to the NowYouHear.me installation...  *
@echo *                                               *
@echo *************************************************
@echo.
@echo Note, you will need an Internet connection in order for this installation to work.
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.
@echo.

msg "%username%" "Welcome to the NowYouHear.me installation...Don't click inside the console window, as it will pause the install. If you click inside the console and the install appears to be stuck, simply press Enter to resume. Please Click OK."


@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

cls
@echo installing chocolately.org framework to install programs from the chocolatey repository 
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.
@echo.

choco install obs-studio -y

cls
@echo installing OBS (Open Broadcaster Software)


robocopy %~dp0obs-studio %appdata%\obs-studio /MIR

cls
@echo Copied OBS preferences


reg import %~dp0asio4all-bulk.reg

cls
@echo imported registry entry for VB-Audio HiFi Cable for different DAW Profiles
@echo Current Supported Profiles include Ableton and FL Studio

@echo Ableton profiles... C2A277F5 Live 10 Suite, B932A24F Live 10 Standard, F32F36AE Live 10 Intro, C659D8C3 Live 9 Suite, BA37DA75 Live 9 Standard, C85FDD94 Live 9 Intro, AF42E7F0 Live 9 Lite

@echo FL Studio Profiles.. 9AA4D611 FL Studio 20, ADAEFA02 FL Studio 12 (64 bit), 14957CBF FL Studio 12 (32 bit), 22F05333 FL Studio 11 


reg import %~dp0disabledSmartScreen.reg

cls
@echo imported the registry entry to disable the Windows blue run-don't-run popup so installer will properly resume on reboot


xcopy /y %~dp0HowToUse_NowYouHearMe.pdf C:\Users\Public\Desktop

cls
@echo Copied how to use instructions to the Public Desktop

xcopy /y %~dp0HowToSignInto_NowYouHearMe.pdf C:\Users\Public\Desktop

cls
@echo Copied how to sign into instructions to the Public Desktop


xcopy /y %~dp0nowyouhearme-install-postreboot.lnk "C:\NYHM_Temp\"

cls
@echo Copied the shortcut for resuming the install to the nowyouhearme temp folder

xcopy /y %~dp0defaultSmartScreen.reg "C:\NYHM_Temp\"

cls
@echo Copied the registry entry to restore the smart screen Windows blue run-don't-run pop back to the way it was


reg import %~dp0runonce.reg

cls
@echo imported the registry entry to make the install postreboot batch file open on restart


%~dp0HiFiCableAsioBridgeSetup.exe

cls
@echo installed VB Audio-HiFi Cable
@echo.
@echo Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.


%~dp0obs-ndi-4.5.3-Windows-Installer.exe

cls
@echo installed the OBS-NDI plugins + the NDI runtime
@echo.
@echo Almost done. Remember if you click inside the console and the install appears to be stuck, simply press Enter to resume.

cls
@echo Your computer will automatically restart soon and resume setup after rebooting. 
@echo Press CTRL-C if you need to reboot later.

timeout 10
shutdown /r /c "Your computer will restart in less that a minute. NowYouHear.me installation will resume after rebooting."

cls
@echo Since the Windows NDI runtime is installed, this requires a reboot. nowyouhearme-install-postreboot.bat will open at next login.