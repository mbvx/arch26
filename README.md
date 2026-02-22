# arch26

	--> https://itsfoss.com/install-arch-linux/
	--> https://wiki.archlinux.de/title/2._Installation_des_Grundsystems
	--> https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot
	--> https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
	--> https://itsfoss.com/things-to-do-after-installing-arch-linux/
	--> https://github.com/bpteodor/notes/blob/main/install-ARCH.md
	--> https://wiki.archlinux.org/title/Dm-crypt/System_configuration
	--> https://github.com/silentz/arch-linux-install-guide

--nach boot von stick:

	loadkeys de-latin1
	(ls /sys/firmware/efi/efivars) CHECK

d) EFI, crypted-LVM

Partitionieren und Formatieren:

    lsblk - x ermitteln
    ######nein: dd status=progress if=/dev/zero of=/dev/x - bei Bedarf Datentraeger bereinigen
    gdisk /dev/sda - gdisk starten
		o - neue Partitionstabelle im cache schreiben
		y - bestaetigen
		n - neue Partition
		↵ Enter - die Partitionsnummer bestaetigen
		↵ Enter - den ersten Sektor bestaetigen
		+512M - die Partitionsgroesse festlegen
		ef00 - den Partitionstyp fuer EFI setzen
		n - eine weitere Partition anlegen
		↵ Enter - die Partitionsnummer bestaetigen
		↵ Enter - ersten Sektor bestaetigen
		↵ Enter - letzten Sektor bestaetigen
		8309 - den Partitionstyp fuer LINUX-CRYPT setzen
		↵ Enter - den Linux Partitionstyp (8300) bestaetigen
		p - zeige neue Partitionstabelle zur Ueberpruefung an
		w - speichern der neuen Partitionstabelle
		y - bestaetigen	
    cryptsetup -c aes-xts-plain64 -y -s 512 luksFormat /dev/sda2 
    cryptsetup open /dev/sda2 lvm 
    pvcreate /dev/mapper/lvm 
    vgcreate main /dev/mapper/lvm 
    lvcreate -L 8GB -n swap main 
    lvcreate -l 100%FREE -n root main 
    mkfs.fat -F 32 -n EFI /dev/sda1 
    mkfs.ext4 -L ROOT /dev/mapper/main-root
    mkswap -L SWAP /dev/mapper/main-swap 
    mount /dev/mapper/main-root /mnt 
    swapon /dev/mapper/main-swap 
    mkdir /mnt/boot 
    mount /dev/sda1 /mnt/boot

Installation der Basispakete:

    pacstrap /mnt base linux linux-firmware systemd cryptsetup lvm2 networkmanager iwd nano (intel-ucode oder amd-ucode)
	genfstab -Lp /mnt > /mnt/etc/fstab 
    arch-chroot /mnt
    nano /etc/mkinitcpio.conf
		richtig: HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)
	mkinitcpio -P linux
	
Weiter siehe Kapitel 3. Konfiguration 

    echo archpc > /etc/hostname 
    echo LANG=de_DE.UTF-8 > /etc/locale.conf 
    echo KEYMAP=de-latin1 > /etc/vconsole.conf 
    echo FONT=lat9w-16 >> /etc/vconsole.conf 
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime 
    nano /etc/locale.gen - Und das # am Anfang der folgenden Zeilen entfernen:
		de_DE.UTF-8 UTF-8
		de_DE ISO-8859-1
		de_DE@euro ISO-8859-15
		en_US.UTF-8 UTF-8
    locale-gen - locale genrieren
    passwd - Das Root Password erstellen
    useradd -m -g users -s /bin/bash chris
    passwd chris
    usermod -aG wheel,video,power chris
	pacman -S sudo acpid avahi iwd  ---- systemd-sysvcompat ?
    EDITOR=nano visudo
		%wheel ALL=(ALL) ALL

Dienste aktivieren:

    systemctl enable acpid - Energieverwaltung
    systemctl enable avahi-daemon - Netzwerk Zuweisung
    systemctl enable NetworkManager - Netzwerkmanager
    systemctl enable iwd - WLAN Daemon
    systemctl enable systemd-timesyncd - Zeit Synchronisation
    systemctl enable fstrim.timer - woechentlicher SSD Trim-Service

Weiter siehe Kapitel 4. Bootloader 

b) EFI, crypted-LVM

    bootctl install - Systemd-boot vorbereiten
	blkid   ----> UUID -> sda2
    nano /boot/loader/entries/arch.conf - und wie folgt anpassen:
		title Arch Linux
		linux /vmlinuz-linux
		initrd /intel-ucode.img
		initrd /initramfs-linux.img
		options rd.luks.name=d0e.........c7=main root=/dev/mapper/main-root rw
    cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-fallback.conf - Wie oben mit Unterschied in der 'initrd' Zeile:
		initrd /initramfs-linux-fallback.img
    nano /boot/loader/loader.conf - und entsprechend anpassen:
		default arch
		timeout 4
    bootctl update - Systemd-boot updaten

Chrootumgebung verlassen und neustarten

    exit

Für UEFI-Rechner Partitionen loesen:

	umount -R /mnt
    poweroff

ISO-Stick entfernen, Neustarten und auf der Konsole Einloggen 

Weiter siehe Kapitel: 5. Grafische Benutzeroberflaeche 

Für die Installation der grafischen Benutzeroberfläche und des Audiosystems wird hier jeweils nur eine minimalistische Paketauswahl mit einem Terminal vorgestellt. Die weitere Ausgestaltung sollte individuell erfolgen.

Für alle GUIs gleich:

    pacman -S wireplumber pipewire-alsa pipewire-pulse

ODER i3

    pacman -S i3 xorg xorg-apps xorg-xlsfonts xdotool xclip xsel xorg-server xorg-xinit mesa foot dmenu i3-wm i3status i3lock pango lxappearance polybar rofi alacritty dunst feh xss-lock flameshot gsimplecal yazi ueberzugpp ly
	sudo systemctl enable ly 
    i3 --version
	cp /etc/X11/xinit/xinitrc ~/.xinitrc
	nano ~/.xinitrc
	exec i3	
	cp /etc/i3status.conf ~/.config/i3status/config
	nano ~/.config/i3status/config -> %speed löschen
	temporär: export LC_ALL="en_US.UTF-8"
	
	
	startx
	
ODER xfce

	pacman -S xfce4 xfce4-session xorg-server mesa network-manager-applet lightdm-gtk-greeter
	localectl set-x11-keymap de pc105 deadgraveacute - Tastaturlayout (Bsp.)
	systemctl enable lightdm - Login-Manager aktivieren	

GNOME

    pacman -S gnome gnome-shell network-manager-applet pavucontrol gnome-terminal gdm
    systemctl enable gdm - Login-Manager aktivieren	
	
Erstes Update:
	
	sudo nano /etc/pacman.conf 
	"[multilib]"
	comment in Include...
	sudo pacman -Syu

Installation:
	
	sudo pacman -S dbus zip unzip p7zip htop tree dialog reflector inxi base-devel firefox thunderbird libreoffice vlc veracrypt git gcc flatpak fakeroot debugedit  chromium discord telegram-desktop signal-desktop keepass
	reboot	
	"[...]"	
	clone https://aur.archlinux.org/snapd.git 
	cd snapd/
	makepkg -si
	sudo ln -s /var/lib/snapd/snap /snap
	sudo systemctl enable snapd.socket --now
	sudo snap install proton-mail	
	---> wiki.archlinux.de/title/Steam 
	$ flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	$ flatpak --user install flathub com.valvesoftware.Steam
	$ flatpak run com.valvesoftware.Steam
	(KANN DAUERN!)

	flatpak update
	flatpak uninstall --unused
	snap refresh
	
	pacman -S mesa vulkan-amd lib32-mesa lib32-vulkan-amd vulkan-tools mesa-utils
	(you might need to enable DRI3 in Xorg settings)
	reboot

########

[chris@linuxpc ~]$ pacman -Qe

		7zip 26.00-1
		acpid 2.0.34-2
		alsa-plugins 1:1.2.12-5
		alsa-utils 1.2.15.2-2
		amd-ucode 20260110-1
		avahi 1:0.9rc3-1
		axel 2.17.14-2
		base 3-3
		base-devel 1-2
		bind 9.20.19-1
		chromium 145.0.7632.109-1
		conntrack-tools 1.4.8-1
		cryptsetup 2.8.4-1
		debugedit 5.2-1
		dialog 1:1.3_20260107-1
		discord 1:0.0.125-1
		ethtool 1:6.19-1
		evince 1:48.1-1
		exo 4.20.0-2
		fakeroot 1.37.2-1
		fastfetch 2.59.0-1
		feh 3.11.2-2
		firefox 147.0.4-1
		flameshot 13.3.0-2
		flatpak 1:1.16.3-1
		garcon 4.20.0-2
		gcc 15.2.1+r604+g0b99615a8aef-1
		gdm 49.2-1
		gimp 3.0.8-2
		git 2.53.0-1
		gnome-shell 1:49.4-2
		gparted 1.8.0-1
		gradle 9.3.1-1
		gsimplecal 2.5.2-1
		htop 3.4.1-1
		inkscape 1.4.3-2
		inxi 3.3.40.1-1
		iwd 3.11-2
		jdk-openjdk 25.0.2.u10-1
		jdk11-openjdk 11.0.30.u7-1
		jdk17-openjdk 17.0.18.u8-1
		jdk21-openjdk 21.0.10.u7-1
		jdk8-openjdk 8.482.u08-1
		keepass 2.57.1-1
		libreoffice-fresh 26.2.0-4
		lightdm-gtk-greeter 1:2.0.9-1
		linux 6.18.9.arch1-2
		linux-firmware 20260110-1
		lutris 0.5.20-1
		lvm2 2.03.38-1
		lynx 2.9.2-2
		maven 3.9.12-1
		mesa-utils 9.0.0-7
		mousepad 0.6.5-1
		mpv 1:0.41.0-3
		mtr 0.96-1
		nano 8.7.1-1
		net-tools 2.10-3
		network-manager-applet 1.36.0-1
		networkmanager 1.54.3-1
		obs-studio 32.0.4-1
		openbsd-netcat 1.234_1-1
		openra 20250330-1
		openttd 15.2-1
		openvpn 2.7.0-1
		pavucontrol 1:6.2-1
		pipewire-alsa 1:1.4.10-2
		pipewire-pulse 1:1.4.10-2
		qpwgraph 0.9.8-1
		reflector 2023-5
		remmina 1:1.4.43-1
		rsync 3.4.1-2
		signal-desktop 7.90.0-1
		snapd 2.73-1
		socat 1.8.1.1-1
		sof-firmware 2025.12.2-1
		sudo 1.9.17.p2-2
		systemd 259.1-1
		tcpdump 4.99.6-1
		telegram-desktop 6.5.1-1
		thunar 4.20.7-1
		thunar-archive-plugin 0.6.0-1
		thunar-media-tags-plugin 0.6.0-1
		thunar-volman 4.20.0-2
		thunderbird 147.0.1-1
		tree 2.3.1-1
		tumbler 4.20.1-1
		veracrypt 1.26.24-2
		vlc 3.0.21-32
		vulkan-radeon 1:25.3.5-1
		vulkan-tools 1.4.341.0-1
		wesnoth 1:1.18.6-1
		wget 1.25.0-3
		wine 11.3-1
		wine-gecko 2.47.4-2
		wine-mono 11.0.0-1
		winetricks 20260125-1
		wireguard-tools 1.0.20250521-1
		wireplumber 0.5.13-1
		xfce4-appfinder 4.20.0-2
		xfce4-datetime-plugin 0.8.3-2
		xfce4-mount-plugin 1.2.0-1
		xfce4-netload-plugin 1.5.0-1
		xfce4-panel 4.20.6-1
		xfce4-power-manager 4.20.0-3
		xfce4-pulseaudio-plugin 0.5.1-1
		xfce4-screensaver 4.20.1-1
		xfce4-screenshooter 1.11.3-3
		xfce4-session 4.20.3-2
		xfce4-settings 4.20.3-1
		xfce4-terminal 1.1.5-2
		xfce4-whiskermenu-plugin 2.10.1-1
		xfce4-xkb-plugin 0.9.0-1
		xfconf 4.20.0-2
		xfdesktop 4.20.1-3
		xfwm4 4.20.0-2
		xfwm4-themes 4.10.0-6
		xonotic 0.8.6-2
		xorg-server 21.1.21-1
		zip 3.0-11

[chris@linuxpc ~]$ snap list

		bare
		core22
		core24
		cups
		gnome-42-2204
		gnome-46-2404
		gtk-common-themes
		mesa-2404
		proton-mail
		shattered-pixel-dungeon
		snap-store
		snapd
		warzone2100
		warzone2100-videos

[chris@linuxpc ~]$ flatpak list

		Name                               Anwendungskennung
		Steam                              com.valvesoftware.Steam
		Path of Building                   community.pathofbuilding.PathOfBuilding
		Unciv                              io.github.yairm210.unciv
		Freedesktop Platform               org.freedesktop.Platform
		i386                               org.freedesktop.Platform.Compat.i386
		Mesa                               org.freedesktop.Platform.GL.default
		Mesa (Extra)                       org.freedesktop.Platform.GL.default
		Mesa                               org.freedesktop.Platform.GL32.default
		Mesa (Extra)                       org.freedesktop.Platform.GL32.default
		Codecs Extra Extension             org.freedesktop.Platform.codecs-extra
		i386                               org.freedesktop.Platform.codecs_extra.i386
		Adwaita dark GTK theme             org.gtk.Gtk3theme.Adwaita-dark

Blizzard Games:

	Download and add „Battle.net-Setup.exe“ as „Non-Steam-Game“ to your library…

Tastatur → Tastaturbelegung → deutsch
Tastatur → Tastenkürzel für Anwendungen:

	amixer -D pulse sset Master 5%+ → vol up
	amixer -D pulse sset Master 5%- → vol down 
	amixer -D pulse set Master toggle → mute
	xfce4-screensaver-command --lock → super + L
	xflock4 → strg + alt + L (default)
	??? → strg + alt + D (default)
	xfce4-popup-whiskermenu → Super (doesn’t work)

Login Screen:

	Hintergund → festlegen
