    .text
    .globl main

    # main function
main:

    # save registers and setup stack frame
    pushq   %rbp                # save caller's base pointer onto stack
    movq    %rsp, %rbp          # our frame pointer = current stack top
    pushq   %rbx                # save %rbx (we use it as loop counter i)
    pushq   %r12                # save %r12 (we use it for argv)
    pushq   %r13                # save %r13 (we use it for n)
    pushq   %r14                # save %r14 (we use it for arr[])
    pushq   %r15                # save %r15 (we use it for result[])
    subq    $16, %rsp           # 8 bytes for stk[] local var + 8 bytes padding
                                # (keeps stack 16-byte aligned as required by ABI)

    # get argc and argv
    movq    %rsi, %r12          # %r12 = argv  (safe across all function calls)
    movq    %rdi, %r13          # %r13 = argc temporarily
    subq    $1,   %r13          # %r13 = n = argc - 1  (number of IQ values)

    # if no input, just print new line and exit
    cmpq    $0, %r13            # is n == 0?
    jg      allocate_memory     # if n > 0, go to normal processing
    movq    $10, %rdi           # just print a newline and exit
    call    putchar
    jmp     main_return

allocate_memory:
    # make space for arr, result, stack

    # arr for input numbers
    movq    %r13, %rdi          # first argument to malloc: n
    imulq   $8, %rdi            # in bytes: n * 8
    call    malloc              # malloc(n * 8)
    movq    %rax, %r14          # %r14 = arr[]  (callee-saved, survives further calls)

    # result for answers
    movq    %r13, %rdi
    imulq   $8, %rdi
    call    malloc
    movq    %rax, %r15          # %r15 = result[]  (callee-saved)

    # stack for indices
    movq    %r13, %rdi
    imulq   $8, %rdi
    call    malloc
    movq    %rax, -48(%rbp)     # store stk[] pointer at -48(%rbp) (our local var slot)

    # fill arr with numbers from command line
    movq    $0, %rbx            # %rbx = i = 0

fill_arr_loop:
    cmpq    %r13, %rbx          # is i == n?
    jge     fill_arr_done       # yes -- stop

    # get argv[i+1]
    movq    %rbx, %rax          # rax = i
    addq    $1,   %rax          # rax = i + 1
    shlq    $3,   %rax          # rax = (i+1) * 8   [left shift by 3 = multiply by 8]
    addq    %r12, %rax          # rax = &argv[i+1]  [%r12 is argv base]
    movq    (%rax), %rdi        # rdi = argv[i+1]   [dereference to get the string]
    call    atoi                # eax = integer value of that string
                                # atoi can destroy: rax rcx rdx rsi rdi r8-r11
                                # but NOT: rbx(our i), r12(argv), r13(n), r14(arr), r15(result)
    movslq  %eax, %rax          # sign-extend 32-bit int result to 64-bit

    # put value in arr[i]
    movq    %rbx, %rdx          # rdx = i
    shlq    $3,   %rdx          # rdx = i * 8
    movq    %rax, (%r14, %rdx)  # arr[i] = the parsed integer value

    addq    $1, %rbx            # i++
    jmp     fill_arr_loop

fill_arr_done:

    # set all result to -1 first
    movq    $0, %rbx            # i = 0

init_result_loop:
    cmpq    %r13, %rbx          # is i == n?
    jge     init_result_done

    movq    %rbx, %rdx
    shlq    $3,   %rdx
    movq    $-1,  (%r15, %rdx)  # result[i] = -1

    addq    $1, %rbx
    jmp     init_result_loop

init_result_done:

    # do the next greater element logic
    movq    -48(%rbp), %r9      # %r9 = stk[] base pointer
    movq    $-1, %r10           # %r10 = stack_top = -1  (stack empty)
    movq    %r13, %rbx
    subq    $1,   %rbx          # %rbx = i = n - 1  (start from last element)

nge_outer_loop:
    cmpq    $0, %rbx            # is i < 0?
    jl      nge_outer_done      # yes -- we are done

    # arr[i] in rax
    movq    %rbx, %rdx          # rdx = i
    shlq    $3,   %rdx          # rdx = i * 8
    movq    (%r14, %rdx), %rax  # %rax = arr[i]

    # pop stack if top is not greater
nge_pop_loop:
    cmpq    $-1, %r10           # is stack empty?
    je      nge_pop_done        # yes, stop popping

    # get index from stack top
    movq    %r10, %rcx          # rcx = stack_top
    shlq    $3,   %rcx          # rcx = stack_top * 8
    movq    (%r9, %rcx), %rcx   # %rcx = stk[stack_top]  (an index into arr[])

    # get arr[stack top]
    shlq    $3,   %rcx          # rcx = stk[top] * 8
    movq    (%r14, %rcx), %rdx  # %rdx = arr[stk[top]]

    # compare arr[stack top] and arr[i]
    cmpq    %rax, %rdx          # sets flags based on rdx - rax
    jg      nge_pop_done        # if arr[stk[top]] > arr[i], stop popping

    # pop if not greater
    subq    $1, %r10            # stack_top--
    jmp     nge_pop_loop

nge_pop_done:
    # if stack not empty, set result[i]
    cmpq    $-1, %r10           # is stack empty?
    je      nge_do_push         # yes -- result[i] stays -1

    # stack top is answer
    movq    %r10, %rcx          # rcx = stack_top
    shlq    $3,   %rcx          # rcx = stack_top * 8
    movq    (%r9, %rcx), %rcx   # %rcx = stk[stack_top]  (the answer: index of next greater)

    # put answer in result[i]
    movq    %rbx, %rdx          # rdx = i
    shlq    $3,   %rdx          # rdx = i * 8
    movq    %rcx, (%r15, %rdx)  # result[i] = answer index

nge_do_push:
    # push i to stack
    addq    $1,   %r10          # stack_top++
    movq    %r10, %rcx          # rcx = new stack_top
    shlq    $3,   %rcx          # rcx = stack_top * 8
    movq    %rbx, (%r9, %rcx)   # stk[stack_top] = i

    subq    $1, %rbx            # i--
    jmp     nge_outer_loop

nge_outer_done:

    # print all result
    movq    $0, %rbx            # i = 0

print_loop:
    cmpq    %r13, %rbx          # is i == n?
    jge     print_done

    # get result[i]
    movq    %rbx, %rdx
    shlq    $3,   %rdx
    movq    (%r15, %rdx), %rsi  # %rsi = result[i]

    # check if last element
    movq    %r13, %rax
    subq    $1, %rax            # rax = n - 1
    cmpq    %rax, %rbx          # is i == n-1?
    je      print_last_elem

    # print with space
    leaq    fmt_space(%rip), %rdi  # format string "%ld "
    xorq    %rax, %rax             # no floating point args
    call    printf
    jmp     print_next

print_last_elem:
    # print last element without space
    leaq    fmt_nospace(%rip), %rdi
    xorq    %rax, %rax
    call    printf

print_next:
    addq    $1, %rbx            # i++
    jmp     print_loop

print_done:
    # print new line
    movq    $10, %rdi           # 10 = ASCII code for '\n'
    call    putchar

main_return:
    movq    $0, %rax            # return value = 0 (success)

    # restore registers and return
    addq    $16, %rsp           # undo the subq $16 we did in prologue
    popq    %r15                # restore %r15
    popq    %r14                # restore %r14
    popq    %r13                # restore %r13
    popq    %r12                # restore %r12
    popq    %rbx                # restore %rbx
    popq    %rbp                # restore caller's base pointer
    ret                         # return to OS

    # format strings for printf
    .section .rodata

fmt_space:
    .string "%ld "      # print number and space

fmt_nospace:
    .string "%ld"       # print number only

