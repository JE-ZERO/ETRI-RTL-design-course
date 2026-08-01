# ----------------------------------------------------------------------------
# Ultra96 Training Kit constraints
# Only the signals used by this UART multiplier project are enabled.
#
# Bank 26 VCCO = 1.8 V
# Bank 65 VCCO = 1.2 V
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# High-speed expansion connector / Bank 65
# Unused Pmod C pins are left commented out.
# ----------------------------------------------------------------------------
# set_property PACKAGE_PIN F1 [get_ports {pmod_c[1]}]
# set_property PACKAGE_PIN G1 [get_ports {pmod_c[0]}]
# set_property PACKAGE_PIN E3 [get_ports {pmod_c[3]}]
# set_property PACKAGE_PIN E4 [get_ports {pmod_c[2]}]
# set_property PACKAGE_PIN D1 [get_ports {pmod_c[5]}]
# set_property PACKAGE_PIN E1 [get_ports {pmod_c[4]}]
# set_property PACKAGE_PIN C3 [get_ports {pmod_c[7]}]
# set_property PACKAGE_PIN D3 [get_ports {pmod_c[6]}]

# Pmod96 onboard 40 MHz oscillator
set_property PACKAGE_PIN L2 [get_ports {clk_40m}]
set_property IOSTANDARD LVCMOS12 [get_ports {clk_40m}]
create_clock -name clk_40m -period 25.000 [get_ports {clk_40m}]

# ----------------------------------------------------------------------------
# Low-speed expansion connector / Bank 26
# Pmod A upper row:
#   pin 2 = F8 = FPGA TXD -> Pmod USBUART RXD
#   pin 3 = F7 = Pmod USBUART TXD -> FPGA RXD
# ----------------------------------------------------------------------------
# set_property PACKAGE_PIN D7 [get_ports {pmod_a[0]}]
set_property PACKAGE_PIN F8 [get_ports {txd}]
set_property PACKAGE_PIN F7 [get_ports {rxd}]
# set_property PACKAGE_PIN G7 [get_ports {pmod_a[3]}]
# set_property PACKAGE_PIN F6 [get_ports {pmod_a[4]}]
# set_property PACKAGE_PIN G5 [get_ports {pmod_a[5]}]
# set_property PACKAGE_PIN A6 [get_ports {pmod_a[6]}]
# set_property PACKAGE_PIN A7 [get_ports {pmod_a[7]}]

# Pmod B is unused.
# set_property PACKAGE_PIN G6 [get_ports {pmod_b[0]}]
# set_property PACKAGE_PIN E6 [get_ports {pmod_b[1]}]
# set_property PACKAGE_PIN E5 [get_ports {pmod_b[2]}]
# set_property PACKAGE_PIN D6 [get_ports {pmod_b[3]}]
# set_property PACKAGE_PIN D5 [get_ports {pmod_b[4]}]
# set_property PACKAGE_PIN C7 [get_ports {pmod_b[5]}]
# set_property PACKAGE_PIN B6 [get_ports {pmod_b[6]}]
# set_property PACKAGE_PIN C5 [get_ports {pmod_b[7]}]

# Bluetooth flow-control pins are unused.
# set_property PACKAGE_PIN B7 [get_ports BT_ctsn]
# set_property PACKAGE_PIN B5 [get_ports BT_rtsn]

set_property IOSTANDARD LVCMOS18 [get_ports {rxd txd}]
set_property DRIVE 4 [get_ports {txd}]
set_property SLEW SLOW [get_ports {txd}]
