# SKY130 Technology Configuration for RISC-V CPU Synthesis

## Overview

This document describes the SKY130 technology configuration used in the synthesis and power analysis of the RISC-V CPU pipeline implementation.

## Technology Node

- **Process**: SKY130 (130nm)
- **Foundry**: SkyWater Technology
- **Type**: Open-source PDK (Process Design Kit)
- **Standard Cell Library**: sky130_fd_sc_hd (High Density)

## File Structure and Configuration

### 1. Library Files Used

#### Standard Cell Library

```
../libs/sky130_fd_sc_hd/
├── sky130_fd_sc_hd.tf              # Technology file for Synopsys tools
├── sky130_fd_sc_hd__tt_025C_1v80.db # Liberty database (typical corner)
├── sky130_fd_sc_hd__tt_025C_1v80.lib # Liberty timing file
├── output.lef                       # Layout Exchange Format
├── sky130_v5_5.lef                 # LEF technology file
└── default.svf                     # Setup Verification Format
```

#### NDM Database

```
../libs/sky130_library/ndm/
├── sky130_fd_sc_hd.ndm/            # Synopsys Native Database
└── sram_32_32.ndm/                 # SRAM memory compiler
```

#### Parasitic Extraction

```
../libs/sky130_library/
├── skywater130.nominal.tluplus     # RC parasitic data (nominal corner)
├── skywater130.nominal.itf         # Interface technology file
└── skywater130.mw2itf.map         # Milkyway to ITF mapping
```

### 2. Script Configuration Details

#### rtla.tcl Configuration

```tcl
# Search paths include sky130 libraries
set search_path "* ./ ./INPUT//ndm ../../cpu ../libs/sky130_library/ndm"

# Use sky130 standard cell library
create_lib cpu_LIB -ref_libs "sky130_fd_sc_hd.ndm" -technology ../libs/sky130_fd_sc_hd/sky130_fd_sc_hd.tf
```

#### tz_setup.tcl Configuration

```tcl
# Parasitic technology setup for sky130
read_parasitic_tech -tlup ../libs/sky130_library/skywater130.nominal.tluplus -name nominal

# Operating corner setup
create_mode func
create_corner nominal
create_scenario -mode func -corner nominal -name func@nominal

# Clock gating optimized for sky130
set_clock_gating_options -max_fanout 16 -max_number_of_levels 2
set_clock_gate_style -sequential_cell latch -positive_edge_logic {and or}
```

#### restore_new.tcl Configuration

```tcl
# Include sky130 NDM libraries in search path
set search_path "*  ./ ./INPUT//ndm ../../cpu/ ../libs/sky130_library/ndm"
```

## Technology Characteristics

### Process Parameters

- **Technology Node**: 130nm
- **Minimum Feature Size**: 130nm
- **Supply Voltage**: 1.8V (nominal)
- **Operating Temperature**: 25°C (nominal)
- **Process Corner**: Typical-Typical (TT)

### Standard Cell Library Features

- **Library Type**: High Density (HD)
- **Cell Variants**: Multiple drive strengths (X1, X2, X4, X8)
- **Special Cells**: Clock gates, scan cells, fill cells
- **Logic Families**: Standard CMOS logic

### Metal Stack

- **Metal Layers**: 5 layers (M1-M5)
- **Via Layers**: 4 via layers
- **Top Metal**: Thick metal for power distribution

## Synthesis Flow

### 1. Library Setup

- Load sky130_fd_sc_hd NDM database
- Set technology file for physical constraints
- Configure parasitic extraction models

### 2. Design Constraints

- Clock definitions from `./sdc/clocks.sdc`
- Operating conditions: nominal corner
- Power optimization enabled

### 3. Optimization Settings

- Multi-bit register inference enabled
- Clock gating with fanout limit of 16
- Boundary optimization disabled for better control

### 4. Power Analysis

- RTL power analysis enabled
- FSDB waveform data integration
- Hierarchical power reporting

## Key Differences from TSMC 16nm

| Aspect          | TSMC 16nm (Original) | SKY130 (Updated)    |
| --------------- | -------------------- | ------------------- |
| Process         | 16nm FinFET          | 130nm Planar        |
| Supply Voltage  | 0.8V                 | 1.8V                |
| Corners         | cworst/cbest         | nominal             |
| Parasitic Files | Multiple TLU+        | Single nominal TLU+ |
| Clock Gating    | Max fanout 8         | Max fanout 16       |
| Library Prefix  | ts16nc\*             | sky130_fd_sc_hd     |

## Usage Guidelines

### For Synthesis (rtla.tcl)

1. Ensure sky130 libraries are in correct relative paths
2. Run synthesis with nominal operating conditions
3. Generate power, area, and timing reports

### For Power Analysis (restore_new.tcl)

1. Load pre-synthesized design with sky130 mapping
2. Use FSDB data for switching activity
3. Generate detailed power breakdown reports

### For Setup (tz_setup.tcl)

1. Configure parasitic extraction for sky130
2. Set up nominal operating scenario
3. Apply clock constraints and optimization settings

## Expected Results

- **Area**: Larger than 16nm due to larger feature size
- **Power**: Higher due to 1.8V supply vs 0.8V
- **Timing**: Slower due to larger transistors
- **Yield**: Higher due to mature 130nm process

## Files Generated

- Power reports in `results/` directory
- Synthesized netlist with sky130 cell mapping
- Timing and area analysis reports
- RTL power analysis data

## Notes

- Sky130 is an open-source PDK suitable for academic research
- Provides realistic synthesis results with industry-standard tools
- Simpler corner modeling compared to advanced nodes
- Good balance between accuracy and complexity for educational purposes
