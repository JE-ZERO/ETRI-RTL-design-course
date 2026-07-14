@ECHO OFF

CALL C:\Xilinx\Vivado\2020.2\settings64.bat

SET VIVADO=vivado
SET DESIGN=zed
SET DESIGN_NAME=design_%DESIGN%
SET PROJECT_NAME=project_%DESIGN%
SET PROJECT_DIR=%PROJECT_NAME%
SET SOURCE=run_vivado.tcl
SET PART=xc7z020clg484-1
SET BOARD=em.avnet.com:zed:part0:1.4
SET DIR_IP=..\..\..
SET GUI=1

::ECHO %VIVADO%
::ECHO %DESIGN%
::ECHO %DESIGN_NAME%
::ECHO %PROJECT_NAME%
::ECHO %PROJECT_DIR%
::ECHO %SOURCE%
::ECHO %PART%
::ECHO %BOARD%
::ECHO %DIR_IP%
::ECHO %GUI%

IF "%GUI%"=="1" (
    ECHO %VIVADO% -mode gui -source %SOURCE%
    %VIVADO% -mode gui -source %SOURCE%
) ELSE IF "%GUI%"=="0" (
    ECHO %VIVADO% -mode batch -source %SOURCE%
    %VIVADO% -mode batch -source %SOURCE%
)

:END
    PAUSE -1
