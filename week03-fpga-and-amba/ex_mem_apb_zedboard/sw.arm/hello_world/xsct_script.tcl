#
# $ xsct xsct_script.tcl -x hw.xsa -b design.bit -e prog.elf
#
set arglen [llength $argv]
set index 0
while {$index < $arglen} {
    set arg [lindex $argv $index]
    switch -exact $arg {
        -h { puts "$argv0 -h -x hw.xsa -b design.bit -e prog.elf"
             exit }
        -b { set args($arg) [lindex $argv [incr index]] }
        -e { set args($arg) [lindex $argv [incr index]] }
        -x { set args($arg) [lindex $argv [incr index]] }
        -w { set args($arg) [lindex $argv [incr index]] }
        -a { set args($arg) [lindex $argv [incr index]] }
        default  { puts "$arg not known"
                   exit }
    }
    incr index
}

if {[info exists args(-b)]} {
    puts "BIT=$args(-b)"
}
if {[info exists args(-e)]} {
    puts "ELF=$args(-e)"
}
if {[info exists args(-x)]} {
    puts "XSA=$args(-x)"
} else {
    puts "XSA must be given with -x option"
    exit
}
if {[info exists args(-w)]} {
    puts "WORKSPACE=$args(-w)"
}
if {[info exists args(-a)]} {
    puts "APP_NAME=$args(-w)"
}

if {0} {
  # connect to a local or remote hw_server
  connect -url tcp:127.0.0.1:3121
  #connect -host localhost -port 3121
  # list connections
  connect -list
  # list all targets
  targets
  # select a target
} else {
  connect
  targets -set -nocase -filter {name =~"APU*"}
}

set msg [fpga -state]
puts ${msg}

if {[info exists args(-b)]} {
    if {[info exists args(-b)]== 0} {
        puts "bitstream not found.""
    } else {
        rst -system
        after 1000
        # configure FPGA
        fpga -file $args(-b)
        set msg [fpga -state]
        puts ${msg}
       #targets -set -nocase -filter {name =~"APU*"}
       #loadhw -hw $args(-x)\
       #       -mem-ranges [list {0x40000000 0xbfffffff}] -regs
       #configparams force-mem-access 1
    }
}

# fpga -state => FPGA is configured
if {[info exists args(-e)]} {
    if {[info exists args(-e)]== 0} {
        puts "ELF not found."
    } else {
        loadhw -hw $args(-x)\
               -mem-ranges [list {0x40000000 0xbfffffff}] -regs
        configparams force-mem-access 1
        targets -set -nocase -filter {name =~"APU*"}
        source $args(-w)/$args(-a)/_ide/psinit/ps7_init.tcl
        ps7_init
        ps7_post_config
        targets -set -nocase -filter {name =~ "*A9*#0"}
        dow $args(-e)
        con
    }
}
