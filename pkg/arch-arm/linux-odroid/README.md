# Linux kernel for X2 and U2/U3

@tobiasjakobi's port of the Linux kernel aiming to be fully functional
on the `X2` and `U2/U3` boards.

Although, the kernel is developed for the `X2`, it works on the `U2/U3`
just as well since these boards, except for minor differences in their
device trees, are virtually identical.

References:
- [Development thread on HardKernel Forum][hk-forum-linux-tj]
- [Wiki page on Linux Exynos][le-wiki-x2]

_**Note:** The upstream [`linux-armv7`][alarm-linux-armv7] installs the
mainline kernel, which properly boots, but lacks some features, e.g.
hardware accelerated 2D graphics (G2D) and video encoding/decoding
(FMC). Depending on your use case that package may be sufficient._


## Motivation

While the mainline Linux kernel supports these boards, and can be
installed with the upstream [`linux-armv7`][alarm-linux-armv7] package,
it is not feature complete. Notably, it lacks `mali` support which makes
running Kodi and using these boards as media centers, a popular use
case, impossible.

This leaves users to choose between an up-to-date but not feature
complete and a feature complete but out-of-date and [soon to be
deprecated][alarm-hk-kernel-deprecation] kernel. This kernel aims to
provide the best of both worlds.


## Source

Changes by @tobiasjakobi.

- _TODO_


Additional changes by this package.

- **Allow setting Ethernet MAC address as a kernel parameter**

  Recent kernels generate a random MAC address for network interfaces
  that do not have a built-in address. This kernel has been patched to
  allow setting the MAC address of the Ethernet interface with the
  `smsc95xx.macaddr` kernel parameter. The patch was [taken from Arch
  Linux ARM][alarm-patch-mac].


## Package

This package was written from scratch and includes the following
features.

- **Easy customisation**

  The package was specifically written to allow easy customisation, such
  as creating new packages under different names and enabling initial
  ramdisk creation. See the comments in the [PKGBUILD](./PKGBUILD).

- **Display example `extlinux.conf` on installation**

  On installation, an example `extlinux.conf` is displayed that can be
  used to boot the kernel with the [_generic distro configuration_
  enabled U-Boot package][pkg-uboot-odroid] in this repository. Another,
  multi-kernel, example can also be found [here][extlinux-multi].


## Status

The following table summarises the status of each version of the package
on supported boards.

| version   | X  | X2 | U2 | U3 |
| --------- |:--:|:--:|:--:|:--:|
| 4.8.7-1   | ?  | ?  | !  | ?  |
| 4.8.6-2   | ?  | ?  | !  | ?  |
| 4.8.6-1   | ?  | ?  | !  | ?  |
| 4.8.5-1   | ?  | ?  | !  | ?  |
| 4.8.4-1   | ?  | ?  | !  | ?  |
| 4.8.1-1   | ?  | ?  | !  | ?  |
| 4.6.7-1   | ?  | ?  | !  | ?  |

_**Legend:** ✓ - fully working, except mainline issues; ! - partially
working, see [known issues](#known-issues); × - broken, does not boot;
? - not tested._


### Known issues

Issues affecting upstream.

- **Board hangs on reboot**

  **Boards:** `U2`, likely others;
  **Since:** at least `4.6.7`, possibly earlier

  When rebooting the board hangs and requires a complete power cycle to
  be able to boot again. This issue does not affect mainline.


## Documentation

### Storage device naming

Recent kernels, like this or mainline packaged by upstream in
[`linux-armv7`][alarm-linux-armv7], use predictable storage device
naming.

Regardless which devices are attached, the SD card is assigned `mmcblk0`
and the eMMC module is assigned `mmcblk1`.

| Device      | Always     |
| ----------- |:----------:|
| SD card     | `mmcblk0`  |
| eMMC module | `mmcblk1`  |

_**Note:** In the output of `dmesg`, when the device name assignment
happens, the SD card and the eMMC module show up as `mmc0` and `mmc1`,
respectively._

On the other hand, older kernels, like the official HardKernel one
packaged by upstream in [`linux-odroid`][alarm-linux-odroid], assigns
device names sequentially.

First, the SD card is probed, if present it gets `mmcblk0` assigned to
it. Then, the eMMC module is probed, if present it gets the next
available name assigned to it. That is, `mmcblk1` if the SD card is also
present and `mmcblk0` otherwise.

| Device      | SD card only | Both      | eMMC module only |
| ----------- |:------------:|:---------:|:----------------:|
| SD card     | `mmcblk0`    | `mmcblk0` | -                |
| eMMC module | -            | `mmcblk1` | `mmcblk0`        |

_**Note:** This behaviour seems to be consistent accross reboots, but a
race condition may be present._


<!-- REFERENCES -->

<!-- odroid-tools -->
[pkg-uboot-odroid]: ../uboot-odroid/
[extlinux-multi]: ../../../misc/u-boot/extlinux/extlinux.conf

<!-- other -->
[hk-forum-linux-tj]: http://forum.odroid.com/viewtopic.php?f=55&t=3691
[le-wiki-x2]: http://linux-exynos.org/wiki/Hardkernel_ODROID-X2

<!-- distro -->
[alarm-linux-odroid]: https://github.com/archlinuxarm/PKGBUILDs/blob/master/core/linux-odroid/
[alarm-linux-armv7]: https://github.com/archlinuxarm/PKGBUILDs/blob/master/core/linux-armv7/
[alarm-hk-kernel-deprecation]: https://github.com/archlinuxarm/PKGBUILDs/pull/1400#issuecomment-255926458
[alarm-patch-mac]: https://github.com/archlinuxarm/PKGBUILDs/blob/e3646a9858c3675301632953d0fa12a07490cfc3/core/linux-armv7/0005-net-smsc95xx-Allow-mac-address-to-be-set-as-a-parame.patch
