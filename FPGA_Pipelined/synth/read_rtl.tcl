# Source inside Design Compiler. Core package first; optional SRAM-system RTL
# follows. No testbench, functional memory model, or vendor simulation HDL.
if {![llength [info commands ::synthcfg::rtl_sources]]} {
    source [file join [file dirname [info script]] config.tcl]
}
set rtl_files [synthcfg::rtl_sources]
if {![analyze -format sverilog $rtl_files]} { error "RTL analysis failed" }
