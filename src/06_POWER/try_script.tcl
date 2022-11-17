## PrimeTime Script
set_host_options -max_cores 16
set power_enable_analysis TRUE
set power_analysis_mode time_based

read_file -format verilog  ../04_APR/polar_decoder_pr.v
current_design polar_decoder
link

# ===== modified to your max clock freq ===== #
create_clock -period 10.0 [get_ports clk]
set_propagated_clock      [get_clock clk]
# ===== active window ===== #
read_fsdb  -strip_path test/u_polar_decoder ../05_POST/polar_decoder_BASE.fsdb \
          -when {module_en}

update_power
report_power 
report_power -verbose > try_active.power

exit