# https://adventofcode.com/2016/day/3
# (part 2)
#
# Now that you've helpfully marked up their design documents, it occurs to you that triangles are specified in groups of three vertically. Each set of three numbers in a column specifies a triangle. Rows are unrelated.
#
# For example, given the following specification, numbers with the same hundreds digit would be part of the same triangle:
#
# 101 301 501
# 102 302 502
# 103 303 503
# 201 401 601
# 202 402 602
# 203 403 603
#
# In your puzzle input, and instead reading by columns, how many of the listed triangles are possible?

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_NUMBER_READ, EC_SUCCESS + 1
.equ EC_CHALLENGE_ARGS, EC_NUMBER_READ + 1
.equ EC_CHALLENGE_TRIANGLES_COUNT, EC_CHALLENGE_ARGS + 1
.equ EC_CHALLENGE_DATA, EC_CHALLENGE_TRIANGLES_COUNT + 1
.equ EC_CHALLENGE_DATA_TRIANGLES_COUNT_GET, EC_CHALLENGE_DATA + 1
.equ EC_CHALLENGE_DATA_LINES_CONSUME, EC_CHALLENGE_DATA_TRIANGLES_COUNT_GET + 1
.equ EC_CHALLENGE_DATA_NUMBER_READ, EC_CHALLENGE_DATA_LINES_CONSUME + 1

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_MINUS, '-'
.equ CHAR_NEWLINE, '\n'
.equ CHAR_SPACE, ' '

.bss
.lcomm num, 18 # buffer to hold number to print, 'write' syscall refuse a data stack pointer

.text

u_exit_ec:
    mov     %rdi, %rbx
    movq    $1, %rax
    int     $0x80

u_string_leng:
    mov     $0, %rax
.u_string_leng_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .u_string_leng_end
    incq    %rax
    incq    %rdi
    jmp     .u_string_leng_loop
.u_string_leng_end:
    ret

u_stdout:
    push    %rdi
    call    u_string_leng
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
    movq    $16, %r12 # loop 9 times
.u_number_print_s64_loop:
    movq    %r10, %rax
    movq    %r11, %rcx
    movq    $0, %rdx
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

c_triangle_check:
    # set max value to r10 and other two to r11 and r12
    cmp     %rdi, %rsi
    jg      .c_triangle_check_cmp1_rsi_bigger
    mov     %rdi, %r10
    mov     %rsi, %r11
    jmp     .c_triangle_check_cmp1_done
.c_triangle_check_cmp1_rsi_bigger:
    mov     %rsi, %r10
    mov     %rdi, %r11
.c_triangle_check_cmp1_done:
    cmp     %r10, %rdx
    jg      .c_triangle_check_cmp2_rdx_bigger
    mov     %rdx, %r12
    jmp     .c_triangle_check_fit_check
.c_triangle_check_cmp2_rdx_bigger:
    mov     %r10, %r12
    mov     %rdx, %r10
    # check that larger side is inferior to the sum of the other two
.c_triangle_check_fit_check:
    add     %r11, %r12
    cmp     %r10, %r12
    jg      .c_triangle_check_fit_ok
.c_triangle_check_fit_ko:
    mov     $0, %rax
    jmp     .c_triangle_check_wrap_up
.c_triangle_check_fit_ok:
    mov     $1, %rax
    jmp     .c_triangle_check_wrap_up
.c_triangle_check_wrap_up:
    ret

c_lines_consume:
    xor     %rax, %rax # number of lines consumed
.c_lines_consume_loop:
    mov     (%rdi), %rbx
    movzb   (%rbx), %rcx
    cmp     $CHAR_EOF, %rcx
    je      .c_lines_consume_eof
    incq    (%rdi) # consume char
    cmp     $CHAR_NEWLINE, %rcx
    je      .c_lines_consume_newline
    jmp     .c_lines_consume_loop
.c_lines_consume_newline:
    incq    %rax
    cmp     $3, %rax
    je      .c_lines_consume_wrap_up
    jmp     .c_lines_consume_loop
.c_lines_consume_eof:
    incq    %rax
    cmp     $3, %rax
    jne     .c_lines_consume_error
.c_lines_consume_wrap_up:
    ret
.c_lines_consume_error:
    mov     $EC_CHALLENGE_DATA_LINES_CONSUME, %rdi
    call    u_exit_ec

c_number_read:
    # rdi: buffer
    # rsi: index of triangle within the line (x)
    # rbx: index of the line (y)
    xor     %rcx, %rcx # current offset
    xor     %rdx, %rdx # current line
.c_number_read_consume_lines:
    cmp     %rbx, %rdx
    je      .c_number_read_seek_number
.c_number_read_consume_lines_char:
    movzb   (%rdi, %rcx), %rax
    cmp     $CHAR_EOF, %rax
    je      .c_number_read_error
    inc     %rcx # consume char
    cmp     $CHAR_NEWLINE, %rax
    jne     .c_number_read_consume_lines_char
    inc     %rdx
    jmp     .c_number_read_consume_lines
.c_number_read_seek_number:
    add     %rcx, %rdi
.c_number_read_seek_number_loop:
    movzb   (%rdi), %rax
    cmp     $CHAR_EOF, %rax
    je      .c_number_read_error
    cmp     $CHAR_SPACE, %rax
    je      .c_number_seek_number_consume_char
    call    u_number_read_u
    dec     %rsi
    cmp     $0, %rsi
    jge     .c_number_read_seek_number_loop
    jmp     .c_number_read_wrap_up
.c_number_seek_number_consume_char:
    inc     %rdi
    jmp     .c_number_read_seek_number_loop
.c_number_read_wrap_up:
    ret
.c_number_read_error:
    mov     $EC_CHALLENGE_DATA_NUMBER_READ, %rdi
    call    u_exit_ec

c_triangles_count_get:
    xor     %rax, %rax # triangles count
    xor     %rbx, %rbx # current char index
    xor     %rcx, %rcx # flag: 0 = void, 1 = in digit
.c_triangles_count_get_loop:
    movzb   (%rdi, %rbx), %rdx
    cmp     $CHAR_EOF, %rdx
    je      .c_triangles_count_get_wrap_up
    cmp     $CHAR_NEWLINE, %rdx
    je      .c_triangles_count_get_wrap_up
    cmp     $CHAR_SPACE, %rdx
    je      .c_triangles_count_get_loop_space
    cmp     $CHAR_0, %rdx
    jl      .c_triangles_count_get_error
    cmp     $CHAR_9, %rdx
    jg      .c_triangles_count_get_error
    cmp     $1, %rcx
    je      .c_triangles_count_get_loop_next
    inc     %rax
    inc     %rcx
    jmp     .c_triangles_count_get_loop_next
.c_triangles_count_get_loop_space:
    xor     %rcx, %rcx
.c_triangles_count_get_loop_next:
    inc     %rbx
    jmp     .c_triangles_count_get_loop
.c_triangles_count_get_wrap_up:
    ret
.c_triangles_count_get_error:
    mov     $EC_CHALLENGE_DATA_TRIANGLES_COUNT_GET, %rdi
    call    u_exit_ec

challenge:
    push    %rbp
    mov     %rsp, %rbp
    sub     $24, %rsp
    movq    %rdi, -8(%rbp) # buffer to read pointer
    movl    $0, -12(%rbp) # triangle count
    call    u_string_leng
    movl    %eax, -16(%rbp) # buffer length to avoid buffer overflow
    push    $0
.challenge_loop:
    # check eof
    mov     -8(%rbp), %rax
    movzb   (%rax), %rax
    cmp     $0x00, %rax
    je      .challenge_wrap_up
    # get the number of triangles to check from the current line
    movl    $0, -20(%rbp) # index of current triangle
    mov     -8(%rbp), %rdi
    call    c_triangles_count_get
    movl    %eax, -24(%rbp)
    cmp     $0, %rax
    jle     .challenge_error_triangles_count
.challenge_loop_numbers:
    # first side of trianle
    mov     -8(%rbp), %rdi
    movl    -20(%rbp), %esi
    mov     $0, %rbx
    call    c_number_read
    cmp     $0, %rax
    je      .challenge_error_data
    push    %rax
    # second side of triangle
    mov     -8(%rbp), %rdi
    movl    -20(%rbp), %esi
    mov     $1, %rbx
    call    c_number_read
    cmp     $0, %rax
    je      .challenge_error_data
    push    %rax
    # third side of trianle
    mov     -8(%rbp), %rdi
    movl    -20(%rbp), %esi
    mov     $2, %rbx
    call    c_number_read
    cmp     $0, %rax
    je      .challenge_error_data
    # check if it's a trianle
    pop     %rsi
    pop     %rdi
    mov     %rax, %rdx
    call    c_triangle_check
    cmp     $1, %rax
    jne     .challenge_loop_numbers_next
    incl    -12(%rbp)
.challenge_loop_numbers_next:
    # next column
    incl    -20(%rbp)
    movl    -20(%rbp), %eax
    cmpl    %eax, -24(%rbp)
    jne     .challenge_loop_numbers
    lea     -8(%rbp), %rdi
    call    c_lines_consume
    jmp     .challenge_loop
.challenge_wrap_up:
    xor     %rdi, %rdi
    movl    -12(%rbp), %edi
    call    u_number_print_s64
    mov     %rbp, %rsp
    pop     %rbp
    ret
.challenge_error_triangles_count:
    mov     $EC_CHALLENGE_TRIANGLES_COUNT, %rdi
    call    u_exit_ec
.challenge_error_data:
    mov     $EC_CHALLENGE_DATA, %rdi

.global _start
_start:
    cmpl    $2, (%rsp)
    jne     .start_error
    mov     16(%rsp), %rdi
    call    challenge
    mov     $0, %rdi
    call    u_exit_ec
.start_error:
    mov     $EC_CHALLENGE_ARGS, %rdi
    call    u_exit_ec
