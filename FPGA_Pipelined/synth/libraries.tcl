# Adapted from the lab's step_define_library/step_environment scripts.
# This baseline uses one standard-cell TT library, plus the matching TT SRAM.
# It deliberately does not inherit the lab flow's SS/FF analysis conditions.
set_app_var alib_library_analysis_path [file join $synthcfg::run_dir alib]
set_app_var search_path [concat [get_app_var search_path] \
    [list $synthcfg::project_dir [file dirname $synthcfg::std_db] [file dirname $synthcfg::sram_db]]]
set_app_var target_library [list $synthcfg::std_db]
set library_links [list * $synthcfg::std_db]
if {$synthcfg::top eq "cpu_sram_system"} { lappend library_links $synthcfg::sram_db }
set_app_var link_library $library_links
# The first get_libs/get_lib_cells query can load link_library automatically.
# Read explicitly only when a required library is still absent.
if {![sizeof_collection [get_libs -quiet $synthcfg::std_lib]]} {
    read_db $synthcfg::std_db
}
if {[sizeof_collection [get_libs -quiet $synthcfg::std_lib]] != 1} {
    error "Expected standard-cell library $synthcfg::std_lib was not loaded"
}
if {$synthcfg::top eq "cpu_sram_system"} {
    if {![sizeof_collection [get_libs -quiet $synthcfg::sram_lib]]} {
        read_db $synthcfg::sram_db
    }
    if {[sizeof_collection [get_lib_cells -quiet $synthcfg::sram_lib/$synthcfg::sram_cell]] != 1} {
        error "SRAM timing cell $synthcfg::sram_lib/$synthcfg::sram_cell was not loaded"
    }
}
set scan_cells [get_lib_cells -quiet $synthcfg::std_lib/SDFF*]
if {[sizeof_collection $scan_cells]} { set_dont_use $scan_cells }
