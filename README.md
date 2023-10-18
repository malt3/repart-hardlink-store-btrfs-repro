# systemd-repart bug: hardlink store leaks into the final image

When using systemd-repart on a host with btrfs,
systemd-repart fails to delete the temporary hardlink store and copies it into the final image.

## How to reproduce

Boot a system with a btrfs root filesystem (or ensure repart create the hardlink store in a mounted btrfs partition),
then run the reproducer (`bash reproduce.sh`).

```shell-session
$ bash reproduce.sh
[...]

Applying changes.
Wiped block device.
Discarded entire block device.
Successfully wiped file system signatures from future partition 0.
Copying in '/var/tmp/.#repart436a1ed324ffaafe' (4.0K) on block level into future partition 0.
Copying in of '/var/tmp/.#repart436a1ed324ffaafe' on block level completed.
Adding new partition 0 to partition table.
Writing new partition table.
All done.
./ type=dir mode=0755 uid=0 gid=0
./.\x23hardlink022ccd29d350cfb1/ type=dir mode=0700 uid=0 gid=0
./.\x23hardlink022ccd29d350cfb1/0:43:7663846 type=file mode=0644 uid=1000 gid=100 size=0
./hardlink-1 type=file mode=0644 uid=1000 gid=100 size=0
./hardlink-2 type=file mode=0644 uid=1000 gid=100 size=0
```

On an older version of systemd-repart (likely 253), we also saw the following message:

```
Failed to remove hardlink store (.#hardlink3cd2b58ca584d667) directory, ignoring: Directory not empty
```

## Expected behavior

The resulting image should only contain of the root dir (`/`) and two files hardlinking the same inode (`hardlink-1` and `hardlink-2`).

## Actual behavior

The image also contains the hardlink store, that should have been deleted.

## System info

This bug was seen on NixOS 23.05 with systemd-repart v254.3 and Archlinux with systemd-repart 254.5-1.
It does not reproduce on every system we tested, but we do have multiple systems that show this behavior consistently.
The target filesystem (squashfs) does not matter (this also reproduces with any other target filesystem we tried).
The host filesystem seems to matter. This was only observed on btrfs.

## Bisect

- 6.5.5 works
- [btrfs: file_remove_privs needs an exclusive lock in direct io write
](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/commit/?h=v6.5.6&id=59a051389e1433b1a9abd258f3b4278b5e30654d) works
- [btrfs: set last dir index to the current last index when opening dir
](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/commit/?h=v6.5.6&id=73b4e302165b402d2059c92c00edc2f5c2eb203a) broken
- 6.5.6 broken


## Verbose log

```
Couldn't find any partition table to derive sector size of.
No machine ID set, using randomized partition UUIDs.
Pre-populating squashfs filesystem of partition 10-root.conf twice to calculate minimal partition size
Populating squashfs filesystem.
Failed to remove hardlink store (.#hardlinkd89f0de3084f4cfd) directory, ignoring: Directory not empty
Successfully populated squashfs filesystem.
Executing mkfs command: /nix/store/g9jfw5r6879zhdm0dk4q83zyjgb4zd9p-squashfs-4.6.1/bin/mksquashfs /var/tmp/.#repart438918c51c66e95c /var/tmp/.#repartd13ead09d044dfe4 -noappend
Successfully forked off '(mkfs)' as PID 195360.
Bind-mounting /dev/null on /proc/self/mounts (MS_BIND "")...
Parallel mksquashfs: Using 16 processors
Creating 4.0 filesystem on /var/tmp/.#repartd13ead09d044dfe4, block size 131072.
[|                                                                                                                                                                                                                                                                  ] 0/0 100%

Exportable Squashfs 4.0 filesystem, gzip compressed, data block size 131072
        compressed data, compressed metadata, compressed fragments,
        compressed xattrs, compressed ids
        4k unaligned
        duplicates are removed
Filesystem size 0.28 Kbytes (0.00 Mbytes)
        73.83% of uncompressed filesystem size (0.38 Kbytes)
Inode table size 65 bytes (0.06 Kbytes)
        53.28% of uncompressed inode table size (122 bytes)
Directory table size 78 bytes (0.08 Kbytes)
        67.24% of uncompressed directory table size (116 bytes)
Number of duplicate files found 1
Number of inodes 3
Number of files 1
Number of fragments 0
Number of symbolic links 0
Number of device nodes 0
Number of fifo nodes 0
Number of socket nodes 0
Number of directories 2
Number of hard-links 2
Number of ids (unique uids + gids) 3
Number of uids 2
        malte (1000)
        root (0)
Number of gids 2
        users (100)
        root (0)
(mkfs) succeeded.
/var/tmp/.#repartd13ead09d044dfe4 successfully formatted as squashfs (no label or uuid specified)
Minimal partition size of squashfs filesystem of partition 10-root.conf is 4.0K
Automatically determined minimal disk image size as 11.0M.
Sized 'system.raw' to 11.0M.
Not resizing partition table, as there currently is none.
Couldn't find any partition table to derive sector size of.
Sector size of device is 512 bytes. Using grain size of 4096.
Successfully forked off '(pager)' as PID 195480.
Found cgroup2 on /sys/fs/cgroup/, full unified hierarchy
Pager executable is "less", options "FRSXMK", quit_on_interrupt: yes
TYPE        LABEL       UUID                                 FILE         NODE         OFFSET OLD SIZE RAW SIZE      SIZE OLD PADDING RAW PADDING PADDING ACTIVITY
root-x86-64 root-x86-64 5cf5aff4-560a-47dd-bc13-e1fd1d71e5cf 10-root.conf system.raw1 1048576        0 10485760   → 10.0M           0           0    → 0B create
                                                                                                                Σ = 10.0M                          Σ = 0B

 ░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
                         └─ 10-root.conf

Applying changes.
Wiped block device.
Discarded entire block device.
Successfully wiped file system signatures from future partition 0.
Copying in '/var/tmp/.#repartd13ead09d044dfe4' (4.0K) on block level into future partition 0.
Copying in of '/var/tmp/.#repartd13ead09d044dfe4' on block level completed.
Adding new partition 0 to partition table.
Writing new partition table.
Not telling kernel to reread partition table, since we are not operating on a block device.
All done.
./ type=dir mode=0755 uid=0 gid=0
./.\x23hardlinkd89f0de3084f4cfd/ type=dir mode=0700 uid=0 gid=0
./.\x23hardlinkd89f0de3084f4cfd/0:43:7666554 type=file mode=0644 uid=1000 gid=100 size=0
./hardlink-1 type=file mode=0644 uid=1000 gid=100 size=0
./hardlink-2 type=file mode=0644 uid=1000 gid=100 size=0

```
