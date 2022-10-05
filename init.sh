#!/bin/sh

disk="/dev/nvme0n1"
boot="/dev/nvme0n1p1"
root="/dev/nvme0n1p2"
hostname="tester"

# Applications
base="linux linux-firmware base base-devel iwd zsh"
amd="amd-ucode libva-mesa-driver xf86-video-amdgpu mesa mesa-vdpau vulkan-radeon"
xorg="picom xclip xorg-server xorg-xev xorg-xinit"
tools="feh firefox mpc mpd mpv ncmpcpp openssh p7zip pass zathura zathura-pdf-mupdf"
development="fd git languagetool neovim ripgrep tectonic"
fonts="noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono"
sound="pipewire pipewire-alsa pipewire-jack pipewire-pulse pulsemixer wireplumber"
languages="go"

install_linux()
{
	echo "---------------------------------------"
	echo " SYSTEM INSTALL"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	pacstrap -K /mnt $base $amd $xorg $tools $development $fonts $sound $languages
}

install_yay()
{
	echo "---------------------------------------"
	echo " YAY INSTALL"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -si
	cd ..
	rm -rf yay
}

install_suckless()
{
	echo "---------------------------------------"
	echo " SUCKLESS INSTALL"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	git clone git@github.com:tom1slav/dwm.git /home/$user/code/linux/dwm
	git clone git@github.com:tom1slav/dmenu.git /home/$user/code/linux/dmenu
	git clone git@github.com:tom1slav/st.git /home/$user/code/linux/st
	git clone git@github.com:tom1slav/block.git /home/$user/code/linux/block
	git clone git@github.com:tom1slav/slock.git /home/$user/code/linux/slock
	cd /home/$user/code/linux/dwm
	sudo make clean install
	cd /home/$user/code/linux/dmenu
	sudo make clean install
	cd /home/$user/code/linux/st
	sudo make clean install
	cd /home/$user/code/linux/block
	sudo make clean install
	cd /home/$user/code/linux/slock
	sudo make clean install
}

partition()
{
	echo "---------------------------------------"
	echo " FORMAT DISKS"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	fdisk $disk << EOF
g
n
1

+512M
n
2


t
1
1
p
w
EOF
}

encrypt()
{
	echo "---------------------------------------"
	echo " ENCRYPT DISKS"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	cryptsetup -y -v luksFormat $root
	cryptsetup open $root root
}

format()
{
	echo "---------------------------------------"
	echo " FORMAT DISKS"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	mkfs.ext4 /dev/mapper/root
	mkfs.fat -F32 $boot

	mount /dev/mapper/root /mnt
	mount --mkdir $boot /mnt/boot
}

prepare()
{
	echo "---------------------------------------"
	echo " PREPARE ROOT"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	genfstab -U /mnt >> /mnt/etc/fstab
	ln -sf /mnt/usr/share/zoneinfo/Europe/Vienna /mnt/etc/localtime
	echo 'LANG=en_GB.UTF-8' > /mnt/etc/locale.conf
	echo 'KEYMAP=de-latin1' > /mnt/etc/vconsole.conf
	echo $hostname > /mnt/etc/hostname
	sed -i '/^HOOKS=/c\HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)' /mnt/etc/mkinitcpio.conf
	sed -i '/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/c\%wheel ALL=(ALL:ALL) NOPASSWD: ALL' /mnt/etc/sudoers
}

settings()
{
	echo "---------------------------------------"
	echo " SETUP ROOT"
	echo "---------------------------------------"
	read -n1 -sp 'Press enter to continue...'

	hwclock --systohc
	locale-gen
	mkinitcpio -P
	useradd -m -G wheel -s /bin/zsh $user
	echo root:$pass | chpasswd
	echo $user:$pass | chpasswd
	bootctl install
	systemctl enable systemd-networkd.service
	systemctl enable systemd-resolved.service
}

read -p 'Enter your username: ' user
read -sp 'Enter your password: ' pass
clear

loadkeys de-latin1

partition
encrypt
format

install_linux
prepare

export user
export pass

export -f settings
export -f install_suckless

arch-chroot /mnt /bin/bash -c "settings" || echo "arch-chroot returned: $?"
arch-chroot -u $user /mnt /bin/bash -c "install_suckless" || echo "arch-chroot returned: $?"
