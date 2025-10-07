#!/bin/tcsh -f
# =============================================================================
# Technology Setup Script for SKY130 Process
# =============================================================================
# Description: Technology-specific setup for synthesis and optimization
#              targeting SKY130 130nm process technology
# Author: CO502 Group 1
# Technology: SKY130 130nm Process
# =============================================================================

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
    -tlup ../libs/sky130_library/skywater130.nominal.tluplus \
    -name nominal

puts "SKY130 parasitic models loaded"

# -----------------------------------------------------------------------------
# Clock Gating Configuration for SKY130
# -----------------------------------------------------------------------------
puts "Setting up clock gating options for SKY130..."

# Clock gating options optimized for SKY130 130nm process
set_clock_gating_options \
    -max_fanout 16 \
    -max_number_of_levels 2

# Configure clock gate style for SKY130
set_clock_gate_style -target { pos_edge_flip_flop } -test_point before
 

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
create_mode func

# Create nominal corner for SKY130 (typical conditions)
create_corner nominal

# Create scenario combining mode and corner
create_scenario -mode func -corner nominal -name func@nominal

# Set parasitic parameters for the scenario
set_parasitic_parameters \
    -corner nominal \
    -late_spec nominal \
    -early_spec nominal

# Disable hold time analysis for this scenario
set_scenario_status func@nominal -hold false

# Set current scenario
current_scenario func@nominal

puts "Operating scenario func@nominal created and set as current"

# -----------------------------------------------------------------------------
# Load Design Constraints
# -----------------------------------------------------------------------------
puts "Loading design constraints..."

# Source clock constraints
if {[file exists "./sdc/clocks.sdc"]} {
    source ./sdc/clocks.sdc
    puts "Clock constraints loaded from ./sdc/clocks.sdc"
} else {
    puts "Warning: Clock constraints file ./sdc/clocks.sdc not found"
}

# -----------------------------------------------------------------------------
# Report Setup Status
# -----------------------------------------------------------------------------
puts "========== Setup Status Report =========="
report_scenarios
puts "========== SKY130 Technology Setup Complete =========="
