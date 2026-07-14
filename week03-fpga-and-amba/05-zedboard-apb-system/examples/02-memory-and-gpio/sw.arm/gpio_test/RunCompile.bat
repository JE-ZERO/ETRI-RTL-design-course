@ECHO OFF

CALL C:\Xilinx\Vivado\2020.2\settings64.bat

SET DIR_HW=..\..\hw\impl.zed
SET DIR_WORKSPACE=..\workspace.zed
SET DIR_XSA=%DIR_HW%\xsa
SET DESIGN_NAME=design_zed
SET PATH_XSA=%DIR_XSA%\%DESIGN_NAME%_wrapper.xsa
SET DIR_SRC=src
SET APP_NAME=gpio_test
SET BITSTREAM=%DIR_WORKSPACE%\%DESIGN_NAME%_wrapper\hw\%DESIGN_NAME%_wrapper.bit

IF NOT EXIST %PATH_XSA% (
   ECHO "%PATH_XSA% does not exist."
   GOTO END
)
IF EXIST %DIR_WORKSPACE% (
   RMDIR /S/Q %DIR_WORKSPACE%
)

xsct platform.tcl

:END
    PAUSE -1
