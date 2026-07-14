@ECHO OFF
SETLOCAL

REM Always resolve xsim.prj and source paths relative to this batch file.
CD /D "%~dp0"

REM Load the Vivado command-line environment when xelab is not already in PATH.
WHERE xelab >NUL 2>&1
IF ERRORLEVEL 1 (
    IF EXIST "C:\Xilinx\Vivado\2020.2\settings64.bat" (
        CALL "C:\Xilinx\Vivado\2020.2\settings64.bat"
    ) ELSE (
        ECHO ERROR: xelab was not found in PATH and Vivado settings64.bat was not found.
        ECHO Run this file from a Vivado Command Prompt or update the Vivado path.
        GOTO :FAIL
    )
)

CALL xelab -prj xsim.prj -debug typical top -s top
IF ERRORLEVEL 1 (
    ECHO ERROR: XSim elaboration failed. See xelab.log above.
    GOTO :FAIL
)

IF /I "%~1"=="GUI" GOTO :GUI

:CMD
CALL xsim top -t xsim_run.tcl
IF ERRORLEVEL 1 (
    ECHO ERROR: XSim simulation failed. See xsim.log above.
    GOTO :FAIL
)
GOTO :SUCCESS

:GUI
REM In XSim, select Window -^> Waveform and then run all.
CALL xsim top -gui
IF ERRORLEVEL 1 GOTO :FAIL
GOTO :SUCCESS

:FAIL
ECHO.
ECHO Simulation did not complete successfully.
PAUSE
EXIT /B 1

:SUCCESS
ECHO.
ECHO Simulation completed successfully.
PAUSE
EXIT /B 0
