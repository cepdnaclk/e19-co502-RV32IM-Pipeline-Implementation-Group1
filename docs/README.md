---
layout: home
permalink: index.html

# Please update this with your repository name and title
repository-name: e19-co502-RV32IM-Pipeline-Implementation-Group1
title: RV32IM Pipeline Implementation Group1

---

[comment]: # "This is the standard layout for the project, but you can clean this and use your own template"

# RV32IM Pipeline Implementation Group1

---

<!-- 
This is a sample image, to show how to add images to your page. To learn more options, please refer [this](https://projects.ce.pdn.ac.lk/docs/faq/how-to-add-an-image/)

![Sample Image](./images/sample.png)
 -->

## Team
-  E/19/129, Gunawardana K.H., [email](mailto:e19129@eng.pdn.ac.lk)
-  E/19/275, Peeris M.S., [email](mailto:e19275@eng.pdn.ac.lk)
-  E/19/309, Rambukwella H.M.W.K.G., [email](mailto:e19309@eng.pdn.ac.lk)

## Supervisors
- Dr. Isuru Nawinne, [email](mailto:isurunawinne@eng.pdn.ac.lk)

## Table of Contents
1. [Introduction](#introduction)
2. [Processor Design](#processor-design)
3. [Implementation Details](#implementation-details)
4. [Links](#links)

---

## Introduction

This project implements a **RISC-V RV32IM** processor using a **6-stage pipeline architecture** to improve performance and efficiency. The processor supports integer arithmetic, multiplication, and memory operations as defined in the **RV32IM** instruction set. Designed for FPGA deployment, this implementation optimizes execution speed and minimizes stalls using pipeline forwarding and hazard detection techniques.  

The project aims to provide a fully functional, verifiable processor with an open-source implementation, useful for academic research and practical FPGA-based applications.

## Processor Design

The processor follows a **6-stage pipeline** structure:
1. **Instruction Fetch (IF)** – Fetches instructions from memory.
2. **Instruction Decode (ID)** – Decodes instruction and reads registers.
3. **Execute (EX)** – Performs arithmetic and logic operations.
4. **Memory Access (MEM)** – Handles load/store operations.
5. **Write-Back (WB)** – Writes results back to registers.
6. **Hazard Handling & Forwarding (HF)** – Implements data forwarding and hazard mitigation.

## Implementation Details

- **ISA:** RISC-V RV32IM  
- **Pipeline Stages:** 6  
- **Hazard Handling:** Data forwarding, hazard detection  
- **Verification:** Functional testbenches included  
- **Deployment:** FPGA-compatible design  

## Links

- [Project Repository](https://github.com/cepdnaclk/e19-co502-RV32IM-Pipeline-Implementation-Group1)
- [Project Page](https://github.com/cepdnaclk/e19-co502-RV32IM-Pipeline-Implementation-Group1)
- [Department of Computer Engineering](http://www.ce.pdn.ac.lk/)
- [University of Peradeniya](https://eng.pdn.ac.lk/)


[//]: # (Please refer this to learn more about Markdown syntax)
[//]: # (https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
