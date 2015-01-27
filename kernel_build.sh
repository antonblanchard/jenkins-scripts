#!/bin/bash -e

if [ -n "$BIG_ENDIAN" ]; then
	linux_target=pseries_defconfig
else
	linux_target=pseries_le_defconfig
fi

PARALLEL=-j$(($(nproc) * 2))

function finish {
	rm -rf "$WORKSPACE/linux.build"
}
trap finish EXIT

mkdir -p "$WORKSPACE/linux.build"
cd "$WORKSPACE/linux"
export KBUILD_OUTPUT="$WORKSPACE/linux.build"
make $linux_target
make $PARALLEL vmlinux
make $PARALLEL zImage
make $PARALLEL modules

if [ -n "$qemu_testcase" ]; then
	"$WORKSPACE/$qemu_testcase" "$WORKSPACE/linux.build/vmlinux"
fi
