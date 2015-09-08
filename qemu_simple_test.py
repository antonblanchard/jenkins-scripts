#!/usr/bin/python

import pexpect
import sys
import tempfile
import subprocess
import os


# TODO
# user net vs bridged
# large pages
# POWER7 vs POWER8


class qemu_simple_test:
    base_options = '-M pseries -nographic -vga none'

    def __init__(self, qemu='qemu-system-ppc64', memory='4G', cores=1,
                 threads=1, kvm=False, virtio=False, kernel=None, initrd=None,
                 cmdline=None, image=None, image_size='16G', image_cow=True,
                 seed=None):

        self.qemu_cmd = '%s %s -m %s -smp cores=%d,threads=%d' % (
            qemu, self.base_options, memory, cores, threads)

        if kvm is True:
            self.qemu_cmd = self.qemu_cmd + ' -enable-kvm'

        if kernel is not None:
            self.qemu_cmd = self.qemu_cmd + ' -kernel %s' % kernel

        if initrd is not None:
            self.qemu_cmd = self.qemu_cmd + ' -initrd %s' % initrd

        if cmdline is not None:
            self.qemu_cmd = self.qemu_cmd + ' -append \"%s\"' % cmdline

        if virtio is True:
            netdev = 'virtio-net-pci'
            blockdev = 'virtio'
        else:
            netdev = 'spapr-vlan'
            blockdev = 'scsi'

        self.qemu_cmd = self.qemu_cmd + ' -netdev type=%s,id=net0 \
            -device %s,netdev=net0' % ('user', netdev)

        if image_cow is True:
            # Need the full path
            image = os.path.abspath(image)
            self.tmpimage = tempfile.NamedTemporaryFile()
            cmd = 'qemu-img create -f qcow2 -o backing_file=%s %s %s' \
                % (image, self.tmpimage.name, image_size)
            print cmd
            retcode = subprocess.call(cmd, shell=True)
            if retcode != 0:
                raise ValueError
            image = self.tmpimage.name

        self.qemu_cmd = self.qemu_cmd + ' \
            -drive file=%s,if=%s' % (image, blockdev)

        if seed:
            self.qemu_cmd = self.qemu_cmd + ' \
                -drive file=%s,if=%s' % (seed, blockdev)

    def start(self):
        self.child = pexpect.spawn(self.qemu_cmd)
        self.child.logfile = sys.stdout
        # We sometimes get failures in close(), bump the timeouts
        self.child.delayafterclose = 1
        self.child.delayafterterminate = 1

    def expectcheck(self, str, timeout=300):
        keys = [str,
                pexpect.TIMEOUT,
                pexpect.EOF,
                'kernel BUG',
                'BUG:',
                'Kernel panic',
                'Call Trace:',
                'Rebooting in:',
                'Boot has failed, sleeping forever',
                ]

        result = self.child.expect(keys, timeout)

        if result == 1:
            raise Exception('Timeout')
        elif result == 2:
            raise Exception('EOF')
        elif result != 0:
            raise Exception('Boot failure')

    def interact(self):
        self.child.logfile = None
        self.child.interact()

    def close(self):
        self.child.close()
