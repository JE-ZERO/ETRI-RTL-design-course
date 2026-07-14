#-------------------------------------------------------------------------------
SHELL	=/bin/bash

#-------------------------------------------------------------------------------
export VIVADO       = vivado
export DESIGN       = zed
export DESIGN_NAME  = design_$(DESIGN)
export PROJECT_NAME = project_$(DESIGN)
export PROJECT_DIR  = $(PROJECT_NAME)
export SOURCE       = run_vivado.tcl
export PART         = xc7z020clg484-1
export BOARD        = em.avnet.com:zed:part0:1.4
export DIR_IP       = ../../..
export GUI         ?= 1

#-------------------------------------------------------------------------------
all:
	if [ "$(GUI)" = "1" ]; then\
		$(VIVADO) -mode gui -source $(SOURCE);\
	else\
		$(VIVADO) -mode batch -source $(SOURCE);\
	fi

#-------------------------------------------------------------------------------
.PHONY: clean cleanup

clean:
	/bin/rm -f  vivado.jou
	/bin/rm -f  vivado.log
	/bin/rm -f  vivado_*.backup.jou
	/bin/rm -f  vivado_*.backup.log
	/bin/rm -f  hs_err_*.log
	/bin/rm -f  vivado_pid*.str
	/bin/rm -f  vivado_pid*.zip
	/bin/rm -f  vitis_pid6252.str  vitis_pid7057.str  xrc.log
	/bin/rm -f  AddressMap.cvs
	/bin/rm -f  AddressMapGui.cvs
	/bin/rm -f  design_$(DESIGN).pdf
	/bin/rm -f  design_$(DESIGN)_wrapper.bit
	/bin/rm -f  vitis_pid*.str
	/bin/rm -f  vivado_*.backup.jou
	/bin/rm -f  vivado_*.backup.jou
	/bin/rm -f  vivado.jou
	/bin/rm -f  vivado.log
	/bin/rm -f  xrc.log
	@if [ -d .Xil ]; then /bin/rm -fr .Xil; fi
	@if [ -d hd_visual ]; then /bin/rm -fr hd_visual; fi

cleanup clobber: clean
	/bin/rm  -fr project_$(DESIGN)
	/bin/rm  -fr xsa

cleanupall distclean: cleanup
	/bin/rm -f  $(DESIGN_NAME)_wrapper.bit
	/bin/rm -f  $(DESIGN_NAME)_wrapper.ltx
	/bin/rm -f  $(DESIGN_NAME).pdf
	/bin/rm -f  AddressMapTable.xlsx
	/bin/rm -f  AddressMap.cvs AddressMapGui.cvs
	@if [ -d $(PROJECT_DIR) ]; then /bin/rm -fr $(PROJECT_DIR); fi

