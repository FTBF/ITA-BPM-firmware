# ITA BPM firmware

This repo holds the firmware required to operate the ITA BPM system based on a Digilent Eclypse-Z7.

## Project checkout instructions

This repo makes use of submoduels.  To automatiucally check these out add the `--recursive` flag to the clone command as follows

```
git clone --recursive git@github.com:FTBF/ITA-BPM-firmware.git
```

## Vivado projects in repo

### ITA-BPM-DAQ

This projects contains the main firmware design for the BPM DAQ.

### diode_BPM

Test project used as a basis for the petalinux image.

### LTC2333-write

IP project for the IP which controls the LTC2333 ADCs.

### LTC2333-read

IP project to recieve data from LTC2333 ADCs.


## Creating Vivado project with "Xil_prj_utils"

The vivado project is not stored directly in this repo.  Instead the project is regenerated with the "Xil_prj_utils" framework after checkout.  The framework runs in python3 and requires the python packages specified in "prj_utils/requirements.txt".  I recommend that a python virtualenv ([help](https://docs.python.org/3/library/venv.html)) be used to set up a python environment independent of the system installed version.  All packages can be installed with the following command

```
pip install -r requirements.txt
```

In addition to python3 you will need Vivado 2019.2 sourced in your PATH.

```
source [install path]/Xilinx/Vivado/2019.2/settings64.sh
```

### Creating Vivado project after checkout

In order to generate the Vivado project folder after checkout run the following commands

To list all avaliable projects in the repo
```
./project list
```

Create a specific project
```
./project create [project name]
```

build a project (bit file and device tree overlay)
```
./project build [project name]
```

The vivado project can also be used "normally" to compile and analyze the project and view the BD file after it is created.  

### pMCU firmware

In addition to the Vivado projects for the ZYNQ, there is also firmware for the pMCU microcontroller (an ATmega328pb) to bypass the SYZYGY DNA logic needed to power the ZYNQ IO banks which power the SYZYGY ports.  This is housed in the "pMCU-firmware` directory and is independent of the "Xil_prj_utils" framework.  

### Pre-requisites for building the firmware

The firmware is built using `avr-g++` and requires the `gcc-avr` and `avr-libc` packages to be installed.

### Building the firmware

With the pre-requisutes installed the firmware should build simply by running `make` in the `pMCU-firmware` folder.  This will produce the output file `main.hex` which can be uploaded to microcontroller.

### Programming the pMCU microcontroller

The firmware is loaded with a MPLAB SNAP programmer connected to the J9 header of the Eclypse (located next to the P MOD A port) .  Note that J9 is a 6 lin header while the SNAP has an 8 pin header.  Pin 1 of J9 should connect to pin 2 of the SNAP.  The firmware can be loaded from the SNAL using microchip's "MPLAB X IPE" tool [here](https://www.microchip.com/en-us/tools-resources/develop/mplab-x-ide).    

#### MPLAB SNAP configuration issues

When it arrived the MPLAB SNAP had a non-functional version of firmware installed and the "MPLAB X IPE" tool was unable to normally update the firmware.  This was remedied by performing a "factory reset" on the SNAP.  This is accomplished by using the "tools/Hardware Tool Emergency Boot Firmware Recovery" tool in the "MPLAB X IPE" (This only successfully completed in windows for me).  After this is run successfully, the IPE will load a new firmware onto the SNAP the next time it is used to program a device.        

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

##### Add Xilinx AXI I2C support 

By default the ubuntu image lacks support for the Xilinx AXI I2C module.  This must be added in the petalinux build through the kernel configuration menu

```petalinux-config -c kernel```

The activate the following module 

```Device Driver -> I2C Support -> I2C Hardware Bus support ->  Xilinx I2C Controller```

Ensure that the box has a `M` and not a `*` so that petalinux will build the I2C Controller as a kernal module which can be imported into ubuntu.  Also make sure to rebuild the petalinux project after this change is made

##### Compile u-dma-buf module

The `u-dma-buf` module source is located here

https://github.com/ikwzm/udmabuf

The module can be compiled in petalinux following the recipe below (based on [this](https://www.bastibl.net/futuresdr-2/))

1. in petalinux project run `petalinux-create -t modules --name u-dma-buf --enable`
2. copy source files from git repo to ./project-spec/meta-user/recipes-modules/u-dma-buf/files
3. run `petalinux-build`
4. compiled module file is located here `./build/tmp/sysroots-components/plnx_zynq7/u-dma-buf/lib/modules/4.19.0-xilinx/extra/u-dma-buf.ko`
5. Copy this file into rootfs and place in `/lib/modules/4.19.0-xilinx-v2019.2/kernel/drivers/u-dma-buf/`

##### Installing kernel modules 

petalinux places a copy of the kernel modules it builds in

```build/tmp/work/plnx_zynq7-xilinx-linux-gnueabi/linux-xlnx/4.19-xilinx-v2019.2+git999-r0/image/lib/modules/4.19.0-xilinx-v2019.2```

This folder should be coppied into the `/lib/modules`.  Make sure that the file and folder ownership is set to root.  You will need to run the command `sudo depmod -a` to update the list of modules.  In order for the uio module to be recognized and loaded during the dtbo loading you will need to create a `modprobe.d` config file `/lib/modprobe.d/uio-pdrv-genirq.conf` with the following contents

```options uio_pdrv_genirq of_id="linux,uio-pdrv-genirq"```

Similarly for the AXI I2C device make a file `/lib/modprobe.d/i2c-xiic.conf` with the contents

```options i2c-xiic of_id="xlnx,xps-iic-2.00.a"```

And for the u-dma-buf module create `/lib/modprobe.d/u-dma-buf.conf` with the contents

```options u-dma-buf udmabuf0=0x800000 udmabuf1=65536```

Finally to load the modules on boot an estry for each module must be added to `/etc/modules` as follows

```
uio_pdrv_genirq
i2c-xiic
u-dma-buf
```

And run `sudo update-initramfs -u`

### Accessing uio and u-dma-buf modules without root privileges

To access uio devices without root access create the following file '/etc/udev/rules.d/99-uio.rules' with contents

```SUBSYSTEM=="uio", GROUP="uiousr", MODE="660"```

Then create the `uiousr` user with 

```sudo groupadd uiousr```

and add the desired user to the group with 

```sudo usermod -a -G uiousr [username]```

For access to the u-dma-buf buffers create `/etc/udev/rules.d/99-u-dma-buf.rules` with contents

SUBSYSTEM=="u-dma-buf", GROUP="uiousr", MODE="660"
SUBSYSTEM=="u-dma-buf", RUN+="/bin/chgrp -R uiousr /sys/%p"

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

`fpgautil` can be used to load the firmware into the PL after the bit file is converted to a bin file.  A copy of fpgautil can be found [here](https://github.com/Xilinx/meta-xilinx-tools/blob/master/recipes-bsp/fpga-manager-script/files/fpgautil.c).  To fully load the firmware you will need the converted bin file and the compiled device tree overlay (dtbo) file.  The firmware is then loaded with the following incantation

```
sudo ./fpgautil -b diode_BPM.bit.bin -o device-tree/pl.dtbo
```

If a dtbo has already been loaded it will need to be cleared before running the above command with

```
sudo ./fpgautil -R
```