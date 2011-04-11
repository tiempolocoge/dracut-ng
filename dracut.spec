# Variables must be defined
%define with_nbd                1

# nbd in Fedora only
%if 0%{?rhel} >= 6
%define with_nbd 0
%endif

%if %{defined gittag}
%define rdist .git%{gittag}%{?dist}
%define dashgittag -%{gittag}
%else
%define rdist %{?dist}
%endif

Name: dracut
Version: 010
%define release_prefix 0%{?rdist}
Release: %{release_prefix}

Summary: Initramfs generator using udev
%if 0%{?fedora}
Group: System Environment/Base          
%endif
%if 0%{?suse_version}
Group: System/Base
%endif
License: GPLv2+ 
URL: https://dracut.wiki.kernel.org/
# Source can be generated by 
# http://git.kernel.org/?p=boot/dracut/dracut.git;a=snapshot;h=%{?dashgittag};sf=tgz
Source0: http://www.kernel.org/pub/linux/utils/boot/dracut/dracut-%{version}%{?dashgittag}.tar.bz2

BuildArch: noarch

%if 0%{?fedora}
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
%endif
%if 0%{?suse_version}
BuildRoot: %{_tmppath}/%{name}-%{version}-build
%endif

%if 0%{?fedora}
BuildRequires: docbook-style-xsl docbook-dtds libxslt
%endif

%if 0%{?suse_version}
BuildRequires: docbook-xsl-stylesheets libxslt
%endif

%if 0%{?fedora} > 12 || 0%{?rhel} >= 6
# no "provides", because dracut does not offer
# all functionality of the obsoleted packages
Obsoletes: mkinitrd <= 6.0.93
Obsoletes: mkinitrd-devel <= 6.0.93
Obsoletes: nash <= 6.0.93
Obsoletes: libbdevid-python <= 6.0.93
%endif

%if 0%{?suse_version} > 9999
Obsoletes: mkinitrd < 2.6.1
Provides: mkinitrd = 2.6.1
%endif

Obsoletes: dracut-kernel < 005
Provides:  dracut-kernel = %{version}-%{release}

Requires: bash
Requires: bzip2
Requires: coreutils
Requires: cpio
Requires: dash
Requires: filesystem >= 2.1.0
Requires: findutils
Requires: grep
Requires: gzip
Requires: kbd
Requires: mktemp >= 1.5-5
Requires: module-init-tools >= 3.7-9
Requires: sed
Requires: tar
Requires: udev

%if 0%{?fedora}
Requires: util-linux >= 2.16
Requires: initscripts >= 8.63-1
Requires: plymouth >= 0.8.0-0.2009.29.09.19.1
%endif

%if 0%{?suse_version}
Requires: util-linux >= 2.16
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
Requires: rpcbind 
%if %{with_nbd}
Requires: nbd
%endif
Requires: iproute
Requires: bridge-utils

%if 0%{?fedora}
Requires: iscsi-initiator-utils
Requires: nfs-utils 
Requires: dhclient
%endif

%if 0%{?suse_version}
Requires: dhcp-client
Requires: nfs-client
Requires: vlan
%endif
Obsoletes: dracut-generic < 008
Provides:  dracut-generic = %{version}-%{release}

%description network
This package requires everything which is needed to build a generic
all purpose initramfs with network support with dracut.

%if 0%{?fedora}
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
%setup -q -n %{name}-%{version}%{?dashgittag}

%build
make 

%install
%if 0%{?fedora}
rm -rf $RPM_BUILD_ROOT
%endif
make install DESTDIR=$RPM_BUILD_ROOT sbindir=/sbin \
     sysconfdir=/etc mandir=%{_mandir} 

echo %{name}-%{version}-%{release} > $RPM_BUILD_ROOT/%{_datadir}/dracut/modules.d/10rpmversion/dracut-version

%if 0%{?fedora} == 0
rm -fr $RPM_BUILD_ROOT/%{_datadir}/dracut/modules.d/01fips
%endif

# remove gentoo specific modules
rm -fr $RPM_BUILD_ROOT/%{_datadir}/dracut/modules.d/50gensplash

mkdir -p $RPM_BUILD_ROOT/boot/dracut
mkdir -p $RPM_BUILD_ROOT/var/lib/dracut/overlay
mkdir -p $RPM_BUILD_ROOT%{_localstatedir}/log
touch $RPM_BUILD_ROOT%{_localstatedir}/log/dracut.log
mkdir -p $RPM_BUILD_ROOT%{_sharedstatedir}/initramfs

%if 0%{?fedora}
install -m 0644 dracut.conf.d/fedora.conf.example $RPM_BUILD_ROOT/etc/dracut.conf.d/01-dist.conf
install -m 0644 dracut.conf.d/fips.conf.example $RPM_BUILD_ROOT/etc/dracut.conf.d/40-fips.conf
%endif

%if 0%{?suse_version}
install -m 0644 dracut.conf.d/suse.conf.example   $RPM_BUILD_ROOT/etc/dracut.conf.d/01-dist.conf
%endif

%if 0%{?fedora} <= 12 && 0%{?rhel} < 6 && 0%{?suse_version} <= 9999
rm $RPM_BUILD_ROOT/sbin/mkinitrd
rm $RPM_BUILD_ROOT/sbin/lsinitrd
%endif

mkdir -p $RPM_BUILD_ROOT/etc/logrotate.d/dracut
install -m 0644 dracut.logrotate $RPM_BUILD_ROOT/etc/logrotate.d/dracut

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,0755)
%doc README HACKING TODO COPYING AUTHORS NEWS dracut.html dracut.png dracut.svg
/sbin/dracut
%if 0%{?fedora} > 12 || 0%{?rhel} >= 6 || 0%{?suse_version} > 9999
/sbin/mkinitrd
/sbin/lsinitrd
%endif
%dir %{_datadir}/dracut
%dir %{_datadir}/dracut/modules.d
%{_datadir}/dracut/dracut-functions
%{_datadir}/dracut/dracut-logger
%config(noreplace) /etc/dracut.conf
%if 0%{?fedora} || 0%{?suse_version}
%config(noreplace) /etc/dracut.conf.d/01-dist.conf
%endif
%dir /etc/dracut.conf.d
%config(noreplace) /etc/logrotate.d/dracut
%{_mandir}/man8/dracut.8*
%{_mandir}/man7/dracut.kernel.7*
%{_mandir}/man5/dracut.conf.5*
%{_datadir}/dracut/modules.d/00bootchart
%{_datadir}/dracut/modules.d/00dash
%{_datadir}/dracut/modules.d/05busybox
%{_datadir}/dracut/modules.d/10i18n
%{_datadir}/dracut/modules.d/10rpmversion
%{_datadir}/dracut/modules.d/50plymouth
%{_datadir}/dracut/modules.d/60xen
%{_datadir}/dracut/modules.d/90btrfs
%{_datadir}/dracut/modules.d/90crypt
%{_datadir}/dracut/modules.d/90dm
%{_datadir}/dracut/modules.d/90dmraid
%{_datadir}/dracut/modules.d/90dmsquash-live
%{_datadir}/dracut/modules.d/90kernel-modules
%{_datadir}/dracut/modules.d/90lvm
%{_datadir}/dracut/modules.d/90mdraid
%{_datadir}/dracut/modules.d/90multipath
%{_datadir}/dracut/modules.d/95debug
%{_datadir}/dracut/modules.d/95resume
%{_datadir}/dracut/modules.d/95rootfs-block
%{_datadir}/dracut/modules.d/95dasd
%{_datadir}/dracut/modules.d/95dasd_mod
%{_datadir}/dracut/modules.d/95fstab-sys
%{_datadir}/dracut/modules.d/95zfcp
%{_datadir}/dracut/modules.d/95terminfo
%{_datadir}/dracut/modules.d/95udev-rules
%{_datadir}/dracut/modules.d/97biosdevname
%{_datadir}/dracut/modules.d/98selinux
%{_datadir}/dracut/modules.d/98syslog
%{_datadir}/dracut/modules.d/99base
# logfile needs no logrotate, because it gets overwritten
# for every dracut run
%attr(0644,root,root) %ghost %config(missingok,noreplace) %{_localstatedir}/log/dracut.log
%dir %{_sharedstatedir}/initramfs

%files network
%defattr(-,root,root,0755)
%{_datadir}/dracut/modules.d/40network
%{_datadir}/dracut/modules.d/95fcoe
%{_datadir}/dracut/modules.d/95iscsi
%{_datadir}/dracut/modules.d/95nbd
%{_datadir}/dracut/modules.d/95nfs
%{_datadir}/dracut/modules.d/45ifcfg
%{_datadir}/dracut/modules.d/95znet

%if 0%{?fedora}
%files fips
%defattr(-,root,root,0755)
%{_datadir}/dracut/modules.d/01fips
%config(noreplace) /etc/dracut.conf.d/40-fips.conf
%endif

%files caps
%defattr(-,root,root,0755)
%{_datadir}/dracut/modules.d/02caps

%files tools 
%defattr(-,root,root,0755)
%{_mandir}/man8/dracut-gencmdline.8*
%{_mandir}/man8/dracut-catimages.8*
/sbin/dracut-gencmdline
/sbin/dracut-catimages
%dir /boot/dracut
%dir /var/lib/dracut
%dir /var/lib/dracut/overlay

%changelog
