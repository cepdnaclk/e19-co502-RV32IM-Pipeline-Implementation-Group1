_boot:
addi x1, x0, 1
addi x2, x0, 0
addi x5, x0, 0
addi x7, x0, 6
Loop:
add x3, x1, x2
addi x2, x1, 0
addi x1, x3, 0
sw x3, 0(x5)
addi x5, x5, 4
addi x7, x7, -1
beq x7, x0, Done
jal x0, Loop
Done:
lw x6, -4(x5)
add x1, x6, x6
