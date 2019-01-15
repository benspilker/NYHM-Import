#!/bin/sh
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew cask install zerotier-one
brew cask install soundflower
read -p "Click Enter after setting permissions for ZeroTier and Soundflower"
sudo launchctl unload /Library/LaunchDaemons/com.zerotier.one.plist
sudo launchctl load /Library/LaunchDaemons/com.zerotier.one.plist

input "type your email"


sudo zerotier-cli join e4da7455b2e53b41