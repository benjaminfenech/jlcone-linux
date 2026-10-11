# Repackages the upstream .deb (Electron 35 app, bundled runtime) for Arch.
pkgname=jlcone-bin
pkgver=1.0.72
pkgrel=3
pkgdesc="JLCONE - JLCPCB Desktop Client"
arch=('x86_64')
url="https://www.jlcpcb.com"
license=('LicenseRef-proprietary')
depends=('gtk3' 'libnotify' 'nss' 'libxss' 'libxtst' 'xdg-utils' 'at-spi2-core'
         'util-linux-libs' 'libsecret' 'libdrm' 'mesa' 'alsa-lib')
optdepends=('libappindicator-gtk3: tray icon support'
            'base-devel: jlcone-update')
provides=('jlcone')
options=('!strip' '!debug')
source=("https://rs.jlcpcb.com/static/APP/app_version/jlcone-${pkgver}.deb"
        "jlcone.sh")
noextract=("jlcone-${pkgver}.deb")
# sha512 from the publisher's update feed (latest-linux.yml); update.sh rewrites it
sha512sums=('3b7b8ce774b8ea0b0bba6705d802171cf297a24adfa0ad6679baaa8d69e06382aea25626845e784581f7b68bac24ea3801d79a283127a064eae55bad7c31a3de'
            'SKIP')

package() {
  bsdtar -xOf "jlcone-${pkgver}.deb" data.tar.xz | bsdtar -xf - -C "$pkgdir"

  # Debian-only bits: AppArmor profile is unused on Arch, changelog is dpkg metadata
  rm -rf "$pkgdir/usr/share/doc" "$pkgdir/opt/JLCONE/resources/apparmor-profile"

  # Arch kernels have unprivileged user namespaces, so no SUID sandbox needed
  chmod 755 "$pkgdir/opt/JLCONE/chrome-sandbox"

  install -Dm755 jlcone.sh "$pkgdir/usr/bin/jlcone"

  # Ship the build files so jlcone-update can rebuild newer versions
  install -Dm644 "$startdir/PKGBUILD" "$startdir/jlcone.sh" -t "$pkgdir/usr/share/$pkgname"
  install -Dm755 "$startdir/update.sh" -t "$pkgdir/usr/share/$pkgname"
  ln -s "/usr/share/$pkgname/update.sh" "$pkgdir/usr/bin/jlcone-update"
  sed -i 's|^Exec=/opt/JLCONE/jlcone|Exec=jlcone|' "$pkgdir/usr/share/applications/jlcone.desktop"
}
