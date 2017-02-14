BINARIES_ROOT:=SourceDir
MINGW_PREFIX?=mingw-w64-x86_64
WIX_ROOT?=/c/Program\ Files\ \(x86\)/WiX\ Toolset\ v3.10/bin
WIX_ARCH:=x64

.PHONY: all clean .binaries .binaries_init .binaries_core .binaries_gtk .binaries_python .binaries_source .installer .installer_binaries

all: .installer

.installer: .binaries .installer_binaries

.installer_binaries: binaries.wixobj

binaries.wixobj: binaries.wxs
	$(WIX_ROOT)/candle.exe -arch $(WIX_ARCH) $<
	
binaries.wxs:
	$(WIX_ROOT)/heat.exe dir "$(BINARIES_ROOT)" -gg -dr INSTALLDIR -cg binaries -sfrag -sreg -srd -suid -template fragment -out $@

.binaries: .binaries_python .binaries_source
	"$(BINARIES_ROOT)/mingw64/bin/python3" "$(BINARIES_ROOT)/mingw64/bin/pip3-script.py" install -r "$(BINARIES_ROOT)/usr/local/replication-monitor/requirements.txt"

.binaries_python: .binaries_gtk
	if [ ! -f "$(BINARIES_ROOT)/mingw64/bin/python3" ]; then \
		pacman -S $(MINGW_PREFIX)-python3 $(MINGW_PREFIX)-python3-pip $(MINGW_PREFIX)-python3-gobject --noconfirm --root "$(BINARIES_ROOT)"; \
	fi
	
.binaries_source:
	if [ ! -d "$(BINARIES_ROOT)/usr/local/replication-monitor" ]; then \
		mkdir -p "$(BINARIES_ROOT)/usr/local" && \
		pushd "$(BINARIES_ROOT)/usr/local" && \
		git clone --recursive https://github.com/RipcordSoftware/replication-monitor.git && \
		popd; \
	fi

.binaries_gtk: .binaries_core
	if [ ! -d "$(BINARIES_ROOT)/mingw64/lib/gtk-3.0" ]; then \
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

clean:
	rm -rf $(BINARIES_ROOT)
	rm -f *.wixobj
	rm -f *.wixpdb
	rm -f *.msi
	