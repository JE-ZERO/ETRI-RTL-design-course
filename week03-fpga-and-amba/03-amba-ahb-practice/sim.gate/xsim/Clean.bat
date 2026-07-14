@ECHO OFF

DEL   /Q    top.wdb
DEL   /Q    wave.vcd
DEL   /Q    webtalk_*.backup.jou
DEL   /Q    webtalk_*.backup.log
DEL   /Q    webtalk.jou
DEL   /Q    webtalk.log
DEL   /Q    xelab.log
DEL   /Q    xelab.pb
DEL   /Q    xsim_*.backup.jou
DEL   /Q    xsim_*.backup.log
DEL   /Q    xsim.jou
DEL   /Q    xsim.log
DEL   /Q    xvlog.log
DEL   /Q    xvlog.pb
RMDIR /Q/S  xsim.dir
RMDIR /Q/S  .Xil
