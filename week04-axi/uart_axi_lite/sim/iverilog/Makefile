#------------------------------------------------------------------
SHELL    = /bin/sh
MAKEFILE = Makefile
#--------------------------------------------------------
ifeq ($(MAKECMDGOALS),$(findstring $(MAKECMDGOALS), "" "all" "elab" "sim"))
    ifeq (, $(shell which iverilog))
       $(error iverilog not found.)
    endif
endif
#--------------------------------------------------------
ILOG	 = iverilog
ISIM	 = vvp
#--------------------------------------------------------
TOP	  = top
DIR_BENCH = ../../bench/verilog
DIR_RTL   = ../../rtl/verilog
#--------------------------------------------------------
all: compile simulate

compile:
	($(ILOG) -g2012 -o $(TOP).vvp -s $(TOP)\
		-I$(DIR_BENCH)\
		-I$(DIR_RTL)\
		$(DIR_BENCH)/top.sv\
		$(DIR_BENCH)/tester.sv\
		$(DIR_RTL)/uart_axi_lite.v\
		|| exit -1) 2>&1 | tee compile.log


simulate: compile
	$(ISIM) -l vvp.log $(TOP).vvp

#--------------------------------------------------------
clean:
	/bin/rm -f  $(TOP).vvp
	/bin/rm -f  compile.log
	/bin/rm -f  wave.vcd
	/bin/rm -f  vvp.log
	/bin/rm -f  result.bmp

cleanup clobber: clean

cleanupall distclean: cleanup
#--------------------------------------------------------
