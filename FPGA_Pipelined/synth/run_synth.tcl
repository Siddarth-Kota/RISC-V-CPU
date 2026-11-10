# Design Compiler entrypoint. Use the prepared snapshot via make synth.
# A completed flow is not a timing-closure or physical-signoff claim.
source [file join [file dirname [info script]] config.tcl]
namespace eval synthflow {
    variable started 0
    proc text_file {path text} {
        set channel [open $path w]
        puts $channel $text
        close $channel
    }
    proc dc_ok {description command} {
        set result [uplevel 1 $command]
        if {$result ne "1"} { error "$description failed; inspect logs/console.log" }
        return $result
    }
    proc report {name command} {
        set path [file join $::synthcfg::run_dir reports $name]
        uplevel #0 [list redirect -file $path $command]
    }
    proc macro_instances {} {
        return [get_cells -quiet -hierarchical -filter "ref_name == $::synthcfg::sram_cell"]
    }
    proc check_macros {} {
        set expected [expr {$::synthcfg::top eq "cpu_sram_system" ? 2 : 0}]
        set count [sizeof_collection [macro_instances]]
        if {$count != $expected} { error "Expected $expected SRAM macro instances, found $count" }
    }
    proc run {} {
        set prepared [file join [pwd] .. resolved_config.tcl]
        if {![file isfile $prepared]} {
            error "Start from the prepared work/ directory using command.sh or make synth"
        }
        uplevel #0 [list source $prepared]
        ::synthcfg::validate
        set run $::synthcfg::run_dir
        set status_file [file join $run status.txt]
        if {[string trim [read_status $status_file]] ne "PREPARED"} {
            error "This run was already started; create a new RUN_ID instead of overwriting it"
        }
        set ::synthflow::started 1
        text_file $status_file RUNNING
        puts "Synthesis top: $::synthcfg::top; target period: $::synthcfg::period_ns ns"
        puts "Nominal TT baseline; synthesis estimates only."

        set_app_var sh_command_log_file [file join $run logs command.log]
        set_svf [file join $run outputs $::synthcfg::top.svf]
        define_design_lib WORK -path [file join $run work WORK]
        set_host_options -max_cores $::synthcfg::max_cores
        uplevel #0 [list source [file join $::synthcfg::project_dir synth libraries.tcl]]
        uplevel #0 [list source [file join $::synthcfg::project_dir synth read_rtl.tcl]]
        dc_ok elaboration [list elaborate $::synthcfg::top \
            -parameters "PREDICT=$::synthcfg::predict,PREFETCH=$::synthcfg::prefetch"]
        set built_top [current_design]
        if {$built_top ne $::synthcfg::top} {
            dc_ok top_rename [list rename_design $built_top $::synthcfg::top]
        }
        current_design $::synthcfg::top
        dc_ok link {link}
        uniquify
        check_macros
        set macros [macro_instances]
        if {[sizeof_collection $macros]} { set_dont_touch $macros true }
        report check_design_pre.rpt {check_design}
        dc_ok design_check {check_design -no_warnings}

        # Single-corner baseline. The SRAM's own nominal condition is Typ, also
        # 1.8 V / 25 C. No SS/FF pairing or OCV is inferred from the lab example.
        set_operating_conditions $::synthcfg::std_opcond -library $::synthcfg::std_lib
        set_wire_load_mode top
        uplevel #0 [list source [file join $::synthcfg::project_dir synth constraints.sdc]]
        set_fix_multiple_port_nets -all -buffer_constants
        report units.rpt {report_units}
        report standard_library.rpt [list report_lib -operating_condition $::synthcfg::std_lib]
        if {$::synthcfg::top eq "cpu_sram_system"} {
            report sram_library.rpt [list report_lib -operating_condition $::synthcfg::sram_lib]
        }
        report check_timing_pre.rpt {check_timing -verbose}
        report design_pre.rpt {report_design}

        if {$::synthcfg::compile_mode eq "ultra"} {
            dc_ok compile_ultra {compile_ultra -no_autoungroup -no_boundary_optimization}
        } else {
            dc_ok compile {compile -map_effort high}
        }
        current_design $::synthcfg::top
        check_macros
        set latches [all_registers -level_sensitive -cells]
        if {[sizeof_collection $latches]} { error "Unexpected inferred/mapped latches remain" }
        set unmapped [get_cells -quiet -hierarchical -filter {ref_name =~ GTECH* || ref_name == SEQGEN}]
        if {[sizeof_collection $unmapped]} { error "Generic unmapped cells remain after compile" }
        report check_design_post.rpt {check_design}
        dc_ok mapped_design_check {check_design -no_warnings}
        change_names -rules verilog -hierarchy

        report design.rpt {report_design}
        report clock.rpt {report_clock}
        report check_timing.rpt {check_timing -verbose}
        report constraints.rpt {report_constraint -all_violators -verbose}
        report area.rpt {report_area -hierarchy}
        report references.rpt {report_reference -hierarchy}
        report timing_setup.rpt {report_timing -delay_type max -max_paths 20 -path_type full_clock_expanded -nets -transition_time -capacitance}
        report timing_hold.rpt {report_timing -delay_type min -max_paths 20 -path_type full_clock_expanded -nets -transition_time -capacitance}
        set clock [get_clocks $::synthcfg::clock_name]
        foreach delay_type {max min} {
            report rising_to_falling_${delay_type}.rpt [list report_timing \
                -rise_from $clock -fall_to $clock -delay_type $delay_type \
                -max_paths 10 -path_type full_clock_expanded]
            report falling_to_rising_${delay_type}.rpt [list report_timing \
                -fall_from $clock -rise_to $clock -delay_type $delay_type \
                -max_paths 10 -path_type full_clock_expanded]
        }

        write -hierarchy -format verilog -output [file join $run outputs $::synthcfg::top.gate.v]
        write -hierarchy -format ddc -output [file join $run outputs $::synthcfg::top.ddc]
        write_sdc [file join $run outputs $::synthcfg::top.sdc]
        # This SDF is based on synthesis timing, not extracted routed parasitics.
        write_sdf [file join $run outputs $::synthcfg::top.sdf]

        # DC has already calculated complete area/timing totals. Summarize its
        # reports without relying on instance-area attributes or scoped lookups.
        uplevel #0 [list source [file join $::synthcfg::project_dir synth summarize.tcl]]
        ::synthsummary::write_summary $run
        set_svf -off
        text_file $status_file COMPLETED
        puts "SYNTHESIS_COMPLETED: outputs and reports saved in $run"
        puts "Review check_timing, constraints, setup/hold and half-cycle reports; completion does not imply timing closure."
    }
    proc read_status {path} {
        set channel [open $path r]
        set text [read $channel]
        close $channel
        return $text
    }
}
if {[catch {synthflow::run} message options]} {
    if {$message eq ""} {
        set message "Design Compiler rejected a command; see the preceding Error message"
    }
    puts stderr "SYNTHESIS_FAILED: $message"
    if {[dict exists $options -errorinfo]} { puts stderr [dict get $options -errorinfo] }
    if {$synthflow::started && $synthcfg::run_dir ne ""} {
        synthflow::text_file [file join $synthcfg::run_dir status.txt] FAILED
    }
    exit 1
}
exit 0
