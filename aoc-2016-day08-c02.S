# https://adventofcode.com/2016/day/8
# (part 2)

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_NUMBER_READ, EC_SUCCESS + 1
.equ EC_CHALLENGE_ARGS, 50
.equ EC_CHALLENGE_INSTRUCTION_UNKNOWN, EC_CHALLENGE_ARGS + 1
.equ EC_CHALLENGE_INSTRUCTION_REC, EC_CHALLENGE_INSTRUCTION_UNKNOWN + 1
.equ EC_CHALLENGE_INSTRUCTION_ROTATE_COL, EC_CHALLENGE_INSTRUCTION_REC + 1
.equ EC_CHALLENGE_INSTRUCTION_ROTATE_ROW, EC_CHALLENGE_INSTRUCTION_ROTATE_COL + 1

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_DASH, '@'
.equ CHAR_DOT, ' '
.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_MINUS, '-'
.equ CHAR_NEWLINE, '\n'

.equ DISPLAY_WIDTH, 50
.equ DISPLAY_HEIGHT, 6
.equ DISPLAY_SIZE, DISPLAY_WIDTH * DISPLAY_HEIGHT

.equ DATA_INPUT_OFFSET, -8
.equ DATA_POS_OFFSET, -16
.equ DATA_SIZE, 16

.bss
.lcomm num, 18 # buffer to hold number to print, 'write' syscall refuse a data stack pointer? :-/
.lcomm buffer, DISPLAY_WIDTH + 2 # +2 for new line and '\0'
.lcomm display, DISPLAY_SIZE

.data
LID_PREFIX: .byte 'r', 'e', 'c', 't', ' '
LID_PREFIX_END:
.equ LID_PREFIX_LEN, LID_PREFIX_END - LID_PREFIX
.equ LID_SEP_CHAR, 'x'
ROTATE_ROW_PREFIX: .byte 'r', 'o', 't', 'a', 't', 'e', ' ', 'r', 'o', 'w', ' ', 'y', '='
ROTATE_ROW_PREFIX_END:
.equ ROTATE_ROW_PREFIX_LEN, ROTATE_ROW_PREFIX_END - ROTATE_ROW_PREFIX
ROTATE_COL_PREFIX: .byte 'r', 'o', 't', 'a', 't', 'e', ' ', 'c', 'o', 'l', 'u', 'm', 'n', ' ', 'x', '='
ROTATE_COL_PREFIX_END:
.equ ROTATE_COL_PREFIX_LEN, ROTATE_COL_PREFIX_END - ROTATE_COL_PREFIX
ROTATE_SEP: .byte ' ', 'b', 'y', ' '
ROTATE_SEP_END:
.equ ROTATE_SEP_LEN, ROTATE_SEP_END - ROTATE_SEP

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

c_print_row:
    xor     %rcx, %rcx
.c_print_row_loop:
    cmp     $DISPLAY_WIDTH, %rcx
    je      .c_print_row_wrapup
    cmpb    $0, (%rdi, %rcx)
    jne     .c_print_row_dash
.c_print_row_dot:
    movb    $CHAR_DOT, buffer(%rcx)
    incq    %rcx
    jmp     .c_print_row_loop
.c_print_row_dash:
    movb    $CHAR_DASH, buffer(%rcx)
    incq    %rcx
    jmp     .c_print_row_loop
.c_print_row_wrapup:
    movb    $CHAR_NEWLINE, buffer(%rcx)
    incq    %rcx
    movb    $CHAR_EOF, buffer(%rcx)
    movq    $buffer, %rdi
    call    u_stdout
    ret

c_print_display:
    xor     %rcx, %rcx
.c_print_display_loop:
    cmp     $DISPLAY_HEIGHT, %rcx
    je      .c_print_display_end
    mov     $DISPLAY_WIDTH, %rax
    mul     %rcx
    lea     display(%rax), %rdi
    push    %rcx
    push    %rdi
    call    c_print_row
    pop     %rdi
    pop     %rcx
    incq    %rcx
    jmp     .c_print_display_loop
.c_print_display_end:
    xor     %rax, %rax
    ret

c_count:
    xor     %rax, %rax # return value
    xor     %rcx, %rcx # iterator
.c_count_loop:
    cmp     $DISPLAY_SIZE, %rcx
    je      .c_count_wrap_up
    cmpb    $CHAR_DASH, display(%rcx)
    jne     .c_count_loop_next
    incq    %rax
.c_count_loop_next:
    incq    %rcx
    jmp     .c_count_loop
.c_count_wrap_up:
    ret

c_rotate_col:
    # copy input as it's also the destination
    xor     %r8, %r8 # row iterator
.c_rotate_col_copy_to_loop:
    cmpq    $DISPLAY_HEIGHT, %r8
    je      .c_rotate_col_rotation
    movq    $DISPLAY_WIDTH, %rax
    mul     %r8
    movb    display(%rax, %rdi), %al
    movb    %al, buffer(%r8)
    incq    %r8
    jmp     .c_rotate_col_copy_to_loop
.c_rotate_col_rotation:
    xor     %r8, %r8 # iterator
    mov     $DISPLAY_HEIGHT, %r9
.c_rotate_col_rotation_loop:
    cmpq    $DISPLAY_HEIGHT, %r8
    je      .c_rotate_col_end
    movb    buffer(%r8), %r10b # src
    xor     %rdx, %rdx
    movq    %rsi, %rax
    addq    %r8, %rax
    div     %r9
    movq    $DISPLAY_WIDTH, %rax
    mul     %rdx
    movb    %r10b, display(%rax, %rdi)
    incq    %r8
    jmp     .c_rotate_col_rotation_loop
.c_rotate_col_copy_from_loop:
    cmpq    $DISPLAY_HEIGHT, %r8
    je      .c_rotate_col_end
    mov     buffer(%r8), %r9
    movq    $DISPLAY_WIDTH, %rax
    mul     %r8
    movb    %r9b, display(%rax, %rdi)
    incq    %r8
    jmp     .c_rotate_col_copy_from_loop
.c_rotate_col_end:
    ret

c_rotate_row:
    # copy input as it's also the destination
    xor     %r8, %r8 # col iterator
    movq    $DISPLAY_WIDTH, %rax
    mul     %rdi
    movq    %rax, %r9 # row offset
.c_rotate_row_copy_to_loop:
    cmpq    $DISPLAY_WIDTH, %r8
    je      .c_rotate_row_rotation
    movb    display(%r9, %r8), %bl
    movb    %bl, buffer(%r8)
    incq    %r8
    jmp     .c_rotate_row_copy_to_loop
.c_rotate_row_rotation:
    xor     %r8, %r8 # col iterator
    mov     $DISPLAY_WIDTH, %r10
.c_rotate_row_rotation_loop:
    cmpq    $DISPLAY_WIDTH, %r8
    je      .c_rotate_row_end
    movb    buffer(%r8), %r11b # src
    xor     %rdx, %rdx
    movq    %rsi, %rax
    addq    %r8, %rax
    divq    %r10
    movb    %r11b, display(%rdx, %r9)
    incq    %r8
    jmp     .c_rotate_row_rotation_loop
.c_rotate_row_copy_from_loop:
    cmpq    $DISPLAY_HEIGHT, %r8
    je      .c_rotate_row_end
    mov     buffer(%r8), %r9
    movq    $DISPLAY_WIDTH, %rax
    mul     %r8
    movb    %r9b, display(%rax, %rdi)
    incq    %r8
    jmp     .c_rotate_row_copy_from_loop
.c_rotate_row_end:
    ret

c_instruction_rotate_col:
    push    %rbp
    movq    %rsp, %rbp
    mov     $ROTATE_COL_PREFIX, %rsi
    mov     $ROTATE_COL_PREFIX_LEN, %rcx
    call    u_mem_cmp
    cmp     $0, %rax
    je      .c_instruction_rotate_col_wrap_up
    push    %rax # number of bytes consumed
    push    $0 # col pos
    push    $0 # shift value
    # %rdi is already pointing to next unread data
    call    u_number_read_u
    cmp     $0, %rbx
    je      .c_instruction_rotate_col_error
    addq    %rbx, -8(%rbp)
    movq    %rax, -16(%rbp)
    # check separator
    mov     $ROTATE_SEP, %rsi
    mov     $ROTATE_SEP_LEN, %rcx
    call    u_mem_cmp
    cmp     $0, %rax
    je      .c_instruction_rotate_col_error
    addq    $ROTATE_SEP_LEN, -8(%rbp)
    call    u_number_read_u
    cmp     $0, %rbx
    je      .c_instruction_rotate_col_error
    addq    %rbx, -8(%rbp)
    mov     -16(%rbp), %rdi
    mov     %rax, %rsi
    call    c_rotate_col
    mov     -8(%rbp), %rax
.c_instruction_rotate_col_wrap_up:
    movq    %rbp, %rsp
    pop     %rbp
    ret
.c_instruction_rotate_col_error:
    mov     $EC_CHALLENGE_INSTRUCTION_ROTATE_COL, %rdi
    call    u_exit_ec

c_instruction_rotate_row:
    push    %rbp
    movq    %rsp, %rbp
    mov     $ROTATE_ROW_PREFIX, %rsi
    mov     $ROTATE_ROW_PREFIX_LEN, %rcx
    call    u_mem_cmp
    cmp     $0, %rax
    je      .c_instruction_rotate_row_wrap_up
    push    %rax # number of bytes consumed
    push    $0 # row pos
    push    $0 # shift value
    # %rdi is already pointing to next unread data
    call    u_number_read_u
    cmp     $0, %rbx
    je      .c_instruction_rotate_row_error
    addq    %rbx, -8(%rbp)
    movq    %rax, -16(%rbp)
    # check separator
    mov     $ROTATE_SEP, %rsi
    mov     $ROTATE_SEP_LEN, %rcx
    call    u_mem_cmp
    cmp     $0, %rax
    je      .c_instruction_rotate_row_error
    addq    $ROTATE_SEP_LEN, -8(%rbp)
    call    u_number_read_u
    cmp     $0, %rbx
    je      .c_instruction_rotate_row_error
    addq    %rbx, -8(%rbp)
    mov     -16(%rbp), %rdi
    mov     %rax, %rsi
    call    c_rotate_row
    mov     -8(%rbp), %rax
.c_instruction_rotate_row_wrap_up:
    movq    %rbp, %rsp
    pop     %rbp
    ret
.c_instruction_rotate_row_error:
    mov     $EC_CHALLENGE_INSTRUCTION_ROTATE_ROW, %rdi
    call    u_exit_ec

c_rect:
    mov     %rdi, %r8 # width
    mov     %rsi, %r9 # height
    xor     %r10, %r10 # row iterator
.c_rect_row:
    cmp     %r9, %r10
    je      .c_rect_end
    mov     $DISPLAY_WIDTH, %rax
    mul     %r10
    leaq    display(%rax), %rdi
    mov     %r8, %rcx
    mov     $CHAR_DASH, %rax
    rep     stosb
    incq    %r10
    jmp     .c_rect_row
.c_rect_end:
    ret

c_instruction_rec:
    push    %rbp
    movq    %rsp, %rbp
    mov     $LID_PREFIX, %rsi
    mov     $LID_PREFIX_LEN, %rcx
    call    u_mem_cmp
    cmp     $0, %rax
    je      .c_instruction_rec_wrap_up
    push    %rax # number of bytes consumed
    push    $0 # lid with
    # %rdi is already pointing to next unread data
    push    %rdi
    call    u_number_read_u
    cmp     $0, %rbx
    je      .c_instruction_rec_error
    pop     %rdi
    addq    %rbx, %rdi
    cmpb    $LID_SEP_CHAR, (%rdi)
    jne     .c_instruction_rec_error
    incq    %rbx
    addq    %rbx, -8(%rbp)
    movq    %rax, -16(%rbp)
    incq    %rdi
    call    u_number_read_u
    cmp     $0, %rbx
    je      .c_instruction_rec_error
    addq    %rbx, -8(%rbp)
    mov     -16(%rbp), %rdi
    mov     %rax, %rsi
    call    c_rect
    mov     -8(%rbp), %rax
.c_instruction_rec_wrap_up:
    movq    %rbp, %rsp
    pop     %rbp
    ret
.c_instruction_rec_error:
    mov     $EC_CHALLENGE_INSTRUCTION_REC, %rdi
    call    u_exit_ec

c_instruction:
    push    %rbp
    movq    %rsp, %rbp
    push    %rdi
    call    c_instruction_rec
    cmp     $0, %rax
    jne     .c_instruction_wrap_up
    mov     (%rsp), %rdi
    call    c_instruction_rotate_col
    cmp     $0, %rax
    jne     .c_instruction_wrap_up
    mov     (%rsp), %rdi
    call    c_instruction_rotate_row
    cmp     $0, %rax
    jne     .c_instruction_wrap_up
    pop     %rdi
    mov     $EC_CHALLENGE_INSTRUCTION_UNKNOWN, %rdi
    call    u_exit_ec
.c_instruction_wrap_up:
    pop     %rdi
    movq    %rbp, %rsp
    pop     %rbp
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    movq    %rsp, %rbp
    subq    $DATA_SIZE, %rsp
    movq    %rdi, DATA_INPUT_OFFSET(%rbp)
    movq    $0, DATA_POS_OFFSET(%rbp)
.challenge_loop:
    movq    DATA_INPUT_OFFSET(%rbp), %rdi
    addq    DATA_POS_OFFSET(%rbp), %rdi
    cmpb    $0, (%rdi)
    je      .challenge_count
    cmpb    $CHAR_NEWLINE, (%rdi)
    je      .challenge_loop_consume_1
    call    c_instruction
    cmp     $0, %rax
    je      .challenge_count
    addq    %rax, DATA_POS_OFFSET(%rbp)
    mov     %rax, %rdi
    jmp     .challenge_loop
.challenge_loop_consume_1:
    incq    DATA_POS_OFFSET(%rbp)
    jmp     .challenge_loop
.challenge_count:
    call    c_print_display
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
