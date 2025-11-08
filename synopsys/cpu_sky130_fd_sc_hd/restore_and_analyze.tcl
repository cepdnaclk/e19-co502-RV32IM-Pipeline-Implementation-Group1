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
# Robust Helper Procedures
# -----------------------------------------------------------------------------

# Convert attribute string with units to floating ns
proc to_ns {val} {
    if {[string length $val] == 0} { return -1 }
    if {[regexp {^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$} $val]} {
        return [expr {double($val)}]
    }
    set map { ns 1.0 ps 0.001 us 1000.0 ms 1000000.0 }
    set s [string trim $val]
    if {[regexp {^([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\s*([a-zA-Z]+)$} $s -> num unit]} {
        set num [expr {double($num)}]
        set unit [string tolower $unit]
        if {[dict exists $map $unit]} { return [expr {$num * [dict get $map $unit]}] }
    }
    # fallback: remove non-numeric chars then parse
    set cleaned [regsub -all {[^0-9eE\+\-\.]} $s ""]
    if {[regexp {^([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)$} $cleaned -> n]} {
        return [expr {double($n)}]
    }
    return -1
}

# Safe get_attribute wrapper
proc safe_get_attr {obj attr} {
    if {$obj eq ""} { return "" }
    if {[catch {get_attribute $obj $attr} res]} { return "" }
    return $res
}

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

# Try to open library but don't assume command will throw if missing
if {[catch {open_lib $LIB_NAME} lib_err]} {
    puts "ERROR: open_lib failed: $lib_err"
    # continue to check existence anyway
}

# Check libs via get_libs
set libs [get_libs $LIB_NAME]
if {[llength $libs] == 0} {
    puts "ERROR: Library '$LIB_NAME' not found (get_libs returned nothing)."
    puts "Please run rtla.tcl first to create and save the initial design."
    exit 1
} else {
    puts "Library '$LIB_NAME' present."
}

# Find the block object and open it
set blocks [get_blocks ${DESIGN_NAME}.design]
if {[llength $blocks] == 0} {
    # try generic block query
    set blocks [get_blocks *]
    puts "ERROR: Block '${DESIGN_NAME}.design' not found. Available blocks:"
    foreach b $blocks { puts "  - [get_object_name $b]" }
    puts "Please run rtla.tcl first to create and save the initial design."
    exit 1
}
# open the first matching block object
set blk [lindex $blocks 0]
if {[catch {open_block $blk} ob_err]} {
    puts "ERROR: open_block failed: $ob_err"
    exit 1
}
puts "Successfully restored design block: [get_object_name $blk]"

# set top module (guarded)
if {[catch {set_top_module $TOP_MODULE} st_err]} {
    puts "Note: set_top_module failed or not supported: $st_err"
} else {
    puts "Set top module to $TOP_MODULE"
}

# -----------------------------------------------------------------------------
# Technology Setup and Constraints
# -----------------------------------------------------------------------------
puts "========== Reloading Technology Setup =========="
source tz_setup.tcl

# Force timing update
if {[catch {update_timing} ut_err]} { 
    puts "Note: update_timing failed: $ut_err" 
}

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
    set raw_period [safe_get_attr $clk period]
    set clk_period [to_ns $raw_period]
    if {$clk_period > 0} {
        puts "  - $clk_name (period: $clk_period ns)"
    } else {
        puts "  - $clk_name (period: $raw_period [PARSING ERROR])"
    }
}

# -----------------------------------------------------------------------------
# Power Analysis Setup
# -----------------------------------------------------------------------------
puts "========== Setting up Power Analysis =========="

# Create temp results directory if it doesn't exist
if {![file exists $TEMP_RESULTS_DIR]} { 
    file mkdir $TEMP_RESULTS_DIR 
}

# Configure RTL power analysis (guarded for tool compatibility)
if {[catch {
    set_rtl_power_analysis_options \
        -scenario $SCENARIO_NAME \
        -design $DESIGN_NAME \
        -strip_path $STRIP_PATH \
        -fsdb $FSDB_FILE \
        -output_dir $OUTPUT_DIR
} err]} {
    puts "WARNING: set_rtl_power_analysis_options failed: $err"
    puts "         (This may be expected if not in rtl_shell with power support)"
} else {
    if {[catch {export_power_data} exp_err]} {
        puts "WARNING: export_power_data failed: $exp_err"
    } else {
        puts "Power analysis data exported"
        puts "Note: Run pwr_shell with restore_new.tcl next for detailed power analysis"
    }
}

# -----------------------------------------------------------------------------
# Maximum Frequency Characterization (Per-Clock Analysis)
# -----------------------------------------------------------------------------
puts "========== Characterizing Maximum Operating Frequency =========="

# Update timing for accurate analysis
if {[catch {update_timing} ut_err]} { 
    puts "Note: update_timing failed: $ut_err" 
}

set all_clocks [get_clocks *]
if {[llength $all_clocks] == 0} {
    puts "ERROR: No clocks found after loading constraints!"
    exit 1
}

# Create subdirectory for restore run reports
set RESTORE_RESULTS_DIR "$TEMP_RESULTS_DIR/restore_run"
if {![file exists $RESTORE_RESULTS_DIR]} { 
    file mkdir $RESTORE_RESULTS_DIR 
}

# Analyze every clock (safer) and produce a per-clock CSV
set csv_file [open "$RESTORE_RESULTS_DIR/timing_metrics_per_clock.csv" w]
puts $csv_file "Clock,Period_ns,WNS_ns,CriticalDelay_ns,Fmax_MHz,Fmax_margin_MHz,Status,Start,End"

set MARGIN_PERCENT 2.0
set global_worst_slack 1000.0
set global_min_fmax 10000.0
set global_clock_name ""

foreach clk $all_clocks {
    set clk_name [get_object_name $clk]
    puts "Analyzing clock: $clk_name"

    set raw_period [safe_get_attr $clk period]
    set current_period [to_ns $raw_period]
    if {$current_period <= 0} {
        puts "  ERROR: invalid period for $clk_name ('$raw_period') - skipping"
        continue
    }
    puts "  Current clock period: $current_period ns"

    # Query top path for this clock domain
    set paths {}
    if {[catch {set paths [get_timing_paths -delay_type max -max_paths 1 -from_clocks $clk -to_clocks $clk]} p_err]} {
        # fallback global query
        if {[catch {set paths [get_timing_paths -delay_type max -max_paths 1]} p_err2]} {
            puts "  WARNING: get_timing_paths failed: $p_err ; $p_err2"
            set paths {}
        }
    }

    if {[llength $paths] == 0} {
        puts "  WARNING: No timing paths found for $clk_name"
        puts $csv_file "$clk_name,$current_period,,,,,NO_PATH,,"
        continue
    }

    # Get the first path object (index into list)
    set p [lindex $paths 0]
    set raw_slack [safe_get_attr $p slack]
    set slack [to_ns $raw_slack]
    if {$slack == -1} { 
        puts "  WARNING: Could not parse slack ('$raw_slack'), assuming 0"
        set slack 0 
    }

    # Calculate minimum period: Tmin = period - slack
    set Tmin [expr {$current_period - $slack}]
    if {$Tmin <= 0} {
        puts "  ERROR: computed Tmin non-positive ($Tmin ns) for $clk_name"
        puts $csv_file "$clk_name,$current_period,$slack,INVALID,0,0,INVALID_TMIN,,"
        continue
    }

    set Tmin_margin [expr {$Tmin * (1.0 + $MARGIN_PERCENT/100.0)}]
    set Fmax [expr {1000.0 / $Tmin}]
    set Fmax_margin [expr {1000.0 / $Tmin_margin}]
    set status "MET"
    if {$slack < 0} { set status "VIOLATED" }

    # Get startpoint and endpoint
    set sp [safe_get_attr $p startpoint]
    set ep [safe_get_attr $p endpoint]
    set spn [expr {$sp ne "" ? [get_object_name $sp] : ""}]
    set epn [expr {$ep ne "" ? [get_object_name $ep] : ""}]

    puts "  WNS: $slack ns"
    puts "  Critical delay: [format %.4f $Tmin] ns"
    puts "  Fmax: [format %.2f $Fmax] MHz"
    puts "  Fmax (with ${MARGIN_PERCENT}% margin): [format %.2f $Fmax_margin] MHz"
    puts "  Status: $status"
    
    puts $csv_file "$clk_name,$current_period,$slack,[format %.4f $Tmin],[format %.2f $Fmax],[format %.2f $Fmax_margin],$status,$spn,$epn"

    # Track global worst case
    if {$slack < $global_worst_slack} {
        set global_worst_slack $slack
        set global_min_fmax $Fmax_margin
        set global_clock_name $clk_name
    }

    # Write small per-clock timing report (best-effort)
    set rpt "$RESTORE_RESULTS_DIR/${clk_name}_critical_path.txt"
    if {[catch {
        report_timing -delay_type max -max_paths 1 -path_type full \
            -from_clocks $clk -to_clocks $clk > $rpt
    } r_err]} {
        # Fallback without clock filters
        catch {report_timing -delay_type max -max_paths 1 -path_type full > $rpt}
    }
}

close $csv_file

puts "================================================"
puts "MAXIMUM FREQUENCY CHARACTERIZATION RESULTS"
puts "================================================"
if {$global_clock_name ne ""} {
    puts "Worst Clock: $global_clock_name"
    puts "Worst Slack: $global_worst_slack ns"
    puts "Recommended Maximum Frequency: [format %.2f $global_min_fmax] MHz (with ${MARGIN_PERCENT}% margin)"
} else {
    puts "No valid timing paths analyzed"
}
puts "================================================"
puts "Per-clock details saved to: timing_metrics_per_clock.csv"
puts "================================================"

# -----------------------------------------------------------------------------
# Generate Comprehensive Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

# Basic reports (with error handling)
if {[catch {report_power > "$RESTORE_RESULTS_DIR/report_power.txt"} err]} {
    puts "WARNING: report_power failed: $err"
}
if {[catch {report_area > "$RESTORE_RESULTS_DIR/report_area.txt"} err]} {
    puts "WARNING: report_area failed: $err"
}
if {[catch {report_qor > "$RESTORE_RESULTS_DIR/report_qor.txt"} err]} {
    puts "WARNING: report_qor failed: $err"
}

# Detailed timing reports
if {[catch {
    report_timing -delay_type max -max_paths 1 -path_type full \
        > "$RESTORE_RESULTS_DIR/report_timing_critical_path.txt"
} err]} {
    puts "WARNING: report_timing (critical path) failed: $err"
}

if {[catch {
    report_timing -delay_type max -max_paths 10 -path_type full \
        > "$RESTORE_RESULTS_DIR/report_timing_top10_paths.txt"
} err]} {
    puts "WARNING: report_timing (top10) failed: $err"
}

if {[catch {
    report_timing -delay_type max -max_paths 1 -nets -transition_time \
        -capacitance -input_pins -significant_digits 4 \
        > "$RESTORE_RESULTS_DIR/report_timing_detailed.txt"
} err]} {
    puts "WARNING: report_timing (detailed) failed: $err"
}

# Constraint and violation reports
if {[catch {
    report_constraint -all_violators > "$RESTORE_RESULTS_DIR/report_violations.txt"
} err]} {
    puts "WARNING: report_constraint failed: $err"
}

# Clock reports
if {[catch {
    report_clock -skew > "$RESTORE_RESULTS_DIR/report_clock.txt"
} err]} {
    puts "WARNING: report_clock failed: $err"
}

# Additional reports
catch {report_reference > "$RESTORE_RESULTS_DIR/report_reference.txt"}
catch {report_hierarchy > "$RESTORE_RESULTS_DIR/report_hierarchy.txt"}
catch {report_design > "$RESTORE_RESULTS_DIR/report_design_stats.txt"}
catch {report_pvt > "$RESTORE_RESULTS_DIR/report_pvt.txt"}

puts "All reports generated in $RESTORE_RESULTS_DIR/ directory"

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

# Use global worst-case results from per-clock analysis
if {$global_clock_name ne ""} {
    puts $summary_file "TIMING ANALYSIS (WORST CASE):"
    puts $summary_file "  Critical Clock:        $global_clock_name"
    puts $summary_file "  Worst Slack (WNS):     [format %.4f $global_worst_slack] ns"
    if {$global_worst_slack >= 0} {
        puts $summary_file "  Timing Status:         MET"
    } else {
        puts $summary_file "  Timing Status:         VIOLATED"
    }
    puts $summary_file ""
    puts $summary_file "MAXIMUM FREQUENCY CHARACTERIZATION:"
    puts $summary_file "  Recommended Frequency: [format %.2f $global_min_fmax] MHz"
    puts $summary_file "  Safety Margin:         ${MARGIN_PERCENT}%"
    puts $summary_file ""
} else {
    puts $summary_file "TIMING ANALYSIS:"
    puts $summary_file "  Status:                No timing paths found"
    puts $summary_file ""
}

puts $summary_file "MULTI-CLOCK ANALYSIS:"
puts $summary_file "  Number of Clocks:      [llength $all_clocks]"
puts $summary_file "  Per-Clock Results:     See timing_metrics_per_clock.csv"
foreach clk $all_clocks {
    puts $summary_file "    - [get_object_name $clk]"
}
puts $summary_file ""

puts $summary_file "PROCESS CORNER:"
puts $summary_file "  Scenario:              $SCENARIO_NAME"
puts $summary_file "  Corner:                Cmax (Worst Case)"
puts $summary_file ""
puts $summary_file "================================================================================"
puts $summary_file "DETAILED REPORTS AVAILABLE:"
puts $summary_file "  - timing_metrics_per_clock.csv        Per-clock frequency analysis"
foreach clk $all_clocks {
    set clk_name [get_object_name $clk]
    puts $summary_file "  - ${clk_name}_critical_path.txt       Critical path for $clk_name"
}
puts $summary_file "  - report_timing_critical_path.txt     Overall critical path breakdown"
puts $summary_file "  - report_timing_top10_paths.txt       Top 10 critical paths"
puts $summary_file "  - report_timing_detailed.txt          Full timing details with nets"
puts $summary_file "  - report_violations.txt               All timing violations"
puts $summary_file "  - report_power.txt                    Power analysis"
puts $summary_file "  - report_area.txt                     Area breakdown"
puts $summary_file "  - report_qor.txt                      Quality of Results summary"
puts $summary_file "================================================================================"

close $summary_file

puts ""
if {$global_clock_name ne ""} {
    puts "KEY RESULT: Maximum Operating Frequency = [format %.2f $global_min_fmax] MHz (with ${MARGIN_PERCENT}% margin)"
    puts "Critical Clock: $global_clock_name"
}
puts ""
puts "========== Restore and Analysis Complete =========="

exit
