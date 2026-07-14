#------------------------------------------------------------------
# VIVADO Batch Mode 
#------------------------------------------------------------------
# Copyright (c) 2022 by Future Design Systems
# All right reserved.
#------------------------------------------------------------------
SHELL		= /bin/sh
MAKEFILE	= Makefile
#-------------------------------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    else
        export VIVADO         = $(XILINX_VIVADO)/bin/vivado
        export VIVADO_VERSION = $(shell vivado -version | sed -n 1p | cut -d" " -f 2 | cut -c 2-7)
        export VIVADO_VER     = vivado.$(VIVADO_VERSION)
    endif
endif

#------------------------------------------------------------------
export PROJECT_DIR   = project_1
export PROJECT_NAME  = project_1
export WORK          = work
export FPGA_TYPE     = ZYNQ7000
export MODULES       = mem_apb
export RIGOR         = 1
export SYNTH_ONLY    = 1
export GUI          ?= 0
#------------------------------------------------------------------
export SOURCE        =vivado_syn.tcl
#------------------------------------------------------------------
all: vivado

vivado:
	if [ "$(GUI)" = "1" ]; then\
		for m in $(MODULES); do\
			(export MODULE=$${m}; $(VIVADO) -mode gui -source $(SOURCE));\
		done;\
	else\
		for m in $(MODULES); do\
			(export MODULE=$${m}; $(VIVADO) -mode batch -source $(SOURCE));\
		done;\
	fi

#------------------------------------------------------------------
DIRS    = $(subst /,, $(dir $(wildcard */Makefile)))

clean:
	-/bin/rm -f  *.log
	-/bin/rm -fr .cache
	-/bin/rm -rf .Xil
	-/bin/rm -f  *.html
	-/bin/rm -f  *.xml
	-/bin/rm -f  *.jou
	-/bin/rm -f  *.backup*
	-/bin/rm -f  planAhead.*
	-/bin/rm -f  vivado.log
	-/bin/rm -f  vivado_pid*.str  vivado_pid*.debug
	-/bin/rm -f  fsm_encoding.os
	-/bin/rm -f  hw_ila_data_*btree
	-/bin/rm -rf $(WORK)
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

cleanup clobber: clean
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done

cleanupall distclean: cleanup
	for M in $(MODULES); do\
		/bin/rm -f  $(M).xdc;\
		/bin/rm -rf $(M).dcp;\
		/bin/rm -rf $(M).edn;\
	done
	/bin/rm -rf project_*;\
	for D in $(DIRS); do\
		if [ -f $$D/Makefile ] ; then \
			echo "make -C $$D -s $@";\
			make -C $$D -s $@;\
		fi;\
	done
#------------------------------------------------------------------
