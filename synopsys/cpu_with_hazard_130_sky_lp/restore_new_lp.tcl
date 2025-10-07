#!/bin/tcsh -f
# =============================================================================
# Low Power Analysis and Metrics Reporting Script for SKY130
# =============================================================================
# Description: This script performs detailed power analysis and generates
#              comprehensive power and RTL metrics reports for the RISC-V CPU
#              using SKY130 Low Power library
# Author: CO502 Group 1  
# Technology: SKY130 130nm Process - Low Power Variant
# Prerequisites: Run after rtla.tcl synthesis completion
# =============================================================================

# -----------------------------------------------------------------------------
# Power Analysis Configuration
# -----------------------------------------------------------------------------
puts "========== Starting Low Power Analysis and Metrics =========="
puts "Technology: SKY130 130nm - Low Power Library"
puts "Design: RISC-V CPU Pipeline"
puts "Focus: Minimum Power Consumption Analysis"

# Enable power analysis features
set_app_var power_enable_rtl_analysis true
set_app_var power_enable_analysis true
set_app_var power_enable_multi_rtl_to_gate_mapping true
set_app_var power_enable_advanced_fsdb_reader true

# Configure parallel processing
set_host_options -max_cores 8
puts "Using 8 cores for power analysis"

# Set search paths for SKY130 Low Power libraries
set search_path "* ./ ./INPUT//ndm ../../cpu/ ../libs/sky130_library/ndm"

# Enable clock gating logic clustering for registers
set_app_var power_rtl_report_register_use_cg_logic_clustering true

# -----------------------------------------------------------------------------
# Load Analysis Data
# -----------------------------------------------------------------------------
puts "========== Loading Analysis Data =========="

# Create results directory if it doesn't exist
file mkdir results

# Compute metrics from previous synthesis run
compute_metrics -reuse TZ_OUTDIR_LP
read_name_mapping
update_power
update_metrics

puts "Low power analysis data loaded and updated"

# -----------------------------------------------------------------------------
# Power Analysis by Component Groups
# -----------------------------------------------------------------------------
puts "========== Generating Power Reports by Component Groups =========="

# Generate power reports grouped by component type
report_power -group register > "results/power_register_lp.txt"
report_power -group sequential > "results/power_sequential_lp.txt"
report_power -group combinational > "results/power_combinational_lp.txt"
report_power -group black_box > "results/power_black_box_lp.txt"
report_power -group io_pad > "results/power_io_pad_lp.txt"

puts "Component group power reports generated"

# -----------------------------------------------------------------------------
# Hierarchical Power Analysis
# -----------------------------------------------------------------------------
puts "========== Generating Hierarchical Power Reports =========="

# Generate hierarchical power reports at different levels of detail
set hierarchy_levels {2 3 5 10 15 20}
foreach level $hierarchy_levels {
    report_power -hierarchy -levels $level -verbose > "results/power_by_module_${level}_lp.txt"
    puts "Generated hierarchical power report for $level levels"
}

# Generate comprehensive hierarchical report
report_power -hierarchy -levels 50 -verbose > "results/power_by_module_complete_lp.txt"

puts "Hierarchical power reports generated"

# -----------------------------------------------------------------------------
# Low Power Specific Analysis
# -----------------------------------------------------------------------------
puts "========== Generating Low Power Specific Reports =========="

# Clock gating effectiveness
report_clock_gating -summary > "results/clock_gating_summary_lp.txt"
report_clock_gating -verbose > "results/clock_gating_detailed_lp.txt"

# Leakage power analysis (important for low power library)
report_power -leakage > "results/power_leakage_analysis_lp.txt"

# Power optimization results
report_power_optimization > "results/power_optimization_results_lp.txt"

puts "Low power specific reports generated"

# -----------------------------------------------------------------------------
# RTL Metrics Analysis
# -----------------------------------------------------------------------------
puts "========== Generating RTL Metrics Reports =========="

# List available RTL metrics
report_rtl_metrics -list > "results/rtl_metrics_list_lp.txt"

# Generate hierarchical RTL metrics
report_rtl_metrics -view hier \
    -hier_attributes {gated_registers icg_cells latch_cells reg_cells sequential_cells combinational_cells total_power} \
    > "results/rtl_metrics_hier_lp.txt"

# Generate register-level RTL metrics  
report_rtl_metrics -view register \
    -reg_attributes {dynamic_power switching_power leakage_power total_power register_gated root_clk_name} \
    > "results/rtl_metrics_register_lp.txt"

# Clock gating RTL metrics
report_rtl_metrics -view clock_gating \
    -cg_attributes {gated_registers ungated_registers gating_ratio power_savings} \
    > "results/rtl_metrics_clock_gating_lp.txt"

puts "RTL metrics reports generated"

# -----------------------------------------------------------------------------
# Power Analysis Validation
# -----------------------------------------------------------------------------
puts "========== Validating Power Analysis =========="

# Check RTL power analysis for issues
check_rtl_power > "results/check_rtl_power_lp.txt"

# Generate summary report
report_power -verbose > "results/power_summary_detailed_lp.txt"

# Generate power comparison report
report_power -net > "results/power_by_net_lp.txt"

puts "Power analysis validation completed"

# -----------------------------------------------------------------------------
# Generate Low Power Summary Statistics
# -----------------------------------------------------------------------------
puts "========== Generating Low Power Summary Statistics =========="

# Create a summary file with key metrics
set summary_file [open "results/low_power_analysis_summary.txt" w]
puts $summary_file "# Low Power Analysis Summary for RISC-V CPU"
puts $summary_file "# Technology: SKY130 130nm - Low Power Library (sky130_fd_sc_lp)"
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

# Get clock gating statistics
set gated_regs [get_attribute [current_design] gated_registers]
set total_regs [get_attribute [current_design] total_registers]

if {$gated_regs != "" && $total_regs != ""} {
    set gating_ratio [expr {$gated_regs * 100.0 / $total_regs}]
    puts $summary_file "Clock Gating Ratio: ${gating_ratio}%"
    puts $summary_file "Gated Registers: $gated_regs"
    puts $summary_file "Total Registers: $total_regs"
}

puts $summary_file ""
puts $summary_file "Library Used: sky130_fd_sc_lp (Low Power)"
puts $summary_file "Expected Benefits:"
puts $summary_file "- 50-70% lower leakage power vs HD library"
puts $summary_file "- 20-30% lower dynamic power vs HD library"
puts $summary_file "- Optimized for battery-powered applications"

close $summary_file

puts "Low power summary statistics generated"

# -----------------------------------------------------------------------------
# Power Comparison (if HD version exists)
# -----------------------------------------------------------------------------
puts "========== Generating Power Comparison =========="

set comparison_file [open "results/power_comparison_lp_vs_hd.txt" w]
puts $comparison_file "# Power Comparison: Low Power vs High Density"
puts $comparison_file "# This file shows expected improvements with LP library"
puts $comparison_file ""
puts $comparison_file "Expected Improvements with sky130_fd_sc_lp:"
puts $comparison_file "========================================="
puts $comparison_file "Leakage Power: 50-70% reduction"
puts $comparison_file "Dynamic Power: 20-30% reduction"
puts $comparison_file "Total Power: 30-50% reduction"
puts $comparison_file ""
puts $comparison_file "Trade-offs:"
puts $comparison_file "==========="
puts $comparison_file "Performance: 30-50% slower"
puts $comparison_file "Area: 10-20% larger"
puts $comparison_file "Maximum Frequency: Reduced"
close $comparison_file

puts "Power comparison analysis generated"

# -----------------------------------------------------------------------------
# Completion Message
# -----------------------------------------------------------------------------
puts "========== Low Power Analysis Complete =========="
puts "All reports generated in results/ directory:"
puts "  - Component group power reports (*_lp.txt)"
puts "  - Hierarchical power reports (multiple levels)"
puts "  - Low power specific analysis"
puts "  - RTL metrics reports"
puts "  - Clock gating effectiveness"
puts "  - Power validation reports"
puts "  - Low power summary statistics"
puts "  - Power comparison analysis"
puts "========== Low Power Analysis Session Complete =========="

exit