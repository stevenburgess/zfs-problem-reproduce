#!/bin/bash

truncate -s 5G zpool.file
zpool create -o version=28 problem $(readlink -f zpool.file)
#zpool create problem $(readlink -f zpool.file)
zfs create -o compression=on problem/fs

truncate -s 3g /problem/fs/file
device=$(losetup -f --show /problem/fs/file)

zfs snapshot problem/fs@base
mkfs.ext4 -E discard $device
mkdir /tmp/zfsprobext
mount -o discard $device /tmp/zfsprobext

dd if=/dev/urandom of=/tmp/zfsprobext/file2 bs=256M count=1
sync
zfs snapshot problem/fs@middle
rm /tmp/zfsprobext/file2
# This needs to be the last thing, mess withthe FS up there ^^
sync
zfs snapshot problem/fs@end

zfs send problem/fs@middle | zfs recv problem/fs2
zfs send -i middle problem/fs@end | zfs recv problem/fs2

zfs clone -o readonly=on problem/fs@end problem/clone1
zfs clone -o readonly=on problem/fs2@end problem/clone2

md5sum /problem/clone1/file
md5sum /problem/clone2/file

umount /tmp/zfsprobext
losetup -d $device
rm -rf /tmp/zfsprobext
