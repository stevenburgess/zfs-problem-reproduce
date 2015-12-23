# zfs-problem-reproduce

# Prompt

This script was made to narrow down under what conditions incremental sendfiles were being incorrectly created. It seemed like the problem was running currnet versions of ZoL on pools with ```feature@hole_birth disabled```. I beleive this script proves this out. When run on a machine running 0.6.5, and an old pool, you get mismatched checksums, all other combinations are fine. Table for clarity:

|  | 0.6.4 | 0.6.5          |
| -------- | -------- | -------- |
| feature@hole_birth disabled | :heavy_check_mark: | :x: |
| feature@hole_birth enabled |  :heavy_check_mark:    | :heavy_check_mark: |

My theory is that changes to the userland want to interact with the hole_birth, but when it’s not there, they do not properly fall back to the old way of doing it, and instead do not transmit the holes. This is supported by running the script on a machine with 0.6.4 loaded grabbing the sendfile, then upgrading to 0.6.5 and grabbing its sendfile. If you do that, you should get a zstreamdump diff similar to [this](https://gist.github.com/stevenburgess/dac2a201607e169a3ac4)

# Walk though script

The idea was to emulate a VM running on a sprase file inside a ZFS system, being replicated to a second ZFS system. The [first part of the file](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L3-L14) is to set up an ext4 filesystem with discard enabled.

[Then we write a file into the FS and delete it, snapshotting along the way](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L16-L22). You need to sync after the actions, or the underlying filesystem may not have been told to record the actions yet.

After the original filesystem is created, the script [replicates the FS within the same pool](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L24-L25) using incremental sends.

Finally, it [clones both of the ending snapshots out](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L27-L28), and [checksums their contents](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L30-L31). Since each snapshot represnets the same state of the same filesystem, we expect them to be identical, and in almost all cases they are, except for current userspace tools interacting with pools that have ```feature@hole_birth disabled```.

[Some cleanup](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L33-L35) is preformed at the end of the script, but the rest of it is performed in cleanup.sh

If you are running a machine with 0.6.5, switching [these two lines](https://github.com/stevenburgess/zfs-problem-reproduce/blob/master/ext.sh#L4-L5) makes the checksums match and un match accordingly.
