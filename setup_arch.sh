#!/usr/bin/env bash
# setup_arch.sh - Paket- und Dienst-Setup fuer Chris' Arch-Desktop (Xfce/X11)
#
# Zweck   : Bringt ein frisch installiertes Arch-System auf den aktuellen Stand:
#           offizielle Pakete, AUR-Pakete, systemd-Dienste, Snap- und
#           Flatpak-Anwendungen (inkl. Steam).
# Aufruf  : sudo bash setup_arch.sh
# Stand   : 2026-09-26, abgeglichen mit dem laufenden System (Kernel 7.2.7-arch1-1)
# Vorab   : [multilib] in /etc/pacman.conf einkommentieren (fuer wine/wine-gecko/
#           wine-mono, steam, winetricks).
# Hinweis : makepkg/yay verweigern den Aufruf als root. Alle AUR-Builds laufen
#           darum als normaler Benutzer ($TARGET_USER) via sudo -u.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Fehler: Dieses Skript muss als Root ausgeführt werden (z.B. mit 'sudo bash setup_arch.sh')."
    exit 1
fi

TARGET_USER="${SUDO_USER:-chris}"
if ! id "$TARGET_USER" &>/dev/null; then
    echo "Fehler: Benutzer '$TARGET_USER' existiert nicht. Bitte TARGET_USER im Skript anpassen."
    exit 1
fi

echo "Fuehre erst aus:"
echo "sudo nano /etc/pacman.conf"
echo "[multilib]"
echo "comment in Include..."

echo "Prüfe System & Paketliste..."
read -p "Dies installiert ca. 177 Pakete + 6 AUR-Pakete und aktiviert Dienste. Fortfahren? [J/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Jj]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

echo "Aktualisiere Paketdatenbank & System..."
pacman -Syu --noconfirm

echo "Installiere angeforderte Pakete..."
PACKAGES=(
    7zip acpid alsa-plugins alsa-utils amd-ucode arm-none-eabi-gdb avahi axel base base-devel bind
    chromium clang cmake code conntrack-tools cryptsetup debugedit dialog discord dmidecode docker
    dotnet-sdk-8.0 ethtool evince exo fakeroot fastfetch feh firefox flameshot flatpak garcon gcc
    gdm gimp git gnome-shell gparted gqrx gradle gsimplecal gvfs-mtp htop inkscape inxi iw iwd
    jdk-openjdk jdk11-openjdk jdk17-openjdk jdk21-openjdk jdk8-openjdk jq keepass less
    libreoffice-fresh libxcrypt-compat lightdm lightdm-gtk-greeter linux linux-firmware
    linux-headers lshw lutris lvm2 lynx maven memtest86+ memtester mesa-utils mousepad mpv mtr
    nano net-tools network-manager-applet networkmanager ninja obs-studio octave openbsd-netcat
    openocd openra openttd openvpn parole pavucontrol pipewire-alsa pipewire-pulse qbittorrent
    qpwgraph radeontop reflector remmina ristretto rsync rtl-sdr sdl3_image signal-desktop socat
    sof-firmware stress-ng sudo systemd tcpdump telegram-desktop tesseract tesseract-data-deu
    thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman thunderbird timeshift
    torbrowser-launcher tree tumbler usbutils uv veracrypt virtualbox vlc vulkan-radeon
    vulkan-tools wesnoth wget wine wine-gecko wine-mono winetricks wireguard-tools wireplumber
    xfburn xfce4-appfinder xfce4-battery-plugin xfce4-clipman-plugin xfce4-cpufreq-plugin
    xfce4-cpugraph-plugin xfce4-dict xfce4-diskperf-plugin xfce4-eyes-plugin xfce4-fsguard-plugin
    xfce4-genmon-plugin xfce4-mailwatch-plugin xfce4-mount-plugin xfce4-mpc-plugin
    xfce4-netload-plugin xfce4-notes-plugin xfce4-panel xfce4-places-plugin xfce4-power-manager
    xfce4-pulseaudio-plugin xfce4-screensaver xfce4-screenshooter xfce4-sensors-plugin
    xfce4-session xfce4-settings xfce4-smartbookmark-plugin xfce4-systemload-plugin
    xfce4-taskmanager xfce4-terminal xfce4-time-out-plugin xfce4-timer-plugin xfce4-verve-plugin
    xfce4-wavelan-plugin xfce4-weather-plugin xfce4-whiskermenu-plugin xfce4-xkb-plugin xfconf
    xfdesktop xfwm4 xonotic xorg-server yay zbar zip
)

pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "AUR-Pakete:"
# 'yay' ist selbst ein AUR-Paket. Fehlt er, wird er als $TARGET_USER gebaut.
if ! command -v yay &> /dev/null; then
    echo "   INFO: 'yay' fehlt -> wird aus dem AUR gebaut (als $TARGET_USER)."
    builddir=$(mktemp -d)
    chown "$TARGET_USER":"$TARGET_USER" "$builddir"
    sudo -u "$TARGET_USER" git clone --depth 1 https://aur.archlinux.org/yay.git "$builddir/yay"
    # Erst bauen (als Benutzer, makepkg verbietet root), dann als root installieren:
    ( cd "$builddir/yay" && sudo -u "$TARGET_USER" makepkg -f --noconfirm )
    pacman -U --noconfirm "$builddir"/yay/yay-*.pkg.tar.zst
    rm -rf "$builddir"
else
    echo "   OKAY: 'yay' ist installiert."
fi
echo "   INFO: 'yay-debug' wird NICHT installiert (veraltet/konfliktiert mit offiziellem yay). Falls nötig: manuell über AUR bauen."

AUR_PACKAGES=(
    arduino-ide-bin eclipse-java-bin snapd xfce4-datetime-plugin xfwm4-themes zoom
)
sudo -u "$TARGET_USER" yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

localectl set-x11-keymap de pc105 deadgraveacute

echo "Aktiviere essentielle systemd-Dienste..."
systemctl enable --now lightdm
systemctl enable --now NetworkManager
systemctl enable --now avahi-daemon
systemctl enable --now docker
systemctl enable --now iwd
systemctl enable --now acpid
systemctl enable --now systemd-timesyncd
systemctl enable --now fstrim.timer

echo "Aktiviere PipeWire (laeuft als BENUTZER-Dienst, nicht als Systemdienst)..."
systemctl --user -M "$TARGET_USER"@ enable --now pipewire pipewire-pulse wireplumber ||
    echo "   INFO: Bitte nach dem ersten Login als $TARGET_USER ausfuehren: systemctl --user enable --now pipewire pipewire-pulse wireplumber"

echo "Installiere Snap:"
# snapd kommt aus dem AUR (siehe AUR_PACKAGES) - kein manueller makepkg-Lauf mehr noetig.
ln -sfn /var/lib/snapd/snap /snap
systemctl enable --now snapd.socket
snap wait system seed.loaded || true
snap refresh || true

echo "installiere Protonmail:"
snap install proton-mail

echo "Update flatpak:"
flatpak update --noninteractive || flatpak update
flatpak uninstall --unused --noninteractive || flatpak uninstall --unused

echo "Bereite Installation von steam vor..."
flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak --user install flathub com.valvesoftware.Steam || true

echo "The following action can take up to 10 minutes of wait time, please don't close before finished:"
echo "execute as user: flatpak run com.valvesoftware.Steam"

echo "Bitte danach neu starten."
