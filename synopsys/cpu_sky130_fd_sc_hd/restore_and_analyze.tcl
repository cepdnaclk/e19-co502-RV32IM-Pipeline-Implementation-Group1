#!/bin/tcsh -f
# =============================================================================
# restore_and_analyze_fixed.tcl
# Robust Restore + Power + Timing + Fmax Characterization Script
# =============================================================================

# Load shared configuration
if {[file exists "config.tcl"]} {
    source config.tcl
} else {
    puts "ERROR: config.tcl not found. Create or point to it before running."
    exit 1
}

puts "========== Restoring Saved Design (fixed) =========="
puts "Technology: 45nm CMOS"
puts "Design: $DESIGN_NAME"

# -------------------- Helper procs --------------------
# Convert strings with units (e.g., "10ns", "500ps", "0.01us") to numeric ns
proc to_ns {val} {
    if {$val == ""} { return -1 }
    # pure numeric?
    if {[regexp {^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$} $val]} {
        return [expr {double($val)}]
    }
    # unit map
    array set map { ns 1.0 ps 0.001 us 1000.0 ms 1000000.0 }
    set s [string trim $val]
    if {[regexp {^([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\s*([a-zA-Z]+)$} $s -> num unit]} {
        set num [expr {double($num)}]
        set unit [string tolower $unit]
        if {[info exists map($unit)]} { return [expr {$num * $map($unit)}] }
    }
    # fallback: strip non-numeric and parse
    set cleaned [regsub -all {[^0-9eE\+\-\.]} $s ""]
    if {[regexp {^([-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)$} $cleaned -> n]} {
        return [expr {double($n)}]
    }
    return -1
}

# Safe get_attribute wrapper: returns "" on failure
proc safe_get_attr {obj attr} {
    if {$obj eq ""} { return "" }
    if {[catch {get_attribute $obj $attr} res]} { return "" }
    return $res
}

# Safe call wrapper for optional commands (prints warning on failure)
proc try_cmd {cmd_msg body} {
    if {[catch {$body} err]} {
        puts "WARNING: $cmd_msg failed: $err"
        return 0
    }
    return 1
}

# -------------------- System setup --------------------
# Try to set host options if variable present
if {[info exists CORES]} {
    try_cmd "set_host_options -max_cores $CORES" { set_host_options -max_cores $CORES }
    puts "Requested cores: $CORES"
}

# Make sure TEMP_RESULTS_DIR exists
if {![info exists TEMP_RESULTS_DIR]} {
    set TEMP_RESULTS_DIR "./results"
}
if {![file exists $TEMP_RESULTS_DIR]} { file mkdir $TEMP_RESULTS_DIR }

# -------------------- Restore library & block --------------------
puts "========== Opening Saved Library and Block =========="

# Try to open library (catch errors)
try_cmd "open_lib $LIB_NAME" { open_lib $LIB_NAME }

# Verify library existence with get_libs
set libs [catch {get_libs $LIB_NAME} _lib_check]
if {$libs != 0} {
    # get_libs raised an error or returned empty; query generically
    if {[catch {set libs [get_libs $LIB_NAME]} lib_err2]} {
        puts "ERROR: get_libs for '$LIB_NAME' failed: $lib_err2"
        exit 1
    }
}
# After this, $libs may be empty list; ensure llength check
if {[llength $libs] == 0} {
    puts "ERROR: Library '$LIB_NAME' not found. Please run rtla.tcl first to create and save the design."
    exit 1
}
puts "Library '$LIB_NAME' present."

# Find and open the block object
set blocks [get_blocks ${DESIGN_NAME}.design]
if {[llength $blocks] == 0} {
    # try listing available blocks for helpful error message
    set avail_blocks [get_blocks *]
    puts "ERROR: Block '${DESIGN_NAME}.design' not found. Available blocks:"
    foreach b $avail_blocks { puts "  - [get_object_name $b]" }
    exit 1
}
set blk [lindex $blocks 0]
try_cmd "open_block $blk" { open_block $blk }
puts "Successfully restored block: [get_object_name $blk]"

# Set the top module (guarded)
if {[info exists TOP_MODULE] && $TOP_MODULE ne ""} {
    try_cmd "set_top_module $TOP_MODULE" { set_top_module $TOP_MODULE }
    puts "Set top module to $TOP_MODULE"
}

# -------------------- Technology setup & timing update --------------------
puts "========== Reloading Technology Setup =========="
if {[file exists "tz_setup.tcl"]} {
    try_cmd "source tz_setup.tcl" { source tz_setup.tcl }
} else {
    puts "Note: tz_setup.tcl not found; continue assuming environment already configured."
}

try_cmd "update_timing" { update_timing }

# -------------------- Clock verification --------------------
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
    set parsed_period [to_ns $raw_period]
    if {$parsed_period < 0} {
        puts "  - $clk_name (period: $raw_period) -- WARNING: couldn't parse numeric period"
    } else {
        puts "  - $clk_name (period: ${parsed_period} ns)"
    }
}

# -------------------- Power analysis (guarded) --------------------
puts "========== Setting up Power Analysis =========="
# create TEMP_RESULTS_DIR if not exists
if {![file exists $TEMP_RESULTS_DIR]} { file mkdir $TEMP_RESULTS_DIR }

if {[info exists SCENARIO_NAME]} {
    if {![catch {
        set_rtl_power_analysis_options -scenario $SCENARIO_NAME \
            -design $DESIGN_NAME -strip_path $STRIP_PATH -fsdb $FSDB_FILE -output_dir $OUTPUT_DIR
    } pwr_err]} {
        # attempt export
        if {[catch {export_power_data} exp_err]} {
            puts "WARNING: export_power_data failed: $exp_err"
        } else {
            puts "Power analysis data exported"
        }
    } else {
        puts "WARNING: set_rtl_power_analysis_options call failed or not supported"
    }
} else {
    puts "SCENARIO_NAME not set; skipping RTL power config."
}

puts "Note: If your flow requires it, run pwr_shell with restore_new.tcl next for detailed power analysis"

# -------------------- Maximum Frequency Characterization (per-clock) --------------------
puts "========== Characterizing Maximum Operating Frequency =========="
# ensure timing is fresh
try_cmd "update_timing" { update_timing }

# Per-clock CSV
set RESTORE_RESULTS_DIR "$TEMP_RESULTS_DIR/restore_run"
if {![file exists $RESTORE_RESULTS_DIR]} { file mkdir $RESTORE_RESULTS_DIR }
set csv_path [file join $RESTORE_RESULTS_DIR "timing_metrics_per_clock.csv"]
set csv_file [open $csv_path w]
puts $csv_file "Clock,Current_Period_ns,WNS_ns,Critical_Path_Delay_ns,Fmax_MHz,Fmax_with_margin_MHz,Timing_Status,StartPoint,EndPoint"

set MARGIN_PERCENT 2.0

# Analyze each clock domain
foreach clk $all_clocks {
    set clk_name [get_object_name $clk]
    puts "--- Analyzing clock: $clk_name ---"

    set raw_period [safe_get_attr $clk period]
    set current_period [to_ns $raw_period]
    if {$current_period <= 0} {
        puts "  ERROR: invalid or missing period for $clk_name ('$raw_period') -- skipping"
        puts $csv_file "$clk_name,,, , , ,INVALID_PERIOD, , "
        continue
    }
    puts "  Current period: ${current_period} ns"

    # get worst path for this clock (prefer scoping by clock)
    set paths {}
    if {[catch {set paths [get_timing_paths -delay_type max -max_paths 1 -from_clocks $clk -to_clocks $clk]} p_err]} {
        # fallback to global search
        if {[catch {set paths [get_timing_paths -delay_type max -max_paths 1]} p_err2]} {
            puts "  WARNING: get_timing_paths failed: $p_err ; $p_err2"
            set paths {}
        }
    }

    if {[llength $paths] == 0} {
        puts "  WARNING: no timing paths found for $clk_name"
        puts $csv_file "$clk_name,$current_period,,,,,NO_PATH,,"
        continue
    }

    set p [lindex $paths 0] ;# path object
    set raw_slack [safe_get_attr $p slack]
    set slack [to_ns $raw_slack]
    if {$slack < -1e5} { set slack 0 } ;# fallback

    puts "  WNS (raw: $raw_slack) -> $slack ns"

    # Correct unified Tmin formula: Tmin = period - slack
    set Tmin [expr {$current_period - $slack}]
    if {$Tmin <= 0} {
        puts "  ERROR: computed Tmin non-positive ($Tmin ns) for $clk_name -- skipping"
        puts $csv_file "$clk_name,$current_period,$slack,INVALID_TMIN,0,0,INVALID_TMIN,,"
        continue
    }

    set Tmin_with_margin [expr {$Tmin * (1.0 + $MARGIN_PERCENT/100.0)}]
    set Fmax [expr {1000.0 / $Tmin}]
    set Fmax_with_margin [expr {1000.0 / $Tmin_with_margin}]
    set timing_status "MET"
    if {$slack < 0} { set timing_status "VIOLATED" }

    # endpoints
    set sp_obj [safe_get_attr $p startpoint]
    set ep_obj [safe_get_attr $p endpoint]
    set sp_name ""
    set ep_name ""
    if {$sp_obj ne ""} { set sp_name [get_object_name $sp_obj] }
    if {$ep_obj ne ""} { set ep_name [get_object_name $ep_obj] }

    puts "  Critical Path Delay (Tmin): [format %.4f $Tmin] ns"
    puts "  Fmax: [format %.2f $Fmax] MHz (with ${MARGIN_PERCENT}% margin -> [format %.2f $Fmax_with_margin] MHz)"
    puts "  Path endpoints: $sp_name -> $ep_name"
    puts "  Timing status: $timing_status"

    # write CSV row
    puts $csv_file "$clk_name,$current_period,$slack,[format %.4f $Tmin],[format %.2f $Fmax],[format %.2f $Fmax_with_margin],$timing_status,$sp_name,$ep_name"

    # generate per-clock small timing report (best-effort)
    set rpt_tcl [file join $RESTORE_RESULTS_DIR \"${clk_name}_critical_path.txt\"]
    if {[catch {report_timing -delay_type max -max_paths 1 -path_type full -from_clocks $clk -to_clocks $clk > $rpt_tcl} rerr]} {
        # fallback without scoping
        catch {report_timing -delay_type max -max_paths 1 -path_type full > $rpt_tcl}
    }
}

close $csv_file

# -------------------- Generate consolidated publication summary --------------------
set summary_file [open "$RESTORE_RESULTS_DIR/publication_summary.txt" w]
puts $summary_file "================================================================================"
puts $summary_file "$DESIGN_NAME - 45nm CMOS - Performance Characterization (Restored Design)"
puts $summary_file "================================================================================"
puts $summary_file ""
puts $summary_file "DESIGN INFORMATION:"
puts $summary_file "  Design Name:           $DESIGN_NAME"
puts $summary_file "  Top Module:            $TOP_MODULE"
puts $summary_file "  Technology:            45nm CMOS"
puts $summary_file "  Analysis Date:         [clock format [clock seconds] -format \"%Y-%m-%d %H:%M:%S\"]"
puts $summary_file "  Analysis Type:         Restored from saved design"
puts $summary_file ""
puts $summary_file "TIMING ANALYSIS:"
puts $summary_file "  Per-clock metrics CSV: $csv_path"
puts $summary_file ""
puts $summary_file "================================================================================"
close $summary_file

puts "All reports generated in $RESTORE_RESULTS_DIR/"
puts "Per-clock CSV: $csv_path"
puts ""
puts "========== Restore and Analysis Complete =========="

exit 0
