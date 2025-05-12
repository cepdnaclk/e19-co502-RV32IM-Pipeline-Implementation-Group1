set_app_var power_enable_rtl_analysis true
set_app_var power_enable_analysis true
set_app_var power_enable_multi_rtl_to_gate_mapping true
set_app_var power_enable_advanced_fsdb_reader true

set search_path "*  ./ ./INPUT//ndm ../../cpu/"

#power_rtl_report_register_use_cg_logic_clustering
set_app_var power_rtl_report_register_use_cg_logic_clustering true

compute_metrics -reuse TZ_OUTDIR
read_name_mapping
update_power
update_metrics

# Optional GUI launch
# echo "========== STEP 3: Launch GUI (optional) =========="
# start_gui

echo "========== STEP 4: Report Power =========="

# Group power consumption
report_power -group register > "results/power_register.txt"
report_power -group sequential > "results/power_sequential.txt"
report_power -group combinational > "results/power_combinational.txt"
report_power -group black_box > "results/power_black_box.txt"
report_power -group io_pad > "results/power_io_pad.txt"

report_power -hierarchy -levels 100 -verbose > "results/power_by_module.txt"


echo "========== STEP 5: RTL Metrics =========="

report_rtl_metrics -list > "results/rtl_metrics_list.txt"
report_rtl_metrics -view hier -hier_attributes {gated_registers icg_cells latch_cells reg_cells sequential_cells combinational_cells total_power} > "results/rtl_metrics_hier.txt"
report_rtl_metrics -view register -reg_attributes {dynamic_power switching_power leakage_power total_power register_gated root_clk_name} > "results/rtl_metrics_register.txt"

echo "========== STEP 6: Check RTL Power =========="
check_rtl_power > "results/check_rtl_power.txt"

exit
