#!/bin/bash -e

if [ -n "$BIG_ENDIAN" ]; then
	target=powerpc64-linux
	target_32=powerpc-linux
	linux_target=pseries_defconfig
else
	target=powerpc64le-linux
	target_32=powerpcle-linux
	linux_target=pseries_le_defconfig
fi

PARALLEL=-j$(nproc)

function finish {
	rm -rf "$WORKSPACE/binutils.build"
	rm -rf "$WORKSPACE/gcc.build"
	rm -rf "$WORKSPACE/install"
	rm -rf "$WORKSPACE/linux.build"
	rm -rf "$WORKSPACE/linux.build.gold"
}
trap finish EXIT

mkdir -p "$WORKSPACE/binutils.build"
cd "$WORKSPACE/binutils.build"
../binutils-gdb/configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --enable-gold --prefix="$WORKSPACE/install" --target=$target
make $PARALLEL
make install

mkdir -p "$WORKSPACE/gcc.build"
cd "$WORKSPACE/gcc.build"
../gcc/configure --prefix="$WORKSPACE/install" --disable-multilib --disable-bootstrap --enable-languages=c --target=$target --enable-targets=$target_32
# We don't need libgcc for building the kernel, so keep it simple
make all-gcc $PARALLEL
make install-gcc

mkdir -p "$WORKSPACE/linux.build"
cd "$WORKSPACE/linux"
rm -f include/linux/compiler-gcc6.h
patch -p1 < "$WORKSPACE/jenkins-scripts/gcclinux-ppc64.patch"
export KBUILD_OUTPUT="$WORKSPACE/linux.build"
export CROSS_COMPILE="$WORKSPACE/install/bin/${target}-"
make $linux_target
make $PARALLEL vmlinux
make $PARALLEL zImage
make $PARALLEL modules

if [ -n "$qemu_testcase" ]; then
	"$WORKSPACE/$qemu_testcase" "$WORKSPACE/linux.build/vmlinux"
fi

if [ -n "$TEST_GOLD" ]; then
	mkdir -p "$WORKSPACE/linux.build.gold"
	export KBUILD_OUTPUT="$WORKSPACE/linux.build.gold"
	# Can't override this via an environment variable
	LD="$WORKSPACE/install/bin/${target}-ld.gold"
	make LD="$LD" $linux_target
	make LD="$LD" $PARALLEL vmlinux
	make LD="$LD" $PARALLEL zImage
	make LD="$LD" $PARALLEL modules

	if [ -n "$qemu_testcase" ]; then
		"$WORKSPACE/$qemu_testcase" "$WORKSPACE/linux.build.gold/vmlinux"
	fi
fi
