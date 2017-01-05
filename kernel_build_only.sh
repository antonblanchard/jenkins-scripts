#!/bin/bash -e

export KBUILD_OUTPUT="$WORKSPACE/linux.build"
rm -rf $KBUILD_OUTPUT

cd "$WORKSPACE/linux"

make pseries_le_defconfig
echo CONFIG_ISO9660_FS=y >> "$WORKSPACE/linux.build/.config"
# Build virtio into kernel  
cat << EOF >> "$WORKSPACE/linux.build/.config"
CONFIG_VIRTIO=y
CONFIG_VIRTIO_PCI=y 
CONFIG_VIRTIO_BLK=y 
CONFIG_SCSI_VIRTIO=y
CONFIG_VIRTIO_NET=y 
EOF

make -j32

make INSTALL_MOD_PATH="$WORKSPACE/install" modules_install
( cd "$WORKSPACE/install" ; find . | cpio -oVH newc | gzip -9 > ../modules.cpio.gz )

cd tools/perf
make

# Reduce on disk space
cp -f $WORKSPACE/linux.build/vmlinux $WORKSPACE/vmlinux
rm -rf "$KBUILD_OUTPUT" "$WORKSPACE/install"
