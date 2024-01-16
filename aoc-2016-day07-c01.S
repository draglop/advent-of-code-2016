# https://adventofcode.com/2016/day/7

# --- Day 7: Internet Protocol Version 7 ---
# 
# While snooping around the local network of EBHQ, you compile a list of IP addresses (they're IPv7, of course; IPv6 is much too limited). You'd like to figure out which IPs support TLS (transport-layer snooping).
# 
# An IP supports TLS if it has an Autonomous Bridge Bypass Annotation, or ABBA. An ABBA is any four-character sequence which consists of a pair of two different characters followed by the reverse of that pair, such as xyyx or abba. However, the IP also must not have an ABBA within any hypernet sequences, which are contained by square brackets.
# 
# For example:
# 
#     abba[mnop]qrst supports TLS (abba outside square brackets).
#     abcd[bddb]xyyx does not support TLS (bddb is within square brackets, even though xyyx is outside square brackets).
#     aaaa[qwer]tyui does not support TLS (aaaa is invalid; the interior characters must be different).
#     ioxxoj[asdfgh]zxcvbn supports TLS (oxxo is outside square brackets, even though it's within a larger string).
# 
# How many IPs in your puzzle input support TLS?

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_CHALLENGE_ARGS, EC_SUCCESS + 1

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_SEQ_S, '['
.equ CHAR_SEQ_E, ']'
.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_MINUS, '-'
.equ CHAR_NEWLINE, '\n'

.equ ABBA_LENGTH, 4

.equ DATA_INPUT_OFFSET, -8
.equ DATA_POS_OFFSET, -16
.equ DATA_COUNT_OFFSET, -24
.equ DATA_SIZE, 24

.bss
.lcomm num, 18 # buffer to hold number to print, 'write' syscall refuse a data stack pointer? :-/

.text

u_exit_ec:
    mov     %rdi, %rbx
    movq    $1, %rax
    int     $0x80

# also count trailing '\n'
u_line_len:
    xor     %rax, %rax
.u_line_len_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .u_line_len_end
    incq    %rax
    cmpb    $CHAR_NEWLINE, (%rdi)
    je      .u_line_len_end
    incq    %rdi
    jmp     .u_line_len_loop
.u_line_len_end:
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

c_check_abba:
    movb    (%r11), %al
    cmpb    %al, 3(%r11)
    jne     .c_check_abba_ko
    movb    1(%r11), %al
    cmpb    %al, 2(%r11)
    jne     .c_check_abba_ko
    cmpb    %al, (%r11)
    je      .c_check_abba_ko
    mov     $1, %rax
    ret
.c_check_abba_ko:
    xor     %rax, %rax
    ret

c_check_ipv7:
    # rdi: line data
    # rsi: line length
    xor     %r8, %r8 # iterator
    xor     %r9, %r9 # within hypernet sequence flag
    xor     %r10, %r10 # valid abba found flag
.c_check_ipv7_loop:
    # check that we are not checking beyond line
    leaq    ABBA_LENGTH(%r8), %rax
    cmp     %rax, %rsi
    jl      .c_check_ipv7_wrap_up
    movq    %rdi, %r11
    addq    %r8, %r11
    incq    %r8
    cmpb    $CHAR_SEQ_S, (%r11) 
    je      .c_check_ipv7_seq_s
    cmpb    $CHAR_SEQ_E, (%r11) 
    je      .c_check_ipv7_seq_e
    call    c_check_abba
    cmp     $0, %rax
    je      .c_check_ipv7_loop
    cmp     $1, %r9
    je      .c_check_ipv7_ko
    mov     $1, %r10
    jmp     .c_check_ipv7_loop
.c_check_ipv7_seq_s:
    movq    $1, %r9
    jmp     .c_check_ipv7_loop
.c_check_ipv7_seq_e:
    xor     %r9, %r9
    jmp     .c_check_ipv7_loop
.c_check_ipv7_ko:
    xor     %r10, %r10 # clear abba found flag
.c_check_ipv7_wrap_up:
    mov     %r10, %rax
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    movq    %rsp, %rbp
    subq    $DATA_SIZE, %rsp
    movq    %rdi, DATA_INPUT_OFFSET(%rbp)
    movq    $0, DATA_POS_OFFSET(%rbp)
    movq    $0, DATA_COUNT_OFFSET(%rbp)
.challenge_loop:
    movq    DATA_INPUT_OFFSET(%rbp), %rdi
    addq    DATA_POS_OFFSET(%rbp), %rdi
    push    %rdi
    call    u_line_len
    pop     %rdi
    cmp     $1, %rax
    jle      .challenge_wrap_up
    add     %rax, DATA_POS_OFFSET(%rbp)
    mov     %rax, %rsi
    call    c_check_ipv7
    cmp     $1, %rax
    jne     .challenge_loop
    incq    DATA_COUNT_OFFSET(%rbp)
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
