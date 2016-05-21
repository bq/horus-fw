#  Part of Horus Firmware
#
#  Copyright (c) 2014-2015 Mundo Reader S.L.
#
#  Horus Firmware is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  Horus Firmware is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Horus Firmware.  If not, see <http://www.gnu.org/licenses/>.

#  This file is based on work from Grbl v0.9, distributed under the 
#  terms of the GPLv3. See COPYING for more details.
#    Copyright (c) 2009-2011 Simen Svale Skogsrud
#    Copyright (c) 2011-2014 Sungeun K. Jeon

# This is a prototype Makefile. Modify it according to your needs.
# You should at least check the settings for
# DEVICE ....... The AVR device you compile for
# CLOCK ........ Target AVR clock rate in Hertz
# OBJECTS ...... The object files created from your source files. This list is
#                usually the same as the list of source files with suffix ".o".
# PROGRAMMER ... Options to avrdude which define the hardware you use for
#                uploading to the AVR and the interface where this hardware
#                is connected.
# FUSES ........ Parameters for avrdude to flash the fuses appropriately.

#To compile for Arduino Mega 2560 R3 change atmega328p for atmega2560
DEVICE     ?= atmega328p
CLOCK      = 16000000
PROGRAMMER ?= -c avrisp2 -P usb
OBJECTS    = main.o motion_control.o gcode.o serial.o laser_control.o ldr.o \
             protocol.o stepper.o eeprom.o settings.o planner.o nuts_bolts.o \
             print.o probe.o report.o system.o
# FUSES      = -U hfuse:w:0xd9:m -U lfuse:w:0x24:m
FUSES      = -U hfuse:w:0xd2:m -U lfuse:w:0xff:m
# update that line with this when programmer is back up:
# FUSES      = -U hfuse:w:0xd7:m -U lfuse:w:0xff:m

# Tune the lines below only if you know what you are doing:

AVRDUDE = avrdude $(PROGRAMMER) -p $(DEVICE) -B 10 -F
COMPILE = avr-gcc -Wall -Os -DF_CPU=$(CLOCK) -mmcu=$(DEVICE) -I. -ffunction-sections

# symbolic targets:
all:	horus-fw.hex

.c.o:
	$(COMPILE) -c $< -o $@
	@$(COMPILE) -MM  $< > $*.d

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

.c.s:
	$(COMPILE) -S $< -o $@

flash:	all
	$(AVRDUDE) -U flash:w:horus-fw.hex:i

fuse:
	$(AVRDUDE) $(FUSES)

# Xcode uses the Makefile targets "", "clean" and "install"
install: flash fuse

# if you use a bootloader, change the command below appropriately:
load: all
	bootloadHID horus-fw.hex

clean:
	rm -f horus-fw.hex main.elf $(OBJECTS) $(OBJECTS:.o=.d)

# file targets:
main.elf: $(OBJECTS)
	$(COMPILE) -o main.elf $(OBJECTS) -lm -Wl,--gc-sections

horus-fw.hex: main.elf
	rm -f horus-fw.hex
	avr-objcopy -j .text -j .data -O ihex main.elf horus-fw.hex
	avr-size --format=berkeley main.elf
# If you have an EEPROM section, you must also create a hex file for the
# EEPROM and add it to the "flash" target.

# Targets for code debugging and analysis:
disasm:	main.elf
	avr-objdump -d main.elf

cpp:
	$(COMPILE) -E main.c

# include generated header dependencies
-include $(OBJECTS:.o=.d)
