#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Fehler: Dieses Skript muss als Root ausgeführt werden (z.B. mit 'sudo bash setup.sh')."
    exit 1
fi

echo "Fuehre erst aus:"
echo "sudo nano /etc/pacman.conf"
echo "[multilib]"
echo "comment in Include..."

echo "Prüfe System & Paketliste..."
read -p "Dies installiert ca. 130 Pakete und aktiviert Dienste. Fortfahren? [J/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

echo "Aktualisiere Paketdatenbank & System..."
pacman -Syu --noconfirm

echo "Installiere angeforderte Pakete..."
PACKAGES=(
    7zip acpid alsa-plugins alsa-utils amd-ucode avahi axel base base-devel bind
    chromium clang cmake code conntrack-tools cryptsetup debugedit dialog discord
    dmidecode docker eclipse-java-bin ethtool evince exo fakeroot fastfetch feh firefox
    flameshot flatpak garcon gcc gimp git gparted gradle gsimplecal htop lightdm
    inkscape inxi iwd jdk-openjdk jdk11-openjdk jdk17-openjdk jdk21-openjdk jdk8-openjdk
    keepass less libreoffice-fresh libxcrypt-compat lightdm-gtk-greeter linux linux-firmware
    lutris lvm2 lynx maven mesa-utils mousepad mpv mtr nano net-tools network-manager-applet
    networkmanager ninja obs-studio octave openbsd-netcat openra openttd openvpn parole
    pavucontrol pipewire-alsa pipewire-pulse qpwgraph radeontop reflector remmina ristretto
    rsync sdl3_image signal-desktop snapd socat sof-firmware sudo systemd tcpdump telegram-desktop
    thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman thunderbird tree tumbler
    veracrypt virtualbox vlc vulkan-radeon vulkan-tools wesnoth wget wine wine-gecko wine-mono
    winetricks wireguard-tools wireplumber xfburn xfce4-appfinder xfce4-battery-plugin
    xfce4-cpufreq-plugin xfce4-cpugraph-plugin xfce4-datetime-plugin xfce4-dict xfce4-diskperf-plugin
    xfce4-eyes-plugin xfce4-fsguard-plugin xfce4-genmon-plugin xfce4-mailwatch-plugin
    xfce4-mount-plugin xfce4-mpc-plugin xfce4-netload-plugin xfce4-notes-plugin xfce4-panel
    xfce4-places-plugin xfce4-power-manager xfce4-pulseaudio-plugin xfce4-screensaver
    xfce4-screenshooter xfce4-sensors-plugin xfce4-session xfce4-settings xfce4-smartbookmark-plugin
    xfce4-systemload-plugin xfce4-taskmanager xfce4-terminal xfce4-time-out-plugin xfce4-timer-plugin
    xfce4-verve-plugin xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin
    xfce4-xkb-plugin xfconf xfdesktop xfwm4 xfwm4-themes xonotic xorg-server yay zip
)

pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "AUR-Pakete:"
if ! command -v yay &> /dev/null; then
    echo "   ERR:  'yay' ist nicht im offiziellen Repo gefunden worden. Bitte manuell installieren oder via AUR-Helper bauen."
else
    echo "   OKAY: 'yay' ist installiert."
fi
echo "   INFO: 'yay-debug' wurde aus der Liste entfernt (veraltet/konfliktiert mit offiziellem yay). Falls nötig: manuell über AUR bauen."

localectl set-x11-keymap de pc105 deadgraveacute

echo "Aktiviere essentielle systemd-Dienste..."
systemctl enable --now lightdm
systemctl enable --now NetworkManager
systemctl enable --now pipewire pipewire-pulse wireplumber
systemctl enable --now avahi-daemon
systemctl enable --now docker
systemctl enable --now snapd
systemctl enable --now iwd

echo "Installiere Snap:"
clone https://aur.archlinux.org/snapd.git
cd snapd/
makepkg -si
ln -s /var/lib/snapd/snap /snap
systemctl enable snapd.socket --now
snap refresh

echo "installiere Protonmail:"
snap install proton-mail

echo "Update flatpak:"
flatpak update
flatpak uninstall --unused

echo "Bereite Installation von steam vor..."
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install flathub com.valvesoftware.Steam

echo "The following action can take up to 10 minutes of wait time, please don't close before finished:"
echo "execute as user: flatpak run com.valvesoftware.Steam"

echo "Bitte danach neu starten."