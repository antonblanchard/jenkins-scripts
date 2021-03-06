#!/bin/bash -e

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
cmake -DCMAKE_INSTALL_PREFIX="$WORKSPACE/install" -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=PowerPC ../llvm
make $PARALLEL
make install

mkdir -p "$WORKSPACE/linux.build"
cd "$WORKSPACE/linux"
#for i in $WORKSPACE/jenkins-scripts/llvm-patches/*
#do
	#patch -p1 < $i
#done
export KBUILD_OUTPUT="$WORKSPACE/linux.build"
make $linux_target
echo CONFIG_PPC_DISABLE_WERROR=y >> "$WORKSPACE/linux.build/.config"
echo CONFIG_ISO9660_FS=y >> "$WORKSPACE/linux.build/.config"
echo CONFIG_FUNCTION_TRACER=n >> "$WORKSPACE/linux.build/.config"
make $PARALLEL CC="$WORKSPACE/install/bin/clang" vmlinux
#make $PARALLEL CC="$WORKSPACE/install/bin/clang" zImage
#make $PARALLEL CC="$WORKSPACE/install/bin/clang" modules

if [ -n "$qemu_testcase" ]; then
	"$WORKSPACE/$qemu_testcase" "$WORKSPACE/linux.build/vmlinux"
fi
