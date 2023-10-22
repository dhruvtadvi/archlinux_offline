root="archlive/airootfs"
pacmanDb="$root/var/lib/pacman/sync/"
pacmanDbPkgs="$root/repo"
pkgs="packages.txt"

ARCH="x86_64"
MIRROR="https://mirrors.kernel.org/archlinux/"
wget "${MIRROR}/core/os/${ARCH}/core.db"
wget "${MIRROR}/extra/os/${ARCH}/extra.db"
wget "${MIRROR}/multilib/os/${ARCH}/multilib.db"

mkdir -p $pacmanDb
cp *.db $pacmanDb
mkdir cache/db -p
pacman -Syw --noconfirm --cachedir $pacmanDbPkgs --dbpath cache/db $(cat $pkgs) amd-ucode intel-ucode efibootmgr
repo-add $pacmanDbPkgs/custom.db.tar.gz
repo-add $pacmanDbPkgs/custom.db.tar.gz $root/repo/*.zst

mkdir -p $root/etc/installer_cache/
mkdir -p $root/home/root
cp packages.txt $root/etc/installer_cache/.
cp inside_chroot.sh $root/root/.
cp installer.sh $root/root/.
cp pacman.conf $root/etc/.

echo -e 'file_permissions+=(\n\t["/root/inside_chroot.sh"]="0:0:755"\n\t["/root/installer.sh"]="0:0:755"\n)' >> archlive/profiledef.sh
echo "dialog" >> archlive/packages.x86_64
