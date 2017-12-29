#!/usr/bin/env sh

cwd="`realpath | sed 's|/scripts||g'`"
desktop_list="`ls ${cwd}/packages`"
workdir="/usr/local"
livecd="${workdir}/comet"
base="${livecd}/base"
packages="${livecd}/packages"
release="${livecd}/release"
cdroot="${livecd}/cdroot"
desktop=$1
vol=${desktop}

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

display_usage()
{
  echo "You must specify a desktop!"
  echo "Possible choices are:"
  echo "${desktop_list}"
  echo "Usage: build.sh gnome"
  exit 1
}

validate_desktop()
{
  if [ ! -f "${cwd}/packages/${desktop}" ] ; then
    display_usage
  fi
}

# We must choose a desktop
if [ -z "${desktop}" ] ; then
  display_usage
else
  validate_desktop
fi

case $desktop in
      gnome) 
            export desktop="gnome";;
        kde) 
            export desktop="kde";;
esac

workspace()
{
  if [ -d "${livecd}" ] ;then
    chflags -R noschg ${release} ${cdroot} >/dev/null 2>/dev/null
    rm -rf ${release} ${cdroot} >/dev/null 2>/dev/null
  fi
  mkdir ${livecd} ${base} ${packages} ${release} >/dev/null 2>/dev/null
}

base()
{
  cd ${base}
  fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.1-RELEASE/base.txz
  fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/11.1-RELEASE/kernel.txz
  tar -zxvf base.txz -C ${release}
  tar -zxvf kernel.txz -C ${release}
}

packages()
{
  cp /etc/resolv.conf ${release}/etc/resolv.conf
  case $desktop in
  	 gnome) 
	       cat ${cwd}/packages/gnome | xargs pkg-static -c ${release} install -y ;;
  	   kde)
	       cat ${cwd}/packages/kde | xargs pkg-static -c ${release} install -y ;;
  esac
  pkg-static -c ${release} clean -a -y
  rm ${release}/etc/resolv.conf
}

rc()
{
  case $desktop in
   gnome)
	 chroot ${release} sysrc -f /etc/rc.conf root_rw_mount="NO"
	 chroot ${release} sysrc -f /etc/rc.conf hostname="livecd"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_enable="NONE"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_submit_enable="NO"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_outbound_enable="NO"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_msp_queue_enable="NO"
	 chroot ${release} sysrc -f /etc/rc.conf dbus_enable="YES"
  	 chroot ${release} sysrc -f /etc/rc.conf hald_enable="YES"
	 chroot ${release} sysrc -f /etc/rc.conf gdm_enable="YES"
	 chroot ${release} sysrc -f /etc/rc.conf gnome_enable="YES" 
	 chroot ${release} sysrc -f /etc/rc.conf livecd_enable="YES" ;;
     kde)
	 chroot ${release} sysrc -f /etc/rc.conf root_rw_mount="NO"
	 chroot ${release} sysrc -f /etc/rc.conf hostname="livecd"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_enable="NONE"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_submit_enable="NO"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_outbound_enable="NO"
	 chroot ${release} sysrc -f /etc/rc.conf sendmail_msp_queue_enable="NO"
	 chroot ${release} sysrc -f /etc/rc.conf dbus_enable="YES"
  	 chroot ${release} sysrc -f /etc/rc.conf hald_enable="YES"
	 chroot ${release} sysrc -f /etc/rc.conf kdm4_enable="YES"
	 chroot ${release} sysrc -f /etc/rc.conf livecd_enable="YES" ;;	
  esac
}

user()
{
  chroot ${release} echo freebsd | chroot ${release} pw mod user root -h 0
  chroot ${release} pw useradd liveuser \
  -c "Live User" -d "/home/liveuser" \
  -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
  chroot ${release} echo freebsd | chroot ${release} pw mod user liveuser -h 0
}

xorg()
{
  install -o root -g wheel -m 755 "${cwd}/xorg/bin/livecd" "${release}/usr/local/bin/"
  install -o root -g wheel -m 755 "${cwd}/xorg/rc.d/livecd" "${release}/usr/local/etc/rc.d/"
  if [ ! -d "${release}/usr/local/etc/X11/cardDetect/" ] ; then
    mkdir -p ${release}/usr/local/etc/X11/cardDetect
  fi
  install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.vesa" "${release}/usr/local/etc/X11/cardDetect/"
  install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.scfb" "${release}/usr/local/etc/X11/cardDetect/"
  install -o root -g wheel -m 755 "${cwd}/xorg/cardDetect/XF86Config.virtualbox" "${release}/usr/local/etc/X11/cardDetect/"
}

uzip() 
{
  install -o root -g wheel -m 755 -d "${cdroot}"
  mkdir "${cdroot}/data"
  makefs "${cdroot}/data/system.ufs" "${release}"
  mkuzip -o "${cdroot}/data/system.uzip" "${cdroot}/data/system.ufs"
  rm -f "${cdroot}/data/system.ufs"
}

ramdisk() 
{
  ramdisk_root="${cdroot}/data/ramdisk"
  mkdir -p "${ramdisk_root}"
  cd "${release}"
  tar -cf - rescue | tar -xf - -C "${ramdisk_root}"
  cd "${cwd}"
  install -o root -g wheel -m 755 "init.sh.in" "${ramdisk_root}/init.sh"
  sed "s/@VOLUME@/${vol}/" "init.sh.in" > "${ramdisk_root}/init.sh"
  mkdir "${ramdisk_root}/dev"
  mkdir "${ramdisk_root}/etc"
  touch "${ramdisk_root}/etc/fstab"
  makefs -b '10%' "${cdroot}/data/ramdisk.ufs" "${ramdisk_root}"
  gzip "${cdroot}/data/ramdisk.ufs"
  rm -rf "${ramdisk_root}"
}

boot() 
{
  cd "${release}"
  tar -cf - --exclude boot/kernel boot | tar -xf - -C "${cdroot}"
  for kfile in kernel geom_uzip.ko nullfs.ko tmpfs.ko unionfs.ko; do
  tar -cf - boot/kernel/${kfile} | tar -xf - -C "${cdroot}"
  done
  cd "${cwd}"
  install -o root -g wheel -m 644 "loader.conf" "${cdroot}/boot/"
  if [ ! -d "${cdroot}/boot/grub" ] ; then
    mkdir ${cdroot}/boot/grub
  fi
  install -o root -g wheel -m 644 "grub.cfg" "${cdroot}/boot/grub/"
}

image() 
{
  cat << EOF >/tmp/xorriso
ARGS=\`echo \$@ | sed 's|-hfsplus ||g'\`
xorriso \$ARGS
EOF
  chmod 755 /tmp/xorriso
  grub-mkrescue --xorriso=/tmp/xorriso -o ${livecd}/${vol}.iso ${cdroot} -- -volid ${vol}
}
