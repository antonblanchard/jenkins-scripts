#!/bin/bash -e

if [ -n "$BIG_ENDIAN" ]; then
	target=powerpc64-linux
	linux_target=pseries_defconfig
else
	target=powerpc64le-linux
	linux_target=pseries_le_defconfig
fi

# Optional git trees to refer to save bandwidth
BINUTILS_GIT=--reference=$HOME/binutils-gdb
GCC_GIT=--reference=$HOME/anton/gcc
LINUX_GIT=--reference=$HOME/anton/linux.junk

PARALLEL=-j$(($(nproc) * 2))

ROOT=$(dirname $0)

if [ -z "$JENKINS_HOME" ]; then
	WORKSPACE=$(mktemp -d)

	function finish {
		rm -rf "$WORKSPACE"
	}
	trap finish EXIT

	cd "$WORKSPACE"

	git clone $BINUTILS_GIT git://sourceware.org/git/binutils-gdb.git
	git clone $GCC_GIT git://gcc.gnu.org/git/gcc.git
	git clone $LINUX_GIT git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
else
	function finish {
		rm -rf "$WORKSPACE/binutils.build"
		rm -rf "$WORKSPACE/gcc.build"
		rm -rf "$WORKSPACE/install"
		rm -rf "$WORKSPACE/linux.build"
	}
	trap finish EXIT
fi

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
	$ROOT/$qemu_testcase vmlinux
fi
