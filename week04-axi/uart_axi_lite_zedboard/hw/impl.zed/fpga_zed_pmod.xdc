#--------------------------------------------------------
# JA PMOD - Bank 13
#    +--+--+--+--+--+--+
#    |V |G |4 |3 |2 |1 | upper
#    +--+--+--+--+--+--+
#    |V |G |10|9 |8 |7 | lower
#  --+--+--+--+--+--+--+--
#  -----------------------PCB
#
# USBUART
#
#   VCC  GND CTS TXD RXD RTS
#             ||  /\  ||  / #     ||  ||  \/  ||  \/  ||
#   +------------------------+
#   |  6   5   4   3   2   1 |
#
set_property PACKAGE_PIN Y11 [get_ports uart_cts]
set_property PACKAGE_PIN AA11 [get_ports uart_txd]
set_property PACKAGE_PIN Y10 [get_ports uart_rxd]
set_property PACKAGE_PIN AA9 [get_ports uart_rts]
#set_property PACKAGE_PIN AB11 [get_ports {JA7}];  # "JA7"
#set_property PACKAGE_PIN AB10 [get_ports {JA8}];  # "JA8"
#set_property PACKAGE_PIN AB9  [get_ports {JA9}];  # "JA9"
#set_property PACKAGE_PIN AA8  [get_ports {JA10}]; # "JA10"

set_property IOSTANDARD LVCMOS33 [get_ports uart_*]
# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard.
#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];


