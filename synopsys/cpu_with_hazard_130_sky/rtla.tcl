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
# Configuration and Setup
# -----------------------------------------------------------------------------
puts "========== Starting RTL Analysis and Synthesis =========="
puts "Technology: SKY130 130nm"
puts "Design: RISC-V CPU Pipeline"

# Configure mismatch handling
set_current_mismatch_config auto_fix 
set_attribute [get_mismatch_types missing_logical_reference] current_repair(auto_fix) create_blackbox

# Set host options for parallel processing
set CORES 8
set_host_options -max_cores $CORES
puts "Using $CORES cores for parallel processing"

# Application options
set_app_options -list {plan.macro.allow_unmapped_design true}

# -----------------------------------------------------------------------------
# Library Setup
# -----------------------------------------------------------------------------
puts "========== Setting up SKY130 Libraries =========="

# Search paths for libraries and source files
set search_path "* ./ ./INPUT//ndm ../../cpu ../libs/sky130_library/ndm"

# Create design library with SKY130 reference libraries
create_lib cpu_LIB \
    -ref_libs "sky130_fd_sc_hd.ndm" \
    -technology ../libs/sky130_fd_sc_hd/sky130_fd_sc_hd.tf

puts "SKY130 libraries loaded successfully"

# -----------------------------------------------------------------------------
# Design Analysis and Elaboration
# -----------------------------------------------------------------------------
puts "========== Analyzing and Elaborating Design =========="

# Analyze RTL source files
analyze -f sv -vcs "-f src.f"

# Elaborate the design
elaborate cpu
set_top_module cpu

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
save_lib cpu_LIB
save_block cpu_top_block
puts "Design saved successfully"

# -----------------------------------------------------------------------------
# Power Analysis Setup
# -----------------------------------------------------------------------------
puts "========== Setting up Power Analysis =========="

# Create results directory if it doesn't exist
file mkdir results

# Configure RTL power analysis (corrected scenario name)
set_rtl_power_analysis_options \
    -scenario func@nominal \
    -design cpu \
    -strip_path cpu_tb/cpu_inst \
    -fsdb "../../cpu/novas.fsdb" \
    -output_dir TZ_OUTDIR

export_power_data
puts "Power analysis data exported"

# -----------------------------------------------------------------------------
# Generate Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

report_power > "results/report_power.txt"
report_area > "results/report_area.txt" 
report_timing > "results/report_timing.txt"
report_qor > "results/report_qor.txt"

# Additional useful reports for SKY130
report_reference > "results/report_reference.txt"
report_hierarchy > "results/report_hierarchy.txt"

puts "All reports generated in results/ directory"
puts "========== RTL Analysis and Synthesis Complete =========="

exit
