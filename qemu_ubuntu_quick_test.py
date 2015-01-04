#!/usr/bin/python

import sys
from qemu_ubuntu_test import qemu_ubuntu_test


if len(sys.argv) != 2:
	print "Usage: qemu_ubuntu_quick_test.py kernel"
	sys.exit(1)

kernel=sys.argv[1]

print "Testing PAPR virtual IO"
q = qemu_ubuntu_test(kvm=False, kernel=kernel, cmdline='root=/dev/sda1 rw')
q.simple_test(timeout=600)
q.close()
