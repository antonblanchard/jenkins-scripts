#!/bin/bash -e

ROOT=$(dirname $0)

if [ -n "$BIG_ENDIAN" ]; then
	target=powerpc64-linux
	linux_target=pseries_defconfig
else
	target=powerpc64le-linux
	linux_target=pseries_le_defconfig
fi

PARALLEL=-j$(nproc)

function finish {
	rm -rf "$WORKSPACE/llvm.build"
	rm -rf "$WORKSPACE/install"
	rm -rf "$WORKSPACE/linux.build"
}
trap finish EXIT

mkdir -p "$WORKSPACE/llvm.build"
cd "$WORKSPACE/llvm.build"
../llvm/configure --prefix="$WORKSPACE/install" --enable-optimized --target=$target
make $PARALLEL
make install

mkdir -p "$WORKSPACE/linux.build"
cd "$WORKSPACE/linux"
patch -p1 < "$ROOT/llvmlinux-ppc64.patch"
export KBUILD_OUTPUT="$WORKSPACE/linux.build"
make $linux_target
make $PARALLEL CC="$WORKSPACE/install/bin/${target}-clang" vmlinux
make $PARALLEL CC="$WORKSPACE/install/bin/${target}-clang" zImage
make $PARALLEL CC="$WORKSPACE/install/bin/${target}-clang" modules

if [ -n "$qemu_testcase" ]; then
	"$WORKSPACE/$qemu_testcase" "$WORKSPACE/linux.build/vmlinux"
fi
