#!/bin/bash -e

export KBUILD_OUTPUT="$WORKSPACE/linux.build"
export PERF_OUTPUT="$WORKSPACE/perf.build"
rm -rf "$KBUILD_OUTPUT" "$PERF_OUTPUT" "$WORKSPACE/install"

cd "$WORKSPACE/linux"

make pseries_le_defconfig
echo CONFIG_ISO9660_FS=y >> "$WORKSPACE/linux.build/.config"
# Build virtio into kernel
cat << EOF >> "$WORKSPACE/linux.build/.config"
CONFIG_VIRTIO_MENU=y
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y
CONFIG_VIRTIO_BLK=y
CONFIG_SCSI_VIRTIO=y
CONFIG_VIRTIO_NET=y
EOF

make -j$(nproc)

make INSTALL_MOD_PATH="$WORKSPACE/install" modules_install
( cd "$WORKSPACE/install" ; find . | cpio -oVH newc | gzip -9 > ../modules.cpio.gz )

mkdir "$PERF_OUTPUT"
cd tools/perf
make O="$PERF_OUTPUT"

# Reduce on disk space
cp -f "$KBUILD_OUTPUT/vmlinux" $WORKSPACE/vmlinux
cp -f "$PERF_OUTPUT/perf" "$WORKSPACE/perf"
rm -rf "$KBUILD_OUTPUT" "$PERF_OUTPUT" "$WORKSPACE/install"
