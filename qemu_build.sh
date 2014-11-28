#!/bin/bash -e

OPTS="--target-list=ppc64-softmmu --enable-fdt"

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

$WORKSPACE/jenkins-scripts/qemu_ubuntu_qemu_test.py
