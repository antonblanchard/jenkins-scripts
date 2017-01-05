#!/bin/bash -e

if [ -n "$BIG_ENDIAN" ]; then
	linux_target=pseries_defconfig
else
	linux_target=pseries_le_defconfig
fi

PARALLEL=-j$(nproc)

function finish {
	rm -rf "$WORKSPACE/linux.build"
}
trap finish EXIT

mkdir -p "$WORKSPACE/linux.build"
cd "$WORKSPACE/linux"
export KBUILD_OUTPUT="$WORKSPACE/linux.build"
make $linux_target
echo CONFIG_ISO9660_FS=y >> "$WORKSPACE/linux.build/.config"

# Build virtio into kernel
cat << EOF >> "$WORKSPACE/linux.build/.config"
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_BLK=y
CONFIG_SCSI_VIRTIO=y
CONFIG_VIRTIO_NET=y
EOF

make $PARALLEL vmlinux
make $PARALLEL zImage
make $PARALLEL modules

if [ -n "$qemu_testcase" ]; then
	"$WORKSPACE/$qemu_testcase" "$WORKSPACE/linux.build/vmlinux"
fi
