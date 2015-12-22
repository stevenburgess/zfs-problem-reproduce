#!/bin/bash

truncate -s 10G zpool.file
zpool create -o version=28 problem $(readlink -f zpool.file)
zfs create -o compression=on -o mountpoint=/tmp/zfsprob problem/fs

# create a 12 k file
truncate -s 12k /tmp/zfsprob/file
zfs snapshot problem/fs@base
# write random data to the end
dd if=/dev/urandom of=/tmp/zfsprob/file bs=4k seek=2 count=1 conv=notrunc
zfs snapshot problem/fs@1
# write random data to the begingin, creating our hole
dd if=/dev/urandom of=/tmp/zfsprob/file bs=4k count=1 conv=notrunc
zfs snapshot problem/fs@2
# overwire the end with 00s
dd if=/dev/zero of=/tmp/zfsprob/file bs=4k seek=2 count=1 conv=notrunc
zfs snapshot problem/fs@3
# overwrite begining with 00s
dd if=/dev/zero of=/tmp/zfsprob/file bs=4k count=1 conv=notruncconv=notrunc
zfs snapshot problem/fs@4
# overwrite the whole thing with random
dd if=/dev/urandom of=/tmp/zfsprob/file bs=4k count=3 conv=notrunc
zfs snapshot problem/fs@5

zfs send problem/fs@1 | zfs recv problem/rec
zfs send -i 1 problem/fs@4 | zfs recv problem/rec
