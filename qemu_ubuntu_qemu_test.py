#!/usr/bin/python

import sys
from qemu_ubuntu_test import qemu_ubuntu_test


if len(sys.argv) != 2:
	print "Usage: qemu_ubuntu_qemu_test.py qemu_binary"
	sys.exit(1)

qemu=sys.argv[1]

print "Testing PAPR virtual IO"
q = qemu_ubuntu_test(qemu=qemu, kvm=False)
q.simple_test(timeout=600)
q.close()

print "Testing virtio virtual IO"
q = qemu_ubuntu_test(qemu=qemu, kvm=False, virtio=True)
q.simple_test(timeout=600)
q.close()
