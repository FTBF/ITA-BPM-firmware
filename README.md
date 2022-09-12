# ITA BPM firmware

## ubuntu/petalinux notes

The base board for this project is an Eclypse-Z7.  This section holds notes on how to create the boot/rootfs images for the board.  This is not a complete recipe ... but a list of resources used

### Hardware support package

The hardware support package was based on the `diode_BPM` project in this repo.  Generate the xsa file from this design.

### Setting up petalinux tools

Complete docker image supporting petalinux-tools 2019.2

https://github.com/hbk-world/petalinux-2019-2-docker

### petalinux build instructions

Creating the petalinux project

```petalinux-create --type project --template zynq --name [project name]```

Initial project configuration

```petalinux-config --get-hw-description [path to xsa file]```

I largely followed these instructions for petalinux-settings, but used ubuntu 20.04 instead of 16.04.  

https://medium.com/developments-and-implementations-on-zynq-7000-ap/install-ubuntu-16-04-lts-on-zynq-zc702-using-petalinux-2016-4-e1da902eaff7

In addition follow the directions here to ensure FPGA manager and device tree overlay options are enabled

https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841645/Solution+Zynq+PL+Programming+With+FPGA+Manager

### Hack to fix booti vs bootm

If u-boot gives the error `Unknown command 'booti' - try 'help'` then change the following

```project-spec/meta-plnx-generated/recipes-bsp/u-boot/configs/platform-auto.h```

Change `booti` in default_bootcmd to `bootm`

```default_bootcmd=run uenvboot; run cp_kernel2ram && run cp_dtb2ram && booti ${netstart} - ${dtbnetstart}```

### Building BOOT.bin

```petalinux-package --boot --u-boot --force```

The BOOT partition of the SD card will need `BOOT.bin`, `image.ub`, and `system.dtb`

### Base rootfs image

I sourced the base rootfs image from here (ubuntu 20.04)

https://rcn-ee.com/rootfs/eewiki/minfs/

#### Add xilinx kernal modules

petalinux places a copy of the kernel modules it builds in

```build/tmp/work/plnx_zynq7-xilinx-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+git999-r0/image/lib/modules/4.19.0-xilinx-v2019.2```

This folder should be coppied into the `/lib/modules`.  Make sure that the file and folder ownership is set to root.  You will need to run the command `sudo depmod` to update the list of modules.  In order for the uio module to be recognized and loaded during the dtbo loading you will need to create a `modprobe.d` config file `/lib/modprobe.d/uio-pdrv-genirq.conf` with the following contents

```options uio_pdrv_genirq of_id="linux,uio-pdrv-genirq"```

#### Fix to load sshd faster on boot

The minimal SOC linux tends to be entropy starved and therefore have a hard time initializing components which need to use `/dev/urandom` (such as sshd).  A workaround is to allow the random seed to credit some entropy to the system at boot by adding the following lines to the `random-seed` config file (open with `sudo systemctl edit systemd-random-seed`)

```
[Service]
  Environment="SYSTEMD_RANDOM_SEED_CREDIT=true"
```

#### Switching from dhcp to static ip

Edit the following config file `/etc/netplan/01-netcfg.yaml` to commend out the line `dhcp4: yes` to `dhcp4: no` and add the line `addresses: ["192.168.46.31/24"]`.

```
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.46.31/24]

```

### Incantation to convert firmware bit file to bin file 

The ZYNQ-7000 cannot be programmed director from the bit file, it must first be converted to a bin file.  

```bootgen -image create.bif -arch zynq -o ./diode_BPM.bit.bin -w -process_bitstream bin```

Contents of `create.bif`
```
all:
{
  ./diode_BPM.bit
}
```

### Loading PL firmware

`fpgautil` can be used to load the firmware into the PL after the bit file is converted to a bin file.  A copy of fpgautil can be found (here)[https://github.com/Xilinx/meta-xilinx-tools/blob/master/recipes-bsp/fpga-manager-script/files/fpgautil.c].  To fully load the firmware you will need the converted bin file and the compiled device tree overlay (dtbo) file.  The firmware is then loaded with the following incantation

```
sudo ./fpgautil -b diode_BPM.bit.bin -o device-tree/pl.dtbo
```

If a dtbo has already been loaded it will need to be cleared before running the above command with

```
sudo ./fpgautil -R
```