set hdlin_translate_off_skip_text "TRUE"
set edifout_netlist_only "TRUE"
set verilogout_no_tri true
set plot_command {lpr -Plw}
set hdlin_auto_save_templates "TRUE"
set compile_fix_multiple_port_nets "TRUE"

set DESIGN "polar_decoder"
set CLOCK "clk"
set CLOCK_PERIOD 10.0

sh rm -rf Netlist
sh rm -rf Report
sh mkdir Netlist
sh mkdir Report

read_file -format verilog ./flist.v
current_design $DESIGN
link

create_clock $CLOCK -period $CLOCK_PERIOD
set_ideal_network -no_propagate $CLOCK
set_dont_touch_network [get_ports $CLOCK]

# ========== Do not modified block ================= #
set_clock_uncertainty  0.1  $CLOCK
set_input_delay  1.0 -clock $CLOCK [remove_from_collection [all_inputs] [get_ports $CLOCK]]
set_output_delay 1.0 -clock $CLOCK [all_outputs]
set_drive 1    [all_inputs]
set_load  0.05 [all_outputs]

set_operating_conditions -max_library slow -max slow
set_wire_load_model -name tsmc13_wl10 -library slow
# =================================================== #
check_design
uniquify
set_fix_multiple_port_nets -all -buffer_constants  [get_designs *]
set_fix_hold [all_clocks]

compile

report_area > Report/$DESIGN\.area
report_power > Report/$DESIGN\.power
report_timing -max_path 20 -delay_type max > Report/$DESIGN\.max.timing
report_timing -max_path 20 -delay_type min > Report/$DESIGN\.min.timing

set bus_inference_style "%s\[%d\]"
set bus_naming_style "%s\[%d\]"
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed "a-z A-Z 0-9 _" -max_length 255 -type cell
define_name_rules name_rule -allowed "a-z A-Z 0-9 _[]" -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive

write -format verilog -hierarchy -output Netlist/$DESIGN\_syn.v
write_sdf -version 2.1 -context verilog Netlist/$DESIGN\_syn.sdf
write_sdc Netlist/$DESIGN\_syn.sdc
