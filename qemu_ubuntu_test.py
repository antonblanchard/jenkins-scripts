#!/usr/bin/python

import os
from qemu_simple_test import qemu_simple_test
import urllib


class qemu_ubuntu_test(qemu_simple_test):
    def __init__(self, qemu='qemu-system-ppc64', memory='4G', cores=1,
                 threads=1, kvm=False, virtio=False, kernel=None,
                 initrd='initrd.img-4.4.0-24-generic',
                 cmdline=None, image='yakkety-server-cloudimg-ppc64el.img',
                 image_size='16G', image_cow=True, seed='my-seed.img',
                 seedurl='http://ozlabs.org/~anton/my-seed.img',
                 imageurl='http://cloud-images.ubuntu.com/yakkety/current/yakkety-server-cloudimg-ppc64el.img',
                 initrdurl='http://ozlabs.org/~anton/initrd.img-4.4.0-24-generic'):

        qemu_simple_test.__init__(self, qemu=qemu, memory=memory, cores=cores,
                                  threads=threads, kvm=kvm, virtio=virtio,
                                  kernel=kernel, initrd=initrd, cmdline=cmdline,
                                  image=image, image_size=image_size,
                                  image_cow=image_cow, seed=seed)

        if os.path.isfile(seed) is False:
            urllib.urlretrieve(seedurl, seed)

        if os.path.isfile(image) is False:
            urllib.urlretrieve(imageurl, image)

        if os.path.isfile(initrd) is False:
            urllib.urlretrieve(initrdurl, initrd)

    def wait_for_login(self, timeout=300):
        # We need to wait for the cloud tools to finish before we can log in.
        # Add a marker in the cloud config file that we can look for:
        # final_message: "SYSTEM READY TO LOG IN"
        self.expectcheck('SYSTEM READY TO LOG IN', timeout=timeout)
        self.child.sendline('')
        self.expectcheck('ubuntu login:', timeout=timeout)

    def wait_for_prompt(self, timeout=300):
        self.child.expect('ubuntu@ubuntu', timeout=timeout)

    def boot(self, timeout=300):
        # boot it
        self.start()
        self.wait_for_login(timeout=timeout)

    def login(self, timeout=300):
        # log in
        self.child.sendline('ubuntu')
        self.child.expect('Password:', timeout=timeout)
        self.child.sendline('passw0rd')
        self.wait_for_prompt(timeout=timeout)

    def simple_test(self, timeout=300):
        self.boot(timeout=timeout)
        self.login(timeout=timeout)

        # quick network test
        self.child.sendline('ping -W 1 -c 1 10.0.2.2')
        self.child.expect('1 received', timeout=timeout)
        self.wait_for_prompt(timeout=timeout)

        # more involved network test
        self.child.sendline('wget http://ozlabs.org/~anton/datafile')
        self.wait_for_prompt(timeout=timeout)

        self.child.sendline('md5sum datafile')
        self.child.expect('2a9981457d46bf85eba3f81728159f84', timeout=timeout)
        self.wait_for_prompt(timeout=timeout)

        # Check dmesg for warn level or greater messages. Ignore systemd.
        self.child.sendline('dmesg --level=warn,err,crit,alert,emerg | grep -v systemd')
        self.wait_for_prompt(timeout=timeout)
