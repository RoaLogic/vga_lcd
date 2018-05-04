# vga_lcd

## Description

The OpenCores VGA/LCD Controller core is an embedded VGA core capable of driving CRT and LCD displays. It supports user programmable resolutions and video timings, which are limited only by the available WISHBONE bandwidth. Making it compatible with almost all available LCD and CRT displays

The core supports a number of color modes, including 32bpp, 24bpp, 16bpp, 8bpp gray-scale, and 8bpp-pseudo color. The video memory is located outside the primary core, thus providing the most flexible memory solution. It can be located on-chip or off-chip, shared with the system’s main memory (VGA on demand) or be dedicated to the VGA system. The color lookup table is, as of core version 2.0, incorporated into the color-processor block.

Pixel data is fetched automatically via the bus master interface, making this an ideal “program-and-forget” video solution. More demanding video applications like streaming video or video games can benefit from the video-bank-switching function, which reduces flicker and cluttered images by automatically switching between video-memory pages and/or color lookup tables on each vertical retrace.
The core can interrupt the host on each horizontal and/or vertical synchronization pulse. The horizontal, vertical and composite synchronization polarization levels, as well as the blanking polarization level are user programmable.

## Features

* CRT and LCD display support
  * 24bit Standard VGA interface
  * Separate VSYNC/HSYNC and combined CSYNC synchronization signals
  * Composite BLANK signal
  * TripleDisplay support
* 12bit Interface
  * Compatible with DVI transmitters and 12bit VGA ADCs
  * 4 different output modes
  * Can be used simultaneous with the 24bit interface
* User programmable video resolutions
* User programmable video timing
* User programmable video control signals polarization levels
* 32bpp, 24bpp and 16bpp color modes
* 8bit gray-scale and 8bit pseudo-color modes
* Supports video- and/or color-lookup-table bankswitching during vertical retrace
* Flexible master and slave interfaces
* Operates from a wide range of input clock frequencies
* Static synchronous design

Fully synthesizeable

See the on-line documentation (current revision 1.2) for more information.

## Status
- VGA/LCD core v2.0 is ready and available in verilog from OpenCores CVS via cvsweb or via cvsget.
- Low level abstraction layer available in C from CVS.

## Background:
The VGA/LCD Controller core is developed and maintained by Roa Logic’s founder, Richard Herveille and was originally released via OpenCores.

Roa Logic is committed to maintaining the cores which the company's founder developed and contributed to OpenCores. All cores will be released and maintained here on the Roa Logic GitHub account.
