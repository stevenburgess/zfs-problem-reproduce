#!/bin/bash

truncate -s 100G zpool.file
zpool create -o version=28 problem $(readlink -f zpool.file)
#zpool create problem $(readlink -f zpool.file)
zfs create -o compression=on problem/fs

truncate -s 4g /problem/fs/file
device=$(losetup -f --show /problem/fs/file)

zfs snapshot problem/fs@base
# write random data to the end
mkfs.ext4 -E discard $device
mkdir /tmp/zfsprobext
mount -o discard $device /tmp/zfsprobext

integritycheck (){
    sync
    echo "synced"
}

dd if=/dev/urandom of=/tmp/zfsprobext/file1 bs=256M count=1
dd if=/dev/urandom of=/tmp/zfsprobext/file2 bs=256M count=1
dd if=/dev/urandom of=/tmp/zfsprobext/file3 bs=256M count=1
integritycheck
zfs snapshot problem/fs@3
rm /tmp/zfsprobext/file2
integritycheck
dd if=/dev/urandom of=/tmp/zfsprobext/file2 bs=256M count=1
dd if=/dev/urandom of=/tmp/zfsprobext/file4 bs=256M count=1
dd if=/dev/urandom of=/tmp/zfsprobext/file5 bs=256M count=1
# This needs to be the last thing, mess withthe FS up there ^^
integritycheck
zfs snapshot problem/fs@end

zfs send problem/fs@3 | zfs recv problem/fs2
zfs send -i 3 problem/fs@5 | zfs recv problem/fs2
zfs send -i 5 problem/fs@end | zfs recv problem/fs2

zfs send problem/fs@3 | zfs recv problem/fs3
zfs send -i 3 problem/fs@end | zfs recv problem/fs3

zfs clone -o readonly=on problem/fs@end problem/clone1
zfs clone -o readonly=on problem/fs2@end problem/clone2
zfs clone -o readonly=on problem/fs3@end problem/clone3

# while these checksums are interesting, its really diffs in the clones that
# we are intrested in.
#md5sum /problem/fs/file
#md5sum /problem/fs2/file
md5sum /problem/clone1/file
md5sum /problem/clone2/file
md5sum /problem/clone3/file

umount /tmp/zfsprobext
losetup -d $device
#rm /tmp/zfsprob/file
rm -rf /tmp/zfsprobext
