# Run with tclsh: checks inputs/configuration without starting Design Compiler.
if {[catch {
    source [file join [file dirname [info script]] config.tcl]
    synthcfg::validate
    foreach name {config.tcl read_rtl.tcl libraries.tcl constraints.sdc run_synth.tcl summarize.tcl prepare.tcl check_setup.tcl} {
        set path [synthcfg::require_file [file join $synthcfg::project_dir synth $name]]
        set channel [open $path r]
        set text [read $channel]
        close $channel
        if {![info complete $text]} { error "Incomplete Tcl syntax in $path" }
    }
    synthcfg::describe stdout
    puts "RTL files checked: [llength [synthcfg::rtl_sources]]"
    puts "SETUP_CHECKED: paths, numeric settings, source order and Tcl completeness only."
    puts "No Design Compiler, RTL compilation, or synthesis was run."
} message]} {
    puts stderr "Setup check failed: $message"
    exit 1
}
