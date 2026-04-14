    .text
    .globl main
main:
    # Set up stack and save registers
    pushq   %rbp
    movq    %rsp, %rbp
    pushq   %rbx   # save file descriptor
    pushq   %r12   # save file length
    pushq   %r13   # save left pointer
    pushq   %r14   # save right pointer
    pushq   %r15   # not used, just for alignment
    subq    $16, %rsp   # space for two char buffers


    # Open input.txt for reading
    movq    $2, %rax
    leaq    filename(%rip), %rdi
    movq    $0, %rsi
    movq    $0, %rdx
    syscall
    cmpq    $0, %rax
    jl      print_yes   # if file doesn't exist, treat as palindrome
    movq    %rax, %rbx


    # Get file length
    movq    $8, %rax
    movq    %rbx, %rdi
    movq    $0, %rsi
    movq    $2, %rdx
    syscall
    movq    %rax, %r12



trim_loop:
    cmpq    $0, %r12
    je      empty_string   # empty file is palindrome
    # Read last byte
    movq    $17, %rax
    movq    %rbx, %rdi
    leaq    -48(%rbp), %rsi
    movq    $1, %rdx
    movq    %r12, %r10
    subq    $1, %r10
    syscall
    movb    -48(%rbp), %al
    # If newline or carriage return, trim
    cmpb    $10, %al
    je      trim_one
    cmpb    $13, %al
    je      trim_one
    jmp     trim_done

trim_one:
    subq    $1, %r12
    jmp     trim_loop

trim_done:



    cmpq    $0, %r12
    je      empty_string
    cmpq    $1, %r12
    je      print_yes



    movq    $0, %r13   # left = 0
    movq    %r12, %r14
    subq    $1, %r14   # right = length - 1

palindrome_loop:
    cmpq    %r14, %r13
    jge     print_yes   # done if left >= right
    # Read left character
    movq    $17, %rax
    movq    %rbx, %rdi
    leaq    -48(%rbp), %rsi
    movq    $1, %rdx
    movq    %r13, %r10
    syscall
    # Read right character
    movq    $17, %rax
    movq    %rbx, %rdi
    leaq    -49(%rbp), %rsi
    movq    $1, %rdx
    movq    %r14, %r10
    syscall
    # Compare
    movb    -48(%rbp), %al
    movb    -49(%rbp), %cl
    cmpb    %cl, %al
    jne     print_no
    addq    $1, %r13
    subq    $1, %r14
    jmp     palindrome_loop


empty_string:
    jmp     print_yes

print_yes:
    movq    $3, %rax
    movq    %rbx, %rdi
    syscall
    movq    $1, %rax
    movq    $1, %rdi
    leaq    str_yes(%rip), %rsi
    movq    $4, %rdx
    syscall
    jmp     do_exit

print_no:
    movq    $3, %rax
    movq    %rbx, %rdi
    syscall
    movq    $1, %rax
    movq    $1, %rdi
    leaq    str_no(%rip), %rsi
    movq    $3, %rdx
    syscall
    jmp     do_exit

do_exit:
    movq    $60, %rax
    movq    $0,  %rdi
    syscall
    addq    $16, %rsp
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    popq    %rbp
    ret


    .section .rodata
filename:
    .string "input.txt"
str_yes:
    .string "Yes\n"
str_no:
    .string "No\n"
