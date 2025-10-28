# =============================================================================
# Design Constraints for RISC-V CPU - SKY130
# =============================================================================

# Clock Definition
create_clock -name CLK -period 10.0 [get_ports CLK]

# Clock Uncertainty (accounts for jitter and skew)
set_clock_uncertainty 0.5 [get_clocks CLK]

# Clock Transition (rise/fall time)
set_clock_transition 0.2 [get_clocks CLK]

# Input Delays (exclude clock port itself)
set_input_delay -max 2.0 -clock CLK [remove_from_collection [all_inputs] [get_ports CLK]]
set_input_delay -min 0.5 -clock CLK [remove_from_collection [all_inputs] [get_ports CLK]]

# Output Delays
set_output_delay -max 2.0 -clock CLK [all_outputs]
set_output_delay -min 0.5 -clock CLK [all_outputs]

# Drive Strength
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y [remove_from_collection [all_inputs] [get_ports CLK]]

# Output Load
set_load 0.05 [all_outputs]