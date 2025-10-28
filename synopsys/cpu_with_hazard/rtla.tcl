set_current_mismatch_config auto_fix 
set_attribute [get_mismatch_types missing_logical_reference] current_repair(auto_fix) create_blackbox
set CORES 8
set_host_options -max_cores $CORES

set_app_options -list { plan.macro.allow_unmapped_design true}

# -----------------------------------------------------------------------------
# Configuration Variables (add these if not in config.tcl)
# -----------------------------------------------------------------------------
set DESIGN_NAME "cpu"
set TOP_MODULE "cpu"
set SCENARIO_NAME "func@cworst"
set TEMP_RESULTS_DIR "results"

# Create results directory if it doesn't exist
file mkdir $TEMP_RESULTS_DIR

# -----------------------------------------------------------------------------
# Library and Design Setup
# -----------------------------------------------------------------------------
set search_path "* ./ ./INPUT//ndm ../../cpu"
create_lib cpu_LIB -ref_libs "ts16ncfllogl16hdh090f.ndm  ts16ncfllogl16hdl090f.ndm  ts16ncfslogl16hdh090f.ndm  ts16ncfslogl16hdl090f.ndm " -technology ./INPUT/ts16ncfslogl16hdl090f_m11f2f1f3f2f0f2_UTRDL.tf

analyze -f sv -vcs "-f src.f "
elaborate cpu
set_top_module cpu

source tz_setup.tcl

# Force timing update after loading constraints
update_timing

# Verify clock constraints were loaded
puts "========== Verifying Clock Constraints =========="
set all_clocks [get_clocks -quiet *]
if {[llength $all_clocks] == 0} {
    puts "ERROR: No clocks found after loading constraints!"
    puts "Checking for clock ports in design..."
    set clk_ports [get_ports -quiet *CLK*]
    if {[llength $clk_ports] > 0} {
        puts "Found clock port(s): [get_object_name $clk_ports]"
        puts "Attempting to create clock manually..."
        # Try to create clock on CLK port with default period
        create_clock -name CLK -period 10.0 [get_ports CLK]
        set all_clocks [get_clocks -quiet *]
    }
    if {[llength $all_clocks] == 0} {
        puts "FATAL: Unable to create or find clocks. Exiting."
        exit 1
    }
}

puts "Clocks found in design:"
foreach clk $all_clocks {
    set clk_name [get_object_name $clk]
    set clk_period [get_attribute $clk period]
    puts "  - $clk_name (period: $clk_period ns)"
}
puts "=============================================="

rtl_opt
save_lib cpu_LIB
save_block cpu_top_block

set_rtl_power_analysis_options -scenario func@cworst -design cpu -strip_path cpu_tb/cpu_inst -fsdb "../../cpu/novas.fsdb"  -output_dir TZ_OUTDIR
export_power_data

# -----------------------------------------------------------------------------
# Maximum Frequency Characterization
# -----------------------------------------------------------------------------
puts "========== Characterizing Maximum Operating Frequency =========="

# Update timing for accurate analysis
update_timing

# Find all clocks in the design
set all_clocks [get_clocks *]
if {[llength $all_clocks] == 0} {
    puts "ERROR: No clocks found in design. Please check your constraints."
    puts "Available ports: [get_object_name [get_ports *clk*]]"
    exit 1
}

# Get the first clock (or find specific clock pattern)
set current_clk [lindex $all_clocks 0]
set clock_name [get_object_name $current_clk]
puts "Found clock: $clock_name"

# If there are multiple clocks, list them
if {[llength $all_clocks] > 1} {
    puts "Multiple clocks found in design:"
    foreach clk $all_clocks {
        puts "  - [get_object_name $clk]"
    }
    puts "Using first clock: $clock_name for analysis"
}

set current_period [get_attribute $current_clk period]
puts "Current clock period: $current_period ns"

# Get worst negative slack (WNS) and critical path information
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
# Validate that we have the necessary data
if {$current_period == "" || $current_period == 0} {
    puts "ERROR: Invalid clock period retrieved"
    exit 1
}

# Tmin = Current_Period - Slack (if slack is negative, this adds the violation)
# If slack is positive, Tmin = Data_Arrival_Time (critical path delay)
if {$slack >= 0} {
    # Timing is met - use actual critical path delay
    set Tmin $data_arrival
    set timing_status "MET"
} else {
    # Timing violated - need to increase period
    set Tmin [expr {$current_period - $slack}]
    set timing_status "VIOLATED"
}

# Sanity check on calculated values
if {$Tmin <= 0} {
    puts "ERROR: Invalid critical path delay calculated: $Tmin ns"
    puts "Current period: $current_period ns"
    puts "Slack: $slack ns"
    exit 1
}

# Add safety margin (typically 2-5% for publication)
set MARGIN_PERCENT 2.0
set Tmin_with_margin [expr {$Tmin * (1.0 + $MARGIN_PERCENT/100.0)}]

# Calculate frequencies (convert from ns to Hz, then to MHz)
# Fmax in MHz: 1/ns = 1000 MHz
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

# Basic reports
report_power > "$TEMP_RESULTS_DIR/report_power.txt"
report_area > "$TEMP_RESULTS_DIR/report_area.txt" 
report_qor > "$TEMP_RESULTS_DIR/report_qor.txt"

# Detailed timing reports
report_timing -delay_type max -max_paths 1 -path_type full \
    > "$TEMP_RESULTS_DIR/report_timing_critical_path.txt"

report_timing -delay_type max -max_paths 10 -path_type full \
    > "$TEMP_RESULTS_DIR/report_timing_top10_paths.txt"

report_timing -delay_type max -max_paths 1 -nets -transition_time \
    -capacitance -input_pins -significant_digits 4 \
    > "$TEMP_RESULTS_DIR/report_timing_detailed.txt"

# Constraint and violation reports
report_constraint -all_violators > "$TEMP_RESULTS_DIR/report_violations.txt"

# Clock reports
report_clock -skew > "$TEMP_RESULTS_DIR/report_clock.txt"

# Additional useful reports
report_reference > "$TEMP_RESULTS_DIR/report_reference.txt"
report_hierarchy > "$TEMP_RESULTS_DIR/report_hierarchy.txt"

# Design statistics
report_design > "$TEMP_RESULTS_DIR/report_design_stats.txt"

# Process corner information
report_pvt > "$TEMP_RESULTS_DIR/report_pvt.txt"

# -----------------------------------------------------------------------------
# Generate Publication-Ready Summary
# -----------------------------------------------------------------------------
puts "========== Generating Publication Summary =========="

set summary_file [open "$TEMP_RESULTS_DIR/publication_summary.txt" w]

puts $summary_file "================================================================================"
puts $summary_file "RISC-V CPU - Performance Characterization"
puts $summary_file "================================================================================"
puts $summary_file ""
puts $summary_file "DESIGN INFORMATION:"
puts $summary_file "  Design Name:           $DESIGN_NAME"
puts $summary_file "  Top Module:            $TOP_MODULE"
puts $summary_file "  Technology:            TSMC 16nm"
puts $summary_file "  Analysis Date:         [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
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

# Also create a simple CSV for easy import
set csv_file [open "$TEMP_RESULTS_DIR/timing_metrics.csv" w]
puts $csv_file "Metric,Value,Unit"
puts $csv_file "Critical_Path_Delay,$Tmin_formatted,ns"
puts $csv_file "Maximum_Frequency,$Fmax_formatted,MHz"
puts $csv_file "Recommended_Frequency,$Fmax_margin_formatted,MHz"
puts $csv_file "Worst_Slack,$slack,ns"
puts $csv_file "Current_Period,$current_period,ns"
close $csv_file

puts "All reports generated in $TEMP_RESULTS_DIR/ directory"
puts ""
puts "KEY RESULT: Maximum Operating Frequency = $Fmax_formatted MHz"
puts "RECOMMENDED: Use $Fmax_margin_formatted MHz (with ${MARGIN_PERCENT}% margin)"
puts ""
puts "========== RTL Analysis and Synthesis Complete =========="

exit