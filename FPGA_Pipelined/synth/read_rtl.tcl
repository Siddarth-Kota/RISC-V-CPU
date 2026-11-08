# Run with source from Design Compiler after loading your lab setup.
# Reads the current RTL for analysis only.
set project_dir [file dirname [file dirname [file normalize [info script]]]]
set file_list [open [file join $project_dir rtl files.f] r]
set rtl_files {}
foreach entry [split [read $file_list] "\n"] {
    set entry [string trim $entry]
    if {$entry ne ""} {
        lappend rtl_files [file join $project_dir $entry]
    }
}
close $file_list

analyze -format sverilog $rtl_files
