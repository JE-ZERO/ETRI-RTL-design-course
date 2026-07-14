@ECHO OFF

xelab -prj xsim.prj -debug typical top -s top
xsim top -t xsim_run.tcl

:END
PAUSE
