@ECHO OFF

IF "%~1"=="" GOTO :CMD
IF /I "%1"=="GUI" GOTO :GUI

:CMD
    cmd.exe /c vivado -mode batch -source vivado_syn.tcl
    GOTO :END

:GUI
    cmd.exe /c vivado -mode gui -source vivado_syn.tcl
    GOTO :END

:END
   PAUSE -1
