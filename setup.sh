root="archlive/airootfs"
pacmanDb="$root/repo/db"
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
pacman -Syw --noconfirm --cachedir $pacmanDbPkgs --dbpath cache/db $(cat $pkgs)

mkdir -p $root/etc/installer_cache/
mkdir -p $root/home/root
cp packages.txt $root/etc/installer_cache/.
cp inside_chroot.sh $root/home/root/.
cp installer.sh $root/home/root/.
cp pacman.conf $root/etc/.
