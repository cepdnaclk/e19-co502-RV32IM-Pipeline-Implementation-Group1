#!/usr/bin/env python3
"""
RISC-V 32IM Assembler
Converts RISC-V assembly code to binary format
"""

import sys
import csv
import os
import argparse
from typing import Dict, List, Tuple, Optional

class RISCVAssembler:
    def __init__(self):
        self.inst_data: Dict[str, Dict] = {}
        self.instructions: List[str] = []
        self.label_positions: Dict[str, int] = {}
        self.inst_count = 0
        self.file_size = 1024
        
        # Register mappings
        self.registers = {
            'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
            't0': 5, 't1': 6, 't2': 7, 's0': 8, 'fp': 8, 's1': 9,
            'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15,
            'a6': 16, 'a7': 17, 's2': 18, 's3': 19, 's4': 20, 's5': 21,
            's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
            't3': 28, 't4': 29, 't5': 30, 't6': 31
        }
        
        # Add x0-x31 register names
        for i in range(32):
            self.registers[f'x{i}'] = i

    def to_binary(self, num_digits: int, num: int) -> str:
        """Convert number to binary with specified width"""
        if isinstance(num, str):
            num = int(num)
        
        # Handle negative numbers using two's complement
        if num < 0:
            num = (1 << num_digits) + num
        
        # Mask to ensure we only get the required bits
        mask = (1 << num_digits) - 1
        return format(num & mask, f'0{num_digits}b')

    def parse_register(self, reg_str: str) -> int:
        """Parse register string to register number"""
        reg_str = reg_str.strip().lower()
        
        # Remove 'x' prefix if present
        if reg_str.startswith('x') and reg_str[1:].isdigit():
            return int(reg_str[1:])
        
        # Check named registers
        if reg_str in self.registers:
            return self.registers[reg_str]
        
        # If it's just a number
        if reg_str.isdigit():
            reg_num = int(reg_str)
            if 0 <= reg_num <= 31:
                return reg_num
        
        raise ValueError(f"Invalid register: {reg_str}")

    def parse_immediate(self, imm_str: str) -> int:
        """Parse immediate value"""
        imm_str = imm_str.strip()
        
        # Handle hex values
        if imm_str.startswith('0x') or imm_str.startswith('0X'):
            return int(imm_str, 16)
        
        # Handle binary values
        if imm_str.startswith('0b') or imm_str.startswith('0B'):
            return int(imm_str, 2)
        
        # Handle decimal (including negative)
        return int(imm_str)

    def read_instruction_set(self, csv_file: str = 'RV32IM.csv'):
        """Read instruction set from CSV file"""
        try:
            with open(csv_file, 'r') as f:
                csv_reader = csv.reader(f)
                for row in csv_reader:
                    if len(row) >= 4:  # At least opcode, funct3, funct7, instruction
                        # Handle opcode (binary format)
                        opcode_str = row[0].strip()
                        if opcode_str:
                            opcode = opcode_str  # Keep as binary string
                        else:
                            opcode = '0000000'
                        
                        # Handle funct3 (binary format)
                        funct3_str = row[1].strip()
                        if funct3_str:
                            funct3 = funct3_str  # Keep as binary string
                        else:
                            funct3 = '000'
                        
                        # Handle funct7 (binary format, can be empty)
                        funct7_str = row[2].strip()
                        if funct7_str:
                            funct7 = funct7_str  # Keep as binary string
                        else:
                            funct7 = '0000000'
                        
                        inst_name = row[3].strip().upper()
                        
                        # Handle instruction type (may be in column 4 or missing)
                        inst_type = row[4].strip() if len(row) > 4 else 'Unknown'
                        
                        self.inst_data[inst_name] = {
                            'opcode': opcode,
                            'funct3': funct3,
                            'funct7': funct7,
                            'type': inst_type
                        }
        except FileNotFoundError:
            print(f"Error: Instruction set file '{csv_file}' not found.")
            sys.exit(1)

    def parse_instruction(self, line: str) -> Tuple[str, List[str]]:
        """Parse instruction line into opcode and operands"""
        # Remove comments
        if ';' in line:
            line = line[:line.index(';')]
        
        line = line.strip()
        if not line:
            return '', []
        
        # Split by whitespace
        parts = line.split()
        opcode = parts[0].upper()
        
        # Join remaining parts and split by comma
        if len(parts) > 1:
            operands_str = ' '.join(parts[1:])
            operands = [op.strip() for op in operands_str.split(',')]
        else:
            operands = []
        
        return opcode, operands

    def handle_r_type(self, opcode: str, operands: List[str]) -> str:
        """Handle R-type instructions: rd, rs1, rs2"""
        if len(operands) != 3:
            raise ValueError(f"R-type instruction {opcode} requires 3 operands")
        
        rd = self.parse_register(operands[0])
        rs1 = self.parse_register(operands[1])
        rs2 = self.parse_register(operands[2])
        
        inst_info = self.inst_data[opcode]
        instruction = (inst_info['funct7'] + 
                      self.to_binary(5, rs2) + 
                      self.to_binary(5, rs1) + 
                      inst_info['funct3'] + 
                      self.to_binary(5, rd) + 
                      inst_info['opcode'])
        
        return instruction

    def handle_i_type(self, opcode: str, operands: List[str]) -> str:
        """Handle I-type instructions: rd, rs1, imm OR rd, imm(rs1) for loads"""
        if len(operands) != 2 and len(operands) != 3:
            raise ValueError(f"I-type instruction {opcode} requires 2 or 3 operands")
        
        # Check if it's a load instruction (2 operands with memory addressing)
        if len(operands) == 2 and ('(' in operands[1] or opcode.startswith('L')):
            return self.handle_load_instruction(opcode, operands)
        
        # Regular I-type instruction (3 operands)
        if len(operands) != 3:
            raise ValueError(f"I-type instruction {opcode} requires 3 operands")
        
        rd = self.parse_register(operands[0])
        rs1 = self.parse_register(operands[1])
        imm = self.parse_immediate(operands[2])
        
        inst_info = self.inst_data[opcode]
        
        # Special handling for shift instructions
        if opcode in ['SLLI', 'SRLI', 'SRAI']:
            # For shifts, immediate is 5 bits and funct7 is used
            shamt = imm & 0x1F  # 5-bit shift amount
            instruction = (inst_info['funct7'] + 
                          self.to_binary(5, shamt) + 
                          self.to_binary(5, rs1) + 
                          inst_info['funct3'] + 
                          self.to_binary(5, rd) + 
                          inst_info['opcode'])
        else:
            # Regular I-type instruction
            instruction = (self.to_binary(12, imm) + 
                          self.to_binary(5, rs1) + 
                          inst_info['funct3'] + 
                          self.to_binary(5, rd) + 
                          inst_info['opcode'])
        
        return instruction

    def handle_s_type(self, opcode: str, operands: List[str]) -> str:
        """Handle S-type instructions: rs2, imm(rs1)"""
        if len(operands) != 2:
            raise ValueError(f"S-type instruction {opcode} requires 2 operands")
        
        rs2 = self.parse_register(operands[0])
        
        # Parse imm(rs1) format
        addr_operand = operands[1]
        if '(' in addr_operand and ')' in addr_operand:
            imm_str = addr_operand[:addr_operand.index('(')]
            rs1_str = addr_operand[addr_operand.index('(')+1:addr_operand.index(')')]
            imm = self.parse_immediate(imm_str) if imm_str else 0
            rs1 = self.parse_register(rs1_str)
        else:
            raise ValueError(f"Invalid S-type operand format: {addr_operand}")
        
        inst_info = self.inst_data[opcode]
        imm_bin = self.to_binary(12, imm)
        instruction = (imm_bin[:7] + 
                      self.to_binary(5, rs2) + 
                      self.to_binary(5, rs1) + 
                      inst_info['funct3'] + 
                      imm_bin[7:] + 
                      inst_info['opcode'])
        
        return instruction

    def handle_b_type(self, opcode: str, operands: List[str], pc: int) -> str:
        """Handle B-type instructions: rs1, rs2, label"""
        if len(operands) != 3:
            raise ValueError(f"B-type instruction {opcode} requires 3 operands")
        
        rs1 = self.parse_register(operands[0])
        rs2 = self.parse_register(operands[1])
        
        # Calculate branch offset
        label = operands[2]
        if label in self.label_positions:
            target_pc = self.label_positions[label]
            imm = (target_pc - pc - 1) * 4  # PC-relative, word-aligned
        else:
            imm = self.parse_immediate(label)
        
        inst_info = self.inst_data[opcode]
        imm_bin = self.to_binary(13, imm)
        instruction = (imm_bin[0] + 
                      imm_bin[2:8] + 
                      self.to_binary(5, rs2) + 
                      self.to_binary(5, rs1) + 
                      inst_info['funct3'] + 
                      imm_bin[8:12] + 
                      imm_bin[1] + 
                      inst_info['opcode'])
        
        return instruction

    def handle_u_type(self, opcode: str, operands: List[str]) -> str:
        """Handle U-type instructions: rd, imm"""
        if len(operands) != 2:
            raise ValueError(f"U-type instruction {opcode} requires 2 operands")
        
        rd = self.parse_register(operands[0])
        imm = self.parse_immediate(operands[1])
        
        inst_info = self.inst_data[opcode]
        instruction = (self.to_binary(20, imm >> 12) + 
                      self.to_binary(5, rd) + 
                      inst_info['opcode'])
        
        return instruction

    def handle_j_type(self, opcode: str, operands: List[str], pc: int) -> str:
        """Handle J-type instructions: rd, label"""
        if len(operands) != 2:
            raise ValueError(f"J-type instruction {opcode} requires 2 operands")
        
        rd = self.parse_register(operands[0])
        
        # Calculate jump offset
        label = operands[1]
        if label in self.label_positions:
            target_pc = self.label_positions[label]
            imm = (target_pc - pc - 1) * 4  # PC-relative, word-aligned
        else:
            imm = self.parse_immediate(label)
        
        inst_info = self.inst_data[opcode]
        imm_bin = self.to_binary(21, imm)
        instruction = (imm_bin[0] + 
                      imm_bin[10:20] + 
                      imm_bin[9] + 
                      imm_bin[1:9] + 
                      self.to_binary(5, rd) + 
                      inst_info['opcode'])
        
        return instruction

    def format_instruction(self, line: str, pc: int) -> str:
        """Format a single instruction"""
        opcode, operands = self.parse_instruction(line)
        
        if not opcode or opcode not in self.inst_data:
            raise ValueError(f"Unknown instruction: {opcode}")
        
        inst_type = self.inst_data[opcode]['type'].strip().upper()
        
        # Handle special instructions
        if inst_type == "NOP-TYPE" or opcode == "NOP":
            return "00000000000000000000000000000000"  # 32-bit NOP
        
        if opcode == "FENCE":
            # FENCE instruction - simplified implementation
            return "00000000000000000000000000001111"
        
        if opcode == "ECALL":
            return "00000000000000000000000001110011"
        
        if opcode == "EBREAK":
            return "00000000000100000000000001110011"
        
        # Handle regular instruction types
        if inst_type == "R-TYPE":
            return self.handle_r_type(opcode, operands)
        elif inst_type == "I-TYPE" or inst_type == "I - TYPE":
            return self.handle_i_type(opcode, operands)
        elif inst_type == "S-TYPE":
            return self.handle_s_type(opcode, operands)
        elif inst_type == "B-TYPE":
            return self.handle_b_type(opcode, operands, pc)
        elif inst_type == "U-TYPE" or inst_type == "U -TYPE":
            return self.handle_u_type(opcode, operands)
        elif inst_type == "J-TYPE":
            return self.handle_j_type(opcode, operands, pc)
        else:
            raise ValueError(f"Unknown instruction type: {inst_type} for instruction: {opcode}")
    
    def handle_load_instruction(self, opcode: str, operands: List[str]) -> str:
        """Handle load instructions: rd, imm(rs1)"""
        if len(operands) != 2:
            raise ValueError(f"Load instruction {opcode} requires 2 operands")
        
        rd = self.parse_register(operands[0])
        
        # Parse imm(rs1) format
        addr_operand = operands[1]
        if '(' in addr_operand and ')' in addr_operand:
            imm_str = addr_operand[:addr_operand.index('(')]
            rs1_str = addr_operand[addr_operand.index('(')+1:addr_operand.index(')')]
            imm = self.parse_immediate(imm_str) if imm_str else 0
            rs1 = self.parse_register(rs1_str)
        else:
            # Handle case where it's just a register (imm = 0)
            imm = 0
            rs1 = self.parse_register(addr_operand)
        
        inst_info = self.inst_data[opcode]
        instruction = (self.to_binary(12, imm) + 
                      self.to_binary(5, rs1) + 
                      inst_info['funct3'] + 
                      self.to_binary(5, rd) + 
                      inst_info['opcode'])
        
        return instruction

    def save_to_file(self, instruction: str, output_file: str):
        """Save instruction to file as hex integer"""
        with open(output_file, 'a') as f:
            # Convert binary string to integer, then to hex
            hex_value = int(instruction, 2)
            f.write(f"{hex_value:08X}\n")
        self.inst_count += 1

    def fill_file(self, output_file: str):
        """Fill the rest of the file with padding"""
        with open(output_file, 'a') as f:
            for i in range(self.file_size - self.inst_count):
                f.write("00000000\n")  # Write hex zeros for padding

    def assemble(self, input_file: str, output_file: Optional[str] = None):
        """Main assembly function"""
        if not output_file:
            output_file = os.path.splitext(input_file)[0] + '.hex'
        
        # Clear existing output file
        if os.path.exists(output_file):
            os.remove(output_file)
        
        # First pass: collect labels
        with open(input_file, 'r') as f:
            pc = 0
            for line in f:
                line = line.strip()
                if not line or line.startswith(';'):
                    continue
                
                if line.endswith(':'):
                    # Label definition
                    label = line[:-1]
                    self.label_positions[label] = pc
                else:
                    # Regular instruction
                    self.instructions.append(line)
                    pc += 1
        
        # Second pass: generate machine code
        self.save_to_file("00000000", output_file)
        for i, instruction in enumerate(self.instructions):
            try:
                binary_inst = self.format_instruction(instruction, i)
                hex_inst = f"0x{int(binary_inst, 2):08X}"
                print(f"[{i:3d}] {instruction:<25} -> {binary_inst} ({hex_inst})")
                self.save_to_file(binary_inst, output_file)
            except Exception as e:
                print(f"Error processing instruction '{instruction}': {e}")
                sys.exit(1)
        
        # Fill remaining file
        self.fill_file(output_file)
        
        print(f"\nLabels found: {self.label_positions}")
        print(f"Total instructions: {self.inst_count}")
        print(f"Hex file saved to: {os.path.abspath(output_file)}")

def main():
    parser = argparse.ArgumentParser(description='RISC-V 32IM Assembler')
    parser.add_argument('-i', '--input', required=True, help='Input assembly file')
    parser.add_argument('-o', '--output', help='Output hex file')
    parser.add_argument('-c', '--csv', default='RV32IM.csv', help='Instruction set CSV file')
    parser.add_argument('-s', '--size', type=int, default=1024, help='Output file size in lines')
    
    args = parser.parse_args()
    
    assembler = RISCVAssembler()
    assembler.file_size = args.size
    
    # Read instruction set
    assembler.read_instruction_set(args.csv)
    
    # Assemble the file
    assembler.assemble(args.input, args.output)

if __name__ == "__main__":
    main()