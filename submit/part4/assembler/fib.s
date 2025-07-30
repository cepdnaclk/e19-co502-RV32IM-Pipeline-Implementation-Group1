.global _boot
.text

_boot:
    addi x1, x0, 1         # x1 = 1 (Fib[1])
    addi x2, x0, 0         # x2 = 0 (Fib[0])
    addi x5, x0, 0         # x5 = 0 (memory offset)
    addi x7, x0, 6         # x7 = 5 (iteration counter)

Loop:
    add  x3, x1, x2        # x3 = x1 + x2

    addi x2, x1, 0         # x2 = x1
    addi x1, x3, 0         # x1 = x3

    sw   x3, 0(x5)         # store Fib[i] to memory at [x5]
    addi x5, x5, 4         # move memory offset to next word

    addi x7, x7, -1        # decrement counter
    beq  x7, x0, Done      # if counter == 0, done

    jal  x0, Loop          # loop again

Done:
    lw   x6, -4(x5)        # load last stored Fib value into x6
    add  x1, x6, x6

    j    .                 # infinite loop
