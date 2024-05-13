#!/bin/sh

set -e
SCRIPT=$(guix system vm --persistent --expose=/home/cole config.scm)

$SCRIPT -m 2048 -smp 2 \
        -nic user,model=virtio-net-pci \
        -display spice-app,gl=on \
        -device virtio-vga-gl \
        -spice gl=on,unix=on \
        -audiodev spice,id=snd0 \
        -chardev spicevmc,name=vdagent,id=vdagent
