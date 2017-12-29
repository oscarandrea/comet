# comet
FreeBSD desktop LiveCD creator

## Introduction
The purpose of this tool is quickly generate bloat free images containing stock FreeBSD, and supported desktop environments.

## Features
* FreeBSD 11.1-RELEASE
* AMD64
* Gnome & KDE desktop environments
* Hybrid DVD/USB image

## Screenshots

![Alt text](/screenshots/gnome-livecd.png?raw=true "Gnome LiveCD")

![Alt text](/screenshots/kde-livecd.png?raw=true "KDE LiveCD")

## System Requirements
* FreeBSD 11.1, or higher for AMD64
* 20GB of free disk space
* 1GB of free memory
* UFS, or ZFS

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
Burn image to DVD:
```
cdrecord /usr/local/comet/gnome.iso
```
Burn image to USB:
```
dd if=/usr/local/comet/gnome.iso of=/dev/da0 bs=4m
```

## Usage for KDE
Build desktop image with KDE:
```
./comet kde
```
Burn image to DVD:
```
cdrecord /usr/local/comet/kde.iso
```
Burn image to USB:
```
dd if=/usr/local/comet/kde.iso of=/dev/da0 bs=4m
```

## Credentials for live media
User: liveuser

Password: freebsd
