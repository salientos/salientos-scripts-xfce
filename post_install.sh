#!/usr/bin/env bash
#
##############################################################################
#
#  Program :    PostInstall v0.1
#  Author  :    Silent Robot
#  Website :    https://sourceforge.net/projects/salient-os/
#  License :    Distributed under the terms of GNU GPL v3
#
##############################################################################

#n_user=${SUDO_USER:-$USER}
# username with given id
n_user=`id -un -- 1000`

## Get mount points of target system according to installer being used (calamares or abif)
if [[ `pidof calamares` ]]; then
	chroot_path="/tmp/`lsblk | grep 'calamares-root' | awk '{ print $NF }' | sed -e 's/\/tmp\///' -e 's/\/.*$//' | tail -n1`"
fi

#if [[ "$chroot_path" == '/tmp/' ]] ; then
#	echo "+---------------------->>"
#    echo "[!] Fatal error: `basename $0`: chroot_path is empty!"
#fi

## Use chroot not arch-chroot
arch_chroot() {
    chroot "$chroot_path" /bin/bash -c ${1}
}

#-------------------------------------------------------------------------------------

# remove live environment files
[[ -f /etc/sudoers.d/g_wheel ]] && rm -f /etc/sudoers.d/g_wheel
[[ -f /etc/polkit-1/rules.d/49-nopasswd_global.rules ]] && rm -f /etc/polkit-1/rules.d/49-nopasswd_global.rules
[[ -f /etc/systemd/system/etc-pacman.d-gnupg.mount ]] && rm -f /etc/systemd/system/etc-pacman.d-gnupg.mount
[[ -f /root/.automated_script.sh ]] && rm -f /root/.automated_script.sh
[[ -f /root/.zlogin ]] && rm -f /root/.zlogin

#-------------------------------------------------------------------------------------

# remove remnants of calamares completely
[[ -d /usr/share/calamares ]] && rm -rf /usr/share/calamares
[[ -d /etc/calamares ]] && rm -rf /etc/calamares
[[ -f /etc/xdg/autostart/calamares.desktop ]] && rm -f /etc/xdg/autostart/calamares.desktop
[[ -f /home/${n_user}/.config/autostart/calamares.desktop ]] && rm -f /home/${n_user}/.config/autostart/calamares.desktop

#-------------------------------------------------------------------------------------

# remove autologin.conf
[[ -f /usr/bin/mkinitcpio-archiso ]] && pacman -R mkinitcpio-archiso --noconfirm
[[ -f /etc/salientos-release ]] && mv /etc/salientos-release /etc/lsb-release

#-------------------------------------------------------------------------------------

# clean out archiso files from install
[[ -f /usr/bin/find ]] && find /usr/lib/initcpio -name archiso* -type f -exec rm '{}' \;

#-------------------------------------------------------------------------------------

# change smb.conf to the current user
[[ -f /usr/bin/sed ]] && sed -i "s|liveuser|${n_user}|g" /etc/samba/smb.conf

# add user to samba with blank passwd for now
# we'll inform them later after install
[[ -f /usr/bin/smbpasswd ]] && (
    echo " "
    echo " "
) | smbpasswd -s -a ${n_user}

# change users home permissions
[[ -f /usr/bin/chmod ]] && chmod o+x /home/${n_user}

#-------------------------------------------------------------------------------------

# update user dirs, make sure they have been populated
[[ -f /usr/bin/xdg-user-dirs-update ]] && runuser -u ${n_user} -- xdg-user-dirs-update --force

# ensure config is set to current user
[[ -f /usr/bin/sed ]] && sed -i "s|liveuser|${n_user}|g" /home/${n_user}/.gtkrc-2.0

#-------------------------------------------------------------------------------------

# bluetooth enhancements
[[ -f /usr/bin/sed ]] && sed -i "s|#AutoEnable=false|AutoEnable=true|g" /etc/bluetooth/main.conf
[[ -f /usr/bin/echo ]] && echo 'load-module module-switch-on-connect' | tee --append /etc/pulse/default.pa

#-------------------------------------------------------------------------------------

# fix file permissions
[[ -f /usr/bin/chmod ]] && chmod 755 /home/${n_user}/.fehbg

#-------------------------------------------------------------------------------------

## Vconsole
cat <<EOF >/etc/vconsole.conf
COLOR_0=212121
COLOR_1=f92672
COLOR_2=a6e22e
COLOR_3=f4bf75
COLOR_4=66d9ef
COLOR_5=ae81ff
COLOR_6=a1efe4
COLOR_7=f8f8f2
COLOR_8=75715e
COLOR_9=f92672
COLOR_10=a6e22e
COLOR_11=f4bf75
COLOR_12=66d9ef
COLOR_13=ae81ff
COLOR_14=a1efe4
COLOR_15=f9f8f5
EOF

#-------------------------------------------------------------------------------------
# inject our colors hook for console output

cat <<EOF >/etc/mkinitcpio.conf
MODULES=()
HOOKS=(base udev colors autodetect modconf block filesystems keyboard fsck)
COMPRESSION=(zstd)
COMPRESSION_OPTIONS=(-9)
EOF

#-------------------------------------------------------------------------------------

# change grub default to reflect os
[[ -f /usr/bin/sed ]] && sed -i "s|Salient OS|salientos|g" /etc/default/grub

#-------------------------------------------------------------------------------------

# change permissions on executables with and without extensions
[[ -f /usr/bin/find ]] && find /home/${n_user}/.config/* -type f \( -iname '*.sh' -o -iname '*.py' \) -print0 | xargs -0 --no-run-if-empty chmod 755
[[ -f /usr/bin/find ]] && find /home/${n_user}/.local/bin/* -type f \( -iname '*.sh' -o -iname '*.py' -o ! -iname '*.*' \) -print0 | xargs -0 --no-run-if-empty chmod 755
[[ -f /usr/bin/find ]] && find /usr/local/bin/* -type f \( -iname '*.sh' -o -iname '*.py' -o ! -iname '*.*' \) -print0 | xargs -0 --no-run-if-empty chmod 755

#-------------------------------------------------------------------------------------

# pacman sync
[[ -f /usr/bin/pacman ]] && pacman -Syy --noconfirm

#-------------------------------------------------------------------------------------

# unset user
unset n_user

## Run the final script inside calamares chroot (target system)
if [[ `pidof calamares` ]]; then
    echo "+---------------------->>"
    echo "[*] Running chroot post installation script in target system..."
    arch_chroot "/usr/bin/chrooted_post_install.sh"
fi

# Continue cleanup
rm -f /usr/local/bin/post_install.sh
