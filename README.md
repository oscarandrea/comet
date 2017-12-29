# comet
FreeBSD desktop LiveCD creator

## Introduction
The purpose of this tool is quickly generate bloat free images containing stock FreeBSD, and supported desktop environments.

## Features
* FreeBSD 11.1-RELEASE
* AMD64
* Gnome & KDE desktop environments
* Hybrid DVD/USB image

## Initial Setup
Install the required packages:
```
pkg install git grub2-pcbsd grub2-efi xorriso
```
Clone the repo:
```
git clone https://www.github.com/pkgdemon/comet
```
Enter the directory for running the LiveCD creator:
```
cd comet/src
```

## Usage for Gnome
Build desktop image with Gnome:
```
./comet gnome
```
Location of image for Gnome:
```
/usr/local/comet/gnome.iso
```

## Usage for KDE
Build desktop image with KDE:
```
./comet kde
```
Location of image for KDE:
```
/usr/local/comet/kde.iso
```

## Credentials for live media
User: liveuser
Password: freebsd
