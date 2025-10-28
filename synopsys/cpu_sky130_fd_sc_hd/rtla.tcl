#!/bin/tcsh -f
# =============================================================================
# RISC-V CPU RTL Analysis and Synthesis Script for SKY130
# =============================================================================
# Description: This script performs RTL analysis, synthesis, and power 
#              analysis for the RISC-V CPU using SKY130 technology
# Author: CO502 Group 1
# Technology: SKY130 130nm Process
# =============================================================================

# Load shared configuration
source config.tcl

# -----------------------------------------------------------------------------
# Configuration and Setup
# -----------------------------------------------------------------------------
puts "========== Starting RTL Analysis and Synthesis =========="
puts "Technology: SKY130 130nm"
puts "Design: RISC-V CPU Pipeline"

# Configure mismatch handling
set_current_mismatch_config auto_fix 
set_attribute [get_mismatch_types missing_logical_reference] current_repair(auto_fix) create_blackbox

# Set host options for parallel processing
set_host_options -max_cores $CORES
puts "Using $CORES cores for parallel processing"

# Application options
set_app_options -list {plan.macro.allow_unmapped_design true}

# -----------------------------------------------------------------------------
# Library Setup
# -----------------------------------------------------------------------------
puts "========== Setting up SKY130 Libraries =========="

# Search paths for libraries and source files
set search_path $SEARCH_PATHS

# Create design library with SKY130 reference libraries
create_lib $LIB_NAME \
    -ref_libs "$REF_LIBS" \
    -technology $TECH_TF

puts "SKY130 libraries loaded successfully"

# -----------------------------------------------------------------------------
# Design Analysis and Elaboration
# -----------------------------------------------------------------------------
puts "========== Analyzing and Elaborating Design =========="

# Analyze RTL source files
analyze -f sv -vcs "-f $FILELIST"

# Elaborate the design
elaborate $DESIGN_NAME
set_top_module $TOP_MODULE

puts "Design elaboration completed"

# -----------------------------------------------------------------------------
# Technology Setup and Constraints
# -----------------------------------------------------------------------------
puts "========== Loading Technology Setup =========="
source tz_setup.tcl

# -----------------------------------------------------------------------------
# RTL Optimization
# -----------------------------------------------------------------------------
puts "========== Starting RTL Optimization =========="
rtl_opt
puts "RTL optimization completed"

# Save the optimized design
save_block
save_lib
puts "Design saved successfully"

# -----------------------------------------------------------------------------
# Power Analysis Setup
# -----------------------------------------------------------------------------
puts "========== Setting up Power Analysis =========="

# Create temp results directory if it doesn't exist
file mkdir $TEMP_RESULTS_DIR

# Configure RTL power analysis (corrected scenario name)
set_rtl_power_analysis_options \
    -scenario $SCENARIO_NAME \
    -design $DESIGN_NAME \
    -strip_path $STRIP_PATH \
    -fsdb $FSDB_FILE \
    -output_dir $OUTPUT_DIR

export_power_data
puts "Power analysis data exported"

# -----------------------------------------------------------------------------
# Generate Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

report_power > "$TEMP_RESULTS_DIR/report_power.txt"
report_area > "$TEMP_RESULTS_DIR/report_area.txt" 
report_timing > "$TEMP_RESULTS_DIR/report_timing.txt"
report_qor > "$TEMP_RESULTS_DIR/report_qor.txt"

# Additional useful reports for SKY130
report_reference > "$TEMP_RESULTS_DIR/report_reference.txt"
report_hierarchy > "$TEMP_RESULTS_DIR/report_hierarchy.txt"

update_timing
report_timing -max_paths 1 -delay_type max > "$TEMP_RESULTS_DIR/report_timing_max.txt"
set slack [get_attribute [get_timing_paths -max_paths 1 -sort_by slack] slack]
set period [get_attribute [get_clocks clk] period]
set Tmin [expr {$period - $slack}]
set Fmax [expr {1.0 / $Tmin}]
set freq_MHz [expr {$Fmax * 1e-6}]
set timing_summary_file [open "$TEMP_RESULTS_DIR/timing_summary.txt" w]
puts $timing_summary_file "Minimum period = $Tmin ns"
puts $timing_summary_file "Maximum frequency = $freq_MHz MHz"
close $timing_summary_file
puts "Minimum period = $Tmin ns"
puts "Maximum frequency = $freq_MHz MHz"

puts "All reports generated in $TEMP_RESULTS_DIR/ directory"
puts "========== RTL Analysis and Synthesis Complete =========="

exit
