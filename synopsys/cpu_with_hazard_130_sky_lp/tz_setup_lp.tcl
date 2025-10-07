#!/bin/tcsh -f
# =============================================================================
# Technology Setup Script for SKY130 Low Power Process
# =============================================================================
# Description: Technology-specific setup for synthesis and optimization
#              targeting SKY130 130nm Low Power process technology
# Author: CO502 Group 1
# Technology: SKY130 130nm Process - Low Power Variant
# Library: sky130_fd_sc_lp (Optimized for minimum power consumption)
# =============================================================================

puts "========== SKY130 Low Power Technology Setup =========="

# -----------------------------------------------------------------------------
# Synthesis Flow Options - Power Optimized
# -----------------------------------------------------------------------------
puts "Configuring synthesis flow options for low power..."

# Enable multi-bit register inference for better area and power
set_app_options -list {compile.flow.enable_multibit true}

# Disable TCL error returns for compatibility
set_app_options -name shell.dc_compatibility.return_tcl_errors -value false

# Control ungrouping behavior
set_app_options -name compile.flow.autoungroup -value false
set_app_options -name compile.datapath.ungroup -value false

# Disable datapath ungrouping for DesignWare components
set_app_options -as_user_default -list {ungr.dw.hlo_enable_dw_ungrp false}

# Enable power optimization features
set_app_options -name compile.power_opt_enable -value true
set_app_options -name rtl_opt.power.enable -value true

puts "Power-focused synthesis options configured"

# -----------------------------------------------------------------------------
# Parasitic Technology Files for SKY130
# -----------------------------------------------------------------------------
puts "Loading SKY130 parasitic technology files..."

# Load parasitic extraction data for SKY130
# Note: Using skywater130 parasitic files - adjust paths if needed
read_parasitic_tech \
    -tlup ../libs/sky130_library/skywater130.nominal.tluplus \
    -name nominal

puts "SKY130 parasitic models loaded"

# -----------------------------------------------------------------------------
# Clock Gating Configuration for SKY130 Low Power
# -----------------------------------------------------------------------------
puts "Setting up aggressive clock gating options for low power..."

# Aggressive clock gating options for maximum power savings
set_clock_gating_options \
    -max_fanout 32 \
    -max_number_of_levels 3 \
    -min_bitwidth 2

# Configure clock gate style for SKY130 - optimized for low power
set_clock_gate_style -target { pos_edge_flip_flop } -test_point before

puts "Aggressive clock gating configured for maximum power savings"

# -----------------------------------------------------------------------------
# Low Power Optimization Control
# -----------------------------------------------------------------------------
puts "Setting low power optimization controls..."

# Enable power optimization
set_app_options -name rtl_opt.conditioning.disable_boundary_optimization_and_auto_ungrouping -value true

# Set user defaults for optimization control
set_app_options -as_user_default -list {compile.flow.autoungroup false}
set_app_options -as_user_default -list {compile.flow.boundary_optimization false}

# Enable power-aware synthesis
set_app_options -name compile.power_opt_enable -value true

# -----------------------------------------------------------------------------
# Operating Scenarios Setup - Low Power
# -----------------------------------------------------------------------------
puts "Creating low power operating scenarios..."

# Create functional mode
create_mode func

# Create nominal corner for SKY130 Low Power (typical conditions)
create_corner nominal

# Create low power scenario combining mode and corner
create_scenario -mode func -corner nominal -name func@nominal_lp

# Set parasitic parameters for the scenario
set_parasitic_parameters \
    -corner nominal \
    -late_spec nominal \
    -early_spec nominal

# Disable hold time analysis for this scenario (faster runtime)
set_scenario_status func@nominal_lp -hold false

# Set current scenario
current_scenario func@nominal_lp

puts "Low power operating scenario func@nominal_lp created and set as current"

# -----------------------------------------------------------------------------
# Load Design Constraints
# -----------------------------------------------------------------------------
puts "Loading design constraints..."

# Source clock constraints
if {[file exists "./sdc/clocks_lp.sdc"]} {
    source ./sdc/clocks_lp.sdc
    puts "Low power clock constraints loaded from ./sdc/clocks_lp.sdc"
} elseif {[file exists "./sdc/clocks.sdc"]} {
    source ./sdc/clocks.sdc
    puts "Standard clock constraints loaded from ./sdc/clocks.sdc"
} else {
    puts "Warning: Clock constraints file not found"
}

# -----------------------------------------------------------------------------
# Power Optimization Settings
# -----------------------------------------------------------------------------
puts "Applying low power optimization settings..."

# Set power optimization priorities
set_power_optimization -power_driven true
set_power_optimization -leakage_driven true

# Enable voltage scaling if available
if {[info commands set_voltage] != ""} {
    # Lower voltage for reduced power (if design can handle it)
    set_voltage -object_list [all_inputs] -voltage 1.62
    set_voltage -object_list [all_outputs] -voltage 1.62
    puts "Voltage scaling applied for low power operation"
}

# Enable activity-based power optimization
set_switching_activity -period 100 -toggle_rate 0.1 -static_probability 0.5

puts "Low power optimization settings applied"

# -----------------------------------------------------------------------------
# Report Setup Status
# -----------------------------------------------------------------------------
puts "========== Setup Status Report =========="
report_scenarios
puts "========== SKY130 Low Power Technology Setup Complete =========="