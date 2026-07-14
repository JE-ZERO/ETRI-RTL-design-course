SHELL=/bin/bash

GUI ?= 0

ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifndef XILINX_VIVADO
       $(error XILINX_VIVADO environment variable not defined)
    else
        XELAB = $(XILINX_VIVADO)/bin/xelab
        XSIM  = $(XILINX_VIVADO)/bin/xsim
    endif
endif

all: elab sim

elab:
	@$(XELAB) -prj xsim.prj -debug typical top -s top

sim:
	@if [ "$(GUI)" = "1" ]; then\
		$(XSIM) top -gui;\
	else\
		$(XSIM) top -t xsim_run.tcl;\
	fi

wave:
	@if [ -f wave.vcd ]; then\
		gtkwave wave.vcd;\
	fi

clean:
	/bin/rm -f  top.wdb
	/bin/rm -f  wave.vcd
	/bin/rm -f  webtalk_*.backup.jou
	/bin/rm -f  webtalk_*.backup.log
	/bin/rm -f  webtalk.jou
	/bin/rm -f  webtalk.log
	/bin/rm -f  xelab.log
	/bin/rm -f  xelab.pb
	/bin/rm -fr .Xil
	/bin/rm -f  xsim_*.backup.jou
	/bin/rm -f  xsim_*.backup.log
	/bin/rm -fr xsim.dir
	/bin/rm -f  xsim.jou
	/bin/rm -f  xsim.log
	/bin/rm -f  xvlog.log
	/bin/rm -f  xvlog.pb

cleanup clobber: clean

cleanupall: cleanup

.PHONY: all elab sim wave clean clobber cleanup cleanupall
