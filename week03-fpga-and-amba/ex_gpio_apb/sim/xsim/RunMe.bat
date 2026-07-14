@ECHO OFF

CALL C:\Xilinx\Vivado\2020.2\settings64.bat

cmd.exe /c xelab -prj xsim.prj -debug typical top -s top

cmd.exe /c xsim top -t xsim_run.tcl

:END
PAUSE -1
