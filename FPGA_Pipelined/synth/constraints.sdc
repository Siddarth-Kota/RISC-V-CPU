# Nominal pre-layout baseline; I/O values are recorded experimental assumptions.
# No false paths, multicycle paths, case analysis, or generated clocks are used.
set clock_port [get_ports clk]
if {[sizeof_collection $clock_port] != 1} { error "Expected exactly one clk port" }
create_clock -name $synthcfg::clock_name -period $synthcfg::period_ns \
    -waveform [list 0.0 [expr {$synthcfg::period_ns / 2.0}]] $clock_port
set clock_object [get_clocks $synthcfg::clock_name]
set_clock_uncertainty -setup $synthcfg::setup_uncertainty_ns $clock_object
set_clock_uncertainty -hold $synthcfg::hold_uncertainty_ns $clock_object
set_clock_transition $synthcfg::clock_transition_ns $clock_object
set_drive 0 $clock_port
set data_inputs [remove_from_collection [all_inputs] $clock_port]
set_driving_cell -library $synthcfg::std_lib -lib_cell $synthcfg::driving_cell $data_inputs
set_input_delay -clock $clock_object -max $synthcfg::input_delay_max_ns $data_inputs
set_input_delay -clock $clock_object -min $synthcfg::input_delay_min_ns $data_inputs
set_output_delay -clock $clock_object -max $synthcfg::output_delay_max_ns [all_outputs]
set_output_delay -clock $clock_object -min $synthcfg::output_delay_min_ns [all_outputs]
set_load $synthcfg::output_load_pf [all_outputs]
# rst_n and core_rst_n remain constrained inputs; host loading and CPU execution
# both remain implemented. Falling-edge adapter paths use the clock waveform.
