#!/bin/tcsh -f
# =============================================================================
# RISC-V CPU RTL Analysis and Synthesis Script for SKY130
# =============================================================================
# Description: This script performs RTL analysis, synthesis, and power 
#              analysis for the RISC-V CPU using SKY130 technology
# Author: CO502 Group 1
# Technology: SKY130 130nm Process
# =============================================================================

# -----------------------------------------------------------------------------
# Variables (edit these for your environment)
# -----------------------------------------------------------------------------
# Cores for parallel processing
set CORES 8

# Design names and top
set DESIGN_NAME "cpu"
set TOP_MODULE  "cpu"

# Library configuration
set LIB_NAME   "cpu_LIB"
set REF_LIBS   "sky130_fd_sc_hd.ndm"            ;# one or more NDMs (space-separated)
set TECH_TF    "/tech/sky130/libs/sky130_fd_sc_hd/sky130_fd_sc_hd.tf"

# Search paths for libraries and source files
set SEARCH_PATHS "* ./ ../../cpu /tech/sky130/libs/sky130_library/ndm"

# Filelist for analyze
set FILELIST "src.f"

# Scenario/mode/corner names (must match tz_setup.tcl)
set SCENARIO_NAME "func@nominal"

# Power analysis inputs and output locations
set FSDB_FILE  "../../cpu/novas.fsdb"
set STRIP_PATH "cpu_tb/cpu_inst"
set OUTPUT_DIR "TZ_OUTDIR"                       ;# reused by restore_new.tcl
set RESULT_DIR "results"

# Temporary results directory for run-time outputs (can be overridden via ENV)
set TEMP_RESULTS_DIR $RESULT_DIR
if {[info exists ::env(TEMP_RESULTS_DIR)]} {
    set TEMP_RESULTS_DIR $::env(TEMP_RESULTS_DIR)
}

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

puts "All reports generated in $TEMP_RESULTS_DIR/ directory"
puts "========== RTL Analysis and Synthesis Complete =========="

exit
