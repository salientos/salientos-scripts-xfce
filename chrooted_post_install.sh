#!/bin/bash

## Post installation script for Salient OS (Executes on target system)
## ---------------------------------------------------------------------------
## Based on the scripts for Archcraft by Aditya Shakya modified for Salient OS

# Get new user's username
new_user=`cat /etc/passwd | grep "/home" | cut -d: -f1 | head -1`

# Check if package installed (0) or not (1)
_is_pkg_installed() {
    local pkgname="$1"
    pacman -Q "$pkgname" >& /dev/null
}

# Remove a package
_remove_a_pkg() {
    local pkgname="$1"
    pacman -Rsn --noconfirm "$pkgname"
}

# Remove package(s) if installed
_remove_pkgs_if_installed() {
    local pkgname
    for pkgname in "$@" ; do
        _is_pkg_installed "$pkgname" && _remove_a_pkg "$pkgname"
    done
}

## -------- Enable/Disable services/targets ------
_manage_systemd_services() {
    local _enable_services=(
        'acpid.service'
        'NetworkManager.service'
        'avahi-dnsconfd.service'
        'avahi-daemon.service'
        'avahi-daemon.socket'
        'smb.service'
        'nmb.service'
        'winbind.service'
        'cups.service'
        'bluetooth.service'
        'systemd-timesyncd.service'
        'ufw.service'
        'lightdm.service'
    )
    #local _snapd_services=('apparmor.service'
    #                      'snapd.apparmor.service'
    #                      'snapd.socket')
    local srv
    #local snapsrv

    # Enable hypervisors services if installed on it
    [[ `lspci | grep -i virtualbox` ]] && echo "+---------------------->>" && echo "[*] Enabling vbox service..." && systemctl enable -f vboxservice.service
    [[ `lspci -k | grep -i qemu` ]] && echo "+---------------------->>" && echo "[*] Enabling qemu service..." && systemctl enable -f qemu-guest-agent.service

    # Manage services on target system
    for srv in "${_enable_services[@]}"; do
        echo "+---------------------->>"
        echo "[*] Enabling $srv for target system..."
        systemctl enable -f ${srv}
    done

    # Manage snapd services on target system
    #if [[ -x `which snap` ]]; then
    #   for snapsrv in "${_snapd_services[@]}"; do
    #       echo "+---------------------->>"
    #       echo "[*] Enabling $snapsrv for target system..."
    #       systemctl enable -f ${snapsrv}
    #   done
    #fi

    # Manage targets on target system
    systemctl disable -f multi-user.target
}

## -------- Remove VM Drivers --------------------

# Remove virtualbox pkgs if not running in vbox
_remove_vbox_pkgs() {
    local vbox_pkg='virtualbox-guest-utils'
    local vsrvfile='/etc/systemd/system/multi-user.target.wants/vboxservice.service'

    lspci | grep -i "virtualbox" >/dev/null
    if [[ "$?" != 0 ]] ; then
        echo "+---------------------->>"
        echo "[*] Removing $vbox_pkg from target system..."
        test -n "`pacman -Q $vbox_pkg 2>/dev/null`" && pacman -Rnsdd ${vbox_pkg} --noconfirm
        if [[ -L "$vsrvfile" ]] ; then
            rm -f "$vsrvfile"
        fi
    fi
}

# Remove vmware pkgs if not running in vmware
_remove_vmware_pkgs() {
    local vmware_pkgs=('open-vm-tools' 'xf86-input-vmmouse' 'xf86-video-vmware')
    local _vw_pkg

    lspci | grep -i "VMware" >/dev/null
    if [[ "$?" != 0 ]] ; then
        for _vw_pkg in "${vmware_pkgs[@]}" ; do
            echo "+---------------------->>"
            echo "[*] Removing ${_vw_pkg} from target system..."
            test -n "`pacman -Q ${_vw_pkg} 2>/dev/null`" && pacman -Rnsdd ${_vw_pkg} --noconfirm
        done
    fi
}

# Remove qemu guest pkg if not running in Qemu
_remove_qemu_pkgs() {
    local qemu_pkg='qemu-guest-agent'
    local qsrvfile='/etc/systemd/system/multi-user.target.wants/qemu-guest-agent.service'

    lspci -k | grep -i "qemu" >/dev/null
    if [[ "$?" != 0 ]] ; then
        echo "+---------------------->>"
        echo "[*] Removing $qemu_pkg from target system..."
        test -n "`pacman -Q $qemu_pkg 2>/dev/null`" && pacman -Rnsdd ${qemu_pkg} --noconfirm
        if [[ -L "$qsrvfile" ]] ; then
            rm -f "$qsrvfile"
        fi
    fi
}

## -------- Remove Un-wanted Ucode ---------------

# Remove un-wanted ucode package
_remove_unwanted_ucode() {
    cpu="`grep -w "^vendor_id" /proc/cpuinfo | head -n 1 | awk '{print $3}'`"

    case "$cpu" in
        GenuineIntel)   echo "+---------------------->>" && echo "[*] Removing amd-ucode from target system..."
                        _remove_pkgs_if_installed amd-ucode
                        ;;
        *)              echo "+---------------------->>" && echo "[*] Removing intel-ucode from target system..."
                        _remove_pkgs_if_installed intel-ucode
                        ;;
    esac
}

## -------- Remove Packages/Installer ------------

# Remove unnecessary packages
_remove_unwanted_packages() {
    local _packages_to_remove=(
        'arch-install-scripts'
        'archinstall'
        'boost'
        'ckbcomp'
        'clonezilla'
        'cmake'
        'darkhttpd'
        'dd_rescue'
        'ddrescue'
        'elinks'
        'extra-cmake-modules '
        'gftp'
        'grml-zsh-config'
        'grsync'
        'hardinfo'
        'irssi'
        'kconfig'
        'kcoreaddons'
        'kcrash'
        'kdbusaddons '
        'ki18n'
        'kitty-terminfo'
        'kparts'
        'kpmcore'
        'kservice'
        'kwidgetsaddons'
        'lftp'
        'lynx'
        'mc'
        'memtest86+'
        'mkinitcpio-archiso'
        'nmap'
        'partclone'
        'partimage'
        'polkit-qt5'
        'pyqt5-common'
        'python-pyqt5'
        'python-sip-pyqt5'
        'salientos-calamares'
        'salientos-calamares-xfce-config'
        'solid'
        'syslinux'
        'termite-terminfo'
        'testdisk'
        'yaml-cpp'
    )

    local rpkg

    echo "+---------------------->>"
    echo "[*] Removing unnecessary packages..."
    for rpkg in "${_packages_to_remove[@]}"; do
        pacman -Rnsc ${rpkg} --noconfirm
    done
}

## -------- Delete Unnecessary Files -------------

# Clean live ISO stuff from target system
_clean_target_system() {
    local _files_to_remove=(
        /etc/sudoers.d/g_wheel
        /etc/systemd/system/{etc-pacman.d-gnupg.mount,getty@tty1.service.d}
        /etc/systemd/system/getty@tty1.service.d/autologin.conf
        /etc/initcpio
        /etc/mkinitcpio-archiso.conf
        /etc/polkit-1/rules.d/49-nopasswd-calamares.rules
        /etc/{group-,gshadow-,passwd-,shadow-}
        /etc/udev/rules.d/81-dhcpcd.rules
        #/etc/skel/{.xinitrc,.xsession,.xprofile}
        #/home/"$new_user"/{.xinitrc,.xsession,.xprofile,.wget-hsts,.screenrc,.ICEauthority}
        /home/"$new_user"/{.wget-hsts,.screenrc,.ICEauthority}
        /root/{.automated_script.sh,.zlogin}
        /root/{.xinitrc,.xsession,.xprofile}
        /usr/local/bin/{Installation_guide}
        /usr/share/calamares
        /{gpg.conf,gpg-agent.conf,pubring.gpg,secring.gpg}
        /var/lib/NetworkManager/NetworkManager.state
        # SalientOS
        /etc/polkit-1/rules.d/49-nopasswd_global.rules
        /etc/systemd/system/etc-pacman.d-gnupg.mount
    )
    local dfile

    echo "+---------------------->>"
    echo "[*] Deleting live ISO files..."
    for dfile in "${_files_to_remove[@]}"; do
        rm -rf ${dfile}
    done
    find /usr/lib/initcpio -name archiso* -type f -exec rm '{}' \;
}

## -------- Perform Misc Operations --------------

_fix_permissions_prepare() {

    # Copy grub theme to boot directory
    echo "+---------------------->>"
    echo "[*] Copying grub theme to boot directory..."
    mkdir -p /boot/grub/themes
    cp -rf /usr/share/grub/themes/salient /boot/grub/themes

    # Perform various operations
    echo "+---------------------->>"
    echo "[*] Running operations as new user : ${new_user}..."
    [[ -x `which salientos-hooks-runner` ]] && salientos-hooks-runner

    # remove existing config files

    folders=(
        Desktop
        Documents
        Downloads
        Music
        Pictures
        Public
        Templates
        Videos
    )

    for dir in "${folders[@]}"; do
        [[ -d "$dir" ]] && rm "$dir"
    done

    [[ -f /home/${new_user}/.config/user-dirs.{dirs,locale} ]] && rm /home/${new_user}/.config/user-dirs.{dirs,locale}

    runuser -l ${new_user} -c 'xdg-user-dirs-update'
    runuser -l ${new_user} -c 'xdg-user-dirs-gtk-update'

    # Journal stuff
    sed -i 's/volatile/auto/g' /etc/systemd/journald.conf 2>>/tmp/.errlog
    sed -i 's/.*pam_wheel\.so/#&/' /etc/pam.d/su

    # Salient OS Specific
    #-------------------------------------------------------------------------------------

    [[ -f /etc/salientos-release ]] && mv /etc/salientos-release /etc/lsb-release

    #-------------------------------------------------------------------------------------

    # clean out archiso files from install
    [[ -f /usr/bin/find ]] && find /usr/lib/initcpio -name archiso* -type f -exec rm '{}' \;

    #-------------------------------------------------------------------------------------

    # change smb.conf to the current user
    [[ -f /usr/bin/sed ]] && sed -i "s|liveuser|${new_user}|g" /etc/samba/smb.conf

    #-------------------------------------------------------------------------------------

    # add user to samba with blank passwd for now
    # we'll inform them later after install
    [[ -f /usr/bin/smbpasswd ]] && (
        echo " "
        echo " "
    ) | smbpasswd -s -a ${new_user}

    # change users home permissions
    [[ -f /usr/bin/chmod ]] && chmod o+x /home/${new_user}

    #-------------------------------------------------------------------------------------

    # ensure config is set to current user
    [[ -f /usr/bin/sed ]] && [[ -f /home/${new_user}/.gtkrc-2.0 ]] && sed -i "s|liveuser|${new_user}|g" /home/${new_user}/.gtkrc-2.0

    #-------------------------------------------------------------------------------------

    # bluetooth enhancements
    [[ -f /usr/bin/sed ]] && sed -i "s|#AutoEnable=false|AutoEnable=true|g" /etc/bluetooth/main.conf
    [[ -f /usr/bin/echo ]] && echo 'load-module module-switch-on-connect' | tee --append /etc/pulse/default.pa

    #-------------------------------------------------------------------------------------

    # fix file permissions
    [[ -f /usr/bin/chmod ]] && [[ -f /home/${new_user}/.fehgb ]] && chmod 755 /home/${new_user}/.fehbg

    #-------------------------------------------------------------------------------------

    # change permissions on executables with and without extensions
    [[ -f /usr/bin/find ]] && find /home/${new_user}/.config/* -type f \( -iname '*.sh' -o -iname '*.py' \) -print0 | xargs -0 --no-run-if-empty chmod 755
    [[ -f /usr/bin/find ]] && find /home/${new_user}/.local/bin/* -type f \( -iname '*.sh' -o -iname '*.py' -o ! -iname '*.*' \) -print0 | xargs -0 --no-run-if-empty chmod 755
    [[ -f /usr/bin/find ]] && find /usr/local/bin/* -type f \( -iname '*.sh' -o -iname '*.py' -o ! -iname '*.*' \) -print0 | xargs -0 --no-run-if-empty chmod 755

    #-------------------------------------------------------------------------------------
}

## -------- ## Execute Script ## -----------------
_manage_systemd_services
_remove_vbox_pkgs
_remove_vmware_pkgs
_remove_qemu_pkgs
_remove_unwanted_ucode
_remove_unwanted_packages
_clean_target_system
_fix_permissions_prepare
