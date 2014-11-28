#!/usr/bin/python

import sys
from qemu_ubuntu_test import qemu_ubuntu_test


if len(sys.argv) != 2:
	print "Usage: qemu_ubuntu_kernel_test.py kernel"
	sys.exit(1)

kernel=sys.argv[1]

print "Testing PAPR virtual IO"
q = qemu_ubuntu_test(kvm=True, kernel=kernel, cmdline='root=/dev/sda1 rw')
q.simple_test(q, timeout=30)
q.close()

print "Testing virtio virtual IO"
q = qemu_ubuntu_test(kvm=True, kernel=kernel, cmdline='root=/dev/vda1 rw', virtio=True)
q.simple_test(q, timeout=30)
q.close()

print "Testing SMP"
q = qemu_ubuntu_test(kvm=True, cores=8, threads=8, kernel=kernel, cmdline='root=/dev/sda1 rw')
q.simple_test(q, timeout=30)
q.close()

print "Testing QEMU full emulation"
q = qemu_ubuntu_test(kvm=False, kernel=kernel, cmdline='root=/dev/sda1 rw')
q.simple_test(q)
q.close()
