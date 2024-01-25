# https://adventofcode.com/2016/day/9
# (part2)

# --- Part Two ---
#
# Apparently, the file actually uses version two of the format.
#
# In version two, the only difference is that markers within decompressed data are decompressed. This, the documentation explains, provides much more substantial compression capabilities, allowing many-gigabyte files to be stored in only a few kilobytes.
#
# For example:
#
#     (3x3)XYZ still becomes XYZXYZXYZ, as the decompressed section contains no markers.
#     X(8x2)(3x3)ABCY becomes XABCABCABCABCABCABCY, because the decompressed data from the (8x2) marker is then further decompressed, thus triggering the (3x3) marker twice for a total of six ABC sequences.
#     (27x12)(20x12)(13x14)(7x10)(1x12)A decompresses into a string of A repeated 241920 times.
#     (25x3)(3x3)ABC(2x3)XY(5x2)PQRSTX(18x9)(3x2)TWO(5x7)SEVEN becomes 445 characters long.
#
# Unfortunately, the computer you brought probably doesn't have enough memory to actually decompress the file; you'll have to come up with another way to get its decompressed length.
#
# What is the decompressed length of the file using this improved format?

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_CHALLENGE_ARGS, EC_SUCCESS + 1
.equ EC_CHALLENGE_MARKER_ERROR, EC_CHALLENGE_ARGS + 1
.equ EC_CHALLENGE_CONSUME_ERROR, EC_CHALLENGE_MARKER_ERROR + 1
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

marked_consume:
    push    %rbp
    movq    %rsp, %rbp
    push    %rsi # length to consume
    push    $0 # raw length consumed
    push    $0 # 'decompressed' length
.marked_consume_loop:
    movq    -8(%rbp), %rsi
    cmp     -16(%rbp), %rsi
    je      .marked_consume_wrap_up
    cmpb    $0, (%rdi)
    je      .marked_consume_error
    cmpb    $CHAR_MARKER_START, (%rdi)
    jne     .marked_consume_1
    call    marker_advance
    addq    %rbx, -16(%rbp)
    addq    %rax, -24(%rbp)
    jmp     .marked_consume_loop
.marked_consume_1:
    incq    %rdi
    incq    -16(%rbp)
    incq    -24(%rbp)
    jmp     .marked_consume_loop
.marked_consume_wrap_up:
    pop     %rax
    pop     %rbx
    mov     %rbp, %rsp
    pop     %rbp
    ret
.marked_consume_error:
    mov     $EC_CHALLENGE_CONSUME_ERROR, %rdi
    call    u_exit_ec

# return rax as the 'decompressed' size
# return rbx as the consumed input data length
marker_advance:
    push    %rbp
    movq    %rsp, %rbp
    push    $0 # raw length consumed
    cmpb    $CHAR_MARKER_START, (%rdi)
    jne     .marker_advance_error
    incq    %rdi
    incq    -8(%rbp)
    call    u_number_read_u
    addq    %rbx, -8(%rbp)
    cmpb    $CHAR_MARKER_SEP, (%rdi)
    jne     .marker_advance_error
    incq    %rdi
    incq    -8(%rbp)
    push    %rax # raw length to consume
    call    u_number_read_u
    addq    %rbx, -8(%rbp)
    cmpb    $CHAR_MARKER_END, (%rdi)
    jne     .marker_advance_error
    incq    %rdi
    incq    -8(%rbp)
    pop     %rsi # raw length to consume
    push    %rax # multiply factor
    call    marked_consume # consume marked data and return marked length
    addq    %rbx, -8(%rbp)
    pop     %rcx
    mul     %rcx # now raw has the 'decompressed' size
    mov     -8(%rbp), %rbx
    mov     %rbp, %rsp
    pop     %rbp
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
    push    %rdi
    call    marker_advance
    pop     %rdi
    addq    %rbx, %rdi
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
