@ECHO OFF

IF EXIST wave.vcd (
    C:\work\software\gtkwave-3.3.90-bin-win64\gtkwave64\bin\gtkwave.exe wave.vcd
) ELSE (
    ECHO "Cannot find wave.vcd."
    PAUSE
)
