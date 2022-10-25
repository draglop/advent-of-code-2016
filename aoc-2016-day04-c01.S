# https://adventofcode.com/2016/day/4
#
# Each room consists of an encrypted name (lowercase letters separated by dashes) followed by a dash, a sector ID, and a checksum in square brackets.
#
# A room is real (not a decoy) if the checksum is the five most common letters in the encrypted name, in order, with ties broken by alphabetization. For example:
#
#     aaaaa-bbb-z-y-x-123[abxyz] is a real room because the most common letters are a (5), b (3), and then a tie between x, y, and z, which are listed alphabetically.
#     a-b-c-d-e-f-g-h-987[abcde] is a real room because although the letters are all tied (1 of each), the first five are listed alphabetically.
#     not-a-real-room-404[oarel] is a real room.
#     totally-real-room-200[decoy] is not.
#
# Of the real rooms from the list above, the sum of their sector IDs is 1514.
#
# What is the sum of the sector IDs of the real rooms?

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_NUMBER_READ, EC_SUCCESS + 1
.equ EC_CHALLENGE_ARGS, EC_NUMBER_READ + 1
.equ EC_CHALLENGE_CHEKCSUM_VERIFY, EC_CHALLENGE_ARGS + 1

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_EOF, 0
.equ CHAR_MINUS, '-'
.equ CHAR_NEWLINE, '\n'
.equ CHAR_SPACE, ' '
.equ CHAR_A, 'a'
.equ CHAR_Z, 'z'
.equ CHAR_DASH, '-'
.equ CHAR_BRACKET_OPEN, '['
.equ CHAR_BRACKET_CLOSE, ']'
.equ CHECKSUM_LENGTH, 5

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

sector_id_scan:
    call    u_number_read_u
    ret

checksum_compute:
    mov     %rdi, %r10 # char to check pointer
    mov     %rsi, %r11 # checksum to write pointer
    mov     $-1, %rbx # char index
.checksum_compute_char_candidate:
    inc     %rbx
    cmp     $26, %rbx
    je      .checksum_compute_wrap_up
    mov     $-1, %rcx # checksum pos index
.checksum_compute_pos_try:
    inc     %rcx
    cmp     $5, %rcx
    je      .checksum_compute_char_candidate
    cmpb    $0, (%r11, %rcx)
    je      .checksum_compute_pos
    # retrieve current checksum char count
    movzb    (%r11, %rcx), %rax
    movzb   -1(%r10, %rax), %rax
    #
    cmpb    %al, (%r10, %rbx)
    jg      .checksum_compute_pos
    jmp     .checksum_compute_pos_try
.checksum_compute_pos:
    mov     $4, %r12
.checksum_compute_pos_set_shift_loop:
    cmp     %r12, %rcx
    je      .checksum_compute_pos_set
    movzb   -1(%r11, %r12), %rax
    mov     %al, (%r11, %r12)
    dec     %r12
    jmp     .checksum_compute_pos_set_shift_loop
.checksum_compute_pos_set:
    movb    %bl, (%r11, %rcx)
    incb    (%r11, %rcx)
    jmp     .checksum_compute_char_candidate
.checksum_compute_wrap_up:
    mov     $0, %rax
.checksum_compute_charify_loop:
    decb    (%r11, %rax)
    addb    $CHAR_A, (%r11, %rax)
    inc     %rax
    cmp     $5, %rax
    jne     .checksum_compute_charify_loop
    ret

checksum_verify:
    mov     $-1, %rax
    movq    %rdi, %r10
    cmpb    $CHAR_BRACKET_OPEN, (%r10)
    jne     .checksum_verify_error
    inc     %r10
    mov     %rsi, %r11
    mov     $0, %r12
.checksum_verify_char_check:
    movzb   (%r10), %rbx
    cmpb    %bl, (%r11)
    jne     .checksum_verify_wrap_up
    incq    %r10
    incq    %r11
    incq    %r12
    cmp     $CHECKSUM_LENGTH, %r12
    jne     .checksum_verify_char_check
    cmpb    $CHAR_BRACKET_CLOSE, (%r10)
    jne     .checksum_verify_error
    mov     $0, %rax
.checksum_verify_wrap_up:
    ret
.checksum_verify_error:
    mov     $EC_CHALLENGE_CHEKCSUM_VERIFY, %rdi
    call    u_exit_ec

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $72, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movq    $0, 8(%rsp) # sum of the sector ids
    movl    $0, 64(%rsp) # index within buffer
.challenge_room_new:
    movq    $0, 16(%rsp) # a - h
    movq    $0, 24(%rsp) # i - p
    movq    $0, 32(%rsp) # q - x
    movq    $0, 40(%rsp) # y - z + 2b of padding
    movq    $0, 48(%rsp) # sector id read
    movq    $0, 56(%rsp) # computed checksum + 3b of padding
    # check eof
    mov     (%rsp), %rdi
    add     64(%rsp), %rdi
    movzb   (%rdi), %rax
    cmp     $0, %rax
    je      .challenge_wrap_up
    # check new line
    cmp     $CHAR_NEWLINE, %rax
    je      .challenge_line_consume_new_line
.challenge_char_new:
    mov     (%rsp), %rdi
    add     64(%rsp), %rdi
    movzb   (%rdi), %rax
    cmp     $0, %rax
    # check dash
    cmp     $CHAR_DASH, %rax
    je      .challenge_consume_char
    # check char
    cmp     $CHAR_A, %rax
    jl      .challenge_encrypted_name_end
    cmp     $CHAR_Z, %rax
    jg      .challenge_encrypted_name_end
    # increase char count
    sub     $CHAR_A, %rax
    incb    16(%rsp, %rax)
    incq    64(%rsp) # consume char
    jmp     .challenge_char_new
.challenge_encrypted_name_end:
    # not a dash nor a char to count
    # get the input checkssum
    movq    (%rsp), %rdi
    add     64(%rsp), %rdi
    call    sector_id_scan
    mov     %rax, 48(%rsp)
    add     %rbx, 64(%rsp)
    # get the computed checksum
    lea     16(%rsp), %rdi
    lea     56(%rsp), %rsi
    call    checksum_compute
    # compare checksums
    movq    (%rsp), %rdi
    add     64(%rsp), %rdi
    lea     56(%rsp), %rsi
    call    checksum_verify
    addq    $CHECKSUM_LENGTH, 64(%rsp) # consume checksum
    addq    $2, 64(%rsp) # consume brackets
    cmp     $0, %rax
    jne     .challenge_room_new
    movq    48(%rsp), %rax
    add     %rax, 8(%rsp)
    jmp     .challenge_room_new
.challenge_consume_char:
    incq    64(%rsp)
    jmp     .challenge_char_new
.challenge_line_consume_new_line:
    incq    64(%rsp)
    jmp     .challenge_room_new
.challenge_wrap_up:
    movq    8(%rsp), %rdi
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
