#!/bin/bash

get_partition_by_mount_point() {
    local mount_point="$1"
    local partition_name
    
    partition_name=$(df -hP "$mount_point" | awk 'NR==2 {print $1}')
    
    if [[ -n "$partition_name" ]]; then
        echo "$partition_name"
    else
        echo "No partition found for mount point: $mount_point"
    fi
}

create_ext4_partition() {
    local device="/dev/$1"
    
    # Check if the device exists
    if [ ! -e "$device" ]; then
        echo "Error: Device '$device' not found."
        exit 1
    fi
    
    echo "Creating ext4 partition on $device..."
    mkfs.ext4 "$device"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create ext4 partition on $device."
        exit 1
    fi
    
    echo "ext4 partition created successfully on $device."
}

create_fat32_partition() {
    local device="/dev/$1"
    
    if [ ! -e "$device" ]; then
        echo "Error: Device '$device' not found."
        exit 1
    fi
    
    if [ -n "$(lsblk -no UUID "$device" 2>/dev/null)" ]; then
        echo "Error: Partition already exists on $device."
        exit 1
    fi
    
    echo "Creating FAT32 partition on $device..."
    mkfs.fat -F32 "$device"
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create FAT32 partition on $device."
        exit 1
    fi
    
    echo "FAT32 partition created successfully on $device."
}

create_swap_partition() {
    local device="/dev/$1"
    
    # Check if the device exists
    if [ ! -e "$device" ]; then
        echo "Error: Device '$device' not found."
        exit 1
    fi
    
    
    # Create swap partition
    echo "Creating swap partition on $device..."
    mkswap "$device"
    
    # Check if partition creation was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create swap partition on $device."
        exit 1
    fi
    
    # Enable the swap partition
    swapon "$device"
    
    # Check if swap activation was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to activate swap on $device."
        exit 1
    fi
    
    echo "Swap partition created and activated successfully on $device."
}

mount_partition() {
    local device="/dev/$1"
    local mount_point="$2"
    
    # Check if the device exists
    if [ ! -e "$device" ]; then
        echo "Error: Device '$device' not found."
        exit 1
    fi
    
    # Check if the mount point exists, create if not
    if [ ! -d "$mount_point" ]; then
        mkdir -p "$mount_point"
    fi
    
    # Mount the partition with specified file system type
    echo "Mounting $device to $mount_point"
    mount  "$device" "$mount_point"
    
    # Check if mounting was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to mount $device to $mount_point"
        exit 1
    fi
    
    echo "Partition mounted successfully on $mount_point."
}

menu() {
    while true; do
        if [ ! -d /sys/firmware/efi ]; then
	    menu=$(dialog --menu "Arch offline installer" 12 45 4 1 "Partitioning" 2 "Hostname" 3 "add user" 4 "Install" 5 "Exit" 6 "disk partition name" 2>&1 >/dev/tty)
        else
            menu=$(dialog --menu "Arch offline installer" 12 45 4 1 "Partitioning" 2 "Hostname" 3 "add user" 4 "Install" 5 "Exit" 2>&1 >/dev/tty)
	fi
        if [[ $menu == "1" ]]; then
            menu=$(dialog --menu "What would you like to do?" 12 35 4 1 "Format partition" 2 "Mount partition" 3 "Back" 2>&1 >/dev/tty)
            if [[ $menu == "1" ]]; then
                partition=$(dialog --menu "Select partition :" 20 40 4 \
                    $(lsblk -n --output TYPE,KNAME | awk '$1=="part"{print $2, i++}') 2>&1 >/dev/tty)
                format_partition_type=$(dialog --menu "Which type of partition?" 12 45 4 1 "ext4" 2 "fat32" 3 "swap" 4 "Back" 2>&1 >/dev/tty)
                if [[ $format_partition_type == "1" ]]; then
                    create_ext4_partition $partition
                elif [[ $format_partition_type == "2" ]]; then
                    create_fat32_partition $partition
                elif [[ $format_partition_type == "3" ]]; then
                    create_swap_partition $partition
                elif [[ $format_partition_type == "4" ]]; then
                    continue
                fi
            elif [[ $menu == "2" ]]; then
                partition=$(dialog --menu "Select Partition: " 20 40 4 \
                    $(lsblk -n --output TYPE,KNAME | awk '$1=="part"{print $2, i++}') 2>&1 >/dev/tty)
                mount_point=$(dialog --inputbox "What's the mount point, enter for exit" 10 60 2>&1 >/dev/tty)
                if [[ $mount_point == "" ]]; then
		  continue
		fi 
                mount_partition $partition $mount_point
            elif [[ $menu == "3" ]]; then
                continue
            fi
        elif [[ $menu == "2" ]]; then
            hostname=$(dialog --inputbox "What's the Hostname, enter for exit" 10 60 2>&1 >/dev/tty)
	    if [[ $hostname == "" ]]; then
              continue
            fi
            echo $hostname > hostname.txt
        elif [[ $menu == "3" ]]; then
            username=$(dialog --inputbox "What's the username, enter for exit" 10 60 2>&1 >/dev/tty)
	    password=$(dialog --inputbox "What's the password, enter for no password" 10 60 2>&1 >/dev/tty)
	    if [ ! -z "$username" ]; then
		echo "$username" > username.txt
	    fi
            if [ ! -z "$password" ]; then
	        echo "$password" > password.txt
	    fi
	elif [[ $menu == "4" ]]; then
            pacman-key --init
            pacman-key --populate
	    root_partition=$(get_partition_by_mount_point "/mnt")
	    echo $root_partition > root_partition.txt
	    if grep -qi 'vendor_id.*intel' /proc/cpuinfo; then
                pacstrap /mnt intel-ucode
            elif grep -qi 'vendor_id.*amd' /proc/cpuinfo; then
                pacstrap /mnt amd-ucode
            fi
            if [[ -d /sys/firmware/efi ]]; then
              pacstrap -K /mnt $(cat /etc/installer_cache/packages.txt) efibootmgr
            else
              pacstrap -K /mnt $(cat /etc/installer_cache/packages.txt)
            fi
    	    genfstab -U /mnt > /mnt/etc/fstab
            mkdir -p /mnt/etc/installer_cache/
	    cp inside_chroot.sh /mnt/etc/installer_cache/.
            cp *.txt /mnt/etc/installer_cache/.
  	    arch-chroot /mnt /bin/bash /etc/installer_cache/inside_chroot.sh

        elif [[ $menu == "5" ]]; then
            exit
	elif [[ $menu == "6" ]]; then
            boot_partition_bios=$(dialog --inputbox "enter disk partition" 10 60 2>&1 >/dev/tty)
	    if [ $? -eq 0 ]; then
               echo $boot_partition_bios > boot_partition_bios.txt
            else
               continue
            fi
         fi
    done
}
menu
