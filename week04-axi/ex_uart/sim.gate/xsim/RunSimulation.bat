@ECHO OFF

SET VIVADO_VERSION=2020.2

echo "C:\Xilinx\Vivado\%VIVADO_VERSION%\settings64.bat"

CALL C:\Xilinx\Vivado\%VIVADO_VERSION%\settings64.bat
C:\Windows\System32\cmd.exe /c xvlog -d SIM -d VCD -d VIVADO -d GATESIM ^
	-i ../../bench/verilog ^
	-i ../../syn/vivado.z7 ^
           C:/Xilinx/Vivado/%VIVADO_VERSION%/data/verilog/src/glbl.v ^
           ../../bench/verilog/top.v ^
           ../../bench/verilog/tester.v ^
           ../../syn/vivado.z7/memory.vm
C:\Windows\System32\cmd.exe /c xelab -debug typical -L secureip -L unisims_ver -L unimacro_ver top glbl -s top

IF "%~1"=="" GOTO :CMD
IF /I "%1"=="GUI" GOTO :GUI

:CMD
    cmd.exe /c xsim top -t xsim_run.tcl
    GOTO :END

:GUI
    # select "Window-->Waveform"
    # run all
    xsim top -gui
    GOTO :END

:END
   PAUSE -1
