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
apt-get install -y live-build debootstrap squashfs-tools xorriso git ca-certificates isolinux syslinux-common

# Debian's live-build package currently looks for Contents-amd64.gz one level too high.
# The Debian archive stores it under the main component, so patch both URL templates.
LIVE_BUILD_KERNEL_HELPER=/usr/lib/live/build/lb_chroot_linux-image
if [[ -f "$LIVE_BUILD_KERNEL_HELPER" ]]; then
  sed -i \
    -e 's@/dists/${LB_PARENT_DISTRIBUTION}/Contents-@/dists/${LB_PARENT_DISTRIBUTION}/main/Contents-@g' \
    -e 's@/dists/${LB_DISTRIBUTION}/Contents-@/dists/${LB_DISTRIBUTION}/main/Contents-@g' \
    "$LIVE_BUILD_KERNEL_HELPER"
fi

echo "Preparing clean build configuration..."
mkdir -p out
lb clean --purge || true

lb config \
  --mode debian \
  --distribution trixie \
  --initsystem systemd \
  --mirror-bootstrap https://deb.debian.org/debian \
  --mirror-chroot https://deb.debian.org/debian \
  --mirror-binary https://deb.debian.org/debian \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --debian-installer false \
  --archive-areas "main contrib non-free-firmware" \
  --firmware-chroot true \
  --firmware-binary true \
  --security false \
  --apt-recommends true \
  --iso-application "DnyaOS Live" \
  --iso-publisher "DnyaOS Project" \
  --iso-volume "DNYAOS_LIVE"

mkdir -p config/package-lists config/archives config/includes.chroot/root/isolinux config/includes.chroot/etc/skel/Desktop config/includes.chroot/usr/local/bin \
  config/includes.chroot/usr/share/applications \
  config/includes.chroot/usr/share/backgrounds/dnyaos \
  config/includes.chroot/usr/share/themes/DnyaOS/gtk-3.0 \
  config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml

# live-build's syslinux stage looks for these files at /root/isolinux
# inside its build chroot. Include them in the chroot instead of the host.
test -s /usr/lib/ISOLINUX/isolinux.bin || {
  echo "Missing /usr/lib/ISOLINUX/isolinux.bin (package: isolinux)" >&2
  exit 1
}
test -s /usr/lib/syslinux/modules/bios/vesamenu.c32 || {
  echo "Missing /usr/lib/syslinux/modules/bios/vesamenu.c32 (package: syslinux-common)" >&2
  exit 1
}
install -m 0644 /usr/lib/ISOLINUX/isolinux.bin config/includes.chroot/root/isolinux/isolinux.bin
install -m 0644 /usr/lib/syslinux/modules/bios/vesamenu.c32 config/includes.chroot/root/isolinux/vesamenu.c32

cp package-lists/dnyaos.list.chroot config/package-lists/dnyaos.list.chroot
cp config-templates/dnyaos-security.list.chroot config/archives/dnyaos-security.list.chroot
cp app/dnyaos-birthday config/includes.chroot/usr/local/bin/dnyaos-birthday
chmod 0755 config/includes.chroot/usr/local/bin/dnyaos-birthday
cp app/dnyaos-birthday.desktop app/dnyaos-birthday-preview.desktop config/includes.chroot/usr/share/applications/
cp app/dnyaos-birthday.desktop app/dnyaos-birthday-preview.desktop config/includes.chroot/etc/skel/Desktop/
cp theme/index.theme config/includes.chroot/usr/share/themes/DnyaOS/index.theme
cp theme/gtk.css config/includes.chroot/usr/share/themes/DnyaOS/gtk-3.0/gtk.css
cp theme/wallpaper.svg config/includes.chroot/usr/share/backgrounds/dnyaos/wallpaper.svg
cp theme/xfce4-desktop.xml config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
cp theme/xsettings.xml config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cp launchers/*.desktop config/includes.chroot/usr/share/applications/
cp launchers/*.desktop config/includes.chroot/etc/skel/Desktop/
chmod 0755 config/includes.chroot/etc/skel/Desktop/*.desktop

lb build
test -s live-image-amd64.hybrid.iso
mv -f live-image-amd64.hybrid.iso out/DnyaOS-live-amd64.iso
sha256sum out/DnyaOS-live-amd64.iso > out/DnyaOS-live-amd64.iso.sha256
echo "Build complete: out/DnyaOS-live-amd64.iso"
