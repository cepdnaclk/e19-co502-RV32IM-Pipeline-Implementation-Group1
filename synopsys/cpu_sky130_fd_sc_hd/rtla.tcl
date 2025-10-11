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
set LIBS_SKY130_PATH "../libs/sky130_library/ndm"
set LIBS_SKY130_FD_SC_HD_PATH "../libs/sky130_fd_sc_hd"
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

# Check FSDB exists (warning only, not fatal)
if {![file exists $FSDB_PATH]} {
    puts "WARNING: FSDB not found at $FSDB_PATH"
    puts "Power analysis will be skipped. Generate FSDB with simulation for power analysis."
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
if {[catch {
    create_lib cpu_LIB \
        -ref_libs "${LIBS_SKY130_PATH}/sky130_fd_sc_hd.ndm" \
        -technology ${LIBS_SKY130_FD_SC_HD_PATH}/sky130_fd_sc_hd.tf
    puts "SKY130 libraries loaded successfully"
} err]} {
    puts "WARNING: Standard library creation failed: $err"
    puts "Trying alternative library setup..."
    
    # Alternative: try to create library without technology file
    if {[catch {
        create_lib cpu_LIB -ref_libs "${LIBS_SKY130_PATH}/sky130_fd_sc_hd.ndm"
        puts "SKY130 libraries loaded with alternative method"
    } err2]} {
        puts "ERROR: Could not create library: $err2"
        error "Library creation failed"
    }
}

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

# Basic clock constraint setup (if no tz_setup.tcl)
# Define a default clock for the CPU design
if {[catch {
    if {[sizeof_collection [get_ports clk*]] > 0} {
        set clk_port [get_ports clk*]
        create_clock -name cpu_clk -period 10.0 $clk_port
        puts "Created default clock constraint: 100MHz (10ns period)"
    } elseif {[sizeof_collection [get_ports clock*]] > 0} {
        set clk_port [get_ports clock*]
        create_clock -name cpu_clk -period 10.0 $clk_port
        puts "Created default clock constraint: 100MHz (10ns period)"
    } else {
        # If no clock port found, create a virtual clock
        create_clock -name virtual_clk -period 10.0
        puts "Created virtual clock: 100MHz (10ns period)"
    }
} err]} {
    puts "WARNING: Clock setup failed: $err"
    puts "Proceeding without clock constraints"
}

# Load technology setup if available
if {[file exists "./tz_setup.tcl"]} {
    puts "Loading technology setup from tz_setup.tcl"
    source ./tz_setup.tcl
} else {
    puts "WARNING: tz_setup.tcl not found, using basic constraints"
    
    # Basic timing constraints with error handling
    if {[catch {
        # Try to set basic constraints if clock exists
        if {[sizeof_collection [get_clocks]] > 0} {
            set_input_delay -clock [get_clocks] 2.0 [all_inputs]
            set_output_delay -clock [get_clocks] 2.0 [all_outputs]
            puts "Basic timing constraints applied"
        }
        
        # Set basic load and driving cell constraints
        set_load 0.1 [all_outputs]
        set_driving_cell -lib_cell sky130_fd_sc_hd__buf_1 -pin A [all_inputs]
        puts "Basic I/O constraints applied"
        
    } err]} {
        puts "WARNING: Constraint setup failed: $err"
        puts "Continuing with minimal constraints"
    }
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
# Multi-Corner Analysis Setup  
# -----------------------------------------------------------------------------
puts "========== Setting up Multi-Corner Analysis =========="

# Simplified single corner approach for RTL synthesis
# Create a single operating condition for synthesis
if {[catch {
    # Try to set up basic operating conditions
    set_operating_conditions -library sky130_fd_sc_hd typical
} err]} {
    puts "WARNING: Could not set operating conditions: $err"
    puts "Continuing with default conditions"
}

# Set up parasitic parameters for basic analysis
if {[catch {
    set_parasitics_parameters -early_spec 0.5 -late_spec 1.5
} err]} {
    puts "WARNING: Could not set parasitic parameters: $err"
}

# -----------------------------------------------------------------------------
# Power Analysis Setup (Simplified for RTL)
# -----------------------------------------------------------------------------
puts "========== Setting up Power Analysis =========="

# Only proceed with power analysis if FSDB exists and design compiled successfully
if {[file exists $FSDB_PATH]} {
    puts "Setting up RTL power analysis with FSDB: $FSDB_PATH"
    
    if {[catch {
        set_rtl_power_analysis_options \
            -design cpu \
            -strip_path cpu_tb/cpu_inst \
            -fsdb "${FSDB_PATH}" \
            -output_dir "results"
            
        export_power_data
        puts "Power analysis data exported successfully"
    } err]} {
        puts "WARNING: Power analysis setup failed: $err"
        puts "Continuing without power analysis"
    }
} else {
    puts "WARNING: FSDB not found, skipping power analysis"
}

# -----------------------------------------------------------------------------
# Generate Reports
# -----------------------------------------------------------------------------
puts "========== Generating Reports =========="

# Create summary file with metadata
set summary_file [open "results/synthesis_summary.txt" w]
puts $summary_file "# SKY130 CPU Synthesis Summary"
puts $summary_file "# Generated: [clock format [clock seconds]]"
puts $summary_file "# Technology: SKY130 130nm (sky130_fd_sc_hd)"
puts $summary_file "# Tool: PrimeTime RTL"
if {[file exists $FSDB_PATH]} {
    puts $summary_file "# FSDB: $FSDB_PATH"
} else {
    puts $summary_file "# FSDB: Not available"
}
puts $summary_file ""
close $summary_file

# Generate basic reports with error handling
if {[catch {report_timing > "results/timing_report.txt"} err]} {
    puts "WARNING: Timing report failed: $err"
}

if {[catch {report_area > "results/area_report.txt"} err]} {
    puts "WARNING: Area report failed: $err"
}

if {[catch {report_qor > "results/qor_report.txt"} err]} {
    puts "WARNING: QoR report failed: $err"
}

# Try to generate power reports only if analysis was successful
if {[file exists $FSDB_PATH]} {
    if {[catch {report_power > "results/power_report.txt"} err]} {
        puts "WARNING: Power report failed: $err"
    }
}

# Generate hierarchy report
if {[catch {report_reference > "results/reference_report.txt"} err]} {
    puts "WARNING: Reference report failed: $err"
}

if {[catch {report_hierarchy > "results/hierarchy_report.txt"} err]} {
    puts "WARNING: Hierarchy report failed: $err"
}

puts "All reports generated in results/ directory"
puts "Ready for gate-level correlation flow"
puts "========== CPU RTL Analysis and Synthesis Complete =========="

exit
