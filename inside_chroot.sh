#!/bin/bash
hwclock --systoh
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

root_partition=$(cat /etc/installer_cache/root_partition.txt)
username=$(cat /etc/installer_cache/username.txt)
if [ -f "/etc/installer_cache/hostname.txt" ]; then
  cat /etc/installer_cache/hostname.txt > /etc/hostname
else
  echo "natu" > /etc/hostname
fi

if [ -f "/etc/installer_cache/username.txt" ]; then
  if [ -f "/etc/installer_cache/password.txt" ]; then
    password=$(cat /etc/installer_cache/password.txt)
    useradd -m -p $(perl -e 'print crypt($ARGV[0], "password")' $password) $username
  else
     useradd -m "$username"
  fi
  usermod -aG wheel,audio,video,storage $username
  echo "$username	ALL=(ALL:ALL) ALL" >> /etc/sudoers
fi

if [[ -d /sys/firmware/efi ]]; then
    echo "Installing GRUB on EFI system..."
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub --removable
else
    echo "Installing GRUB on MBR system..."
    grub-install --target=i386-pc  $root_partition
    grub-install --target=i386-pc $root_partition --removable
fi

mkdir -p /etc/systemd/system/getty@tty1.service.d/
echo -e "[Service]\nExecStart=\nExecStart=-/usr/bin/agetty -a $username --noclear %I $TERM" > /etc/systemd/system/getty\@tty1.service.d/override.conf
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable bluetooth.service
systemctl enable NetworkManager.service
