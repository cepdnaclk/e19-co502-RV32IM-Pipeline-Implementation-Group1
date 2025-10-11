#!/bin/tcsh -f
# =============================================================================
# Shared Configuration File for SKY130 Synthesis Scripts
# =============================================================================
# Description: Common variables and settings for rtla.tcl, restore_new.tcl, 
#              and tz_setup.tcl scripts
# Author: CO502 Group 1
# Technology: SKY130 130nm Process
# =============================================================================

puts "Loading shared configuration..."

# -----------------------------------------------------------------------------
# System Configuration
# -----------------------------------------------------------------------------
# Cores for parallel processing
set CORES 8

# -----------------------------------------------------------------------------
# Design Configuration
# -----------------------------------------------------------------------------
# Design names and top module
set DESIGN_NAME "cpu"
set TOP_MODULE  "cpu"

# -----------------------------------------------------------------------------
# Library Configuration
# -----------------------------------------------------------------------------
# Library names and references
set LIB_NAME   "cpu_LIB"
set REF_LIBS   "sky130_fd_sc_hd.ndm"            ;# one or more NDMs (space-separated)
set TECH_TF    "/tech/sky130/libs/sky130_fd_sc_hd/sky130_fd_sc_hd.tf"

# Search paths for libraries and source files
set SEARCH_PATHS "* ./ ../../cpu/ /tech/sky130/libs/sky130_library/ndm"

# -----------------------------------------------------------------------------
# File Locations
# -----------------------------------------------------------------------------
# Source files
set FILELIST "src.f"

# Power analysis inputs
set FSDB_FILE  "../../cpu/novas.fsdb"
set STRIP_PATH "cpu_tb/cpu_inst"

# -----------------------------------------------------------------------------
# Technology Setup Configuration
# -----------------------------------------------------------------------------
# Parasitic technology files
set TLU_NOMINAL "/tech/sky130/libs/sky130_library/skywater130.nominal.tluplus"
set TLU_NAME    "nominal"

# Clock gating preferences
set CG_MAX_FANOUT 16
set CG_MAX_LEVELS 2
set CG_TARGET     { pos_edge_flip_flop }
set CG_TEST_POINT before

# Scenario configuration
set MODE_NAME     "func"
set CORNER_NAME   "nominal"
set SCENARIO_NAME "func@nominal"

# Constraints
set SDC_FILE "./sdc/clocks.sdc"

# -----------------------------------------------------------------------------
# Output Configuration
# -----------------------------------------------------------------------------
# Directory configuration
set RESULT_DIR   "results"
set OUTPUT_DIR   "TZ_OUTDIR"                     ;# reused by restore_new.tcl

# Temporary results directory for run-time outputs (can be overridden via ENV)
set TEMP_RESULTS_DIR $RESULT_DIR
if {[info exists ::env(TEMP_RESULTS_DIR)]} {
    set TEMP_RESULTS_DIR $::env(TEMP_RESULTS_DIR)
    puts "Using environment TEMP_RESULTS_DIR: $TEMP_RESULTS_DIR"
} else {
    puts "Using default TEMP_RESULTS_DIR: $TEMP_RESULTS_DIR"
}

# -----------------------------------------------------------------------------
# Analysis Configuration
# -----------------------------------------------------------------------------
# Hierarchical levels for reporting
set HIERARCHY_LEVELS {2 3 5 10 20 100}

puts "Configuration loaded successfully"
puts "  Design: $DESIGN_NAME"
puts "  Technology: SKY130 130nm" 
puts "  Cores: $CORES"
puts "  Results directory: $TEMP_RESULTS_DIR"