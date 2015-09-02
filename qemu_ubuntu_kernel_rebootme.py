#!/usr/bin/python

import sys
from qemu_ubuntu_test import qemu_ubuntu_test


if len(sys.argv) != 3:
    print "Usage: qemu_ubuntu_kernel_rebootme.py kernel iterations"
    sys.exit(1)

kernel = sys.argv[1]
iterations = int(sys.argv[2])

q = qemu_ubuntu_test(kvm=True, cores=8, threads=8, kernel=kernel,
                     cmdline='root=/dev/sda1 rw', virtio=True)
q.boot()

for i in range(iterations):
    q.login()
    q.child.sendline('shutdown -r now')
    q.wait_for_login()
