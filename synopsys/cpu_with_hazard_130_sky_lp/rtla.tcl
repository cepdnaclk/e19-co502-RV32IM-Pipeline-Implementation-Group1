#!/bin/tcsh -f
# =============================================================================
# RISC-V CPU RTL Analysis and Synthesis Script for SKY130 Low Power
# =============================================================================
# Description: This script performs RTL analysis, synthesis, and power 
#              analysis for the RISC-V CPU using SKY130 Low Power library
# Author: CO502 Group 1
# Technology: SKY130 130nm Process - Low Power (LP) Variant
# Library: sky130_fd_sc_lp (Lowest Power Consumption)
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration and Setup
# -----------------------------------------------------------------------------
puts "========== Starting RTL Analysis and Synthesis (LOW POWER) =========="
puts "Technology: SKY130 130nm - Low Power Library"
puts "Design: RISC-V CPU Pipeline"
puts "Target: Minimum Power Consumption"

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
# Library Setup - SKY130 Low Power
# -----------------------------------------------------------------------------
puts "========== Setting up SKY130 Low Power Libraries =========="

# Search paths for libraries and source files
set search_path "* ./ ./INPUT//ndm ../../cpu ../libs/sky130_library/ndm"

# Create design library with SKY130 Low Power reference libraries
create_lib cpu_LP_LIB \
    -ref_libs "sky130_fd_sc_lp.ndm" \
    -technology ../libs/sky130_fd_sc_lp/sky130_fd_sc_lp.tf

puts "SKY130 Low Power libraries loaded successfully"

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
source tz_setup_lp.tcl

# -----------------------------------------------------------------------------
# RTL Optimization for Low Power
# -----------------------------------------------------------------------------
puts "========== Starting RTL Optimization (Low Power Focus) =========="

# Enable power-focused optimization
set_app_options -name compile.power_opt_enable -value true
set_app_options -name rtl_opt.power.enable -value true

# Perform RTL optimization
rtl_opt
puts "RTL optimization completed with power focus"

# Save the optimized design
save_lib cpu_LP_LIB
save_block cpu_lp_top_block
puts "Low power design saved successfully"

# -----------------------------------------------------------------------------
# Power Analysis Setup
# -----------------------------------------------------------------------------
puts "========== Setting up Power Analysis =========="

# Create results directory if it doesn't exist
file mkdir results

# Configure RTL power analysis for low power scenario
set_rtl_power_analysis_options \
    -scenario func@nominal_lp \
    -design cpu \
    -strip_path cpu_tb/cpu_inst \
    -fsdb "../../cpu/novas.fsdb" \
    -output_dir TZ_OUTDIR_LP

export_power_data
puts "Power analysis data exported"

# -----------------------------------------------------------------------------
# Generate Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

report_power > "results/report_power_lp.txt"
report_area > "results/report_area_lp.txt" 
report_timing > "results/report_timing_lp.txt"
report_qor > "results/report_qor_lp.txt"

# Additional useful reports for SKY130 Low Power
report_reference > "results/report_reference_lp.txt"
report_hierarchy > "results/report_hierarchy_lp.txt"

# Power-specific reports
report_power -hierarchy -levels 5 > "results/report_power_hierarchy_lp.txt"
report_clock_gating > "results/report_clock_gating_lp.txt"

puts "All reports generated in results/ directory"
puts "========== RTL Analysis and Synthesis Complete (LOW POWER) =========="

exit