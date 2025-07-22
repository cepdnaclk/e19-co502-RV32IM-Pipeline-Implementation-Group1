set_current_mismatch_config auto_fix 
set_attribute [get_mismatch_types missing_logical_reference] current_repair(auto_fix) create_blackbox
set CORES 8
set_host_options -max_cores $CORES

set_app_options -list { plan.macro.allow_unmapped_design true}

set search_path "* ./ ./INPUT//ndm ../../cpu"
create_lib cpu_LIB -ref_libs "ts16ncfllogl16hdh090f.ndm  ts16ncfllogl16hdl090f.ndm  ts16ncfslogl16hdh090f.ndm  ts16ncfslogl16hdl090f.ndm " -technology ./INPUT/ts16ncfslogl16hdl090f_m11f2f1f3f2f0f2_UTRDL.tf

analyze -f sv -vcs "-f src.f "
elaborate cpu
set_top_module cpu

source tz_setup.tcl

rtl_opt
save_lib cpu_LIB
save_block cpu_top_block

set_rtl_power_analysis_options -scenario func@cworst -design cpu -strip_path cpu_tb/cpu_inst -fsdb "../../cpu/novas.fsdb"  -output_dir TZ_OUTDIR
export_power_data

report_power > "results/report_power.txt
report_area > "results/report_area.txt
report_timing > "results/report_timing.txt


exit
