@ECHO OFF

CALL C:\Xilinx\Vivado\2020.2\settings64.bat

IF "%~1"=="" GOTO :CMD
IF /I "%1"=="GUI" GOTO :GUI

:CMD
    C:\Windows\System32\cmd.exe /c vivado -mode tcl -source vivado_syn.tcl
    GOTO :END

:GUI
    C:\Windows\System32\cmd.exe /c vivado -mode gui -source vivado_syn.tcl
    GOTO :END

:END
   PAUSE -1
