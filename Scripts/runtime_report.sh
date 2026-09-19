#!/bin/sh
set -eu
printf '%s\n' '=== SmartDialSIM runtime report ==='
printf '%s\n' '[0] OS version:'
sw_vers 2>/dev/null || uname -a 2>/dev/null || true
printf '%s\n' '[1] Candidate Phone processes:'
ps -A -o pid,comm 2>/dev/null | grep -iE 'phone|mobilephone' || true
printf '%s\n' '[2] Candidate Phone app bundles under original rootfs:'
find /rootfs/Applications /rootfs/System/Applications -maxdepth 2 -type d \( -iname '*phone*.app' -o -iname '*mobilephone*.app' \) -print 2>/dev/null || true
printf '%s\n' 'Run this separately on iOS 15.x and iOS 16.2. Send only OS/process/bundle identifiers and relevant runtime class/selector traces; do not send private call/contact data.'
