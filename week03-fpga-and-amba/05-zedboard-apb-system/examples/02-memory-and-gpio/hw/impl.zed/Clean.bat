@ECHO OFF

DEL   /Q    vivado.jou
DEL   /Q    vivado.log
DEL   /Q    vidado_*.jou vivado_*.*.jou
DEL   /Q    vivado_*.log vivado_*.*.log
DEL   /Q    vivado_*.str vivado_*.*.str
DEL   /Q    design_zed_wrapper.bit
DEL   /Q    design_zed_wrapper.ltx
DEL   /Q    AddressMap.cvs AddressMapGui.cvs
DEL   /Q    design_zed.pdf
RMDIR /S/Q  .Xil
RMDIR /S/Q  project_zed
RMDIR /S/Q  xsa

::PAUSE -1
