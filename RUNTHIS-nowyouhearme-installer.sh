#!/bin/sh
echo | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"


brew cask install zerotier-one

brew cask install soundflower

/usr/bin/sudo launchctl unload /Library/LaunchDaemons/com.zerotier.one.plist        
#stop zero tier

brew cask install obs

brew cask install teamviewer

/usr/bin/sudo launchctl load /Library/LaunchDaemons/com.zerotier.one.plist
#start zero tier



#copy obs-ndi plugin to /Library/Application Support/obs-studio/plugins

/usr/bin/sudo cp -pr /Volumes/open-to-install-nowyouhearme/open-to-install-nowyouhearme.app/Contents/bin/obsplugins/Library/Application\ Support/obs-studio/plugins/obs-ndi /Library/Application\ Support/obs-studio/plugins



#copy ndi runtime stuff to
#/usr/local/lib/libndi.3.dylib
#/usr/local/lib/libndi_licenses.txt



/usr/bin/sudo cp -pr /Volumes/open-to-install-nowyouhearme/open-to-install-nowyouhearme.app/Contents/bin/libndi/libndi_licenses.txt /usr/local/lib/

/usr/bin/sudo cp -pr /Volumes/open-to-install-nowyouhearme/open-to-install-nowyouhearme.app/Contents/bin/nowyouhearme-copystuff/libndi/libndi.3.dylib /usr/local/lib/



#preserves previous obs preferences if applicable

/usr/bin/sudo mv ~/Library/Application\ Support/obs-studio ~/Library/Application\ Support/obs-studio-archive




#copy obs-studio preferences to /Users/$user/Library/application support/ 


cp -pr /Volumes/open-to-install-nowyouhearme/open-to-install-nowyouhearme.app/Contents/bin/obs-studio ~/Library/Application\ Support/





/usr/bin/sudo launchctl unload /Library/LaunchDaemons/com.zerotier.one.plist        
#stop zero tier

#move launch daemon to applications folder to prevent auto start of zero tier

#move com.zerotier.one.plist from /Library/LaunchDaemons/com.zerotier.one.plist to applications/nowyouhearme/temp (making it not auto-start)



/usr/bin/sudo mkdir /Applications/nowyouhearme
/usr/bin/sudo mkdir /Applications/nowyouhearme/temp

/usr/bin/sudo mv /Library/LaunchDaemons/com.zerotier.one.plist /Applications/nowyouhearme/temp


exit 0
#open HowToSignIn.pdf
