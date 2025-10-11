#!/usr/bin/env tclsh
# Run with: pt_shell -f rtla.tcl > results/rtla.log 2>&1
# =============================================================================
# CPU RTL Analysis and Synthesis Script for SKY130
# =============================================================================
# Description: This script performs RTL analysis, synthesis, and power 
#              analysis for the cpu design using SKY130 technology
# Author: CO502 Group 1
# Technology: SKY130 130nm Process (sky130_fd_sc_hd)
# Tool Versions: PrimeTime 2021.06-SP4, VCS 2021.09
# Library: SKY130 PDK v1.0.1
# =============================================================================

# Define paths as variables
set LIBS_SKY130_PATH "/tech/sky130/libs/sky130_library/ndm"
set LIBS_SKY130_FD_SC_HD_PATH "/tech/sky130/libs/sky130_fd_sc_hd"
set RTL_CPU_PATH "../../cpu"
set FSDB_PATH "../../cpu/novas.fsdb"

# Logging setup
set LOG_DIR "results"
set TIMESTAMP [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set LOG_FILE "$LOG_DIR/rtla_$TIMESTAMP.log"

# -----------------------------------------------------------------------------
# Critical File Existence Guards
# -----------------------------------------------------------------------------
# Ensure results directory exists
if {![file exists "results"]} {
    file mkdir "results"
}

# Check FSDB exists
if {![file exists $FSDB_PATH]} {
    puts "ERROR: FSDB not found at $FSDB_PATH"
    error "Missing FSDB file: $FSDB_PATH - regenerate with representative workload"
}

# Check source file list exists
if {![file exists "src.f"]} {
    puts "ERROR: Source file list 'src.f' not found"
    error "Missing source file list"
}

# -----------------------------------------------------------------------------
# Configuration and Setup
# -----------------------------------------------------------------------------
puts "========== Starting CPU RTL Analysis and Synthesis =========="
puts "Technology: SKY130 130nm (sky130_fd_sc_hd)"
puts "Design: RV32IM Pipeline CPU"
puts "Timestamp: [clock format [clock seconds]]"
puts "FSDB: $FSDB_PATH"

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
set search_path "* ./ ${LIBS_SKY130_PATH} ${RTL_CPU_PATH}"

# Create design library with SKY130 reference libraries
create_lib cpu_LIB \
    -ref_libs "${LIBS_SKY130_PATH}/sky130_fd_sc_hd.ndm" \
    -technology ${LIBS_SKY130_FD_SC_HD_PATH}/sky130_fd_sc_hd.tf

puts "SKY130 libraries loaded successfully"

# -----------------------------------------------------------------------------
# Design Analysis and Elaboration
# -----------------------------------------------------------------------------
puts "========== Analyzing and Elaborating Design =========="

# Analyze RTL source files with error checking
if {[catch {analyze -f sv -vcs "-f src.f"} err]} {
    puts "ERROR: analyze failed: $err"
    error "Halting due to analyze failure"
}

# Elaborate the design with error checking
if {[catch {elaborate cpu} err]} {
    puts "ERROR: elaborate failed: $err"
    error "Halting due to elaborate failure"
}

set_top_module cpu
puts "Design elaboration completed successfully"

# -----------------------------------------------------------------------------
# Technology Setup and Constraints
# -----------------------------------------------------------------------------
puts "========== Loading Technology Setup =========="
if {[file exists "./tz_setup.tcl"]} {
    source ./tz_setup.tcl
} else {
    puts "ERROR: tz_setup.tcl not found"
    error "Missing technology setup file"
}

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
# Multi-Corner Power Analysis Setup
# -----------------------------------------------------------------------------
puts "========== Setting up Multi-Corner Power Analysis =========="

# Define corners with explicit PVT values (SKY130 typical values)
set corners {nominal worst_case}
set corner_data(nominal) {voltage 1.8 temperature 25}
set corner_data(worst_case) {voltage 1.62 temperature 85}

foreach corner $corners {
    puts "Setting up corner: $corner"
    array set pv $corner_data($corner)
    
    # Document PVT conditions (actual values set in library/technology files)
    puts "  PVT: $pv(voltage)V, $pv(temperature)°C"
    
    # Configure RTL power analysis for this corner
    set_rtl_power_analysis_options \
        -scenario func@$corner \
        -design cpu \
        -strip_path cpu_tb/cpu_inst \
        -fsdb "${FSDB_PATH}" \
        -output_dir "results/$corner"
    
    if {[catch {export_power_data} err]} {
        puts "WARNING: Power data export failed for $corner: $err"
    } else {
        puts "Power analysis data exported for $corner"
    }
}

# -----------------------------------------------------------------------------
# Generate Comprehensive Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

# Create summary file with metadata
set summary_file [open "results/synthesis_summary.txt" w]
puts $summary_file "# SKY130 CPU Synthesis Summary"
puts $summary_file "# Generated: [clock format [clock seconds]]"
puts $summary_file "# Technology: SKY130 130nm (sky130_fd_sc_hd)"
puts $summary_file "# Tool: PrimeTime RTL"
puts $summary_file "# FSDB: $FSDB_PATH"
puts $summary_file "# Corners: nominal (1.8V, 25°C), worst_case (1.62V, 85°C)"
puts $summary_file "# Note: PVT values defined in SKY130 library files"
puts $summary_file ""
close $summary_file

# Generate standard reports
report_timing > "results/timing_report.txt"
report_timing -max_paths 10 > "results/timing_report_10.txt"
report_area > "results/area_report.txt"
report_qor > "results/qor_report.txt"

# Generate clock gating reports
report_power -group register > "results/power_gated_registers.txt"
report_timing -gated_registers > "results/timing_gated_registers.txt"

# Generate CSV reports for analysis
report_power -format csv -output "results/power_summary.csv"
report_area -format csv -output "results/area_summary.csv"

# Additional useful reports for SKY130
report_reference > "results/reference_report.txt"
report_hierarchy > "results/hierarchy_report.txt"

# Export SAIF for gate-level correlation
if {[catch {write_saif -output "results/design.saif"} err]} {
    puts "WARNING: SAIF export failed: $err"
} else {
    puts "SAIF exported for gate-level correlation"
}

# Save name mapping for correlation
if {[catch {write_name_mapping -output "results/name_mapping.txt"} err]} {
    puts "WARNING: Name mapping export failed: $err"
} else {
    puts "Name mapping saved for gate-level correlation"
}

puts "All reports generated in results/ directory"
puts "Ready for gate-level correlation flow"
puts "========== CPU RTL Analysis and Synthesis Complete =========="

exit
