#!/bin/bash

devbackingfile=/encrypted/dev1
if [ ! -f "$devbackingfile" ]; then
    # Create the file backing the block device
    dd if=/dev/zero "of=$devbackingfile" bs=1M count=512 oflag=direct
fi

# Start the loopback device
mknod /dev/loop0 b 7 0
# To remove any associations from previous container boot
losetup -d /dev/loop0
# needs:
# cap_add:
#    - CAP_MKNOD
# device_cgroup_rules:
#    - 'b 7:* rmw'
losetup /dev/loop0 "$devbackingfile"
losetup -l

# Stay in an endless loop
while true; do
    sleep 1h
done
