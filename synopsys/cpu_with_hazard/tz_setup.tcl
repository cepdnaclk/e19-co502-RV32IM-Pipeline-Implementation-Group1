#set_app_options  -name compile.datapath.ungroup -value false
set_app_options -list {compile.flow.enable_multibit true}
set_app_options -name shell.dc_compatibility.return_tcl_errors  -value false
set_app_options -name compile.flow.autoungroup -value false
#set_app_options -name compile.flow.fast_enable_cts -value true

#source /slowfs/cae680/users/jonworth/testcases/pp_rtl/openpiton/mcmm.auto_expanded.tcl


read_parasitic_tech -tlup ./INPUT/cln16ffc_1p11m_2xa1xd3xe2y2r_mim_ut-alrdl_cworst.tluplus -layermap ./INPUT/layers.map -name cworst
read_parasitic_tech -tlup ./INPUT/cln16ffc_1p11m_2xa1xd3xe2y2r_mim_ut-alrdl_cbest.tluplus -layermap ./INPUT/layers.map -name cbest

# set_dont_touch [get_cells -hier -filter {ref_name=~"*HDBSVT16_FSDP*"}] true
# set_dont_touch [get_cells -hier -filter {ref_name=~"*HDBLVT16_CKGTPLT_V8_1*"}] true
# set_attribute -objects [get_cells -hier -filter "ref_name=~*SELECT_OP*"] -name map_to_mux -value true

set_app_options -name compile.datapath.ungroup -value false
set_app_options -as_user_default -list {ungr.dw.hlo_enable_dw_ungrp false}

set_clock_gating_options -max_fanout 8 -max_number_of_levels  2
set_clock_gate_style -target { pos_edge_flip_flop } -test_point before

set_app_options -name compile.flow.enable_multibit -value true

set_app_option -name  rtl_opt.conditioning.disable_boundary_optimization_and_auto_ungrouping -value true

set_app_options -as_user_default -list {compile.flow.autoungroup false}
set_app_options -as_user_default -list {compile.flow.boundary_optimization false}
#set_app_options -as_user_default -list {compile.flow.constant_and_unloaded_propagation_with_no_boundary_opt false}


create_mode func
create_corner cworst

create_scenario -mode func -corner cworst -name func@cworst
set_parasitic_parameters -corner cworst -late_spec cworst -early_spec cworst
set_scenario_status func@cworst -hold false

current_scenario func@cworst

source ./sdc/clocks.sdc

#set REF_LIB_PATH "/u/powercae/paths/libs/TSMC_16"
#source  /slowfs/cae680/users/jonworth/testcases/openpiton/fusion_sparc/./rm_fc_scripts/read_parasitic_tech.tcl
#source /slowfs/cae680/users/jonworth/testcases/pp_rtl/openpiton/work_fc/wscript/top.tcl
report_scenarios
