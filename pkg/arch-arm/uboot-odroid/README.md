# uboot-odroid

U-Boot with generic distro configuration support for the `X`, `X2` and
`U2/U3` boards.


## Motivation

Implementing generic distro configuration has the following advantages.

- **Simpler configuration**

  All boot related settings can be modified in a central location in a
  transparent and intuitive manner, without obscuring the process with
  the compiled-in environment, as it is often the case. This results in
  a simpler and more friendly experience, akin to what most have
  accustomed to on x86 machines. 
  
- **Flexible environment**

  Simple but powerful boot disk and file discovery enables complicated
  setups, including separate `boot` and `root` partitions, with minimal
  configuration. At the same time, convenient defaults keep common
  setups effortless.

  A fallback boot script can also be used to provide backward
  compatibility or implement custom boot environments without modifying
  and recompiling U-Boot.

- **Less code to maintain**

  U-Boot implements the boot environment which is shared between all
  boards that enable this configuration method. Boards only have to
  define the memory addresses where various images should be loaded and
  the devices which should be searched for boot files. Modifying device
  order, boot prefixes, and customising network setup is supported too.
  This results in a smaller footprint.

- **Board agnostic boot configuration**

  More often than not, adding new board support to a distribution
  requires board-specific knowledge. Most boards have a different boot
  mechanism and environment. This complicates boot support and
  installation.

  Generic distro configuration aims to ease this process by defining a
  set of conventions and features a board can implement to allow
  distributions to support it without in-depth knowledge of how its boot
  process is implemented.


See [U-Boot's documentation][distro-docs] for details on the behaviour
and design of this feature. For implementation details, see the
[environment's definition][distro-bootcmd].

_**Note:** "Submitting this patch upstream would require removing or
replacing deprecated features and testing on boards I don't own. See
[Contributing](#contributing) below to see how you can help." --
@ztombol_


## Source

Changes over upstream U-Boot.

- **Implement `extlinux.conf` support**

  U-Boot implements a versatile and highly configurable boot environment
  which is shared between all boards enabling this configuration method.
  Boards only have to define the memory addresses where various images
  should be loaded and the devices which should be searched for boot
  files. Modifying device order, boot prefixes, and customising network
  setup is supported too. This allows booting more exotic configurations
  and results in a smaller code base.

- **Refactor and comment header file**

  The boards' [header file][odroid-header] has been carefully refactored
  and commented to make it easier to understand.


## Package

Changes over upstream `uboot-odroid` package.

- **Rewrite `sd_fusing.sh` from scratch**

  The new script introduces proper error detection and reporting, which
  was faulty and incomplete before, and more polished output. It also
  reapplies read-only access to the boot partition of eMMC modules after
  fusing and on error.

- **Do not duplicate fusing logic in install script**

  Use the installed `sd_fusing.sh` script instead of duplicating logic
  in the install script of the package.


The `X` support is based on the upstream [patch][alarm-patch-odroid-x].

References:
- [Patched U-Boot source][branch-odroid]
- [X support branch][branch-odroid-x]


## Status

The following table summarises the status of each version of the package
on supported boards.

| version      | X  | X2 | U2 | U3 |
| ------------ |:--:|:--:|:--:|:--:|
| 2017.01-1    | ?  | ?  | ✓  | ?  |
| 2016.11-1    | ?  | ?  | ✓  | ?  |
| 2016.09.01-3 | ?  | ?  | ✓  | ?  |
| 2016.09.01-2 | ?  | ?  | ✓  | ?  |
| 2016.09.01-1 | ?  | ?  | ✓  | ?  |

_**Legend:** ✓ - fully working, except upstream issues; ! - partially
working, see [known issues](#known-issues); × - broken, does not boot;
? - not tested._


### Known issues

Issues affecting upstream.

- **USB and Ethernet is broken in upstream**

  **Boards:** `U2`, most likely all others;
  **Since:** at least `v2016.07`, possibly earlier

  As of `v2016.07`, and possibly earlier, the USB and Ethernet support
  is broken in upstream U-Boot. This prevents using TFTP, DHCP or USB
  mass storage booting, as well as using the network console. The
  upstream package has the same issue.


## Contributing

Contributions are always welcome. Let them be fixes, bug reports,
testing or new features.

If you are looking for ideas, see the following list of tasks. Please,
follow the [contribution guidelines][contrib] to make things go smooth.

Upstream U-Boot tasks.

- **Report USB and Network bug to U-Boot**

  These boards are still [actively maintained][odroid-status] in U-Boot.
  Attempt to bring the USB and Network subsystems up as described in the
  [documentation][odroid-docs] and capture the console output. Then,
  report the error upstream.

- **Remove deprecated features**

  Upstream has [deprecated features][deprecated-docs] that need to be
  removed or replaced before submitting patches. This includes the
  following tasks.

  - Switching to a new memory test implementation. See the [related
    documentation][memtest-docs] and comments in the boards' [header
    file][odroid-header] for more.

  - Removing deprecated I2C macros. See the comments in the boards'
    [header file][odroid-header] and the warrning during compilation.

    ```
    ===================== WARNING ======================
    This board uses CONFIG_DM_I2C_COMPAT. Please remove
    (possibly in a subsequent patch in your series)
    before sending patches to the mailing list.
    ====================================================
    ```


  This is a prerequisite of upstreaming generic distro configuration
  support.


## Documentation

### Boot process

Discovering boot discs and locating boot files is a [standard
process][distro-docs] implemented by a [common
environment][distro-bootcmd]. Boot devices, network boot options and
their order, however, are implementation and board specific. The
following sections describe this process as implemented for the boards
supported by this package.

Before being able to load boot files, however, the bootloader has to be
loaded from somewhere. On the `X` and `X2` boards the `JP2` jumper is
used to select the source device. The `U2/U3` automatically selects the
eMMC module if attached, and the SD card if not. For a detailed
description of the boot sequence, see the [ODROID wiki][odroid-wiki].


#### Local devices

First, local devices are searched for boot configuration files in the
following order.

  1. eMMC module
  2. SD card

<!--
  3. USB mass storage
-->

_**Note:** USB mass storage devices are not considered as USB support on
these boards is broken in upstream. See the list of [known
issues](#known-issues) below._

All partitions marked as _bootable_ are searched. In the absence of such
partitions, the first partition of the device is chosen.

Boot files are searched under `/` and `/boot/` prefixes, in this order.
Thus, separate `boot` and `root` partitions are supported out of the
box.

There are two sources of boot configuration.

1. **`extlinux/extlinux.conf`**

  This is the recommended method of configuration. It allows modifying
  all boot related settings in a central location in a transparent and
  intuitive manner, without obscuring the process with the compiled-in
  environment, as it is often the case.
  
  For example, kernel parameters can be specified on a single line
  instead of in multiple environment variables that are mysteriously
  combined together with compiled-in settings.

  It is also possible to define multiple configurations in a single
  file, and switch between them by editing only one line.

  This makes for a user friendly experience, akin to what most have
  accustomed to on x86 machines.

  The syntax is derived from and is virtually identical to Syslinux's
  configuration file of the same name.

  ```
  default arch

  label arch
      linux ../zImage
      fdtdir ../dtbs
      append root=/dev/mmcblk0p1 rootwait rw console=ttySAC1,115200n8
  ```

  The file installed by this package contains numerous examples that
  should cover most setups. For the exact syntax see [U-Boot's
  documentation][distro-docs].

2. **`boot.scr` or `boot.scr.uimg`**

  When `extlinux.conf` does not exist or fails to boot due to erroneous
  configuration or failure of loading images, U-Boot falls back to a
  boot script. It looks for `boot.scr` or `boot.scr.uimg`.

  This can be used to provide backward compatibility or implement custom
  boot environments without the need to modify and recompile U-Boot.

  To simplify configuration and avoid confusing situations, in which the
  user provides a bad `extlinux.conf` but the board still boots with an
  unexpected configuration thanks to the fallback boot script, this
  package does not install one.
  
  If needed, however, one can be installed manually. This repository
  contains a [generic boot script][generic-boot-script] that supports
  multiple image formats and may be readily used with any board that
  support generic distro configuration.


During boot file discovery, only after checking all files does U-Boot
move on to the next device or boot option. This means that if the eMMC
module contains only `boot.scr`, then that will be used to boot even if
the SD card contains `extlinux.conf`.


#### Network boot

<!--
Next, network options are considered.

  1. PXE
  2. DHCP

The USB Ethernet chip on these boards does not have a built-in MAC
address. Thus, one has to be assigned before starting the USB subsystem.
This version of U-Boot uses `02:de:ad:be:ef:ff`. The interface is then
expected to receive an IP address via DHCP.

_**Note:** Boot devices and options are board specific. Different boards
may allow different devices and boot options._
-->

_**Note:** Network boot options are not available as Ethernet is broken
in upstream. See the list of [known issues](#known-issues) below._


<!-- REFERENCES -->

<!-- odroid-tools -->
[contrib]: ../../../CONTRIBUTING.md
[generic-boot-script]: ../../../misc/u-boot/boot-script/

<!-- u-boot -->
[distro-docs]: https://github.com/ztombol/u-boot/blob/odroid/doc/README.distro
[distro-bootcmd]: https://github.com/ztombol/u-boot/blob/odroid/include/config_distro_bootcmd.h
[odroid-docs]: https://github.com/ztombol/u-boot/blob/odroid/doc/README.odroid
[odroid-header]: https://github.com/ztombol/u-boot/blob/odroid/include/configs/odroid.h
[odroid-status]: https://github.com/u-boot/u-boot/blob/master/board/samsung/odroid/MAINTAINERS
[memtest-docs]: https://github.com/ztombol/u-boot/blob/odroid/doc/README.memory-test
[deprecated-docs]: https://github.com/u-boot/u-boot/blob/master/doc/feature-removal-schedule.txt
[branch-odroid]: https://github.com/ztombol/u-boot/tree/odroid
[branch-odroid-x]: https://github.com/ztombol/u-boot/tree/odroid-x

<!-- other -->
[odroid-wiki]: http://odroid.com/dokuwiki/doku.php?id=en:exynos4412bootsequence

<!-- distro -->
[alarm-patch-odroid-x]: https://github.com/archlinuxarm/PKGBUILDs/blob/586e583ce2a0fd6cd426f3706bb92567bd805b51/alarm/uboot-odroid/0002-odroid-x-support.patch
