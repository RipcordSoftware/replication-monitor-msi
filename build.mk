# set ARCH on the command line to x86 for 32bit builds, the default is x64
ARCH?=x64

# set the version for the MSI version stamp and filename
VERSION?=0.0.0

# debug variables
DISABLE_PYTHON?=no
DISABLE_GTK?=no
DISABLE_CLONE?=no

ifeq ($(ARCH), x86)
	MINGW_PREFIX:=mingw-w64-i686
	MINGW_ROOT:=mingw32
else
	MINGW_PREFIX:=mingw-w64-x86_64
	MINGW_ROOT:=mingw64
endif

BINARIES_ROOT:=SourceDir
WIX_ROOT?=/c/Program\ Files\ \(x86\)/WiX\ Toolset\ v3.10/bin
WIX_ARCH:=$(ARCH)

.PHONY: all clean .binaries .binaries_init .binaries_core .binaries_gtk .binaries_python .binaries_source .binaries_trim .installer

all: .installer

.installer: replication-monitor-$(VERSION)-$(ARCH).msi

replication-monitor-$(VERSION)-$(ARCH).msi: binaries.wixobj replication-monitor.wixobj
	$(WIX_ROOT)/light.exe -ext WixUtilExtension -ext WixUIExtension $^ -o $@

replication-monitor.wixobj: replication-monitor.wxs
	$(WIX_ROOT)/candle.exe -arch $(WIX_ARCH) $<

binaries.wixobj: binaries.wxs
	$(WIX_ROOT)/candle.exe -arch $(WIX_ARCH) $<
	
binaries.wxs: .binaries .binaries_trim tmp/license.rtf
	$(WIX_ROOT)/heat.exe dir "$(BINARIES_ROOT)" -gg -dr INSTALLDIR -cg binaries -sfrag -sreg -srd -suid -template fragment -out $@
	
tmp/license.rtf:
	mkdir -p tmp && \
	echo "{\rtf1\ansi\pard" > $@ && \
	sed 's/^$$/\\par\\par/g' LICENSE >> $@ && \
	echo "\par}" >> $@

.binaries: .binaries_python .binaries_source
ifeq ($(DISABLE_PYTHON)$(DISABLE_CLONE), nono)
	"$(BINARIES_ROOT)/$(MINGW_ROOT)/bin/python3" "$(BINARIES_ROOT)/$(MINGW_ROOT)/bin/pip3-script.py" install -r "$(BINARIES_ROOT)/usr/local/replication-monitor/requirements.txt"
endif

.binaries_python: .binaries_gtk
ifeq ($(DISABLE_PYTHON), no)
	if [ ! -f "$(BINARIES_ROOT)/$(MINGW_ROOT)/bin/python3" ]; then \
		pacman -S $(MINGW_PREFIX)-python3 $(MINGW_PREFIX)-python3-pip --noconfirm --root "$(BINARIES_ROOT)" && \
		if [ "$(DISABLE_GTK)" == "no" ]; then pacman -S $(MINGW_PREFIX)-python3-gobject --noconfirm --root "$(BINARIES_ROOT)"; fi; \
	fi
endif
	
.binaries_source:
ifeq ($(DISABLE_CLONE), no)
	if [ ! -d "$(BINARIES_ROOT)/usr/local/replication-monitor" ]; then \
		mkdir -p "$(BINARIES_ROOT)/usr/local" && \
		pushd "$(BINARIES_ROOT)/usr/local" && \
		git clone --recursive https://github.com/RipcordSoftware/replication-monitor.git && \
		popd; \
	fi
endif

.binaries_gtk: .binaries_core
ifeq ($(DISABLE_GTK), no)
	if [ ! -d "$(BINARIES_ROOT)/$(MINGW_ROOT)/lib/gtk-3.0" ]; then \
		pacman -S $(MINGW_PREFIX)-gtk3 --noconfirm --root "$(BINARIES_ROOT)"; \
	fi
endif

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
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/terminfo; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/pkgconfig; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/python3.5/test; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/python3.5/site-packages/pip/*; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/lib/python3.5/__pycache__/*; \
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
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/share/mime; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/bin/gtk3-demo*.exe; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/include/*; \
	rm -rf "$(BINARIES_ROOT)"/$(MINGW_ROOT)/var/cache/fontconfig/*

clean:
	rm -rf $(BINARIES_ROOT); \
	rm -f binaries.wxs; \
	rm -f *.wixobj; \
	rm -f *.wixpdb; \
	rm -f *.msi
	
