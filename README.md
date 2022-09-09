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

### Building BOOT.bin

```petalinux-package --boot --u-boot --force```

The BOOT partition of the SD card will need `BOOT.bin`, `image.ub`, and `system.dtb`

### Base rootfs image

I sourced the base rootfs image from here

https://rcn-ee.com/rootfs/eewiki/minfs/


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


