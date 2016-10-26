#/usr/bin/env bash

#
# Copyright (C) 2011 Samsung Electronics Co., Ltd.
#              http://www.samsung.com/
#
# Copyright (C) 2016 Zoltan Tombol <zoltan dot tombol at gmail>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#

#
# sd_fusing.sh
# ------------
#
# Flash U-Boot files to an SD card or eMMC module.
#
# This script, originally written by Samsung and HardKernel, has been
# modified to be used in Arch Linux ARM.
#
# With the exception of `local' this script is POSIX compatible.
#
# Supported devices:
#   - Odroid-X        (Exynos 4412)
#   - Odroid-X2/U2/U3 (Exynos 4412 Prime)
#

set -o errexit
set -o nounset


###############################################################################
# Functions
###############################################################################

usage() {
cat<<EOF
Usage:
  ./sd_fusing.sh <dev>

Arguments:
  dev - boot device to fuse, e.g. /dev/mmcblk0

Notes:
  Must be called from the directory containing the binaries to be fused.

    bl1.HardKernel  - Firmware blob 1          (Samsung)
    bl2.HardKernel  - Secondary Program Loader (Samsung)
    u-boot.bin      - U-Boot
    tzsw.HardKernel - ARM TrustZone Platform   (Samsung)

EOF
}

# EXIT signal handler. Disable write access to MMC boot partition and
# print a summary.
#
# Globals:
#   is_dev_mmc
# Arguments:
#   none
# Returns:
#   none
exit_trap() {
  local -ri status="$?"

  if [ "$is_dev_mmc" -eq 1 ] && is_mmc_part_rw "$dev" \
    && ! set_mmc_part_ro "$dev"
  then
    local -ri is_mmc_rw=1
  fi

  echo
  echo '===> Summary'
  echo "  result : $( [ "$status" -eq 0 ] && echo success || echo failure )"

  if [ "$is_dev_mmc" -eq 1 ]; then
    if [ "$is_mmc_rw" -eq 1 ]; then
      echo 'boot   : unlocked (RW)'
    else
      echo 'boot   : locked (RO)'
    fi
  fi

  echo
}

# Determine whether the given device is an MMC device.
#
# Globals:
#   none
# Arguments:
#   $1 - device to check
# Returns:
#   0 - MMC device
#   1 - otherwise
is_mmc() {
  local dev="$1"
  [ -d "/sys/block/${dev##*/}boot0" ]
}

# Determine whether the given partition of an MMC device is writable.
#
# Globals:
#   none
# Arguments:
#   $1 - partition
# Returns:
#   0 - writable
#   1 - otherwise
is_mmc_part_rw() {
  local dev="$1"
  [ "$(cat "/sys/block/${dev##*/}/force_ro")" == 0 ]
}

# Enable write access to the given partition of an MMC device.
#
# Globals:
#   none
# Arguments:
#   $1 - partition
# Returns:
#   0 - on success
#   1 - otherwise
set_mmc_part_rw() {
  local dev="$1"
  if ! echo 0 > "/sys/block/${dev##*/}/force_ro"; then
    echo "Error: Gaining write access to: \`${dev}'"
    return 1
  fi
  echo "-> Write access gained to: \`${dev}'"
}

# Disable write access to the given partition of an MMC device.
#
# Globals:
#   none
# Arguments:
#   $1 - partition
# Returns:
#   0 - on success
#   1 - otherwise
set_mmc_part_ro() {
  local dev="$1"
  if ! echo 1 > "/sys/block/${dev##*/}/force_ro"; then
    echo "Error: Re-enabling read-only access on: \`${dev}'"
    return 1
  fi
  echo "Read-only access re-enabled on: \`${dev}'"
}


###############################################################################
# Check Arguments
###############################################################################

if [ "$#" -ne 1 ]; then
  echo 'Error: No device specified!'
  usage
  exit 1
fi
dev="$1"

if [ ! -b "$dev" ]; then
  echo "Error: Not a block device: \`${dev}'"
  exit 1
fi


###############################################################################
# Main
###############################################################################

trap exit_trap EXIT

echo '===> Overview'
echo "  device : ${dev}"

if is_mmc "$dev"; then
  echo '  type   : eMMC module'
  part=boot0
  echo "  part   : ${part}"
  dev="${dev}${part}"
  is_dev_mmc=1
  pos_bl1=0
  pos_bl2=30
  pos_uboot=62
  pos_tzsw=2110
else
  echo '  type   : SD card'
  is_dev_mmc=0
  pos_bl1=1
  pos_bl2=31
  pos_uboot=63
  pos_tzsw=2111
fi

echo
echo '===> Fusing'

if [ "$is_dev_mmc" -eq 1 ]; then
  set_mmc_part_rw "$dev"
fi

echo '-> BL1'
dd if=bl1.HardKernel seek="$pos_bl1" of="$dev" obs=512 iflag=dsync oflag=dsync

echo '-> BL2'
dd if=bl2.HardKernel seek="$pos_bl2" of="$dev" obs=512 iflag=dsync oflag=dsync

echo '-> U-Boot'
dd if=u-boot.bin seek="$pos_uboot" of="$dev" obs=512 iflag=dsync oflag=dsync

echo '-> TrustZone S/W'
dd if=tzsw.HardKernel seek="$pos_tzsw" of="$dev" obs=512 iflag=dsync oflag=dsync
