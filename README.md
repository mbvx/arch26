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

Weiter siehe Kapitel: Chrootumgebung verlassen und neustarten
Chrootumgebung verlassen und neustarten

    exit

Für UEFI-Rechner Partitionen loesen:

	umount -R /mnt
    poweroff

ISO-Stick entfernen, Neustarten und auf der Konsole Einloggen 

Weiter siehe Kapitel: 5. Grafische Benutzeroberflaeche 

Für die Installation der grafischen Benutzeroberfläche und des Audiosystems wird hier jeweils nur eine minimalistische Paketauswahl mit einem Terminal vorgestellt. Die weitere Ausgestaltung sollte individuell erfolgen.
Audio

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
  [multilib]
  - comment in Include...
  sudo pacman -Syu

Installation:
  sudo pacman -S dbus zip unzip p7zip htop tree dialog reflector inxi base-devel firefox thunderbird libreoffice vlc veracrypt git gcc flatpak fakeroot debugedit  chromium discord telegram-desktop signal-desktop keepass
  reboot
  [...]
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
