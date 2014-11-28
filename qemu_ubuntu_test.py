#!/usr/bin/python

import os
from qemu_simple_test import qemu_simple_test
import urllib


class qemu_ubuntu_test(qemu_simple_test):
	def __init__(self, qemu='qemu-system-ppc64', memory='4G', cores=1, threads=1, kvm=False, virtio=False, kernel=None, initrd=None, cmdline=None, image='utopic-server-cloudimg-ppc64el-disk1.img', image_size='16G', image_cow=True, seed='my-seed.img', seedurl='http://ozlabs.org/~anton/my-seed.img', imageurl='http://cloud-images.ubuntu.com/utopic/current/utopic-server-cloudimg-ppc64el-disk1.img'):

		qemu_simple_test.__init__(self, qemu=qemu, memory=memory, cores=cores, threads=threads, kvm=kvm, virtio=virtio, kernel=kernel, initrd=initrd, cmdline=cmdline, image=image, image_size=image_size, image_cow=image_cow, seed=seed)

		if os.path.isfile(seed) == False:
			urllib.urlretrieve(seedurl, seed)

		if os.path.isfile(image) == False:
			urllib.urlretrieve(imageurl, image)


	def simple_test(self, timeout=300):
		# boot it
		self.start()
		self.expectcheck('ubuntu login:', timeout=timeout)

		# log in
		self.child.sendline('ubuntu')
		self.child.expect('Password:', timeout=timeout)
		self.child.sendline('passw0rd')
		self.child.expect('ubuntu@ubuntu', timeout=timeout)

		# quick network test
		self.child.sendline('ping -W 1 -c 1 10.0.2.2')
		self.child.expect('1 received', timeout=timeout)
		self.child.expect('ubuntu@ubuntu', timeout=timeout)

		# more involved network test
		self.child.sendline('wget http://ozlabs.org/~anton/datafile')
		self.child.expect('ubuntu@ubuntu', timeout=timeout)
		self.child.sendline('md5sum datafile')
		self.child.expect('2a9981457d46bf85eba3f81728159f84', timeout=timeout)
		self.child.expect('ubuntu@ubuntu', timeout=timeout)
