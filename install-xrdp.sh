#!/bin/bash
#
# This script automates the process of downloading, building, and installing xrdp and xorgxrdp on Kubuntu,
# with x264 support enabled for enhanced performance. 
# 

# Define xrdp version and working directory
xrdpVersion=v0.10.4
WORKDIR=$PWD/tmpxrdp

# Prevent script from running as root
if [ "$(id -u)" == 0 ]; then
    echo 'This script must be run without root privileges' >&2
    exit 1
fi

# Install required kernel tools and development packages
sudo apt-get -y install linux-cloud-tools-virtual
sudo apt-get -y install git curl autoconf automake clang gcc g++ libtool make nasm pkg-config check \
libcmocka-dev libfreetype-dev libpam0g-dev libssl-dev libx11-dev libxrandr-dev libxfixes-dev \
libxkbfile-dev libfuse3-dev libjpeg-dev libmp3lame-dev libfdk-aac-dev libibus-1.0-dev libimlib2-dev \
libopus-dev libpixman-1-dev libx264-dev libopenh264-dev xserver-xorg-dev xserver-xorg-core

# Create and enter working directory
mkdir -p -- "$WORKDIR"
cd "$WORKDIR" || exit

# Clone and build xrdp with enhanced codec support
git clone -b $xrdpVersion https://github.com/neutrinolabs/xrdp.git --recursive
cd "$WORKDIR"/xrdp || exit
./bootstrap
./configure --with-systemdsystemunitdir=/usr/lib/systemd/system \
    --enable-jpeg --enable-fuse --enable-mp3lame --enable-rfxcodec \
    --enable-painter --enable-x264 --enable-openh264 --enable-vsock
make
sudo make install

# Clone and build xorgxrdp
cd "$WORKDIR" || exit
git clone -b $xrdpVersion https://github.com/neutrinolabs/xorgxrdp.git --recursive
cd "$WORKDIR"/xorgxrdp || exit
./bootstrap
./configure
make
sudo make install

# Clean up temporary build directory
cd "$WORKDIR"/.. || exit
sudo rm -rf "$WORKDIR"

# Enable support for both TCP and VSOCK transport in xrdp
sudo sed -i_orig -e 's/port=3389/port=tcp:\/\/:3389 vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini

# Enable VMConnect integration
sudo sed -i -e 's/#vmconnect=true/vmconnect=true/g' /etc/xrdp/xrdp.ini

# Set KDE as the default desktop environment for xrdp sessions
sudo sed -i_orig '8a export XDG_CURRENT_DESKTOP=KDE' /etc/xrdp/startwm.sh

# Rename shared drive mount point for better clarity
sudo sed -i_orig -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Allow all users to start X sessions (needed for xrdp)
sudo sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Create polkit rule to allow Flatpak repo modifications without authentication in xrdp sessions
sudo bash -c "cat >/etc/polkit-1/rules.d/48-allow-flatpak.rules" <<EOF
/* Allow system refresh without authentication xrdp Session */
polkit.addRule(function(action, subject) {
if (action.id = "org.freedesktop.Flatpak.modify-repo" &&
subject.isInGroup("sudo")) {
return polkit.Result.YES;
}
});
EOF

# Create polkit rule to allow power control (shutdown/reboot) in xrdp sessions for KDE
sudo bash -c "cat >/etc/polkit-1/rules.d/49-allow-KDE-Power.rules" <<EOF
/* Allow poweroff Control in xrdp Session for KDE mainly */

polkit.addRule(function(action, subject) {
if (~["org.freedesktop.login1.power-off","org.freedesktop.login1.power-off-multiple-sessions","org.freedesktop.login1.reboot","org.freedesktop.login1.reboot-multiple-sessions"].indexOf(action.id)) &&
subject.isInGroup("sudo")) {
return polkit.Result.YES;
}
});
EOF

# Create polkit rule to allow all users to manage color profiles via Colord
sudo bash -c "cat >/etc/polkit-1/rules.d/49-allow-KDE-Colord.rules" <<EOF
// Allow Colord all Users
polkit.addRule(function(action, subject) {
if (action.id == "org.freedesktop.color-manager.create-device" ||
action.id == "org.freedesktop.color-manager.create-profile" ||
action.id == "org.freedesktop.color-manager.delete-device" ||
action.id == "org.freedesktop.color-manager.delete-profile" ||
action.id == "org.freedesktop.color-manager.modify-device" ||
action.id == "org.freedesktop.color-manager.modify-profile" &&
subject.isInGroup("users") ) {
return polkit.Result.YES;
}
});
EOF

# Create polkit rule to allow system update and proxy configuration in xrdp sessions
sudo bash -c "cat >/etc/polkit-1/rules.d/50-allow-KDE-UpdateRepo.rules" <<EOF
//Allow Network manager control
polkit.addRule(function(action, subject) {
if (action.id == "org.freedesktop.packagekit.system-sources-refresh"||
action.id == "org.freedesktop.packagekit.system-network-proxy-configure" &&
subject.isInGroup("sudo")) {
return polkit.Result.YES;
}
});
EOF

# Create polkit rule to allow network control via NetworkManager in xrdp sessions
sudo bash -c "cat >/etc/polkit-1/rules.d/50-allow-KDE-NetworkManager.rules" <<EOF
//Allow Network manager control
polkit.addRule(function(action, subject) {
if (action.id == "org.freedesktop.NetworkManager.network-control" && subject.isInGroup("sudo")) {
return polkit.Result.YES;
}
});
EOF

# Install PipeWire module for xrdp to enable audio redirection
sudo apt-get -y install pipewire-module-xrdp

# Enable xrdp and its session manager to start on boot
sudo systemctl enable xrdp xrdp-sesman

clear
echo -e "\n"
echo -e "\033[1;36m|===================================================================|\033[0m"
echo -e "\033[1;36m|                      Installation Complete                        |\033[0m"
echo -e "\033[1;36m|===================================================================|\033[0m"
echo -e "\033[1;36m|  To enable enhanced session support, run the following command    |\033[0m"
echo -e "\033[1;36m|  in PowerShell (as Administrator) on the host machine:            |\033[0m"
echo -e "\033[1;36m|                                                                   |\033[0m"
echo -e "\033[1;36m|  Set-VM -VMName \"NAME\" -EnhancedSessionTransportType HvSocket     |\033[0m"
echo -e "\033[1;36m|                                                                   |\033[0m"
echo -e "\033[1;36m|      Reboot your machine to start using xrdp.                     |\033[0m"
echo -e "\033[1;36m|===================================================================|\033[0m"
echo -e "\n"
