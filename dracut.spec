%define dracutlibdir %{_prefix}/lib/dracut

# Variables must be defined
%define with_nbd                1

# nbd in Fedora only
%if 0%{?rhel} >= 6
%define with_nbd 0
%endif

Name: dracut
Version: xxx
Release: xxx

Summary: Initramfs generator using udev
%if 0%{?fedora} || 0%{?rhel}
Group: System Environment/Base
%endif
%if 0%{?suse_version}
Group: System/Base
%endif

# The entire source code is GPLv2+
# except install/* which is LGPLv2.1+
License: GPLv2+ and LGPLv2.1+

URL: https://dracut.wiki.kernel.org/

# Source can be generated by
# http://git.kernel.org/?p=boot/dracut/dracut.git;a=snapshot;h=%{version};sf=tgz
Source0: http://www.kernel.org/pub/linux/utils/boot/dracut/dracut-%{version}.tar.bz2

BuildRequires: dash bash git

%if 0%{?fedora} || 0%{?rhel}
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
%endif
%if 0%{?suse_version}
BuildRoot: %{_tmppath}/%{name}-%{version}-build
%endif

%if 0%{?fedora} || 0%{?rhel}
BuildRequires: docbook-style-xsl docbook-dtds libxslt
%endif

%if 0%{?suse_version}
-BuildRequires: docbook-xsl-stylesheets libxslt
%endif

BuildRequires: asciidoc

%if 0%{?fedora} > 12 || 0%{?rhel}
# no "provides", because dracut does not offer
# all functionality of the obsoleted packages
Obsoletes: mkinitrd <= 6.0.93
Obsoletes: mkinitrd-devel <= 6.0.93
Obsoletes: nash <= 6.0.93
Obsoletes: libbdevid-python <= 6.0.93
%endif

%if 0%{?fedora} > 16 || 0%{?rhel} > 6
BuildRequires: systemd-units
%endif

%if 0%{?suse_version} > 9999
Obsoletes: mkinitrd < 2.6.1
Provides: mkinitrd = 2.6.1
%endif

Obsoletes: dracut-kernel < 005
Provides:  dracut-kernel = %{version}-%{release}

Requires: bash
Requires: coreutils
Requires: cpio
Requires: filesystem >= 2.1.0
Requires: findutils
Requires: grep
Requires: hardlink
Requires: gzip xz
Requires: module-init-tools >= 3.7-9
Requires: sed
Requires: file
Requires: udev > 166
%if 0%{?fedora} || 0%{?rhel} > 6
Requires: util-linux >= 2.21
Requires: systemd >= 44-15
%else
Requires: util-linux-ng >= 2.21
%endif

%if 0%{?fedora} || 0%{?rhel} > 6
Conflicts: initscripts < 8.63-1
Conflicts: plymouth < 0.8.0-0.2009.29.09.19.1
%endif

%description
Dracut contains tools to create a bootable initramfs for 2.6 Linux kernels.
Unlike existing implementations, dracut does hard-code as little as possible
into the initramfs. Dracut contains various modules which are driven by the
event-based udev. Having root on MD, DM, LVM2, LUKS is supported as well as
NFS, iSCSI, NBD, FCoE with the dracut-network package.

%package network
Summary: Dracut modules to build a dracut initramfs with network support
Requires: %{name} = %{version}-%{release}
Obsoletes: dracut-generic < 008
Provides:  dracut-generic = %{version}-%{release}

%description network
This package requires everything which is needed to build a generic
all purpose initramfs with network support with dracut.

%if 0%{?fedora} || 0%{?rhel} >= 6
%package fips
Summary: Dracut modules to build a dracut initramfs with an integrity check
Requires: %{name} = %{version}-%{release}
Requires: hmaccalc
%if 0%{?rhel} > 5
# For Alpha 3, we want nss instead of nss-softokn
Requires: nss
%else
Requires: nss-softokn
%endif
Requires: nss-softokn-freebl

%description fips
This package requires everything which is needed to build an
all purpose initramfs with dracut, which does an integrity check.
%endif

%package fips-aesni
Summary: Dracut modules to build a dracut initramfs with an integrity check with aesni-intel
Requires: %{name}-fips = %{version}-%{release}

%description fips-aesni
This package requires everything which is needed to build an
all purpose initramfs with dracut, which does an integrity check
and adds the aesni-intel kernel module.

%package caps
Summary: Dracut modules to build a dracut initramfs which drops capabilities
Requires: %{name} = %{version}-%{release}
Requires: libcap

%description caps
This package requires everything which is needed to build an
all purpose initramfs with dracut, which drops capabilities.

%package tools
Summary: Dracut tools to build the local initramfs
Requires: %{name} = %{version}-%{release}

%description tools
This package contains tools to assemble the local initrd and host configuration.

%prep
%setup -q -n %{name}-%{version}

%if %{defined PATCH1}
git init
git config user.email "dracut-maint@redhat.com"
git config user.name "Fedora dracut team"
git add .
git commit -a -q -m "%{version} baseline."

# Apply all the patches.
git am -p1 %{patches}
%endif

%build
make all

%install
%if 0%{?fedora} || 0%{?rhel}
rm -rf $RPM_BUILD_ROOT
%endif
make install DESTDIR=$RPM_BUILD_ROOT \
     libdir=%{_prefix}/lib \
     bindir=%{_bindir} \
%if %{defined _unitdir}
     systemdsystemunitdir=%{_unitdir} \
%endif
     sysconfdir=/etc mandir=%{_mandir}

echo "DRACUT_VERSION=%{version}-%{release}" > $RPM_BUILD_ROOT/%{dracutlibdir}/dracut-version.sh

%if 0%{?fedora} == 0 && 0%{?rhel} == 0
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/01fips
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/02fips-aesni
%endif

# remove gentoo specific modules
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/50gensplash

%if %{defined _unitdir}
# with systemd IMA and selinux modules do not make sense
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/96securityfs
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/97masterkey
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/98integrity
rm -fr $RPM_BUILD_ROOT/%{dracutlibdir}/modules.d/98selinux
%endif

mkdir -p $RPM_BUILD_ROOT/boot/dracut
mkdir -p $RPM_BUILD_ROOT/var/lib/dracut/overlay
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/log
touch $RPM_BUILD_ROOT%{_localstatedir}/log/dracut.log
mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/initramfs

%if 0%{?fedora} || 0%{?rhel}
install -m 0644 dracut.conf.d/fedora.conf.example $RPM_BUILD_ROOT/etc/dracut.conf.d/01-dist.conf
install -m 0644 dracut.conf.d/fips.conf.example $RPM_BUILD_ROOT/etc/dracut.conf.d/40-fips.conf
%endif

%if 0%{?suse_version}
install -m 0644 dracut.conf.d/suse.conf.example   $RPM_BUILD_ROOT/etc/dracut.conf.d/01-dist.conf
%endif

%if 0%{?fedora} <= 12 && 0%{?rhel} < 6 && 0%{?suse_version} <= 9999
rm $RPM_BUILD_ROOT%{_bindir}/mkinitrd
rm $RPM_BUILD_ROOT%{_bindir}/lsinitrd
%endif

mkdir -p $RPM_BUILD_ROOT/etc/logrotate.d
install -m 0644 dracut.logrotate $RPM_BUILD_ROOT/etc/logrotate.d/dracut_log

# create compat symlink
mkdir -p $RPM_BUILD_ROOT/sbin
ln -s /usr/bin/dracut $RPM_BUILD_ROOT/sbin/dracut

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,0755)
%doc README HACKING TODO COPYING AUTHORS NEWS dracut.html dracut.png dracut.svg
%{_bindir}/dracut
# compat symlink
/sbin/dracut
%if 0%{?fedora} > 12 || 0%{?rhel} >= 6 || 0%{?suse_version} > 9999
%{_bindir}/mkinitrd
%{_bindir}/lsinitrd
%endif
%dir %{dracutlibdir}
%dir %{dracutlibdir}/modules.d
%{dracutlibdir}/dracut-functions.sh
%{dracutlibdir}/dracut-functions
%{dracutlibdir}/dracut-version.sh
%{dracutlibdir}/dracut-logger.sh
%{dracutlibdir}/dracut-initramfs-restore
%{dracutlibdir}/dracut-install
%config(noreplace) /etc/dracut.conf
%if 0%{?fedora} || 0%{?suse_version} || 0%{?rhel}
%config /etc/dracut.conf.d/01-dist.conf
%endif
%dir /etc/dracut.conf.d
%{_mandir}/man8/dracut.8*
%{_mandir}/man7/dracut.kernel.7*
%{_mandir}/man7/dracut.cmdline.7*
%{_mandir}/man5/dracut.conf.5*
%{dracutlibdir}/modules.d/00bootchart
%{dracutlibdir}/modules.d/00dash
%{dracutlibdir}/modules.d/04watchdog
%{dracutlibdir}/modules.d/05busybox
%{dracutlibdir}/modules.d/10i18n
%{dracutlibdir}/modules.d/30convertfs
%{dracutlibdir}/modules.d/45url-lib
%{dracutlibdir}/modules.d/50plymouth
%{dracutlibdir}/modules.d/80cms
%{dracutlibdir}/modules.d/90btrfs
%{dracutlibdir}/modules.d/90crypt
%{dracutlibdir}/modules.d/90dm
%{dracutlibdir}/modules.d/90dmraid
%{dracutlibdir}/modules.d/90dmsquash-live
%{dracutlibdir}/modules.d/90kernel-modules
%{dracutlibdir}/modules.d/90lvm
%{dracutlibdir}/modules.d/90mdraid
%{dracutlibdir}/modules.d/90multipath
%{dracutlibdir}/modules.d/90qemu
%{dracutlibdir}/modules.d/91crypt-gpg
%{dracutlibdir}/modules.d/95debug
%{dracutlibdir}/modules.d/95resume
%{dracutlibdir}/modules.d/95rootfs-block
%{dracutlibdir}/modules.d/95dasd
%{dracutlibdir}/modules.d/95dasd_mod
%{dracutlibdir}/modules.d/95fstab-sys
%{dracutlibdir}/modules.d/95zfcp
%{dracutlibdir}/modules.d/95terminfo
%{dracutlibdir}/modules.d/95udev-rules
%{dracutlibdir}/modules.d/95virtfs
%if %{undefined _unitdir}
%{dracutlibdir}/modules.d/96securityfs
%{dracutlibdir}/modules.d/97masterkey
%{dracutlibdir}/modules.d/98selinux
%{dracutlibdir}/modules.d/98integrity
%endif
%{dracutlibdir}/modules.d/97biosdevname
%{dracutlibdir}/modules.d/98ecryptfs
%{dracutlibdir}/modules.d/98pollcdrom
%{dracutlibdir}/modules.d/98syslog
%{dracutlibdir}/modules.d/98systemd
%{dracutlibdir}/modules.d/98usrmount
%{dracutlibdir}/modules.d/99base
%{dracutlibdir}/modules.d/99fs-lib
%{dracutlibdir}/modules.d/99img-lib
%{dracutlibdir}/modules.d/99shutdown
%config(noreplace) /etc/logrotate.d/dracut_log
%attr(0644,root,root) %ghost %config(missingok,noreplace) %{_localstatedir}/log/dracut.log
%dir %{_sharedstatedir}/initramfs
%if %{defined _unitdir}
%{_unitdir}/*.service
%{_unitdir}/*.target
%{_unitdir}/*/*.service
%endif

%files network
%defattr(-,root,root,0755)
%{dracutlibdir}/modules.d/40network
%{dracutlibdir}/modules.d/95fcoe
%{dracutlibdir}/modules.d/95iscsi
%{dracutlibdir}/modules.d/90livenet
%{dracutlibdir}/modules.d/90qemu-net
%{dracutlibdir}/modules.d/95nbd
%{dracutlibdir}/modules.d/95nfs
%{dracutlibdir}/modules.d/95ssh-client
%{dracutlibdir}/modules.d/45ifcfg
%{dracutlibdir}/modules.d/95znet

%if 0%{?fedora} || 0%{?rhel}
%files fips
%defattr(-,root,root,0755)
%{dracutlibdir}/modules.d/01fips
%config(noreplace) /etc/dracut.conf.d/40-fips.conf
%endif

%files fips-aesni
%defattr(-,root,root,0755)
%doc COPYING
%{dracutlibdir}/modules.d/02fips-aesni

%files caps
%defattr(-,root,root,0755)
%{dracutlibdir}/modules.d/02caps

%files tools
%defattr(-,root,root,0755)
%{_mandir}/man8/dracut-catimages.8*
%{_bindir}/dracut-catimages
%dir /boot/dracut
%dir /var/lib/dracut
%dir /var/lib/dracut/overlay

%changelog
