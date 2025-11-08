#!/bin/tcsh -f
# =============================================================================
# Maximum Frequency Characterization Script for 45nm CMOS (PRODUCTION)
# =============================================================================
# Description: Production-ready script to calculate maximum operating frequency
#              without power analysis (uses pwr_shell with restore)
#              Fixes: tool-specific attributes, output redirection, Tcl quoting,
#                     fallback parsing, robust error handling
# Author: Neuromorphic Accelerator Team  
# Technology: 45nm CMOS Process
# Prerequisites: Run after rtla.tcl (design must be saved)
# Usage: pwr_shell -f get_max_freq.tcl
# =============================================================================

# Load shared configuration
source config.tcl

# -----------------------------------------------------------------------------
# Validate Configuration
# -----------------------------------------------------------------------------
if {![info exists DESIGN_NAME]} {
    puts "ERROR: DESIGN_NAME not set in config.tcl"
    exit 1
}
if {![info exists TEMP_RESULTS_DIR]} {
    puts "ERROR: TEMP_RESULTS_DIR not set in config.tcl"
    exit 1
}
if {![info exists CORES]} {
    set CORES 4
    puts "WARNING: CORES not set, using default: $CORES"
}

# -----------------------------------------------------------------------------
# Helper Procedures
# -----------------------------------------------------------------------------

# Convert time value with units to numeric ns
proc time_to_ns {time_str} {
    # Handle empty or invalid input
    if {$time_str eq "" || $time_str eq "INFINITY" || $time_str eq "INF"} {
        return 0.0
    }
    
    # Strip whitespace
    set time_str [string trim $time_str]
    
    # Extract numeric part and unit
    if {[regexp {^([0-9.eE+-]+)\s*([a-zA-Z]*)} $time_str -> num unit]} {
        set num [expr {double($num)}]
        
        # Convert to ns based on unit
        switch -nocase $unit {
            "ps" { return [expr {$num / 1000.0}] }
            "ns" { return $num }
            "us" { return [expr {$num * 1000.0}] }
            "ms" { return [expr {$num * 1000000.0}] }
            "s"  { return [expr {$num * 1000000000.0}] }
            ""   { return $num }  ;# assume ns if no unit
            default {
                puts "WARNING: Unknown time unit '$unit', assuming ns"
                return $num
            }
        }
    } else {
        # Try to parse as pure number (assume ns)
        if {[string is double -strict $time_str]} {
            return [expr {double($time_str)}]
        } else {
            puts "ERROR: Cannot parse time value: '$time_str'"
            return 0.0
        }
    }
}

# Safe clock period reader with fallbacks
proc read_clock_period_ns {clk clk_name} {
    set raw ""
    # Try get_attribute first (PrimeTime/pwr_shell)
    if {[catch {set raw [get_attribute -quiet $clk period]}]} {
        # Try get_property (alternate accessor)
        if {[catch {set raw [get_property -quiet $clk period]}]} {
            puts "  WARNING: Cannot read period for clock $clk_name using standard accessors"
            return -1.0
        }
    }
    
    if {$raw eq ""} {
        puts "  WARNING: Empty period returned for clock $clk_name"
        return -1.0
    }
    
    return [time_to_ns $raw]
}

# Parse timing report file to extract slack (fallback method)
proc parse_slack_from_report {report_file} {
    if {![file exists $report_file]} {
        return 0.0
    }
    
    set fp [open $report_file r]
    set content [read $fp]
    close $fp
    
    # Look for slack line: "slack (MET)" or "slack (VIOLATED)"
    if {[regexp {slack\s+\((?:MET|VIOLATED)\s*:\s*([0-9.eE+-]+)\s*([a-zA-Z]*)\)} $content -> num unit]} {
        return [time_to_ns "${num}${unit}"]
    }
    # Alternate format: "  slack     12.34"
    if {[regexp {slack\s+([0-9.eE+-]+)} $content -> num]} {
        return [time_to_ns $num]
    }
    
    return 0.0
}

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
puts "========== Maximum Frequency Characterization (PRODUCTION) =========="
puts "Technology: 45nm CMOS"
puts "Design: $DESIGN_NAME"

# Enable timing analysis features
set_app_var power_enable_rtl_analysis true
set_app_var power_enable_analysis true

# Configure parallel processing
set_host_options -max_cores $CORES
puts "Using $CORES cores for analysis"

# Create temp results directory if it doesn't exist
file mkdir $TEMP_RESULTS_DIR

# -----------------------------------------------------------------------------
# Load Design Data
# -----------------------------------------------------------------------------
puts "========== Loading Design Data =========="

# Read design data from synthesis workspace
read_design_data $OUTPUT_DIR

# Process name mapping
read_name_mapping

# Update metrics to get timing information
update_metrics

# Update timing to enable timing path queries
puts "Updating timing analysis..."
update_timing

puts "Design data loaded successfully"
puts "Checking constraints and timing setup..."

# Verify SDC constraints are loaded
set constraint_check [get_clocks -quiet *]
if {[llength $constraint_check] == 0} {
    puts "WARNING: No clocks found after loading design data."
    puts "         Please verify SDC constraints are properly loaded."
    puts "ERROR: Cannot proceed without clock definitions."
    exit 1
}

# -----------------------------------------------------------------------------
# Maximum Frequency Characterization
# -----------------------------------------------------------------------------
puts "========== Characterizing Maximum Operating Frequency =========="

# Safety margin for recommended operating frequency
set MARGIN_PERCENT 2.0

# Find all clocks in the design
set all_clocks [get_clocks -quiet *]
if {[llength $all_clocks] == 0} {
    puts "ERROR: No clocks found in design. Please check your constraints."
    exit 1
}

puts "Found [llength $all_clocks] clock(s) in design"

# Storage for results across all clocks
set clock_results [list]
set global_min_fmax 999999.0
set global_critical_clock ""

# Analyze each clock domain
foreach clk $all_clocks {
    set clk_name [get_object_name $clk]
    puts "\n----------------------------------------"
    puts "Analyzing clock: $clk_name"
    puts "----------------------------------------"
    
    # Get current clock period with robust unit handling
    set raw_period ""
    if {[catch {set raw_period [get_attribute -quiet $clk period]}]} {
        puts "  WARNING: Cannot read period attribute for clock $clk_name"
        continue
    }
    
    set current_period [time_to_ns $raw_period]
    
    if {$current_period <= 0} {
        puts "  ERROR: Invalid period for clock $clk_name: '$raw_period'"
        puts "         Skipping this clock domain."
        continue
    }
    
    puts "  Current clock period: $current_period ns (raw: $raw_period)"
    
    # Get the worst (most critical) path for this clock domain
    # Use -from_clocks and -to_clocks to focus on this domain
    set paths [get_timing_paths -quiet -delay_type max -max_paths 1 \
                                 -from_clocks $clk -to_clocks $clk]
    
    if {[llength $paths] == 0} {
        puts "  WARNING: No timing paths found for clock $clk_name"
        puts "           This may indicate missing paths or timing exceptions."
        continue
    }
    
    # INDEX THE FIRST PATH OBJECT - critical fix!
    set p [lindex $paths 0]
    
    # Get numeric slack with robust unit handling and fallback
    set raw_slack ""
    set slack 0.0
    
    # Try direct attribute access
    if {[catch {set raw_slack [get_attribute -quiet $p slack]}]} {
        puts "  WARNING: Cannot read slack attribute directly, using fallback..."
        
        # Fallback: generate timing report and parse
        set tmp_report "$TEMP_RESULTS_DIR/_tmp_slack_${clk_name}.txt"
        
        # Use redirect_cmd to capture report output
        redirect -variable timing_output {report_timing -delay_type max -max_paths 1 \
                                          -from_clocks $clk -to_clocks $clk}
        
        # Write to temp file
        set fp [open $tmp_report w]
        puts $fp $timing_output
        close $fp
        
        # Parse slack from report
        set slack [parse_slack_from_report $tmp_report]
        set raw_slack "${slack}ns"
        
        # Clean up temp file
        file delete -force $tmp_report
    } else {
        set slack [time_to_ns $raw_slack]
    }
    
    puts "  Slack: $slack ns (raw: $raw_slack)"
    
    # Compute critical path delay using unified formula: Tmin = period - slack
    # This works for both positive and negative slack
    set Tmin [expr {$current_period - $slack}]
    
    # Sanity check
    if {$Tmin <= 0} {
        puts "  ERROR: Computed Tmin ($Tmin ns) is not positive!"
        puts "         Current period: $current_period ns"
        puts "         Slack: $slack ns"
        puts "         Skipping this clock domain."
        continue
    }
    
    # Determine timing status
    if {$slack >= 0} {
        set timing_status "MET"
    } else {
        set timing_status "VIOLATED"
    }
    
    # Add safety margin
    set Tmin_with_margin [expr {$Tmin * (1.0 + $MARGIN_PERCENT/100.0)}]
    
    # Calculate frequencies (convert from ns to MHz: 1/ns = 1000 MHz)
    set Fmax [expr {1000.0 / $Tmin}]
    set Fmax_with_margin [expr {1000.0 / $Tmin_with_margin}]
    
    # Format results
    set Fmax_formatted [format "%.2f" $Fmax]
    set Fmax_margin_formatted [format "%.2f" $Fmax_with_margin]
    set Tmin_formatted [format "%.4f" $Tmin]
    set Tmin_margin_formatted [format "%.4f" $Tmin_with_margin]
    set slack_formatted [format "%.4f" $slack]
    
    # Extract path endpoints with safe attribute access
    set startpoint "N/A"
    set endpoint "N/A"
    
    if {![catch {set startpoint_obj [get_attribute -quiet $p startpoint]}]} {
        if {$startpoint_obj ne ""} {
            if {![catch {set startpoint [get_object_name $startpoint_obj]}]} {
                # Success - keep the name
            }
        }
    }
    
    if {![catch {set endpoint_obj [get_attribute -quiet $p endpoint]}]} {
        if {$endpoint_obj ne ""} {
            if {![catch {set endpoint [get_object_name $endpoint_obj]}]} {
                # Success - keep the name
            }
        }
    }
    
    # Display results
    puts "  ----------------------------------------"
    puts "  RESULTS FOR CLOCK: $clk_name"
    puts "  ----------------------------------------"
    puts "  Timing Status:                $timing_status"
    puts "  Critical Path Delay (Tmin):   $Tmin_formatted ns"
    puts "  Maximum Frequency:            $Fmax_formatted MHz"
    puts "  Recommended Frequency (${MARGIN_PERCENT}% margin): $Fmax_margin_formatted MHz"
    puts "  Recommended Clock Period:     $Tmin_margin_formatted ns"
    puts "  ----------------------------------------"
    puts "  Critical Path:"
    puts "    Startpoint: $startpoint"
    puts "    Endpoint:   $endpoint"
    puts "  ----------------------------------------"
    
    # Store results for this clock
    lappend clock_results [list $clk_name $timing_status $slack_formatted $Tmin_formatted \
                               $Fmax_formatted $Fmax_margin_formatted $Tmin_margin_formatted \
                               $startpoint $endpoint]
    
    # Track global minimum Fmax (bottleneck)
    if {$Fmax < $global_min_fmax} {
        set global_min_fmax $Fmax
        set global_critical_clock $clk_name
    }
    
    # Generate per-clock timing reports using redirect (not shell >)
    puts "  Generating timing reports for clock $clk_name..."
    
    # Critical path report
    set report_file "$TEMP_RESULTS_DIR/timing_${clk_name}_critical_path.txt"
    redirect -file $report_file {
        report_timing -delay_type max -max_paths 1 -path_type full \
                      -from_clocks $clk -to_clocks $clk
    }
    
    # Top 10 paths report
    set report_file "$TEMP_RESULTS_DIR/timing_${clk_name}_top10_paths.txt"
    redirect -file $report_file {
        report_timing -delay_type max -max_paths 10 -path_type full \
                      -from_clocks $clk -to_clocks $clk
    }
}


# -----------------------------------------------------------------------------
# Generate Reports and Summary
# -----------------------------------------------------------------------------
puts "\n========== Generating Global Summary Reports =========="

# Display global summary
if {[llength $clock_results] == 0} {
    puts "ERROR: No valid clock domains were analyzed!"
    puts "       Please check constraints and timing paths."
    exit 1
}

puts "\n================================================================================"
puts "GLOBAL MAXIMUM FREQUENCY CHARACTERIZATION SUMMARY"
puts "================================================================================"
puts "Total clock domains analyzed: [llength $clock_results]"
puts "Critical bottleneck clock:    $global_critical_clock"
puts "Minimum Fmax across clocks:   [format %.2f $global_min_fmax] MHz"
puts "================================================================================"

# Generate comprehensive summary file
set summary_file [open "$TEMP_RESULTS_DIR/max_frequency_summary.txt" w]

# Create timestamp with proper Tcl quoting
set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]

puts $summary_file "================================================================================"
puts $summary_file "$DESIGN_NAME - 45nm CMOS - Maximum Frequency Characterization"
puts $summary_file "================================================================================"
puts $summary_file ""
puts $summary_file "DESIGN INFORMATION:"
puts $summary_file "  Design Name:           $DESIGN_NAME"
puts $summary_file "  Top Module:            $TOP_MODULE"
puts $summary_file "  Technology:            45nm CMOS"
puts $summary_file "  Process Corner:        $SCENARIO_NAME"
puts $summary_file "  Analysis Date:         $timestamp"
puts $summary_file "  Safety Margin:         ${MARGIN_PERCENT}%"
puts $summary_file ""
puts $summary_file "GLOBAL SUMMARY:"
puts $summary_file "  Clock Domains Analyzed:    [llength $clock_results]"
puts $summary_file "  Critical Bottleneck Clock: $global_critical_clock"
puts $summary_file "  Minimum Fmax:              [format %.2f $global_min_fmax] MHz"
puts $summary_file ""
puts $summary_file "================================================================================"
puts $summary_file "PER-CLOCK DOMAIN ANALYSIS"
puts $summary_file "================================================================================"
puts $summary_file ""

foreach result $clock_results {
    lassign $result clk_name timing_status slack_fmt Tmin_fmt Fmax_fmt Fmax_margin_fmt Tmin_margin_fmt start end
    
    puts $summary_file "CLOCK: $clk_name"
    puts $summary_file "  Timing Status:             $timing_status"
    puts $summary_file "  Slack:                     $slack_fmt ns"
    puts $summary_file "  Critical Path Delay:       $Tmin_fmt ns"
    puts $summary_file "  Maximum Frequency:         $Fmax_fmt MHz"
    puts $summary_file "  Recommended Frequency:     $Fmax_margin_fmt MHz (with ${MARGIN_PERCENT}% margin)"
    puts $summary_file "  Recommended Period:        $Tmin_margin_fmt ns"
    puts $summary_file "  Critical Path:"
    puts $summary_file "    Startpoint:              $start"
    puts $summary_file "    Endpoint:                $end"
    puts $summary_file ""
}

puts $summary_file "================================================================================"
puts $summary_file "NOTES:"
puts $summary_file "  - Fmax is calculated from critical path delay: Fmax = 1000 / Tmin (MHz)"
puts $summary_file "  - Tmin is computed as: Current_Period - Slack"
puts $summary_file "  - Recommended frequency includes ${MARGIN_PERCENT}% safety margin"
puts $summary_file "  - For multi-clock designs, use the minimum Fmax as the bottleneck"
puts $summary_file "  - Verify that all SDC constraints (false_path, multicycle_path) are loaded"
puts $summary_file "  - Slack > 0: timing MET; Slack < 0: timing VIOLATED"
puts $summary_file "================================================================================"

close $summary_file

# Generate CSV for easy import (per-clock)
set csv_file [open "$TEMP_RESULTS_DIR/max_frequency_metrics.csv" w]
puts $csv_file "Clock_Name,Timing_Status,Slack_ns,Critical_Path_Delay_ns,Max_Frequency_MHz,Recommended_Frequency_MHz,Recommended_Period_ns,Startpoint,Endpoint"

foreach result $clock_results {
    lassign $result clk_name timing_status slack_fmt Tmin_fmt Fmax_fmt Fmax_margin_fmt Tmin_margin_fmt start end
    puts $csv_file "$clk_name,$timing_status,$slack_fmt,$Tmin_fmt,$Fmax_fmt,$Fmax_margin_fmt,$Tmin_margin_fmt,$start,$end"
}

close $csv_file

# Generate global metrics CSV
set global_csv [open "$TEMP_RESULTS_DIR/global_max_frequency.csv" w]
puts $global_csv "Metric,Value,Unit"
puts $global_csv "Total_Clocks,[llength $clock_results],-"
puts $global_csv "Critical_Clock,$global_critical_clock,-"
set global_min_fmax_fmt [format "%.2f" $global_min_fmax]
puts $global_csv "Minimum_Fmax,$global_min_fmax_fmt,MHz"
puts $global_csv "Safety_Margin,$MARGIN_PERCENT,%"
puts $global_csv "Design_Name,$DESIGN_NAME,-"
puts $global_csv "Technology,45nm_CMOS,-"
puts $global_csv "Scenario,$SCENARIO_NAME,-"
puts $global_csv "Analysis_Date,$timestamp,-"
close $global_csv

# Generate overall timing report (all clocks) using redirect
puts "Generating overall timing reports..."

set report_file "$TEMP_RESULTS_DIR/timing_overall_critical_path.txt"
redirect -file $report_file {
    report_timing -delay_type max -max_paths 1 -path_type full
}

set report_file "$TEMP_RESULTS_DIR/timing_overall_top20_paths.txt"
redirect -file $report_file {
    report_timing -delay_type max -max_paths 20 -path_type full
}

puts "========== Analysis Complete =========="
puts "Reports generated in: $TEMP_RESULTS_DIR"
puts ""
puts "KEY RESULTS:"
puts "  - Critical bottleneck clock: $global_critical_clock"
puts "  - Minimum Fmax (bottleneck):  [format %.2f $global_min_fmax] MHz"
puts "  - Detailed per-clock results in: max_frequency_summary.txt"
puts "  - CSV exports: max_frequency_metrics.csv, global_max_frequency.csv"
puts ""
puts "VALIDATION NOTES:"
puts "  - Review timing reports to verify critical path extraction"
puts "  - Check that slack values match expectations (positive = MET, negative = VIOLATED)"
puts "  - Confirm all clock domains are represented in results"
puts "  - For cross-clock paths, check timing_overall reports"
puts ""

exit
