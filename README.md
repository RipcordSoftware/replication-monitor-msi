# replication-monitor-msi
A Windows installer for Replication Monitor built with MSYS2 and WiX

## Requirements
* An installation of MSYS2 on Windows (http://www.msys2.org/)
* Installed on MSYS2: git, bash, coreutils (for sed, cp, etc.) and make
* An installation of WiX Toolset 3.10 (http://wixtoolset.org/)

## Usage
* Under MSYS2 clone this respository
* Run `make VERSION=X.Y.Z` to build x64 as version X.Y.Z
* Run `make VERSION=X.Y.Z ARCH=x86` to build for 32 bit Windows
* Debug `make` options: `DISABLE_PYTHON`, `DISABLE_GTK`, `DISABLE_CLONE`

The MSI installer files appear in `build/x64` or `build/x86`.
