#!/bin/bash -e

OPTS="--target-list=ppc64-softmmu --enable-fdt"
BINARY="ppc64-softmmu/qemu-system-ppc64"

PARALLEL=-j$(($(nproc) * 2))

ROOT=$(dirname $0)

function finish {
	rm -rf "$WORKSPACE/qemu.build"
}
trap finish EXIT

mkdir -p "$WORKSPACE/qemu.build"

cd "$WORKSPACE/qemu.build"

$WORKSPACE/qemu/configure $OPTS
make $PARALLEL

cd $WORKSPACE
$WORKSPACE/jenkins-scripts/qemu_ubuntu_qemu_test.py $WORKSPACE/qemu.build/$BINARY
