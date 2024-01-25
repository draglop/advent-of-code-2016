# https://adventofcode.com/2016/day/9

# --- Day 9: Explosives in Cyberspace ---
#
# Wandering around a secure area, you come across a datalink port to a new part of the network. After briefly scanning it for interesting files, you find one file in particular that catches your attention. It's compressed with an experimental format, but fortunately, the documentation for the format is nearby.
#
# The format compresses a sequence of characters. Whitespace is ignored. To indicate that some sequence should be repeated, a marker is added to the file, like (10x2). To decompress this marker, take the subsequent 10 characters and repeat them 2 times. Then, continue reading the file after the repeated data. The marker itself is not included in the decompressed output.
#
# If parentheses or other characters appear within the data referenced by a marker, that's okay - treat it like normal data, not a marker, and then resume looking for markers after the decompressed section.
#
# For example:
#
#   - ADVENT contains no markers and decompresses to itself with no changes, resulting in a decompressed length of 6.
#   - A(1x5)BC repeats only the B a total of 5 times, becoming ABBBBBC for a decompressed length of 7.
#   - (3x3)XYZ becomes XYZXYZXYZ for a decompressed length of 9.
#   - A(2x2)BCD(2x2)EFG doubles the BC and EF, becoming ABCBCDEFEFG for a decompressed length of 11.
#   - (6x1)(1x3)A simply becomes (1x3)A - the (1x3) looks like a marker, but because it's within a data section of another marker, it is not treated any differently from the A that comes after it. It has a decompressed length of 6.
#   - X(8x2)(3x3)ABCY becomes X(3x3)ABC(3x3)ABCY (for a decompressed length of 18), because the decompressed data from the (8x2) marker (the (3x3)ABC) is skipped and not processed further.
#
# What is the decompressed length of the file (your puzzle input)? Don't count whitespace.

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_CHALLENGE_ARGS, EC_SUCCESS + 1
.equ EC_CHALLENGE_MARKER_ERROR, EC_CHALLENGE_ARGS + 1
.equ EC_NUMBER_READ, 200

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_MARKER_START, '('
.equ CHAR_MARKER_END, ')'
.equ CHAR_MARKER_SEP, 'x'
.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_MINUS, '-'
.equ CHAR_NEWLINE, '\n'

.equ DATA_INPUT_OFFSET, -8
.equ DATA_COUNT_OFFSET, -16
.equ DATA_SIZE, 16

.bss
.lcomm num, 18 # buffer to hold number to print, 'write' syscall refuse a data stack pointer? :-/


.text

u_exit_ec:
    mov     %rdi, %rbx
    movq    $1, %rax
    int     $0x80

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

u_mem_cmp:
    mov     %rcx, %rax
    repe    cmpsb
    jz      .u_mem_cmp_end
    xor     %rax, %rax
.u_mem_cmp_end:
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

u_number_print_s64:
    movq    $num, %r9 # buffer pointer
    movb    $CHAR_0, (%r9)
    cmp     $0, %rdi
    jge     .u_number_print_s64_unsigned
    movb    $CHAR_MINUS, (%r9) # set digit
    neg     %rdi
.u_number_print_s64_unsigned:
    inc     %r9
    movq    %rdi, %r10 # value to divide
    movq    $1000000000000000, %r11 # divisor
    movq    $16, %r12 # loop 16 times
.u_number_print_s64_loop:
    movq    %r10, %rax
    movq    %r11, %rcx
    xor     %rdx, %rdx
    div     %rcx
    movq    %rdx, %r10
    add     $CHAR_0, %rax
    movb    %al, (%r9) # set digit
    inc     %r9
    # remove one 0 from divisor
    movq    %r11, %rax
    movq    $10, %rcx
    movq    $0, %rdx
    div     %rcx
    movq    %rax, %r11
    dec     %r12
    jne     .u_number_print_s64_loop
    movb    $CHAR_NEWLINE, (%r9)
    # print buffer
    movq    $num, %rdi
    # skip leading 0
    mov     $16, %rcx
.u_number_print_s64_padding_loop:
    cmpb    $CHAR_0, (%rdi)
    jne     .u_number_print_s64_wrap_up
    incq    %rdi
    loop    .u_number_print_s64_padding_loop
.u_number_print_s64_wrap_up:
    call    u_stdout
    ret

u_number_read_u:
    mov     $0, %rax # accumulator
    mov     $0, %r10 # number of digit read
    mov     $10, %r12 # digit multiplicator
.u_number_read_u_loop:
    movzb   (%rdi), %rbx
    cmpb    $CHAR_0, %bl
    jl      .u_number_read_u_wrap_up
    cmpb    $CHAR_9, %bl
    jg      .u_number_read_u_wrap_up
    mul     %r12 # shift previous number by one digit: x10
    sub     $CHAR_0, %bl
    add     %rbx, %rax
    inc     %r10
    incq    %rdi
    jmp     .u_number_read_u_loop
.u_number_read_u_wrap_up:
    cmp     $0, %r10
    je      .u_number_read_u_error
    mov     %r10, %rbx # also return the number of digit read
    ret
.u_number_read_u_error:
    mov     $EC_NUMBER_READ, %rdi
    call    u_exit_ec

marker_advance:
    cmpb    $CHAR_MARKER_START, (%rdi)
    jne     .marker_advance_error
    incq    %rdi
    call    u_number_read_u
    push    %rax
    cmpb    $CHAR_MARKER_SEP, (%rdi)
    jne     .marker_advance_error
    incq    %rdi
    call    u_number_read_u
    cmpb    $CHAR_MARKER_END, (%rdi)
    jne     .marker_advance_error
    incq    %rdi
    pop     %rdx
    addq    %rdx, %rdi # consume marked data
    mul     %rdx
    ret
.marker_advance_error:
    mov     $EC_CHALLENGE_MARKER_ERROR, %rdi
    call    u_exit_ec

challenge:
    # rdi: buffer to parse
    push    %rbp
    movq    %rsp, %rbp
    subq    $DATA_SIZE, %rsp
    movq    %rdi, DATA_INPUT_OFFSET(%rbp)
    movq    $0, DATA_COUNT_OFFSET(%rbp)
.challenge_loop:
    cmpb    $0, (%rdi)
    je      .challenge_wrap_up
    cmpb    $CHAR_MARKER_START, (%rdi)
    jne     .challenge_loop_consume_1
    call    marker_advance
    addq    %rax, DATA_COUNT_OFFSET(%rbp)
    jmp     .challenge_loop
.challenge_loop_consume_1:
    incq    DATA_COUNT_OFFSET(%rbp)
    incq    %rdi
    jmp     .challenge_loop
.challenge_wrap_up:
    movq    DATA_COUNT_OFFSET(%rbp), %rdi
    call    u_number_print_s64
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
