# set ARCH on the command line to x86 for 32bit builds, the default is x64
ARCH?=x64
BUILD_ROOT:=build/$(ARCH)

# debug variables - set in build.mk but available here too
#DISABLE_PYTHON?=no
#DISABLE_GTK?=no
#DISABLE_CLONE?=no

.PHONY: all clean .init

all: .init
	cd "$(BUILD_ROOT)" && \
	$(MAKE)

clean:
	if [ -d "$(BUILD_ROOT)" ]; then \
		cd "$(BUILD_ROOT)"; \
		$(MAKE) $@; \
	fi

.init:
	mkdir -p "$(BUILD_ROOT)" && \
	cp -f build.mk "$(BUILD_ROOT)/Makefile" && \
	cp -f replication-monitor.wxs "$(BUILD_ROOT)" && \
	cp -f defines.wxi "$(BUILD_ROOT)" && \
	cp -f LICENSE "$(BUILD_ROOT)" && \
	cp -rf images "$(BUILD_ROOT)"
