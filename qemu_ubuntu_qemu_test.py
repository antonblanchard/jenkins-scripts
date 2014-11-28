#!/usr/bin/python

import sys
from qemu_ubuntu_test import qemu_ubuntu_test


if len(sys.argv) != 2:
	print "Usage: kernel_test.py qemu_binary"
	sys.exit(1)

qemu=sys.argv[1]

print "Testing PAPR virtual IO"
q = qemu_ubuntu_test(qemu=qemu, kvm=False)
run_tests(q, timeout=300)
q.close()

print "Testing virtio virtual IO"
q = qemu_ubuntu_test(qemu=qemu, kvm=False, virtio=True)
run_tests(q, timeout=300)
q.close()
