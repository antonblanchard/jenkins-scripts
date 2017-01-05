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
    base_options = '-cpu POWER8 -nographic -vga none'

    def __init__(self, qemu='qemu-system-ppc64', memory='4G', cores=1,
                 threads=1, kvm=False, virtio=False, kernel=None, initrd=None,
                 cmdline=None, image=None, image_size='16G', image_cow=True,
                 seed=None):

        self.qemu_cmd = '%s %s -m %s -smp cores=%d,threads=%d' % (
            qemu, self.base_options, memory, cores, threads)

        if kvm is False:
            self.qemu_cmd = self.qemu_cmd + ' -M pseries'
        elif kvm is 'HV':
            self.qemu_cmd = self.qemu_cmd + ' -M pseries,accel=kvm,kvm-type=HV'
        elif kvm is 'PR':
            self.qemu_cmd = self.qemu_cmd + ' -M pseries,accel=kvm,kvm-type=PR'
        else:
            raise Exception('Invalid kvm option')

        if kernel is not None:
            self.qemu_cmd = self.qemu_cmd + ' -kernel %s' % kernel

        if kernel is not None and initrd is not None:
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
        print self.qemu_cmd
        self.child = pexpect.spawn(self.qemu_cmd)
        self.child.logfile = sys.stdout

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
        # On a busy box it might take a while for QEMU to terminate
        self.child.delayafterclose = 1.0
        self.child.delayafterterminate = 1.0
        self.child.terminate()
