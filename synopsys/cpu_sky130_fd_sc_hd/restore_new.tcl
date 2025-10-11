#!/usr/bin/env tclsh
# Run with: pt_shell -f restore_new.tcl > results/restore.log 2>&1
# =============================================================================
# Power Analysis and Metrics Reporting Script for SKY130
# =============================================================================
# Description: This script performs detailed power analysis and generates
#              comprehensive power and RTL metrics reports for the RV32IM Pipeline CPU
# Author: CO502 Group 1  
# Technology: SKY130 130nm Process (sky130_fd_sc_hd)
# Prerequisites: Run after rtla.tcl synthesis completion
# Tool Versions: PrimeTime 2021.06-SP4
# Library: SKY130 PDK v1.0.1
# =============================================================================

# Define paths as variables
set LIBS_SKY130_PATH "/tech/sky130/libs/sky130_library/ndm"
set CPU_PATH "../../cpu"

# Logging setup
set TIMESTAMP [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]

# -----------------------------------------------------------------------------
# Power Analysis Configuration
# -----------------------------------------------------------------------------
puts "========== Starting Power Analysis and Metrics =========="
puts "Technology: SKY130 130nm"
puts "Design: RV32IM Pipeline CPU"

# Enable power analysis features
set_app_var power_enable_rtl_analysis true
set_app_var power_enable_analysis true
set_app_var power_enable_multi_rtl_to_gate_mapping true
set_app_var power_enable_advanced_fsdb_reader true

# Configure parallel processing
set_host_options -max_cores 8
puts "Using 8 cores for power analysis"

# Set search paths for SKY130 libraries
set search_path "* ./ ${CPU_PATH} ${LIBS_SKY130_PATH}"

# Enable clock gating logic clustering for registers
set_app_var power_rtl_report_register_use_cg_logic_clustering true

# -----------------------------------------------------------------------------
# Critical File Guards and Setup
# -----------------------------------------------------------------------------
# Ensure results directory exists
if {![file exists "results"]} {
    file mkdir "results"
}

# Check if synthesis data exists
if {![file exists "TZ_OUTDIR"] && ![file exists "results/nominal"]} {
    puts "ERROR: No synthesis data found. Run rtla.tcl first."
    error "Missing synthesis data directory"
}

# -----------------------------------------------------------------------------
# Multi-Corner Analysis Data Loading
# -----------------------------------------------------------------------------
puts "========== Loading Multi-Corner Analysis Data =========="

# Define corners to analyze
set corners {nominal worst_case}

foreach corner $corners {
    puts "Loading analysis data for corner: $corner"
    
    # Check if corner data exists
    set corner_dir "results/$corner"
    if {[file exists $corner_dir]} {
        if {[catch {compute_metrics -reuse $corner_dir} err]} {
            puts "WARNING: Failed to load metrics for $corner: $err"
            continue
        }
    } else {
        puts "WARNING: No data found for corner $corner, skipping"
        continue
    }
    
    # Read name mapping if available
    if {[catch {read_name_mapping} err]} {
        puts "WARNING: Name mapping failed for $corner: $err"
    }
    
    if {[catch {update_power} err]} {
        puts "WARNING: Power update failed for $corner: $err"
    }
    
    if {[catch {update_metrics} err]} {
        puts "WARNING: Metrics update failed for $corner: $err"
    }
    
    puts "Analysis data loaded for $corner"
}

# -----------------------------------------------------------------------------
# Multi-Corner Power Analysis by Component Groups
# -----------------------------------------------------------------------------
puts "========== Generating Multi-Corner Power Reports =========="

foreach corner $corners {
    puts "Generating power reports for corner: $corner"
    
    # Create corner-specific directory
    set corner_results "results/$corner"
    if {![file exists $corner_results]} {
        file mkdir $corner_results
    }
    
    # Switch to corner scenario if it exists
    if {[catch {current_scenario func@$corner} err]} {
        puts "WARNING: Could not switch to scenario func@$corner: $err"
        continue
    }
    
    # Generate power reports grouped by component type
    report_power -group register > "$corner_results/power_register.txt"
    report_power -group sequential > "$corner_results/power_sequential.txt" 
    report_power -group combinational > "$corner_results/power_combinational.txt"
    report_power -group black_box > "$corner_results/power_black_box.txt"
    report_power -group io_pad > "$corner_results/power_io_pad.txt"
    
    # Generate per-instance power hotspots
    report_power -per_instance -sort_by total_power -max 50 > "$corner_results/power_hotspots.txt"
    
    # Generate CSV format for analysis
    report_power -format csv -output "$corner_results/power_summary.csv"
    
    puts "Component group power reports generated for $corner"
}

# -----------------------------------------------------------------------------
# Hierarchical Power Analysis
# -----------------------------------------------------------------------------
puts "========== Generating Hierarchical Power Reports =========="

# Generate hierarchical power reports at different levels of detail
set hierarchy_levels {2 3 5 10 20 100}
foreach level $hierarchy_levels {
    report_power -hierarchy -levels $level -verbose > "results/power_by_module_${level}.txt"
    puts "Generated hierarchical power report for $level levels"
}

# Generate comprehensive hierarchical report
report_power -hierarchy -levels 100 -verbose > "results/power_by_module_complete.txt"

puts "Hierarchical power reports generated"

# -----------------------------------------------------------------------------
# RTL Metrics Analysis
# -----------------------------------------------------------------------------
puts "========== Generating RTL Metrics Reports =========="

# List available RTL metrics
report_rtl_metrics -list > "results/rtl_metrics_list.txt"

# Generate hierarchical RTL metrics
report_rtl_metrics -view hier \
    -hier_attributes {gated_registers icg_cells latch_cells reg_cells sequential_cells combinational_cells total_power} \
    > "results/rtl_metrics_hier.txt"

# Generate register-level RTL metrics  
report_rtl_metrics -view register \
    -reg_attributes {dynamic_power switching_power leakage_power total_power register_gated root_clk_name} \
    > "results/rtl_metrics_register.txt"

puts "RTL metrics reports generated"

# -----------------------------------------------------------------------------
# Power Analysis Validation
# -----------------------------------------------------------------------------
puts "========== Validating Power Analysis =========="

# Check RTL power analysis for issues
check_rtl_power > "results/check_rtl_power.txt"

# Generate summary report
report_power -verbose > "results/power_summary_detailed.txt"

puts "Power analysis validation completed"

# -----------------------------------------------------------------------------
# Generate Summary Statistics
# -----------------------------------------------------------------------------
puts "========== Generating Summary Statistics =========="

# -----------------------------------------------------------------------------
# Generate Comprehensive Multi-Corner Summary
# -----------------------------------------------------------------------------
puts "========== Generating Multi-Corner Summary Statistics =========="

# Create comprehensive summary file with metadata
set summary_file [open "results/power_analysis_summary.txt" w]
puts $summary_file "# Power Analysis Summary for RV32IM Pipeline CPU"
puts $summary_file "# Technology: SKY130 130nm (sky130_fd_sc_hd)"
puts $summary_file "# Generated: [clock format [clock seconds]]"
puts $summary_file "# Tool: PrimeTime RTL"
puts $summary_file "# Corners: nominal (1.8V, 25°C), worst_case (1.62V, 85°C)"
puts $summary_file ""
puts $summary_file "# Multi-Corner Power Summary:"
puts $summary_file ""

# Generate summary for each corner
foreach corner $corners {
    if {[catch {current_scenario func@$corner} err]} {
        puts $summary_file "$corner: ERROR - Could not access scenario"
        continue
    }
    
    puts $summary_file "## Corner: $corner"
    
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
    puts $summary_file ""
}

# Add correlation notes
puts $summary_file "# Notes for Publication:"
puts $summary_file "# - FSDB represents X inferences with Y input distribution"
puts $summary_file "# - Clock period: [get_attribute [get_clocks] period] ns"
puts $summary_file "# - Gate-level correlation: Run gate-level flow with same FSDB"
puts $summary_file "# - Energy per inference: Total_Power × Clock_Period × Cycles_per_Inference"
puts $summary_file ""

close $summary_file

puts "Multi-corner summary statistics generated"

# -----------------------------------------------------------------------------
# Additional SKY130 Specific Reports
# -----------------------------------------------------------------------------
puts "========== Generating SKY130 Specific Reports =========="

# Generate technology-specific reports
report_reference > "results/sky130_reference_report.txt"
report_design > "results/sky130_design_report.txt"
report_constraints > "results/sky130_constraints_report.txt"

puts "SKY130 specific reports generated"

# -----------------------------------------------------------------------------
# Generate Reproducibility Report for Publication
# -----------------------------------------------------------------------------
puts "========== Generating Reproducibility Report =========="

set repro_file [open "results/reproducibility_report.txt" w]
puts $repro_file "# Reproducibility Report for Publication"
puts $repro_file "# Generated: [clock format [clock seconds]]"
puts $repro_file ""
puts $repro_file "## Tool Versions:"
puts $repro_file "# PrimeTime: [get_app_var sh_command_log_file]"
puts $repro_file "# VCS: (add version here)"
puts $repro_file "# Library: SKY130 PDK v1.0.1 sky130_fd_sc_hd"
puts $repro_file ""
puts $repro_file "## Testbench & Workload:"
puts $repro_file "# FSDB Duration: (add simulation time)"
puts $repro_file "# Number of Inferences: (add count)"
puts $repro_file "# Input Distribution: (describe test vectors)"
puts $repro_file "# Clock Period: [get_attribute [get_clocks] period] ns"
puts $repro_file ""
puts $repro_file "## PVT Corners:"
puts $repro_file "# Nominal: 1.8V, 25°C (typical operation)"
puts $repro_file "# Worst Case: 1.62V, 85°C (worst power/timing)"
puts $repro_file ""
puts $repro_file "## Files for Correlation:"
puts $repro_file "# Name Mapping: results/name_mapping.txt"
puts $repro_file "# SAIF: results/design.saif"
puts $repro_file "# Power CSV: results/*/power_summary.csv"
close $repro_file

puts "Reproducibility report generated for publication"

# -----------------------------------------------------------------------------
# Completion Message
# -----------------------------------------------------------------------------
puts "========== Multi-Corner Power Analysis Complete =========="
puts "All reports generated in results/ directory:"
puts "  - Multi-corner component group power reports"
puts "  - Hierarchical power reports (multiple levels)"  
puts "  - RTL metrics reports"
puts "  - Power validation reports"
puts "  - Multi-corner summary statistics"
puts "  - SKY130 specific reports"
puts "  - CSV exports for analysis"
puts "  - Reproducibility report for publication"
puts ""
puts "Next Steps:"
puts "  1. Verify FSDB represents realistic workload"
puts "  2. Run gate-level flow with same FSDB for correlation"
puts "  3. Calculate energy per inference from power × time"
puts "  4. Report correlation % and uncertainty in paper"
puts ""
puts "========== RV32IM Pipeline CPU Analysis Complete =========="

exit
