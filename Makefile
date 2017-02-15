# set ARCH on the command line to x86 for 32bit builds, the default is x64
ARCH?=x64

MINGW_PREFIX:=mingw-w64-x86_64
MINGW_ROOT:=mingw64

ifeq ($(ARCH), x86)
	MINGW_PREFIX:=mingw-w64-i686
	MINGW_ROOT:=mingw32
endif

BINARIES_ROOT:=SourceDir
WIX_ROOT?=/c/Program\ Files\ \(x86\)/WiX\ Toolset\ v3.10/bin
WIX_ARCH:=$(ARCH)

# debug variables
DISABLE_PYTHON?=
DISABLE_GTK?=
DISABLE_CLONE?=

.PHONY: all clean .binaries .binaries_init .binaries_core .binaries_gtk .binaries_python .binaries_source .binaries_trim .installer

all: .installer

.installer: replication-monitor.msi

replication-monitor.msi: binaries.wixobj replication-monitor.wixobj
	$(WIX_ROOT)/light.exe -ext WixUtilExtension -ext WixUIExtension $^ -o $@

replication-monitor.wixobj: replication-monitor.wxs
	$(WIX_ROOT)/candle.exe -arch $(WIX_ARCH) $<

binaries.wixobj: binaries.wxs
	$(WIX_ROOT)/candle.exe -arch $(WIX_ARCH) $<
	
binaries.wxs: .binaries .binaries_trim
	$(WIX_ROOT)/heat.exe dir "$(BINARIES_ROOT)" -gg -dr INSTALLDIR -cg binaries -sfrag -sreg -srd -suid -template fragment -out $@

.binaries: .binaries_python .binaries_source
	if [ "$(DISABLE_PYTHON)" == "" -a "$(DISABLE_CLONE)" == "" ]; then \
		"$(BINARIES_ROOT)/$(MINGW_ROOT)/bin/python3" "$(BINARIES_ROOT)/$(MINGW_ROOT)/bin/pip3-script.py" install -r "$(BINARIES_ROOT)/usr/local/replication-monitor/requirements.txt"; \
	fi

.binaries_python: .binaries_gtk
	if [ "$(DISABLE_PYTHON)" == "" -a ! -f "$(BINARIES_ROOT)/$(MINGW_ROOT)/bin/python3" ]; then \
		pacman -S $(MINGW_PREFIX)-python3 $(MINGW_PREFIX)-python3-pip --noconfirm --root "$(BINARIES_ROOT)" && \
		if [ "$(DISABLE_GTK)" == "" ]; then pacman -S $(MINGW_PREFIX)-python3-gobject --noconfirm --root "$(BINARIES_ROOT)"; fi; \
	fi
	
.binaries_source:
	if [ "$(DISABLE_CLONE)" == "" -a ! -d "$(BINARIES_ROOT)/usr/local/replication-monitor" ]; then \
		mkdir -p "$(BINARIES_ROOT)/usr/local" && \
		pushd "$(BINARIES_ROOT)/usr/local" && \
		git clone --recursive https://github.com/RipcordSoftware/replication-monitor.git && \
		popd; \
	fi

.binaries_gtk: .binaries_core
	if [ "$(DISABLE_GTK)" == "" -a ! -d "$(BINARIES_ROOT)/$(MINGW_ROOT)/lib/gtk-3.0" ]; then \
		pacman -S $(MINGW_PREFIX)-gtk3 --noconfirm --root "$(BINARIES_ROOT)"; \
	fi

.binaries_core: .binaries_init
	if [ ! -f "$(BINARIES_ROOT)/usr/bin/bash" ]; then \
		pacman -S bash coreutils --noconfirm --root "$(BINARIES_ROOT)"; \
	fi

.binaries_init:
	if [ ! -d "$(BINARIES_ROOT)/var/lib/pacman" ]; then \
		mkdir -p "$(BINARIES_ROOT)/var/lib/pacman" && \
		mkdir -p "$(BINARIES_ROOT)/var/log/" && \
		mkdir -p "$(BINARIES_ROOT)/tmp" && \
		pacman -Sy --root "$(BINARIES_ROOT)"; \
	fi
	
.binaries_trim:
	rm -rf "$(BINARIES_ROOT)"/usr/share/locale; \
	rm -rf "$(BINARIES_ROOT)"/usr/share/doc; \
	rm -rf "$(BINARIES_ROOT)"/usr/share/man; \
	rm -rf "$(BINARIES_ROOT)"/usr/share/info; \
	rm -rf "$(BINARIES_ROOT)"/var/lib/pacman/local; \
	rm -f "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/*.a; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/tdbc*; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/tcl?; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/tcl?.?; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/tk?.?; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/sql*; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/python3.5/test; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/gtk-doc; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/man; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/doc; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/locale; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/terminfo; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/tcl?.?; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/tk?.?; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/tdbc*; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/sql*; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/pkgconfig; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/bin/gtk3-demo*.exe; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/include/*

clean:
	rm -rf $(BINARIES_ROOT); \
	rm -f binaries.wxs; \
	rm -f *.wixobj; \
	rm -f *.wixpdb; \
	rm -f *.msi
	
