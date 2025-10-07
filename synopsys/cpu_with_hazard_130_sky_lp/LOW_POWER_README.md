# SKY130 Low Power Analysis Scripts Documentation

## Overview

This directory contains scripts for synthesizing and analyzing the **lowest possible power consumption** of a RISC-V CPU pipeline implementation using the **SKY130 Low Power (LP) library**. This variant is optimized specifically for battery-powered and power-sensitive applications.

## Technology Configuration - Low Power Variant

### Process Details

- **Technology Node**: SKY130 (130nm)
- **Foundry**: SkyWater Technology
- **Standard Cell Library**: **sky130_fd_sc_lp (Low Power)** ⚡
- **Optimization Target**: **Minimum Power Consumption**
- **Supply Voltage**: 1.8V (nominal, can be scaled lower)
- **Operating Corner**: Nominal (typical conditions)
- **Transistor Type**: High Vt (High Threshold Voltage) for minimum leakage

### Key Low Power Features

- **Aggressive Clock Gating**: Up to 32 fanout, 3 levels, minimum 2-bit width
- **Power-Driven Synthesis**: Enabled power optimization throughout flow
- **Leakage Optimization**: High Vt transistors for 50-70% leakage reduction
- **Activity-Based Optimization**: Low switching activity assumptions
- **Voltage Scaling Ready**: Supports reduced supply voltage

## Expected Power Improvements vs High Density Library

| Metric            | sky130_fd_sc_hd (Baseline) | sky130_fd_sc_lp (Low Power) | Improvement             |
| ----------------- | -------------------------- | --------------------------- | ----------------------- |
| **Leakage Power** | 100%                       | **30-50%**                  | **50-70% reduction** ⚡ |
| **Dynamic Power** | 100%                       | **70-80%**                  | **20-30% reduction**    |
| **Total Power**   | 100%                       | **50-70%**                  | **30-50% reduction**    |
| **Clock Power**   | 100%                       | **60-75%**                  | **25-40% reduction**    |
| **Performance**   | 100%                       | **50-70%**                  | 30-50% slower ⚠️        |
| **Area**          | 100%                       | **110-120%**                | 10-20% larger           |

## Script Files and Low Power Workflow

### 1. `rtla.tcl` - Low Power RTL Analysis and Synthesis

**Key Low Power Enhancements**:

```tcl
# Use Low Power Library
create_lib cpu_LP_LIB \
    -ref_libs "sky130_fd_sc_lp.ndm" \
    -technology ../libs/sky130_fd_sc_lp/sky130_fd_sc_lp.tf

# Enable Power Optimization
set_app_options -name compile.power_opt_enable -value true
set_app_options -name rtl_opt.power.enable -value true

# Power Analysis for Low Power Scenario
set_rtl_power_analysis_options \
    -scenario func@nominal_lp \
    -output_dir TZ_OUTDIR_LP
```

**Generated Low Power Reports**:

- `results/report_power_lp.txt` - Low power consumption analysis
- `results/report_timing_lp.txt` - Timing with LP library (slower)
- `results/report_clock_gating_lp.txt` - Enhanced clock gating effectiveness

### 2. `tz_setup_lp.tcl` - Low Power Technology Setup

**Key Low Power Configurations**:

```tcl
# Aggressive Clock Gating for Maximum Power Savings
set_clock_gating_options \
    -max_fanout 32 \
    -max_number_of_levels 3 \
    -min_bitwidth 2

# Power Optimization Settings
set_app_options -name compile.power_opt_enable -value true
set_power_optimization -power_driven true
set_power_optimization -leakage_driven true

# Low Activity Switching Model
set_switching_activity -period 100 -toggle_rate 0.1 -static_probability 0.5
```

**Low Power Features**:

- **32 fanout clock gating** (vs 16 in HD version)
- **3-level clock gating hierarchy** (vs 2 in HD version)
- **Minimum 2-bit gating** (vs 3-bit in HD version)
- **Power-driven synthesis** enabled
- **Leakage-driven optimization** enabled

### 3. `restore_new_lp.tcl` - Low Power Analysis Script

**Enhanced Low Power Analysis**:

```tcl
# Low Power Specific Reports
report_clock_gating -summary > "results/clock_gating_summary_lp.txt"
report_power -leakage > "results/power_leakage_analysis_lp.txt"
report_power_optimization > "results/power_optimization_results_lp.txt"

# Clock Gating RTL Metrics
report_rtl_metrics -view clock_gating \
    -cg_attributes {gated_registers ungated_registers gating_ratio power_savings}
```

**Additional Low Power Reports**:

- `results/clock_gating_summary_lp.txt` - Clock gating effectiveness
- `results/power_leakage_analysis_lp.txt` - Detailed leakage analysis
- `results/power_optimization_results_lp.txt` - Power optimization results
- `results/rtl_metrics_clock_gating_lp.txt` - Clock gating RTL metrics
- `results/low_power_analysis_summary.txt` - Key low power metrics
- `results/power_comparison_lp_vs_hd.txt` - Comparison with HD library

## Execution Workflow for Low Power Analysis

### Step 1: Low Power Synthesis

```bash
cd cpu_with_hazard_130_sky_lp
rtl_shell -f rtla.tcl
```

**Duration**: 15-45 minutes (slower due to power optimization)

### Step 2: Detailed Low Power Analysis

```bash
rtl_shell -f restore_new_lp.tcl
```

**Duration**: 10-20 minutes

### Step 3: Compare Results

Compare power results between:

- `cpu_with_hazard_130_sky/results/` (HD library)
- `cpu_with_hazard_130_sky_lp/results/` (LP library)

## Low Power Library Characteristics

### sky130_fd_sc_lp Transistor Properties

- **High Threshold Voltage (Vt)**: Reduces leakage current exponentially
- **Longer Channel Length**: Lower leakage, slower switching
- **Optimized Sizing**: Balanced for power vs performance
- **Low Power Design Rules**: Minimized parasitic capacitance

### Power Breakdown (Expected)

```
Total Power = Dynamic Power + Leakage Power

High Density (HD):
- Dynamic: ~60-70% of total
- Leakage: ~30-40% of total

Low Power (LP):
- Dynamic: ~50-60% of total
- Leakage: ~40-50% of total (but much lower absolute value)
```

## Trade-offs and Considerations

### ✅ Advantages of Low Power Library

- **Dramatic leakage reduction** (50-70% lower)
- **Significant total power savings** (30-50% lower)
- **Better battery life** for portable applications
- **Reduced thermal issues**
- **Enhanced clock gating effectiveness**

### ⚠️ Disadvantages of Low Power Library

- **Reduced maximum frequency** (30-50% slower)
- **Larger area** (10-20% increase)
- **Higher delay** (may require timing adjustments)
- **Potential timing closure challenges**

## Power Optimization Techniques Applied

### 1. Enhanced Clock Gating

- **Increased fanout limit**: 32 (vs 16 in HD)
- **More gating levels**: 3 (vs 2 in HD)
- **Lower bitwidth threshold**: 2 bits (vs 3 in HD)

### 2. Power-Driven Synthesis

- Power optimization enabled throughout synthesis
- Leakage-driven cell selection
- Activity-based power optimization

### 3. Voltage Scaling Preparation

- Design ready for reduced supply voltage
- Conservative switching activity assumptions
- Margin for voltage scaling

## Usage Recommendations

### When to Use Low Power Library

- **Battery-powered applications**
- **Always-on systems**
- **Thermal-constrained environments**
- **Power budget critical designs**
- **IoT and wearable devices**

### When NOT to Use Low Power Library

- **High-performance requirements**
- **Tight timing constraints**
- **Area-constrained designs**
- **High-frequency operation needed**

## Library Files Required

Ensure you have the Low Power library files:

```
../libs/sky130_fd_sc_lp/
├── sky130_fd_sc_lp.tf              # Technology file
├── sky130_fd_sc_lp__tt_025C_1v80.db # Liberty database
├── sky130_fd_sc_lp__tt_025C_1v80.lib # Liberty timing file
└── sky130_fd_sc_lp.ndm/            # Native database
```

## Results Analysis

### Key Metrics to Compare

1. **Total Power** (most important)
2. **Leakage Power** (should be dramatically lower)
3. **Clock Gating Ratio** (should be higher)
4. **Maximum Frequency** (will be lower)
5. **Area** (will be larger)

### Success Criteria

- ✅ **50%+ reduction in total power**
- ✅ **70%+ reduction in leakage power**
- ✅ **Higher clock gating ratio**
- ✅ **Still meets minimum frequency requirements**

## Troubleshooting

### Timing Issues

If timing fails with LP library:

1. Reduce clock frequency in constraints
2. Add pipeline stages if needed
3. Use multi-cycle paths for non-critical paths
4. Consider mixed library approach (LP + HD)

### Power Analysis Issues

1. Ensure LP libraries are properly loaded
2. Check switching activity data is available
3. Verify power optimization settings are applied

This low power variant provides the **minimum possible power consumption** achievable with the SKY130 PDK while maintaining functionality of your RISC-V CPU design.
