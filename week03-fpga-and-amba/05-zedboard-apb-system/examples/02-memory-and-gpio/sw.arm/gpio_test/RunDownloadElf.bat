@ECHO OFF

CALL C:\Xilinx\Vivado\2020.2\settings64.bat
CALL C:\Xilinx\Vitis\2020.2\settings64.bat

SET DIR_HW=..\..\hw\impl.zed
SET DIR_WORKSPACE=..\workspace.zed
SET DIR_XSA=%DIR_HW%\xsa
SET DESIGN_NAME=design_zed
SET PATH_XSA=%DIR_XSA%\%DESIGN_NAME%_wrapper.xsa
SET DIR_SRC=src
SET APP_NAME=gpio_test
SET BITSTREAM=%DIR_WORKSPACE%\%DESIGN_NAME%_wrapper\hw\%DESIGN_NAME%_wrapper.bit
SET APP_ELF=%DIR_WORKSPACE%\%APP_NAME%\Debug\%APP_NAME%.elf

IF NOT EXIST %PATH_XSA% (
   ECHO "%PATH_XSA% does not exist."
   GOTO END
)
IF NOT EXIST %DIR_WORKSPACE% (
   ECHO "%DIR_WORKSPACE% does not exist."
   GOTO END
)
IF NOT EXIST %APP_ELF% (
   ECHO "%APP_ELF% does not exist."
   GOTO END
)
xsct xsct_script.tcl -x %PATH_XSA% -w %DIR_WORKSPACE% -a %APP_NAME% -e %APP_ELF%

:END
    PAUSE -1
