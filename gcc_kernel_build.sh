#!/bin/bash -e

if [ -n "$BIG_ENDIAN" ]; then
	target=powerpc64-linux
	linux_target=pseries_defconfig
else
	target=powerpc64le-linux
	linux_target=pseries_le_defconfig
fi

PARALLEL=-j$(($(nproc) * 2))

function finish {
	rm -rf "$WORKSPACE/binutils.build"
	rm -rf "$WORKSPACE/gcc.build"
	rm -rf "$WORKSPACE/install"
	rm -rf "$WORKSPACE/linux.build"
}
trap finish EXIT

mkdir -p "$WORKSPACE/binutils.build"
cd "$WORKSPACE/binutils.build"
../binutils-gdb/configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --prefix="$WORKSPACE/install" --target=$target
make $PARALLEL
make install

mkdir -p "$WORKSPACE/gcc.build"
cd "$WORKSPACE/gcc.build"
../gcc/configure --prefix="$WORKSPACE/install" --disable-multilib --disable-bootstrap --enable-languages=c --target=$target
# We don't need libgcc for building the kernel, so keep it simple
make all-gcc $PARALLEL
make install-gcc

mkdir -p "$WORKSPACE/linux.build"
cd "$WORKSPACE/linux"
export KBUILD_OUTPUT="$WORKSPACE/linux.build"
export CROSS_COMPILE="$WORKSPACE/install/bin/${target}-"
make $linux_target
make $PARALLEL vmlinux
make $PARALLEL zImage
make $PARALLEL modules

if [ -n "$qemu_testcase" ]; then
	$WORKSPACE/$qemu_testcase $WORKSPACE/linux.build/vmlinux
fi
