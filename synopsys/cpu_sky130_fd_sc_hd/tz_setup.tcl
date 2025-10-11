#!/bin/tcsh -f
# =============================================================================
# Technology Setup Script for SKY130 Process
# =============================================================================
# Description: Technology-specific setup for synthesis and optimization
#              targeting SKY130 130nm process technology
# Author: CO502 Group 1
# Technology: SKY130 130nm Process
# =============================================================================

# Load shared configuration
source config.tcl

puts "========== SKY130 Technology Setup =========="

# -----------------------------------------------------------------------------
# Synthesis Flow Options
# -----------------------------------------------------------------------------
puts "Configuring synthesis flow options..."

# Enable multi-bit register inference for better area and power
set_app_options -list {compile.flow.enable_multibit true}

# Disable TCL error returns for compatibility
set_app_options -name shell.dc_compatibility.return_tcl_errors -value false

# Control ungrouping behavior
set_app_options -name compile.flow.autoungroup -value false
set_app_options -name compile.datapath.ungroup -value false

# Disable datapath ungrouping for DesignWare components
set_app_options -as_user_default -list {ungr.dw.hlo_enable_dw_ungrp false}

# -----------------------------------------------------------------------------
# Parasitic Technology Files for SKY130
# -----------------------------------------------------------------------------
puts "Loading SKY130 parasitic technology files..."

# Load parasitic extraction data for SKY130
read_parasitic_tech \
    -tlup $TLU_NOMINAL \
    -name $TLU_NAME

puts "SKY130 parasitic models loaded"

# -----------------------------------------------------------------------------
# Clock Gating Configuration for SKY130
# -----------------------------------------------------------------------------
puts "Setting up clock gating options for SKY130..."

# Clock gating options optimized for SKY130 130nm process
set_clock_gating_options \
    -max_fanout $CG_MAX_FANOUT \
    -max_number_of_levels $CG_MAX_LEVELS

# Configure clock gate style for SKY130
set_clock_gate_style -target $CG_TARGET -test_point $CG_TEST_POINT
 

puts "Clock gating configured for SKY130"

# -----------------------------------------------------------------------------
# Optimization Control
# -----------------------------------------------------------------------------
puts "Setting optimization controls..."

# Disable boundary optimization for better control
set_app_options -name rtl_opt.conditioning.disable_boundary_optimization_and_auto_ungrouping -value true

# Set user defaults for optimization control
set_app_options -as_user_default -list {compile.flow.autoungroup false}
set_app_options -as_user_default -list {compile.flow.boundary_optimization false}

# -----------------------------------------------------------------------------
# Operating Scenarios Setup
# -----------------------------------------------------------------------------
puts "Creating operating scenarios..."

# Create functional mode
create_mode $MODE_NAME

# Create nominal corner for SKY130 (typical conditions)
create_corner $CORNER_NAME

# Create scenario combining mode and corner
create_scenario -mode $MODE_NAME -corner $CORNER_NAME -name $SCENARIO_NAME

# Set parasitic parameters for the scenario
set_parasitic_parameters \
    -corner $CORNER_NAME \
    -late_spec $TLU_NAME \
    -early_spec $TLU_NAME

# Disable hold time analysis for this scenario
set_scenario_status $SCENARIO_NAME -hold false

# Set current scenario
current_scenario $SCENARIO_NAME

puts "Operating scenario $SCENARIO_NAME created and set as current"

# -----------------------------------------------------------------------------
# Load Design Constraints
# -----------------------------------------------------------------------------
puts "Loading design constraints..."

# Source clock constraints
if {[file exists $SDC_FILE]} {
    source $SDC_FILE
    puts "Clock constraints loaded from $SDC_FILE"
} else {
    puts "Warning: Clock constraints file $SDC_FILE not found"
}

# -----------------------------------------------------------------------------
# Report Setup Status
# -----------------------------------------------------------------------------
puts "========== Setup Status Report =========="
report_scenarios
puts "========== SKY130 Technology Setup Complete =========="
