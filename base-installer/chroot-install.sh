# Source config
source ./base-install.conf

# Detect VM and define drives
if cat /proc/cpuinfo | grep -q "hypervisor"; then
	DRIVE=$VM_DRIVE
	ESP=$VM_ESP
	SWAP=$VM_SWAP
	ROOT=$VM_ROOT
	HOME=$VM_HOME
else
	DRIVE=$NVME_DRIVE
	ESP=$NVME_ESP
	SWAP=$NVME_SWAP
	ROOT=$NVME_ROOT
	HOME=$NVME_HOME
fi

# Remount esp
echo "Remounting ESP"
umount /boot
mount /boot

# Configure pacman and install additional packages
echo "Configuring and refreshing pacman"
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i '/ParallelDownloads = 5/a ILoveCandy' /etc/pacman.conf
sed -i 's/#\[multilib\]/\[multilib\]/' /etc/pacman.conf
sed -i '/\[multilib\]/{n;s_.*_Include = /etc/pacman.d/mirrorlist_}' /etc/pacman.conf
pacman -Syyuu --noconfirm zsh
read -rsp "Press enter to continue..."
#sleep 1s
clear

# Locale
echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >/etc/locale.conf

# Timezone
echo "Setting timezone"
ln -sf /usr/share/zoneinfo/Europe/Belgrade /etc/localtime
hwclock --systohc
read -rsp "Press enter to continue..."
#sleep 1s
clear

# Enable fstrim
echo "Enabling fstrim.timer service"
systemctl enable fstrim.timer

# Network
echo "Configuring network"
echo $HOSTNAME >/etc/hostname
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager
systemctl enable systemd-resolved
read -rsp "Press enter to continue..."
#sleep 1s
clear

# Root password
echo "Root password"
passwd root
read -rsp "Press enter to continue..."
#sleep 1s
clear

# Bootloader
echo "Installing bootloader"
bootctl install

echo "default arch.conf" >/boot/loader/loader.conf
echo "timeout 0" >>/boot/loader/loader.conf
echo "editor no" >>/boot/loader/loader.conf

echo -e "title\tArch Linux" >/boot/loader/entries/arch.conf
echo -e "linux\t/vmlinuz-linux" >>/boot/loader/entries/arch.conf
echo -e "initrd\t/amd-ucode.img" >>/boot/loader/entries/arch.conf
echo -e "initrd\t/initramfs-linux.img" >>/boot/loader/entries/arch.conf
echo -e "options root=PARTUUID=$(blkid -s PARTUUID -o value $ROOT) rw" >>/boot/loader/entries/arch.conf
read -rsp "Press ender to continue..."
#sleep 1s
clear

# Add user
echo "Adding user: $USER"
useradd -m -G wheel -s /bin/zsh $USER
passwd $USER
chfn -f $(echo $USER | sed 's/.*/\u&/') $USER

# Sudoers settings
echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/$USER
echo "Defaults rootpw" >>/etc/sudoers.d/$USER

# Exit chroot
read -rsp "Press enter to continue..."
#sleep 1s
clear
exit