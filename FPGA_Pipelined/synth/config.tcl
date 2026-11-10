# Pure Tcl configuration shared by preparation and the Design Compiler driver.
# Adapted from the local SiliconJackets library/environment setup. Vendor files
# remain in the lab checkout; no library binaries or models are copied here.
namespace eval synthcfg {
    proc setting {name fallback} {
        if {[info exists ::env(SYNTH_$name)] && $::env(SYNTH_$name) ne ""} {
            return $::env(SYNTH_$name)
        }
        return $fallback
    }

    variable project_dir [file dirname [file dirname [file normalize [info script]]]]
    variable lab_root [file normalize [setting LAB_ROOT [file join $::env(HOME) physical-design-onboarding-F26]]]
    variable top [setting TOP cpu_sram_system]
    variable predict [setting PREDICT 1]
    variable prefetch [setting PREFETCH 0]
    variable period_ns [setting PERIOD_NS 20.0]
    variable setup_uncertainty_ns [setting SETUP_UNCERTAINTY_NS 0.2]
    variable hold_uncertainty_ns [setting HOLD_UNCERTAINTY_NS 0.1]
    variable clock_transition_ns [setting CLOCK_TRANSITION_NS 0.1]
    variable input_delay_max_ns [setting INPUT_DELAY_MAX_NS 2.0]
    variable input_delay_min_ns [setting INPUT_DELAY_MIN_NS 0.2]
    variable output_delay_max_ns [setting OUTPUT_DELAY_MAX_NS 2.0]
    variable output_delay_min_ns [setting OUTPUT_DELAY_MIN_NS 0.2]
    # The lab uses BUFX2 and 0.033442 pF. These are interface assumptions, not
    # measured board/package characteristics. No reset/mode false paths are set.
    variable driving_cell [setting DRIVING_CELL BUFX2]
    variable output_load_pf [setting OUTPUT_LOAD_PF 0.033442]
    variable std_db [file normalize [setting STD_DB [file join $lab_root resources synopsys_libs sky130_tt_1.8_25.db]]]
    variable std_lib [setting STD_LIB sky130_tt_1.8_25]
    variable std_opcond [setting STD_OPCOND tt_1.8_25]
    variable sram_db [file normalize [setting SRAM_DB [file join $lab_root inputs CF_SRAM_1024x32 db CF_SRAM_1024x32_tt_180V_25C.db]]]
    variable sram_lib [setting SRAM_LIB CF_SRAM_1024x32_tt_180V_25C]
    variable sram_cell CF_SRAM_1024x32
    variable compile_mode [setting COMPILE_MODE compile]
    variable max_cores [setting MAX_CORES 4]
    variable clock_name core_clk
    variable run_dir ""
    variable keys {
        project_dir lab_root top predict prefetch period_ns
        setup_uncertainty_ns hold_uncertainty_ns clock_transition_ns
        input_delay_max_ns input_delay_min_ns output_delay_max_ns output_delay_min_ns
        driving_cell output_load_pf std_db std_lib std_opcond
        sram_db sram_lib sram_cell compile_mode max_cores clock_name
    }

    proc require_file {path} {
        if {![file isfile $path] || ![file readable $path]} {
            error "Missing or unreadable input: $path"
        }
        return [file normalize $path]
    }

    proc rtl_sources {} {
        variable project_dir
        variable top
        set manifests [list [file join $project_dir rtl files.f]]
        if {$top eq "cpu_sram_system"} {
            lappend manifests [file join $project_dir rtl system.f]
        }
        set sources {}
        foreach manifest $manifests {
            set channel [open [require_file $manifest] r]
            set entries [split [read $channel] "\n"]
            close $channel
            foreach entry $entries {
                set entry [string trim $entry]
                if {$entry eq "" || [string match {#*} $entry]} { continue }
                if {![string match {rtl/*.sv} $entry]} {
                    error "Expected a project-relative RTL .sv entry in $manifest: $entry"
                }
                set path [require_file [file join $project_dir $entry]]
                if {$path in $sources} { error "Duplicate RTL source: $path" }
                lappend sources $path
            }
        }
        if {[file tail [lindex $sources 0]] ne "signal_pkg.sv"} {
            error "signal_pkg.sv must be the first RTL source"
        }
        return $sources
    }

    proc validate {} {
        variable top
        variable std_db
        variable sram_db
        variable compile_mode
        variable max_cores
        if {$top ni {cpu cpu_sram_system}} { error "SYNTH_TOP must be cpu or cpu_sram_system" }
        foreach key {predict prefetch} {
            variable $key
            if {[set $key] ni {0 1}} { error "SYNTH_[string toupper $key] must be 0 or 1" }
        }
        foreach key {
            period_ns setup_uncertainty_ns hold_uncertainty_ns clock_transition_ns
            input_delay_max_ns input_delay_min_ns output_delay_max_ns output_delay_min_ns output_load_pf
        } {
            variable $key
            set value [set $key]
            if {![string is double -strict $value] || $value < 0 || $value >= 1.0e9} {
                error "$key must be a finite, nonnegative number less than 1e9"
            }
        }
        variable period_ns
        variable clock_transition_ns
        if {$period_ns == 0 || $clock_transition_ns == 0} {
            error "Clock period and transition must be positive"
        }
        foreach kind {input output} {
            variable ${kind}_delay_min_ns
            variable ${kind}_delay_max_ns
            if {[set ${kind}_delay_min_ns] > [set ${kind}_delay_max_ns]} {
                error "$kind delay minimum exceeds maximum"
            }
        }
        if {$compile_mode ni {compile ultra}} { error "SYNTH_COMPILE_MODE must be compile or ultra" }
        if {![string is integer -strict $max_cores] || $max_cores < 1} { error "SYNTH_MAX_CORES must be a positive integer" }
        require_file $std_db
        if {$top eq "cpu_sram_system"} { require_file $sram_db }
        rtl_sources
    }

    proc describe {channel} {
        variable keys
        foreach key $keys { puts $channel [format "%-27s %s" $key [set ::synthcfg::$key]] }
        puts $channel "corner                      nominal TT, 1.8 V, 25 C; not multi-corner signoff"
        puts $channel "interconnect                library-default wire load, top mode; no extracted parasitics"
        puts $channel "power                       not measured by this flow"
    }
}
