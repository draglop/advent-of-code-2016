# https://adventofcode.com/2016/day/4
# (part 2)
#
# With all the decoy data out of the way, it's time to decrypt this list and get moving.
#
# The room names are encrypted by a state-of-the-art shift cipher, which is nearly unbreakable without the right software. However, the information kiosk designers at Easter Bunny HQ were not expecting to deal with a master cryptographer like yourself.
#
# To decrypt a room name, rotate each letter forward through the alphabet a number of times equal to the room's sector ID. A becomes B, B becomes C, Z becomes A, and so on. Dashes become spaces.
#
# For example, the real name for qzmt-zixmtkozy-ivhz-343 is very encrypted name.
#
# What is the sector ID of the room where North Pole objects are stored?

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_BUFFER_LENGTH, EC_SUCCESS + 1
.equ EC_NUMBER_READ, EC_BUFFER_LENGTH + 1
.equ EC_CHALLENGE_ARGS, EC_NUMBER_READ + 1
.equ EC_CHALLENGE_CHEKCSUM_VERIFY, EC_CHALLENGE_ARGS + 1
.equ EC_CHALLENGE_NOT_FOUND, EC_CHALLENGE_ARGS + 1

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
.equ BUFFER_LENGTH, 32
.equ ALPHABET_LENGTH, 26

.data
STRING_TO_MATCH: .asciz "northpole object storage "

.bss
.lcomm buffer, BUFFER_LENGTH

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

u_string_cmp:
    push    %rdi
    call    u_string_len
    mov     %rax, %rbx
    mov     %rsi, %rdi
    call    u_string_len
    pop     %rdi
    cmp     %rax, %rbx
    jne     .u_string_cmp_ko
    xor     %rcx, %rcx
.u_string_cmp_loop:
    cmp     %rcx, %rbx
    je      .u_string_cmp_ok
    movzb   (%rdi, %rcx), %rax
    movzb   (%rsi, %rcx), %rdx
    cmp     %rax, %rdx
    jne     .u_string_cmp_ko
    inc     %rcx
    jmp .u_string_cmp_loop
.u_string_cmp_ok:
    xor     %rax, %rax
    ret
.u_string_cmp_ko:
    mov     $1, %rax
    ret

u_print_str_ln_n:
    cmp     $BUFFER_LENGTH-2, %rsi
    jl      .u_print_str_ln_n_error
    xor     %rax, %rax
    mov     $buffer, %rbx
.u_print_str_ln_n_copy:
    cmp     %rsi, %rax
    je      .u_print_str_ln_n_wrap_up
    movzb   (%rdi, %rax), %rcx
    movb    %cl, (%rbx, %rax)
    inc     %rax
    jmp     .u_print_str_ln_n_copy
.u_print_str_ln_n_wrap_up:
    mov     $buffer, %rdi
    movb    $CHAR_NEWLINE, (%rdi, %rax)
    movb    $CHAR_EOF, 1(%rdi, %rax)
    call    u_stdout
    ret
.u_print_str_ln_n_error:
    mov     $EC_BUFFER_LENGTH, %rdi
    call    u_exit_ec

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

c_convert_string:
    mov     %rdx, %rax
    xor     %rdx, %rdx
    mov     $ALPHABET_LENGTH, %rcx
    div     %rcx # rdx will hold the modulo
    xor     %rax, %rax # current char index
.c_convert_string_char_modify:
    movzb   (%rdi, %rax), %rbx
    cmp     $CHAR_DASH, %rbx
    je      .c_convert_string_char_modify_dash
    add     %rdx, %rbx
    cmp     $CHAR_Z, %rbx
    jle     .c_convert_string_char_modify_write
    sub     $ALPHABET_LENGTH, %rbx
.c_convert_string_char_modify_write:
    mov     $buffer, %rcx
    movb    %bl, (%rcx, %rax)
.c_convert_string_char_modify_next:
    inc     %rax
    cmp     %rax, %rsi
    jne     .c_convert_string_char_modify
    jmp     .c_convert_string_char_wrap_up
.c_convert_string_char_modify_dash:
    mov     $CHAR_SPACE, %rbx
    jmp     .c_convert_string_char_modify_write
.c_convert_string_char_wrap_up:
    movb    $CHAR_EOF, (%rcx, %rax)
    mov     $1, %rax
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $72, %rsp
    movq    %rdi, (%rsp) # buffer to read pointer
    movl    $0, 64(%rsp) # current offset within current line
.challenge_room_new:
    movq    64(%rsp), %rax
    addq    %rax, (%rsp) # point to next line
    movq    $0, 64(%rsp)
    movq    $0, 8(%rsp) # offset of room name end within current line
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
    je      .challenge_not_found
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
    movq    64(%rsp), %rax
    movq    %rax, 8(%rsp)
    # get the input checkssum
    movq    (%rsp), %rdi
    add     64(%rsp), %rdi
    call    u_number_read_u
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
    movq    (%rsp), %rdi
    movq    8(%rsp), %rsi
    movq    48(%rsp), %rdx
    call    c_convert_string
    mov     $STRING_TO_MATCH, %rdi
    mov     $buffer, %rsi
    call    u_string_cmp
    cmp     $0, %rax
    jne     .challenge_room_new
    jmp     .challenge_wrap_up
.challenge_consume_char:
    incq    64(%rsp)
    jmp     .challenge_char_new
.challenge_line_consume_new_line:
    incq    64(%rsp)
    jmp     .challenge_room_new
.challenge_wrap_up:
    movq    (%rsp), %rdi
    movq    64(%rsp), %rsi
    call    u_print_str_ln_n
    mov     %rbp, %rsp
    pop     %rbp
    ret
.challenge_not_found:
    mov     $EC_CHALLENGE_NOT_FOUND, %rdi
    call    u_exit_ec

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
