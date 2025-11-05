# RV32IM Pipeline Processor Implementation

A complete 5-stage pipelined RISC-V processor implementation supporting the RV32IM instruction set architecture, synthesized for multiple process technologies.

## Overview

This project implements a pipelined RISC-V processor with hazard detection and forwarding units, designed for the CO502 Advanced Computer Architecture course. The design has been verified through simulation and synthesized using Synopsys tools targeting various process technologies including open-source PDKs (SKY130, 16nm FinFET).

## Features

- **Complete RV32IM ISA Support**: Implements integer base instructions (RV32I) and multiplication/division extensions (RV32M)
- **5-Stage Pipeline Architecture**: IF, ID, EX, MEM, WB stages with proper pipeline register implementation
- **Hazard Detection**: Hardware-based data hazard detection and control hazard handling
- **Forwarding Unit**: Data forwarding to minimize pipeline stalls
- **Memory System**: Separate instruction and data memory with cache support
- **Multi-Technology Support**: Synthesis scripts available for multiple process technologies

## Project Structure

```
.
├── assembler/              # RISC-V assembler and test programs
│   ├── assembler.py       # Custom assembler for RV32IM
│   ├── *.s                # Assembly test programs
│   └── *.mem              # Memory initialization files
│
├── cpu/                    # RTL source files
│   ├── cpu.v              # Top-level CPU module
│   ├── cpu_tb.v           # Testbench
│   ├── IF_stage/          # Instruction Fetch components
│   ├── ID_stage/          # Instruction Decode components
│   ├── EX_stage/          # Execute stage components
│   ├── MA_stage/          # Memory Access components
│   ├── pipeline_regs/     # Inter-stage pipeline registers
│   └── utils/             # Utility modules (muxes, adders, encodings)
│
├── synopsys/              # Synthesis scripts and configurations
│   ├── cpu_sky130_fd_sc_hd/
│   │   ├── config.tcl     # Shared configuration variables
│   │   ├── rtla.tcl       # RTL analysis and synthesis script
│   │   ├── tz_setup.tcl   # Technology setup script
│   │   ├── restore_new.tcl # Power analysis script
│   │   ├── script.sh      # Automated synthesis flow
│   │   └── sdc/           # Timing constraints
│   └── libs/              # Process technology libraries
│
├── fpga/                   # FPGA implementation files
│   ├── basic_cpu/         # Basic CPU without hazard handling
│   └── hazard_cpu/        # Full CPU with hazard detection
│
├── docs/                   # Documentation and website
└── documentations/         # Additional reference documentation
```

## Getting Started

### Prerequisites

**For Simulation:**

- VCS (Synopsys VCS compiler/simulator)
- Verdi (for waveform viewing with FSDB support)

**For Synthesis:**

- Synopsys Design Compiler or RTL Compiler
- Synopsys PrimeTime (for power analysis)
- Process technology libraries (e.g., open-source PDKs or commercial libraries)

**For FPGA:**

- Intel Quartus Prime (for Altera DE-115 development board)
- Xilinx Vivado (for Xilinx Vertex-7 FPGA)

### Running Simulations

1. Navigate to the CPU directory:

```bash
cd cpu
```

2. Compile with VCS:

```bash
vcs -sverilog -full64 -kdb -debug_access+all cpu_tb.v +vcs+fsdbon -o simv
```

3. Run simulation:

```bash
./simv +fsdb+all=on +fsdb+delta
```

4. View waveforms:

```bash
verdi -ssf novas.fsdb &
```

### Running Synthesis

The automated synthesis flow handles compilation, simulation, synthesis, and power analysis:

1. Navigate to the synthesis directory:

```bash
cd synopsys/cpu_sky130_fd_sc_hd
```

2. Run the complete flow with a description:

```bash
./script.sh "Description of this synthesis run"
```

Example:

```bash
./script.sh "Baseline synthesis with default constraints"
```

The script will:

- Pull latest changes from Git
- Compile and simulate the design
- Perform RTL synthesis
- Run power analysis
- Generate comprehensive reports
- Archive results with timestamp

**Generated Reports:**

- `run_metadata.txt` - Run information and environment details
- `report_power.txt` - Power consumption analysis
- `report_area.txt` - Area utilization
- `report_timing.txt` - Timing analysis
- `report_qor.txt` - Quality of results summary
- `timing_summary.txt` - Clock frequency and period metrics
- Power analysis reports (hierarchical and component-based)

### Running on FPGA

The design supports implementation on multiple FPGA platforms:

#### Altera/Intel DE-115 Development Board

1. Navigate to the FPGA project directory:

```bash
cd fpga/basic_cpu    # or fpga/hazard_cpu for full hazard detection
```

2. Open the project in Quartus Prime:

```bash
quartus TopLevel.qpf
```

3. Compile the design:

   - Click **Processing** → **Start Compilation**
   - Or use command line: `quartus_sh --flow compile TopLevel`

4. Program the FPGA:

   - Connect the DE-115 board via USB Blaster
   - Click **Tools** → **Programmer**
   - Select the `.sof` file from `output_files/`
   - Click **Start** to program

5. Debug with SignalTap II Logic Analyzer:
   - Open **Tools** → **SignalTap II Logic Analyzer**
   - Add signals to monitor (e.g., PC, instruction, register values)
   - Run the design and capture signals in real-time
   - Analyze waveforms for debugging

**Board Configuration:**

- **Device**: Cyclone IV E (EP4CE115F29C7)
- **Clock**: 50 MHz input from on-board oscillator
- **I/O**: Configured for switches, LEDs, and 7-segment displays

#### Xilinx Vertex-7 FPGA

1. Navigate to the Vivado project directory:

```bash
cd fpga/RISC_CPU
```

2. Open the project in Vivado:

```bash
vivado RISC_CPU.xpr
```

3. Synthesize and implement the design:

   - Click **Run Synthesis** in the Flow Navigator
   - After synthesis, click **Run Implementation**
   - Click **Generate Bitstream**

4. Program the FPGA:

   - Connect the Vertex-7 board
   - Click **Open Hardware Manager**
   - Click **Open Target** → **Auto Connect**
   - Right-click on the device → **Program Device**
   - Select the `.bit` file and click **Program**

5. Debug with Integrated Logic Analyzer (ILA):
   - Insert ILA cores during design:
     - Right-click signal in design → **Debug**
     - Mark signals for debugging
     - Re-synthesize and implement
   - In Hardware Manager, add ILA dashboard
   - Set trigger conditions and capture signals
   - Analyze waveforms in real-time

**Available Implementations:**

- `basic_cpu/` - Basic 5-stage pipeline without hazard handling
- `hazard_cpu/` - Full pipeline with hazard detection and forwarding
- `RISC_CPU/` - Vivado project for Xilinx FPGAs

## Configuration

All synthesis parameters are centralized in `config.tcl`:

```tcl
# Design configuration
set DESIGN_NAME "cpu"
set CORES 8

# Library paths (customize for your technology)
set TECH_TF "../libs/technology_library/tech_file.tf"
set TLU_NOMINAL "../libs/technology_library/parasitic_model.tluplus"

# Constraints
set SDC_FILE "./sdc/clocks.sdc"
```

Edit this file to customize paths, design parameters, or optimization settings.

## Testing

Test programs are provided in the `assembler/` directory:

- `fib.s` - Fibonacci sequence calculation
- `forLoop_beq.s` - Loop with branch-equal testing
- `int_sample.s` - Interrupt handling test
- Additional test cases for instruction validation

Use the provided assembler to generate memory initialization files:

```bash
cd assembler
python assembler.py <input.s> <output.mem>
```

## Pipeline Architecture

### Stage Breakdown

1. **IF (Instruction Fetch)**

   - Program counter management
   - Instruction memory access
   - Branch target calculation

2. **ID (Instruction Decode)**

   - Instruction decoding
   - Register file read
   - Control signal generation
   - Hazard detection

3. **EX (Execute)**

   - ALU operations
   - Branch condition evaluation
   - Forwarding logic

4. **MEM (Memory Access)**

   - Data memory operations
   - Load/store execution

5. **WB (Write Back)**
   - Register file write
   - Result forwarding

### Hazard Handling

- **Data Hazards**: Resolved through forwarding and stalling
- **Control Hazards**: Branch prediction and flush mechanisms
- **Structural Hazards**: Separate instruction and data memory

## Performance Metrics

Synthesis results from post-synthesis analysis using 16nm FinFET:

### Timing Performance

- **Maximum Frequency**: 144.94 MHz
- **Recommended Operating Frequency**: 142.09 MHz
- **Critical Path Delay**: 6.91 ns
- **Critical Path Slack**: 3.03 ns
- **Clock Period**: 10.00 ns
- **Levels of Logic**: 322
- **Total Negative Slack**: 0.00 ns
- **Timing Violations**: 0

### Area Metrics

- **Total Cell Area**: 4,590.17 µm²
- **Combinational Area**: 3,227.30 µm² (70.3%)
- **Sequential Area**: 1,362.87 µm² (29.7%)
- **Buffer/Inverter Area**: 165.99 µm² (3.6%)

### Cell Statistics

- **Total Cells**: 10,530
  - Combinational Cells: 10,290 (97.7%)
  - Sequential Cells: 240 (2.3%)
  - Buffer/Inverter Cells: 1,297 (12.3%)
- **Hierarchical Modules**: 23
- **Number of Nets**: 15,330
- **Design References**: 377

### Power Consumption

- **Total Power**: 197 µW
- **Dynamic Power**: 160.5 µW (81.5%)
  - Internal Power: 78.7 µW
  - Switching Power: 81.8 µW
- **Leakage Power**: 36.3 µW (18.5%)

### Power Distribution by Module

| Module                        | Power (µW) | Percentage |
| ----------------------------- | ---------- | ---------- |
| ALU (with multiplier/divider) | 61.9       | 31.5%      |
| ID/EX Pipeline Register       | 28.4       | 14.4%      |
| EX/MEM Pipeline Register      | 21.8       | 11.1%      |
| Register File                 | 17.5       | 8.9%       |
| MEM/WB Pipeline Register      | 17.7       | 9.0%       |
| IF/ID Pipeline Register       | 14.0       | 7.1%       |
| Program Counter               | 9.57       | 4.9%       |
| Other Logic                   | 25.6       | 13.1%      |

## Team

**CO502 Group 1**

- University of Peradeniya
- Department of Computer Engineering

## Acknowledgments

- RISC-V Foundation for the open ISA specification
- Open-source PDK communities and technology providers
- Course instructors and teaching assistants

## References

- [RISC-V ISA Specification](https://riscv.org/specifications/)
- Course materials: CO502 Advanced Computer Architecture
