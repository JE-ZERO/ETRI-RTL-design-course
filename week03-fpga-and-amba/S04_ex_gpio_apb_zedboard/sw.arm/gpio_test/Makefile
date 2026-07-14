#-------------------------------------------------------------------------------
# Copyright (c) 2024 by Ando Ki.
# All rights are reserved by Ando Ki.
#-------------------------------------------------------------------------------
# Makefile
#-------------------------------------------------------------------------------
SHELL    = /bin/bash
MAKEFILE = Makefile
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all"))
    ifndef XILINX_VITIS
       $(error XILINX_VITIS environment variable not defined)
    else
        export VITIS         = $(XILINX_VITIS)/bin/vitis
        #export VITIS_VERSION = $(shell vitis -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
        #export VITIS_VER     = vitis.$(VIVADO_VERSION)
    endif
endif
#-------------------------------------------------------------------------------
export DIR_HW        := ../../hw/impl.zed
export DIR_WORKSPACE := ../workspace.zed
export DIR_XSA       := $(DIR_HW)/xsa
export DESIGN_NAME   := design_zed
export PATH_XSA      := $(DIR_XSA)/$(DESIGN_NAME)_wrapper.xsa
export DIR_SRC       := src
export DIR_API       := ../../../ex_gpio_apb_simple/api/c
export APP_NAME      := gpio_test
export BITSTREAM     := $(DIR_WORKSPACE)/$(DESIGN_NAME)_wrapper/hw/$(DESIGN_NAME)_wrapper.bit
export TARGET        := $(APP_NAME).elf
export APP_ELF       := $(DIR_WORKSPACE)/$(APP_NAME)/Debug/$(TARGET)
#-------------------------------------------------------------------------------
.PHONY: all build_workspace
all: platform

platform:
	@if [ ! -f $(PATH_XSA) ]; then echo $(PATH_XSA) not found.; fi
	@if [ ! -d $(DIR_WORKSPACE) ]; then xsct platform.tcl; fi

config bit:
	xsct xsct_script.tcl -x $(PATH_XSA) -w $(DIR_WORKSPACE) -a $(APP_NAME) -b $(BITSTREAM)

download elf:
	xsct xsct_script.tcl -x $(PATH_XSA) -w $(DIR_WORKSPACE) -a $(APP_NAME) -e $(APP_ELF)

help:
	@echo "make" : compile program
	@echo "make config" : configue FPGA using $(BITSTREAM)
	@echo "make download" : download $(APP_NAME).elf

#-------------------------------------------------------------------------------
.PHONY: clean cleanup clobber cleanupall distclean
clean:
	/bin/rm -fr obj
	/bin/rm -f  IDE.log
	/bin/rm -f  $(APP_NAME).elf

cleanup clobber: clean
	/bin/rm -f  $(TARGET)

cleanupall distclean: cleanup
	/bin/rm -fr $(DIR_WORKSPACE)
#-------------------------------------------------------------------------------
