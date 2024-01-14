# https://adventofcode.com/2016/day/6
#
# --- Day 6: Signals and Noise ---
#
# Something is jamming your communications with Santa. Fortunately, your signal is only partially jammed, and protocol in situations like this is to switch to a simple repetition code to get the message through.
# 
# In this model, the same message is sent repeatedly. You've recorded the repeating message signal (your puzzle input), but the data seems quite corrupted - almost too badly to recover. Almost.
# 
# All you need to do is figure out which character is most frequent for each position. For example, suppose you had recorded the following messages:
# 
# eedadn
# drvtee
# eandsr
# raavrd
# atevrs
# tsrnev
# sdttsa
# rasrtv
# nssdts
# ntnada
# svetve
# tesnvt
# vntsnd
# vrdear
# dvrsen
# enarar
# 
# The most common character in the first column is e; in the second, a; in the third, s, and so on. Combining these characters returns the error-corrected message, easter.
# 
# Given the recording in your puzzle input, what is the error-corrected version of the message being sent?

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_CHALLENGE_ARGS, EC_SUCCESS + 1
.equ EC_CHALLENGE_LINE_COUNT, EC_CHALLENGE_ARGS + 1
.equ EC_CHALLENGE_CHAR, EC_CHALLENGE_LINE_COUNT + 1

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_EOF, 0
.equ CHAR_NEWLINE, '\n'
.equ CHAR_A, 'a'
.equ CHAR_Z, 'z'
.equ CHARS_COUNT, 26
.equ REGISTER_SIZE, 8
.equ CHARS_SPACE, REGISTER_SIZE * CHARS_COUNT
.equ BUFFER_LENGTH, 32

.equ DATA_INPUT_OFFSET, -8
.equ DATA_INPUT_LENGTH_OFFSET, -16
.equ DATA_LINE_LENGTH_OFFSET, -24
.equ DATA_LINE_COUNT_OFFSET, -32
.equ DATA_SIZE, 32

.bss
.lcomm buffer, BUFFER_LENGTH

.text

u_exit_ec:
    mov     %rdi, %rbx
    movq    $1, %rax
    int     $0x80

u_line_length:
    xor     %rax, %rax
.u_line_length_loop:
    cmpb    $CHAR_NEWLINE, (%rdi)
    je      .u_line_length_end
    cmpb    $CHAR_EOF, (%rdi)
    je      .u_line_length_end
    incq    %rax
    incq    %rdi
    jmp     .u_line_length_loop
.u_line_length_end:
    ret

u_string_len:
    xor     %rax, %rax
.u_string_len_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .u_string_len_end
    incq    %rax
    incq    %rdi
    jmp     .u_string_len_loop
.u_string_len_end:
    ret

u_stdout:
    push    %rdi
    call    u_string_len
    pop     %rdi
    mov     %rax, %rdx # length to write
    mov     $SYS_WRITE, %rax
    mov     $SYS_STDOUT, %rbx
    mov     %rdi, %rcx
    int     $0x80
    ret

c_line_count:
    # rdi: buffer length
    # rsi: line length with trailing '\n'
    xor     %rdx, %rdx
    movq    %rdi, %rax
    div     %rsi
    cmpq    $0, %rdx
    je      .c_line_count_end
    decq    %rsi
    cmpq    %rsi, %rdx # case where the last line doesn't have the trailing '\n'
    jne     .c_line_count_error
    incq    %rax
.c_line_count_end:
    ret
.c_line_count_error:
    mov     $EC_CHALLENGE_LINE_COUNT, %rdi
    call    u_exit_ec

c_char:
    # rdi: buffer
    # rsi: line count
    # rdx: line length
    # rcx: char offset
    push    %rbp
    movq    %rsp, %rbp
    # save data to some registers that are not used to compute
    movq    %rdi, %r8 # buffer
    movq    %rcx, %r9 # char offset
    movq    $REGISTER_SIZE, %r10
    movq    %rdx, %r11
    # reserve and init the space that will hold the char counts
    subq    $CHARS_SPACE, %rsp # 26 * 8
    xor     %rax, %rax
    movq    %rsp, %rdi
    movq    $CHARS_COUNT, %rcx
    cld
    rep     stosq
    # init line loop
    xor     %rbx, %rbx # line iterator
.c_char_count_loop:
    cmp     %rbx, %rsi
    je      .c_char_find_greatest
    movq    %r11, %rax
    mul     %rbx
    addq    %r9, %rax
    movzb   (%r8, %rax), %rax
    cmp     $CHAR_A, %al
    jl      .c_char_error
    cmp     $CHAR_Z, %al
    jg      .c_char_error
    subb    $CHAR_A, %al
    mul     %r10
    incq    (%rsp, %rax)
    incq    %rbx
    jmp     .c_char_count_loop
    # init find greatest value loop
.c_char_find_greatest:
    xor     %r11, %r11 # iterator
    xor     %r12, %r12 # greatest count
    xor     %r13, %r13 # greatest count pos
.c_char_find_greatest_loop:
    movq    $REGISTER_SIZE, %rax
    mul     %r11
    movq    (%rsp, %rax), %rax
    cmp     %r12, %rax
    jng     .c_char_find_greatest_next
    movq    %rax, %r12
    movq    %r11, %r13
.c_char_find_greatest_next:
    incq    %r11
    cmp     $CHARS_COUNT, %r11
    jnz     .c_char_find_greatest_loop
.c_char_end:
    movq    $CHAR_A, %rax
    addq    %r13, %rax
    mov     %rbp, %rsp
    pop     %rbp
    ret
.c_char_error:
    mov     $EC_CHALLENGE_CHAR, %rdi
    call    u_exit_ec

challenge:
    # rdi: buffer to parse
    push    %rbp
    movq    %rsp, %rbp
    subq    $DATA_SIZE, %rsp
    movq    %rdi, DATA_INPUT_OFFSET(%rbp)
    call    u_string_len
    movq    %rax, DATA_INPUT_LENGTH_OFFSET(%rbp)
    movq    DATA_INPUT_OFFSET(%rbp), %rdi
    call    u_line_length
    incq    %rax # add trailing '\n'
    movq    %rax, DATA_LINE_LENGTH_OFFSET(%rbp)
    movq    DATA_INPUT_LENGTH_OFFSET(%rbp), %rdi
    movq    DATA_LINE_LENGTH_OFFSET(%rbp), %rsi
    call    c_line_count
    movq    %rax, DATA_LINE_COUNT_OFFSET(%rbp)
    push    $0 # init loop
.challenge_loop:
    movq    (%rsp), %rax
    incq    %rax # must add trailing '\n' for cmp
    cmpq    %rax, DATA_LINE_LENGTH_OFFSET(%rbp)
    je      .challenge_wrap_up
    movq    DATA_INPUT_OFFSET(%rbp), %rdi
    movq    DATA_LINE_COUNT_OFFSET(%rbp), %rsi
    movq    DATA_LINE_LENGTH_OFFSET(%rbp), %rdx
    movq    (%rsp), %rcx
    call    c_char
    movq    $buffer, %rbx
    addq    (%rsp), %rbx
    movb    %al, (%rbx)
    incq    (%rsp)
    jmp     .challenge_loop
.challenge_wrap_up:
    movq    $buffer, %rdi
    call    u_stdout
    mov     %rbp, %rsp
    pop     %rbp
    ret

.global _start
_start:
    cmpl    $2, (%rsp)
    jne     .start_error
    mov     16(%rsp), %rdi
    call    challenge
    mov     $EC_SUCCESS, %rdi
    call    u_exit_ec
.start_error:
    mov     $EC_CHALLENGE_ARGS, %rdi
    call    u_exit_ec
