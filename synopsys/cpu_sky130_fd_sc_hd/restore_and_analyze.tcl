#!/bin/tcsh -f
# =============================================================================
# Restore Saved Design and Continue Power Analysis for 45nm CMOS
# =============================================================================
# Description: This script restores a previously synthesized design and 
#              continues with power analysis and reporting
# Author: Neuromorphic Accelerator Team
# Technology: 45nm CMOS Process
# =============================================================================

# Load shared configuration
source config.tcl

# -----------------------------------------------------------------------------
# Configuration and Setup
# -----------------------------------------------------------------------------
puts "========== Restoring Saved Design =========="
puts "Technology: 45nm CMOS"
puts "Design: $DESIGN_NAME"

# Set host options for parallel processing
set_host_options -max_cores $CORES
puts "Using $CORES cores for parallel processing"

# -----------------------------------------------------------------------------
# Restore Previously Saved Design
# -----------------------------------------------------------------------------
puts "========== Opening Saved Library and Block =========="

# Open the saved library
open_lib $LIB_NAME

# Check if library exists
if {[sizeof_collection [get_libs $LIB_NAME]] == 0} {
    puts "ERROR: Library $LIB_NAME not found!"
    puts "Please run rtla.tcl first to create and save the initial design."
    exit 1
}

# Open the saved block
open_block ${DESIGN_NAME}.design

# Check if block exists
if {[current_block] == ""} {
    puts "ERROR: Block ${DESIGN_NAME}.design not found!"
    puts "Available blocks: [get_object_name [get_blocks *]]"
    puts "Please run rtla.tcl first to create and save the initial design."
    exit 1
}

puts "Successfully restored design from saved library"

# Set the top module
set_top_module $TOP_MODULE

# -----------------------------------------------------------------------------
# Technology Setup and Constraints
# -----------------------------------------------------------------------------
puts "========== Reloading Technology Setup =========="
source tz_setup.tcl

# Force timing update
update_timing

# Verify clock constraints
puts "========== Verifying Clock Constraints =========="
set all_clocks [get_clocks -quiet *]
if {[llength $all_clocks] == 0} {
    puts "ERROR: No clocks found after loading constraints!"
    exit 1
}

puts "Clocks found in design:"
foreach clk $all_clocks {
    set clk_name [get_object_name $clk]
    set clk_period [get_attribute $clk period]
    puts "  - $clk_name (period: $clk_period ns)"
}

# -----------------------------------------------------------------------------
# Power Analysis Setup
# -----------------------------------------------------------------------------
puts "========== Setting up Power Analysis =========="

# Create temp results directory if it doesn't exist
file mkdir $TEMP_RESULTS_DIR

# Configure RTL power analysis
set_rtl_power_analysis_options \
    -scenario $SCENARIO_NAME \
    -design $DESIGN_NAME \
    -strip_path $STRIP_PATH \
    -fsdb $FSDB_FILE \
    -output_dir $OUTPUT_DIR

export_power_data
puts "Power analysis data exported"
puts "Note: Run pwr_shell with restore_new.tcl next for detailed power analysis"

# -----------------------------------------------------------------------------
# Maximum Frequency Characterization
# -----------------------------------------------------------------------------
puts "========== Characterizing Maximum Operating Frequency =========="

# Update timing for accurate analysis
update_timing

# Get the first clock
set all_clocks [get_clocks *]
set current_clk [lindex $all_clocks 0]
set clock_name [get_object_name $current_clk]
puts "Analyzing clock: $clock_name"

set current_period [get_attribute $current_clk period]
puts "Current clock period: $current_period ns"

# Get worst negative slack and critical path information
set critical_paths [get_timing_paths -delay_type max -max_paths 1]
if {[llength $critical_paths] == 0} {
    puts "WARNING: No timing paths found"
    set slack 0.0
    set data_arrival 0.0
} else {
    set slack [get_attribute $critical_paths slack]
    set data_arrival [get_attribute $critical_paths arrival]
}

puts "Current WNS (Worst Negative Slack): $slack ns"

# Calculate minimum period and maximum frequency
if {$slack >= 0} {
    set Tmin $data_arrival
    set timing_status "MET"
} else {
    set Tmin [expr {$current_period - $slack}]
    set timing_status "VIOLATED"
}

# Add safety margin
set MARGIN_PERCENT 2.0
set Tmin_with_margin [expr {$Tmin * (1.0 + $MARGIN_PERCENT/100.0)}]

# Calculate frequencies
set Fmax [expr {1000.0 / $Tmin}]
set Fmax_with_margin [expr {1000.0 / $Tmin_with_margin}]

# Format results
set Fmax_formatted [format "%.2f" $Fmax]
set Fmax_margin_formatted [format "%.2f" $Fmax_with_margin]
set Tmin_formatted [format "%.4f" $Tmin]
set Tmin_margin_formatted [format "%.4f" $Tmin_with_margin]

puts "================================================"
puts "MAXIMUM FREQUENCY CHARACTERIZATION RESULTS"
puts "================================================"
puts "Timing Status: $timing_status at current period"
puts "Critical Path Delay: $Tmin_formatted ns"
puts "Maximum Frequency: $Fmax_formatted MHz"
puts "Maximum Frequency (with ${MARGIN_PERCENT}% margin): $Fmax_margin_formatted MHz"
puts "Recommended Clock Period: $Tmin_margin_formatted ns"
puts "================================================"

# -----------------------------------------------------------------------------
# Generate Comprehensive Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

# Create subdirectory for restore run reports
set RESTORE_RESULTS_DIR "$TEMP_RESULTS_DIR/restore_run"
file mkdir $RESTORE_RESULTS_DIR

# Basic reports
report_power > "$RESTORE_RESULTS_DIR/report_power.txt"
report_area > "$RESTORE_RESULTS_DIR/report_area.txt" 
report_qor > "$RESTORE_RESULTS_DIR/report_qor.txt"

# Detailed timing reports
report_timing -delay_type max -max_paths 1 -path_type full \
    > "$RESTORE_RESULTS_DIR/report_timing_critical_path.txt"

report_timing -delay_type max -max_paths 10 -path_type full \
    > "$RESTORE_RESULTS_DIR/report_timing_top10_paths.txt"

report_timing -delay_type max -max_paths 1 -nets -transition_time \
    -capacitance -input_pins -significant_digits 4 \
    > "$RESTORE_RESULTS_DIR/report_timing_detailed.txt"

# Constraint and violation reports
report_constraint -all_violators > "$RESTORE_RESULTS_DIR/report_violations.txt"

# Clock reports
report_clock -skew > "$RESTORE_RESULTS_DIR/report_clock.txt"

# Additional reports
report_reference > "$RESTORE_RESULTS_DIR/report_reference.txt"
report_hierarchy > "$RESTORE_RESULTS_DIR/report_hierarchy.txt"
report_design > "$RESTORE_RESULTS_DIR/report_design_stats.txt"
report_pvt > "$RESTORE_RESULTS_DIR/report_pvt.txt"

# -----------------------------------------------------------------------------
# Generate Publication-Ready Summary
# -----------------------------------------------------------------------------
puts "========== Generating Publication Summary =========="

set summary_file [open "$RESTORE_RESULTS_DIR/publication_summary.txt" w]

puts $summary_file "================================================================================"
puts $summary_file "$DESIGN_NAME - 45nm CMOS - Performance Characterization (Restored Design)"
puts $summary_file "================================================================================"
puts $summary_file ""
puts $summary_file "DESIGN INFORMATION:"
puts $summary_file "  Design Name:           $DESIGN_NAME"
puts $summary_file "  Top Module:            $TOP_MODULE"
puts $summary_file "  Technology:            45nm CMOS"
puts $summary_file "  Analysis Date:         [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
puts $summary_file "  Analysis Type:         Restored from saved design"
puts $summary_file ""
puts $summary_file "TIMING ANALYSIS:"
puts $summary_file "  Current Clock Period:  $current_period ns"
puts $summary_file "  Timing Status:         $timing_status"
puts $summary_file "  Worst Slack (WNS):     $slack ns"
puts $summary_file ""
puts $summary_file "MAXIMUM FREQUENCY CHARACTERIZATION:"
puts $summary_file "  Critical Path Delay:   $Tmin_formatted ns"
puts $summary_file "  Maximum Frequency:     $Fmax_formatted MHz"
puts $summary_file ""
puts $summary_file "RECOMMENDED OPERATING POINT (${MARGIN_PERCENT}% margin):"
puts $summary_file "  Clock Period:          $Tmin_margin_formatted ns"
puts $summary_file "  Operating Frequency:   $Fmax_margin_formatted MHz"
puts $summary_file ""

# Get critical path details
if {[llength $critical_paths] > 0} {
    set startpoint [get_attribute $critical_paths startpoint]
    set endpoint [get_attribute $critical_paths endpoint]
    puts $summary_file "CRITICAL PATH:"
    puts $summary_file "  Startpoint:            [get_object_name $startpoint]"
    puts $summary_file "  Endpoint:              [get_object_name $endpoint]"
    puts $summary_file ""
}

puts $summary_file ""
puts $summary_file "PROCESS CORNER:"
puts $summary_file "  Scenario:              $SCENARIO_NAME"
puts $summary_file "  Corner:                Cmax (Worst Case)"
puts $summary_file ""
puts $summary_file "================================================================================"
puts $summary_file "For detailed timing analysis, see:"
puts $summary_file "  - report_timing_critical_path.txt (Critical path breakdown)"
puts $summary_file "  - report_timing_top10_paths.txt (Top 10 critical paths)"
puts $summary_file "  - report_timing_detailed.txt (Full timing details with nets)"
puts $summary_file "================================================================================"

close $summary_file

# Create CSV for easy import
set csv_file [open "$RESTORE_RESULTS_DIR/timing_metrics.csv" w]
puts $csv_file "Metric,Value,Unit"
puts $csv_file "Critical_Path_Delay,$Tmin_formatted,ns"
puts $csv_file "Maximum_Frequency,$Fmax_formatted,MHz"
puts $csv_file "Recommended_Frequency,$Fmax_margin_formatted,MHz"
puts $csv_file "Worst_Slack,$slack,ns"
puts $csv_file "Current_Period,$current_period,ns"
close $csv_file

puts "All reports generated in $RESTORE_RESULTS_DIR/ directory"
puts ""
puts "KEY RESULT: Maximum Operating Frequency = $Fmax_formatted MHz"
puts "RECOMMENDED: Use $Fmax_margin_formatted MHz (with ${MARGIN_PERCENT}% margin)"
puts ""
puts "========== Restore and Analysis Complete =========="

exit
