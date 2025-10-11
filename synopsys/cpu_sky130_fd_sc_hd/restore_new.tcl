#!/bin/tcsh -f
# =============================================================================
# Power Analysis and Metrics Reporting Script for SKY130
# =============================================================================
# Description: This script performs detailed power analysis and generates
#              comprehensive power and RTL metrics reports for the RISC-V CPU
# Author: CO502 Group 1  
# Technology: SKY130 130nm Process
# Prerequisites: Run after rtla.tcl synthesis completion
# =============================================================================

# -----------------------------------------------------------------------------
# Variables (edit these for your environment)
# -----------------------------------------------------------------------------
set CORES 8
set DESIGN_NAME "cpu"

# Paths
set SEARCH_PATHS "* ./  ../../cpu/ /tech/sky130/libs/sky130_library/ndm"
set RESULT_DIR   "results"
set OUTPUT_DIR   "TZ_OUTDIR"   ;# must match rtla.tcl's -output_dir
# Prefer a temporary results directory at runtime; allow ENV override
set TEMP_RESULTS_DIR $RESULT_DIR
if {[info exists ::env(TEMP_RESULTS_DIR)]} {
    set TEMP_RESULTS_DIR $::env(TEMP_RESULTS_DIR)
}

# Hierarchical levels for reporting
set HIERARCHY_LEVELS {2 3 5 10 20 100}

# -----------------------------------------------------------------------------
# Power Analysis Configuration
# -----------------------------------------------------------------------------
puts "========== Starting Power Analysis and Metrics =========="
puts "Technology: SKY130 130nm"
puts "Design: RISC-V CPU Pipeline"

# Enable power analysis features
set_app_var power_enable_rtl_analysis true
set_app_var power_enable_analysis true
set_app_var power_enable_multi_rtl_to_gate_mapping true
set_app_var power_enable_advanced_fsdb_reader true

# Configure parallel processing
set_host_options -max_cores $CORES
puts "Using $CORES cores for power analysis"

# Set search paths for SKY130 libraries
set search_path $SEARCH_PATHS

# Enable clock gating logic clustering for registers
set_app_var power_rtl_report_register_use_cg_logic_clustering true

# -----------------------------------------------------------------------------
# Load Analysis Data
# -----------------------------------------------------------------------------
puts "========== Loading Analysis Data =========="

# Create temp results directory if it doesn't exist
file mkdir $TEMP_RESULTS_DIR

# Compute metrics from previous synthesis run
compute_metrics -reuse $OUTPUT_DIR
read_name_mapping
update_power
update_metrics

puts "Analysis data loaded and updated"

# -----------------------------------------------------------------------------
# Power Analysis by Component Groups
# -----------------------------------------------------------------------------
puts "========== Generating Power Reports by Component Groups =========="

# Generate power reports grouped by component type
report_power -group register > "$TEMP_RESULTS_DIR/power_register.txt"
report_power -group sequential > "$TEMP_RESULTS_DIR/power_sequential.txt"
report_power -group combinational > "$TEMP_RESULTS_DIR/power_combinational.txt"
report_power -group black_box > "$TEMP_RESULTS_DIR/power_black_box.txt"
report_power -group io_pad > "$TEMP_RESULTS_DIR/power_io_pad.txt"

puts "Component group power reports generated"

# -----------------------------------------------------------------------------
# Hierarchical Power Analysis
# -----------------------------------------------------------------------------
puts "========== Generating Hierarchical Power Reports =========="

# Generate hierarchical power reports at different levels of detail
foreach level $HIERARCHY_LEVELS {
    report_power -hierarchy -levels $level -verbose > "$TEMP_RESULTS_DIR/power_by_module_${level}.txt"
    puts "Generated hierarchical power report for $level levels"
}

# Generate comprehensive hierarchical report
report_power -hierarchy -levels 100 -verbose > "$TEMP_RESULTS_DIR/power_by_module_complete.txt"

puts "Hierarchical power reports generated"

# -----------------------------------------------------------------------------
# RTL Metrics Analysis
# -----------------------------------------------------------------------------
puts "========== Generating RTL Metrics Reports =========="

# List available RTL metrics
report_rtl_metrics -list > "$TEMP_RESULTS_DIR/rtl_metrics_list.txt"

# Generate hierarchical RTL metrics
report_rtl_metrics -view hier \
    -hier_attributes {gated_registers icg_cells latch_cells reg_cells sequential_cells combinational_cells total_power} \
    > "$TEMP_RESULTS_DIR/rtl_metrics_hier.txt"

# Generate register-level RTL metrics  
report_rtl_metrics -view register \
    -reg_attributes {dynamic_power switching_power leakage_power total_power register_gated root_clk_name} \
    > "$TEMP_RESULTS_DIR/rtl_metrics_register.txt"

puts "RTL metrics reports generated"

# -----------------------------------------------------------------------------
# Power Analysis Validation
# -----------------------------------------------------------------------------
puts "========== Validating Power Analysis =========="

# Check RTL power analysis for issues
check_rtl_power > "$TEMP_RESULTS_DIR/check_rtl_power.txt"

# Generate summary report
report_power -verbose > "$TEMP_RESULTS_DIR/power_summary_detailed.txt"

puts "Power analysis validation completed"

# -----------------------------------------------------------------------------
# Generate Summary Statistics
# -----------------------------------------------------------------------------
puts "========== Generating Summary Statistics =========="

# Create a summary file with key metrics
set summary_file [open "$TEMP_RESULTS_DIR/power_analysis_summary.txt" w]
puts $summary_file "# Power Analysis Summary for RISC-V CPU"
puts $summary_file "# Technology: SKY130 130nm"
puts $summary_file "# Generated: [clock format [clock seconds]]"
puts $summary_file ""

# Get basic power information
set total_power [get_attribute [current_design] total_power]
set dynamic_power [get_attribute [current_design] dynamic_power]  
set leakage_power [get_attribute [current_design] leakage_power]

if {$total_power != ""} {
    puts $summary_file "Total Power: $total_power"
}
if {$dynamic_power != ""} {
    puts $summary_file "Dynamic Power: $dynamic_power"
}
if {$leakage_power != ""} {
    puts $summary_file "Leakage Power: $leakage_power"
}

close $summary_file

puts "Summary statistics generated"

# -----------------------------------------------------------------------------
# Completion Message
# -----------------------------------------------------------------------------
puts "========== Power Analysis Complete =========="
puts "All reports generated in $TEMP_RESULTS_DIR/ directory:"
puts "  - Component group power reports"
puts "  - Hierarchical power reports (multiple levels)"
puts "  - RTL metrics reports"
puts "  - Power validation reports"
puts "  - Summary statistics"
puts "========== Analysis Session Complete =========="

exit
