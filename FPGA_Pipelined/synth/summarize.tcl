# Pure Tcl summary generation from Design Compiler's existing text reports.
# Can be sourced by the driver or executed with tclsh to recover a failed
# postprocessing run. It never loads a DDC, DB, or HDL and never runs synthesis.
namespace eval synthsummary {
    proc read_text {path} {
        if {![file isfile $path]} { error "Missing report/input: $path" }
        set channel [open $path r]
        set text [read $channel]
        close $channel
        return $text
    }
    proc area_metric {text label} {
        set pattern [format {^[ \t]*%s[ \t]+([^\r\n]+)} $label]
        if {![regexp -line $pattern $text match value]} {
            error "Missing '$label' in area.rpt"
        }
        set value [string trim $value]
        if {![string is double -strict $value] || $value < 0 || $value >= 1.0e20} {
            error "Invalid '$label' value in area.rpt: '$value'"
        }
        return $value
    }
    proc worst_reported_slack {text} {
        set matches [regexp -all -inline {slack \((MET|VIOLATED)\)\s+([-+0-9.eE]+)} $text]
        if {![llength $matches]} {
            if {[regexp -nocase {no (timing )?paths} $text]} { return N/A }
            error "Timing report contains neither reported slack nor an explicit no-paths result"
        }
        set worst ""
        foreach {match condition value} $matches {
            if {![string is double -strict $value]} { error "Invalid slack: $value" }
            if {$worst eq "" || $value < $worst} { set worst $value }
        }
        return $worst
    }
    proc metrics {run} {
        set area [read_text [file join $run reports area.rpt]]
        if {![regexp -line {^Design\s*:\s*(\S+)} $area match design] || $design ne $::synthcfg::top} {
            error "area.rpt design does not match configured top $::synthcfg::top"
        }
        set total [area_metric $area {Total cell area:}]
        set macro [area_metric $area {Macro/Black Box area:}]
        set macro_count [area_metric $area {Number of macros/black boxes:}]
        set expected [expr {$::synthcfg::top eq "cpu_sram_system" ? 2 : 0}]
        if {$macro_count != $expected || $macro > $total} {
            error "Inconsistent area report: macros=$macro_count, expected=$expected, macro area=$macro, total=$total"
        }
        return [list \
            top $::synthcfg::top corner TT_1.8V_25C \
            predict $::synthcfg::predict prefetch $::synthcfg::prefetch \
            target_period_ns $::synthcfg::period_ns \
            target_frequency_MHz [expr {1000.0 / $::synthcfg::period_ns}] \
            worst_setup_slack_ns [worst_reported_slack [read_text [file join $run reports timing_setup.rpt]]] \
            worst_hold_slack_ns [worst_reported_slack [read_text [file join $run reports timing_hold.rpt]]] \
            leaf_cell_area $total sram_area $macro logic_area [expr {$total - $macro}] \
            sram_instances $macro_count \
            reg2reg_setup_slack_ns [worst_reported_slack [read_text [file join $run reports timing_setup_reg2reg.rpt]]] \
            area_source DC_report_area timing_source DC_report_timing \
            power NOT_MEASURED timing_signoff NOT_PERFORMED]
    }
    proc write_summary {run {recovered 0}} {
        set values [metrics $run]
        set stem [expr {$recovered ? "summary-recovered" : "summary"}]
        set destination [file join $run reports ${stem}.tsv]
        if {[file exists $destination]} { error "Refusing to overwrite existing summary: $destination" }
        set original_status [string trim [read_text [file join $run status.txt]]]
        set channel [open $destination w]
        puts $channel "metric\tvalue"
        foreach {name value} $values { puts $channel "$name\t$value" }
        puts $channel "summary_mode\t[expr {$recovered ? {recovered_reports} : {in_flow}}]"
        if {$recovered} { puts $channel "original_flow_status\t$original_status" }
        close $channel
        set channel [open [file join $run reports ${stem}-notes.txt] w]
        puts $channel "Generated UTC: [clock format [clock seconds] -gmt 1 -format %Y-%m-%dT%H:%M:%SZ]"
        puts $channel "Area comes from report_area totals, including all macro/black-box area."
        puts $channel "Slack is the minimum among paths listed in the saved setup/hold reports."
        puts $channel "Numeric precision is limited by those text reports."
        puts $channel "This summary does not certify timing coverage or physical signoff."
        puts $channel "Flow status observed: $original_status; this procedure does not modify it."
        close $channel
        return $destination
    }
}

# Executing this file with tclsh is recovery only. Sourcing it in DC just defines
# the procedures; the normal driver calls write_summary after saving reports.
if {[info exists ::argv0] && [file normalize [info script]] eq [file normalize $::argv0]} {
    if {[catch {
        if {[llength $argv] != 1} { error "Usage: tclsh synth/summarize.tcl RUN_DIR" }
        set run [file normalize [lindex $argv 0]]
        source [file join [file dirname [info script]] config.tcl]
        source [file join $run resolved_config.tcl]
        if {$synthcfg::run_dir ne $run} { error "RUN_DIR does not match resolved_config.tcl" }
        set summary [synthsummary::write_summary $run 1]
        puts "Summary recovered from existing reports: $summary"
        puts "Original run status and outputs are unchanged. No Design Compiler was run."
    } message]} {
        puts stderr "Summary recovery failed: $message"
        exit 1
    }
}
