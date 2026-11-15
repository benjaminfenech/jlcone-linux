# Repackages JLCPCB's official .deb (Electron 35 app, bundled runtime) for RHEL/Fedora.
# sha512 from the publisher's update feed (latest-linux.yml); update.sh rewrites it
%global deb_sha512 2e0d09899970f2f580f39bf28fc23217622ec190818cfc9373c8cd97d9d42b396d1f7c8bdc2750ddeeb027352b6faca57f4bf8a5171f0aa3c1bc51ffb642b03d

# Prebuilt binaries: no debuginfo, stripping or build-id links
%global debug_package %{nil}
%global __strip /bin/true
%global _build_id_links none
# Electron's bundled libraries are private to /opt/JLCONE: don't provide or require them
%global __provides_exclude_from ^/opt/JLCONE/.*$
%global __requires_exclude ^(libffmpeg|libEGL|libGLESv2|libvk_swiftshader|libvulkan)\\.so.*$

Name:           jlcone-bin
Version:        1.0.73
Release:        1%{?dist}
Summary:        JLCONE - JLCPCB Desktop Client
License:        Proprietary
URL:            https://www.jlcpcb.com
Source0:        https://rs.jlcpcb.com/static/APP/app_version/jlcone-%{version}.deb
Source1:        jlcone.sh
Source2:        update.sh
Source3:        jlcone.spec
ExclusiveArch:  x86_64
BuildRequires:  binutils tar xz
# Not picked up by automatic dependencies: used by the app and the scripts
Requires:       xdg-utils curl procps-ng
Recommends:     zenity rpm-build libappindicator-gtk3

%description
JLCPCB's desktop client, repackaged from the official .deb. The app's own
dpkg-based updater is turned off; the jlcone launcher offers updates instead.

%prep
echo "%{deb_sha512}  %{SOURCE0}" | sha512sum -c -

%install
mkdir -p %{buildroot}
ar p %{SOURCE0} data.tar.xz | tar -xJ -C %{buildroot}

# Debian-only bits: AppArmor profile is unused here, changelog is dpkg metadata
rm -rf %{buildroot}/usr/share/doc %{buildroot}/opt/JLCONE/resources/apparmor-profile

# RHEL 8+ and Fedora have unprivileged user namespaces, so no SUID sandbox needed
chmod 755 %{buildroot}/opt/JLCONE/chrome-sandbox

install -Dm755 %{SOURCE1} %{buildroot}%{_bindir}/jlcone
sed -i 's|^Exec=/opt/JLCONE/jlcone|Exec=jlcone|' %{buildroot}%{_datadir}/applications/jlcone.desktop

# Ship the build files so jlcone-update can rebuild newer versions
install -Dm644 %{SOURCE1} %{SOURCE3} -t %{buildroot}%{_datadir}/%{name}
install -Dm755 %{SOURCE2} -t %{buildroot}%{_datadir}/%{name}
ln -s ../share/%{name}/update.sh %{buildroot}%{_bindir}/jlcone-update

%files
/opt/JLCONE
%{_bindir}/jlcone
%{_bindir}/jlcone-update
%{_datadir}/applications/jlcone.desktop
%{_datadir}/icons/hicolor/256x256/apps/jlcone.png
%{_datadir}/%{name}
