set_app_var power_enable_rtl_analysis true
source TZ_OUTDIR/conf_func@nominal.tcl
::pprtl::read_design_data
::pprtl::read_name_mapping
::pprtl::read_activity_files
::pprtl::compute_metrics
quit
