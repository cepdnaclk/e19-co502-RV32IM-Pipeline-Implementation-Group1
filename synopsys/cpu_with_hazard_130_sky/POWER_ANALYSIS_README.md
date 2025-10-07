# SKY130 Power Analysis Scripts Documentation

## Overview

This directory contains scripts for synthesizing and analyzing power consumption of a RISC-V CPU pipeline implementation using the SKY130 130nm process technology. The workflow consists of RTL synthesis, technology-specific setup, and comprehensive power analysis.

## Technology Configuration

### Process Details

- **Technology Node**: SKY130 (130nm)
- **Foundry**: SkyWater Technology
- **PDK Type**: Open-source Process Design Kit
- **Standard Cell Library**: sky130_fd_sc_hd (High Density)
- **Supply Voltage**: 1.8V (nominal)
- **Operating Corner**: Nominal (typical conditions)

### Key Features

- Multi-bit register inference for area/power optimization
- Clock gating with fanout optimization
- Parasitic-aware power analysis
- Hierarchical power reporting

## Script Files and Workflow

### 1. `rtla.tcl` - Main RTL Analysis and Synthesis Script

**Purpose**: Primary synthesis script that performs RTL analysis, elaboration, and optimization.

**Key Functions**:

- **Library Setup**: Configures SKY130 reference libraries and technology files
- **RTL Analysis**: Analyzes SystemVerilog source files
- **Design Elaboration**: Creates synthesizable netlist
- **RTL Optimization**: Performs area, timing, and power optimization
- **Power Analysis Setup**: Configures RTL power analysis with FSDB data
- **Report Generation**: Creates power, area, timing, and QoR reports

**Key Configuration**:

```tcl
# SKY130 Library Configuration
set search_path "* ./ ./INPUT//ndm ../../cpu ../libs/sky130_library/ndm"
create_lib cpu_LIB \
    -ref_libs "sky130_fd_sc_hd.ndm" \
    -technology ../libs/sky130_fd_sc_hd/sky130_fd_sc_hd.tf

# Power Analysis Setup
set_rtl_power_analysis_options \
    -scenario func@nominal \
    -design cpu \
    -strip_path cpu_tb/cpu_inst \
    -fsdb "../../cpu/novas.fsdb" \
    -output_dir TZ_OUTDIR
```

**Generated Reports**:

- `results/report_power.txt` - Overall power consumption
- `results/report_area.txt` - Area utilization
- `results/report_timing.txt` - Timing analysis
- `results/report_qor.txt` - Quality of Results summary
- `results/report_reference.txt` - Cell usage statistics
- `results/report_hierarchy.txt` - Design hierarchy

**Execution**: `rtl_shell -f rtla.tcl`

---

### 2. `tz_setup.tcl` - Technology Setup Script

**Purpose**: Technology-specific configuration for SKY130 process, sourced by `rtla.tcl`.

**Key Functions**:

- **Synthesis Flow Options**: Configures multi-bit inference and optimization controls
- **Parasitic Models**: Loads SKY130 RC extraction data
- **Clock Gating**: Sets up power-efficient clock gating
- **Operating Scenarios**: Creates nominal corner for typical conditions
- **Design Constraints**: Loads timing constraints

**Key Configuration**:

```tcl
# Parasitic Technology Files
read_parasitic_tech \
    -tlup ../libs/sky130_library/skywater130.nominal.tluplus \
    -name nominal

# Clock Gating for SKY130
set_clock_gating_options \
    -max_fanout 16 \
    -max_number_of_levels 2
set_clock_gate_style -target { pos_edge_flip_flop } -test_point before

# Operating Scenario
create_scenario -mode func -corner nominal -name func@nominal
```

**Features**:

- **Multi-bit Registers**: Enabled for better area/power efficiency
- **Clock Gating**: Optimized for SKY130 with 16 fanout limit
- **Boundary Optimization**: Disabled for better design control
- **Hold Analysis**: Disabled for faster runtime

---

### 3. `restore_new.tcl` - Power Analysis and Metrics Script

**Purpose**: Comprehensive power analysis script that generates detailed power reports.

**Key Functions**:

- **Power Analysis Engine**: Configures advanced RTL power analysis
- **Component Analysis**: Power breakdown by logic type
- **Hierarchical Analysis**: Multi-level design hierarchy power reports
- **RTL Metrics**: Clock gating efficiency and register analysis
- **Validation**: Power analysis consistency checks

**Key Configuration**:

```tcl
# Power Analysis Features
set_app_var power_enable_rtl_analysis true
set_app_var power_enable_analysis true
set_app_var power_enable_multi_rtl_to_gate_mapping true
set_app_var power_enable_advanced_fsdb_reader true
set_app_var power_rtl_report_register_use_cg_logic_clustering true
```

**Generated Reports**:

#### Component Power Analysis:

- `results/power_register.txt` - Register power consumption
- `results/power_sequential.txt` - Sequential logic power
- `results/power_combinational.txt` - Combinational logic power
- `results/power_black_box.txt` - Black box/memory power
- `results/power_io_pad.txt` - I/O pad power

#### Hierarchical Power Analysis:

- `results/power_by_module_2.txt` - 2-level hierarchy
- `results/power_by_module_3.txt` - 3-level hierarchy
- `results/power_by_module_5.txt` - 5-level hierarchy
- `results/power_by_module_10.txt` - 10-level hierarchy
- `results/power_by_module_20.txt` - 20-level hierarchy
- `results/power_by_module_100.txt` - Full hierarchy
- `results/power_by_module_complete.txt` - Comprehensive report

#### RTL Metrics:

- `results/rtl_metrics_list.txt` - Available metrics list
- `results/rtl_metrics_hier.txt` - Hierarchical RTL metrics
- `results/rtl_metrics_register.txt` - Register-level metrics

#### Validation and Summary:

- `results/check_rtl_power.txt` - Power analysis validation
- `results/power_summary_detailed.txt` - Detailed power summary
- `results/power_analysis_summary.txt` - Key metrics summary

**Execution**: `rtl_shell -f restore_new.tcl` (after running `rtla.tcl`)

---

## Library Files Used

### SKY130 Standard Cell Library

```
../libs/sky130_fd_sc_hd/
├── sky130_fd_sc_hd.tf              # Technology file for Synopsys
├── sky130_fd_sc_hd__tt_025C_1v80.db # Liberty database (typical corner)
├── sky130_fd_sc_hd__tt_025C_1v80.lib # Liberty timing file
├── output.lef                       # Layout Exchange Format
├── sky130_v5_5.lef                 # LEF technology file
└── default.svf                     # Setup Verification Format
```

### NDM Database

```
../libs/sky130_library/ndm/
├── sky130_fd_sc_hd.ndm/            # Synopsys Native Database
└── sram_32_32.ndm/                 # SRAM memory compiler
```

### Parasitic Extraction

```
../libs/sky130_library/
├── skywater130.nominal.tluplus     # RC parasitic data (nominal corner)
├── skywater130.nominal.itf         # Interface technology file
└── skywater130.mw2itf.map         # Milkyway to ITF mapping
```

### Design Constraints

```
./sdc/clocks.sdc                    # Clock timing constraints
```

### Waveform Data

```
../../cpu/novas.fsdb                # Switching activity data
```

## Execution Workflow

### Step 1: RTL Synthesis and Initial Power Setup

```bash
rtl_shell -f rtla.tcl
```

**Duration**: 10-30 minutes (depending on design size)

**Outputs**:

- Synthesized netlist with SKY130 cell mapping
- Initial power analysis setup
- Basic reports (power, area, timing, QoR)

### Step 2: Detailed Power Analysis

```bash
rtl_shell -f restore_new.tcl
```

**Duration**: 5-15 minutes

**Outputs**:

- Comprehensive power breakdown reports
- Hierarchical power analysis at multiple levels
- RTL metrics and clock gating efficiency
- Power analysis validation

### Step 3: Results Analysis

Check the `results/` directory for all generated reports.

## Key Power Analysis Features

### 1. RTL Power Analysis

- **FSDB Integration**: Uses switching activity from simulation
- **Gate-level Mapping**: Maps RTL to synthesized gates for accuracy
- **Activity Propagation**: Propagates switching activity through hierarchy

### 2. Component-based Analysis

- **Register Power**: Clock tree and register file power
- **Combinational Logic**: Datapath and control logic power
- **Sequential Logic**: State machines and pipeline registers
- **Memory Power**: Cache and memory interface power

### 3. Hierarchical Analysis

- **Multi-level Reporting**: 2 to 100 hierarchy levels
- **Module-wise Breakdown**: Power per CPU module (IF, ID, EX, MEM, WB)
- **Detailed Verbosity**: Comprehensive power attribution

### 4. Clock Gating Analysis

- **Gated Register Count**: Number of clock-gated registers
- **ICG Cell Count**: Integrated clock gate usage
- **Gating Efficiency**: Power savings from clock gating
- **Root Clock Analysis**: Clock tree power breakdown

## Expected Results

### Power Distribution (Typical)

- **Dynamic Power**: 60-80% of total power
- **Leakage Power**: 20-40% of total power
- **Clock Power**: 30-50% of dynamic power
- **Register Power**: 20-30% of total power

### SKY130 vs Advanced Nodes

- **Higher Absolute Power**: Due to 1.8V supply vs 0.8V in advanced nodes
- **Lower Power Density**: Larger transistors spread power over more area
- **Better Leakage Control**: Mature process with well-controlled leakage
- **Clock Gating Benefits**: Significant power savings in 130nm

## Troubleshooting

### Common Issues

1. **Library Path Errors**: Ensure SKY130 libraries are in correct relative paths
2. **FSDB File Missing**: Check that simulation generated `novas.fsdb`
3. **Constraints Missing**: Verify `./sdc/clocks.sdc` exists
4. **Memory Issues**: Large designs may need increased memory limits

### Debug Commands

```tcl
# Check library loading
report_lib
report_reference

# Verify scenarios
report_scenarios

# Check power analysis status
check_rtl_power
```

## Performance Tips

### For Faster Runtime

- Use fewer hierarchy levels in power reports
- Reduce FSDB analysis window
- Disable hold analysis (`set_scenario_status -hold false`)

### For More Accuracy

- Include more switching activity data
- Use more detailed parasitic models
- Enable additional power analysis features

## Files Summary

| File                      | Purpose               | Input Dependencies       | Key Outputs                        |
| ------------------------- | --------------------- | ------------------------ | ---------------------------------- |
| `rtla.tcl`                | Main synthesis script | RTL sources, SKY130 libs | Synthesized netlist, basic reports |
| `tz_setup.tcl`            | Technology setup      | SKY130 parasitic files   | Process configuration              |
| `restore_new.tcl`         | Power analysis        | Synthesized design, FSDB | Detailed power reports             |
| `SKY130_CONFIG_README.md` | Configuration docs    | -                        | Documentation                      |

This workflow provides comprehensive power analysis capabilities for the RISC-V CPU implementation using industry-standard tools and the open-source SKY130 process technology.
