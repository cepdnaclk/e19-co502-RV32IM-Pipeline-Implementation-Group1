set_app_var power_enable_rtl_analysis true
source TZ_OUTDIR/conf.tcl
::pprtl::read_design_data
::pprtl::read_name_mapping
::pprtl::read_activity_files
::pprtl::compute_metrics
quit
