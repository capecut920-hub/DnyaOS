#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"

if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo: sudo bash ./build-dnyaos.sh"
  exit 1
fi
if [[ ! -f /etc/debian_version ]]; then
  echo "This build script must run in Debian or a Debian-based Linux environment."
  exit 1
fi

echo "Installing live-build and required tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y live-build debootstrap squashfs-tools xorriso git ca-certificates

echo "Preparing clean build configuration..."
mkdir -p out
lb clean --purge || true
lb config \
  --mode debian \
  --distribution trixie \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer false \
  --archive-areas "main contrib non-free-firmware" \
  --security false \
  --apt-recommends true \
  --iso-application "DnyaOS Live" \
  --iso-publisher "DnyaOS Project" \
  --iso-volume "DNYAOS_LIVE"

mkdir -p config/package-lists config/includes.chroot/etc/skel/Desktop config/includes.chroot/usr/local/bin \
  config/includes.chroot/usr/share/applications \
  config/includes.chroot/usr/share/backgrounds/dnyaos \
  config/includes.chroot/usr/share/themes/DnyaOS/gtk-3.0 \
  config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

cp package-lists/dnyaos.list.chroot config/package-lists/dnyaos.list.chroot
cp app/dnyaos-birthday config/includes.chroot/usr/local/bin/dnyaos-birthday
chmod 0755 config/includes.chroot/usr/local/bin/dnyaos-birthday
cp app/dnyaos-birthday.desktop config/includes.chroot/usr/share/applications/
cp app/dnyaos-birthday.desktop config/includes.chroot/etc/skel/Desktop/
cp theme/gtk.css config/includes.chroot/usr/share/themes/DnyaOS/gtk-3.0/gtk.css
cp theme/wallpaper.svg config/includes.chroot/usr/share/backgrounds/dnyaos/wallpaper.svg
cp theme/xfce4-desktop.xml config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
cp theme/xsettings.xml config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cp launchers/*.desktop config/includes.chroot/usr/share/applications/

lb build
test -s live-image-amd64.hybrid.iso
mv -f live-image-amd64.hybrid.iso out/DnyaOS-live-amd64.iso
sha256sum out/DnyaOS-live-amd64.iso > out/DnyaOS-live-amd64.iso.sha256
echo "Build complete: out/DnyaOS-live-amd64.iso"
