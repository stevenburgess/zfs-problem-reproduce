#!/bin/bash

truncate -s 10G zpool.file
zpool create -o version=28 problem $(readlink -f zpool.file)
#zpool create problem $(readlink -f zpool.file)
zfs create -o compression=on problem/fs

truncate -s 1g /problem/fs/file
device=$(losetup -f --show /problem/fs/file)

zfs snapshot problem/fs@base
# write random data to the end
mkfs.ext4 -E discard $device
mkdir /tmp/zfsprobext
mount -o discard $device /tmp/zfsprobext

dd if=/dev/urandom of=/tmp/zfsprobext/file1 bs=4k count=1
sync
zfs snapshot problem/fs@1
dd if=/dev/urandom of=/tmp/zfsprobext/file2 bs=4k count=1
sync
zfs snapshot problem/fs@2
dd if=/dev/urandom of=/tmp/zfsprobext/file3 bs=4k count=1
sync
zfs snapshot problem/fs@3
rm /tmp/zfsprobext/file2
sync
zfs snapshot problem/fs@5
dd if=/dev/urandom of=/tmp/zfsprobext/file2 bs=4k count=1
sync
zfs snapshot problem/fs@6
rm /tmp/zfsprobext/file1
sync
zfs snapshot problem/fs@end

zfs send problem/fs@3 | zfs recv problem/fs2
zfs send -i 3 problem/fs@5 | zfs recv problem/fs2
zfs send -i 5 problem/fs@end | zfs recv problem/fs2

zfs clone -o readonly=on problem/fs@end problem/clone1
zfs clone -o readonly=on problem/fs2@end problem/clone2

# while these checksums are interesting, its really diffs in the clones that
# we are intrested in.
#md5sum /problem/fs/file
#md5sum /problem/fs2/file
md5sum /problem/clone1/file
md5sum /problem/clone2/file

umount /tmp/zfsprobext
losetup -d $device
#rm /tmp/zfsprob/file
rm -rf /tmp/zfsprobext
