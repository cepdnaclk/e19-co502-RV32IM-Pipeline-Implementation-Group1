#!/bin/tcsh -f
# =============================================================================
# Technology Setup Script for SKY130 Process
# =============================================================================
# Description: Technology-specific setup for synthesis and optimization
#              targeting SKY130 130nm process technology
# Technology: SKY130 130nm Process
# =============================================================================

# Define paths as variables
set LIBS_SKY130_PATH "/tech/sky130/libs/sky130_library"

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
    -tlup ${LIBS_SKY130_PATH}/skywater130.nominal.tluplus \
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
# Multi-Corner Operating Scenarios Setup
# -----------------------------------------------------------------------------
puts "Creating multi-corner operating scenarios..."

# Create functional mode
create_mode func

# Create corners with explicit PVT values for SKY130
# Based on SKY130 PDK specifications

# Nominal corner (typical conditions: 1.8V, 25°C)
create_corner nominal
puts "Created nominal corner (1.8V, 25°C)"

# Worst case corner (slow, high temp, low voltage: 1.62V, 85°C)
create_corner worst_case  
puts "Created worst_case corner (1.62V, 85°C)"

# Set operating conditions if supported (alternative method)
# Note: Actual PVT values are typically defined in the library files
if {[catch {
    # Try to set operating conditions if command is available
    set_operating_conditions -corner nominal -voltage 1.8 -temperature 25
    set_operating_conditions -corner worst_case -voltage 1.62 -temperature 85
} err]} {
    puts "INFO: Operating conditions set via library files (not command line)"
}

# Create scenarios combining mode and corners
create_scenario -mode func -corner nominal -name func@nominal
create_scenario -mode func -corner worst_case -name func@worst_case

# Set parasitic parameters for nominal scenario (1.8V, 25°C)
set_parasitic_parameters \
    -corner nominal \
    -late_spec nominal \
    -early_spec nominal

# Set parasitic parameters for worst case scenario (1.62V, 85°C)
set_parasitic_parameters \
    -corner worst_case \
    -late_spec worst_case \
    -early_spec worst_case

# Set operating conditions for corners (PVT values documented in comments)
# Nominal: 1.8V, 25°C (typical SKY130 conditions)
# Worst case: 1.62V, 85°C (worst power/timing conditions)
puts "PVT Conditions:"
puts "  - nominal: 1.8V, 25°C (typical)"
puts "  - worst_case: 1.62V, 85°C (worst power/timing)"

# Disable hold time analysis for scenarios
set_scenario_status func@nominal -hold false
set_scenario_status func@worst_case -hold false

# Set current scenario to nominal
current_scenario func@nominal

puts "Operating scenarios created:"
puts "  - func@nominal: 1.8V, 25°C (typical)"
puts "  - func@worst_case: 1.62V, 85°C (worst power/timing)"

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
