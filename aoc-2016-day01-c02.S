# https://adventofcode.com/2016/day/1
# (part 2)
#
#Then, you notice the instructions continue on the back of the Recruiting Document. Easter Bunny HQ is actually at the first location you visit twice.
#
#For example, if your instructions are R8, R4, R4, R8, the first location you visit twice is 4 blocks away, due East.

# gcc -O0 -no-pie -Wall -nostdlib

.equ EC_SUCCESS, 0
.equ EC_NUMBER_READ, EC_SUCCESS + 1
.equ EC_CHALLENGE_ARGS, EC_NUMBER_READ + 1
.equ EC_CHALLENGE_DIRECTION, EC_CHALLENGE_ARGS + 1
.equ EC_CHALLENGE_ADVANCE_DIRECTION, EC_CHALLENGE_DIRECTION + 1
.equ EC_CHALLENGE_ADVANCE_OUT_OF_BOUNDS, EC_CHALLENGE_ADVANCE_DIRECTION + 1
.equ EC_CHALLENGE_LOCATION_NOT_FOUND, EC_CHALLENGE_ADVANCE_OUT_OF_BOUNDS + 1

.equ SYS_WRITE, 4
.equ SYS_STDOUT, 1

.equ CHAR_0, '0'
.equ CHAR_9, '9'
.equ CHAR_L, 'L'
.equ CHAR_R, 'R'
.equ CHAR_EOF, 0
.equ CHAR_MINUS, '-'
.equ CHAR_NEWLINE, '\n'
.equ CHAR_COMMA, ','
.equ CHAR_SPACE, ' '

.equ CHALLENGE_MAP_POS_CENTER, 256 # x and y
.equ CHALLENGE_MAP_SIDE_SIZE, (CHALLENGE_MAP_POS_CENTER * 2) + 1
.equ CHALLENGE_MAP_POS_MIN, 0
.equ CHALLENGE_MAP_POS_MAX, CHALLENGE_MAP_SIDE_SIZE - 1
.equ CHALLENGE_MAP_SIZE, CHALLENGE_MAP_SIDE_SIZE * CHALLENGE_MAP_SIDE_SIZE

.bss
.lcomm num, 18 # buffer to hold number to print, 'write' syscall refuse a data stack pointer
.lcomm map, CHALLENGE_MAP_SIZE

.text

exit_ec:
    mov     %rdi, %rbx
    movq    $1, %rax
    int     $0x80

string_len:
    mov     $0, %rax
.string_len_loop:
    cmpb    $CHAR_EOF, (%rdi)
    je      .string_len_end
    incq    %rax
    incq    %rdi
    jmp     .string_len_loop
.string_len_end:
    ret

stdout:
    push    %rdi
    call    string_len
    pop     %rdi
    mov     %rax, %rdx # length to write
    mov     $SYS_WRITE, %rax
    mov     $SYS_STDOUT, %rbx
    mov     %rdi, %rcx
    int     $0x80
    ret

number_absolute_u32:
    movl    %edi, %eax
    cmpl    $0x00, %eax
    jge     .number_absolute_u32_end
    neg     %eax
.number_absolute_u32_end:
    ret

number_print_s64:
    movq    $num, %r9 # buffer pointer
    movb    $CHAR_0, (%r9)
    cmp     $0, %rdi
    jge     .number_print_s64_unsigned
    movb    $CHAR_MINUS, (%r9) # set digit
    neg     %rdi
.number_print_s64_unsigned:
    inc     %r9
    movq    %rdi, %r10 # value to divide
    movq    $1000000000000000, %r11 # divisor
    movq    $16, %r12 # loop 9 times
.number_print_s64_loop:
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
    jne     .number_print_s64_loop
    movb    $CHAR_NEWLINE, (%r9)
    # print buffer
    movq    $num, %rdi
    call    stdout
    ret

number_read_u:
    mov     $0, %rax # accumulator
    mov     $0, %r10 # number of digit read
    mov     $10, %r12 # digit multiplicator
.number_read_u_loop:
    movzb   (%rdi), %rbx
    cmpb    $CHAR_0, %bl
    jl      .number_read_u_wrap_up
    cmpb    $CHAR_9, %bl
    jg      .number_read_u_wrap_up
    mul     %r12 # shift previous number by one digit: x10
    sub     $CHAR_0, %bl
    add     %rbx, %rax
    inc     %r10
    incq    %rdi
    jmp     .number_read_u_loop
.number_read_u_wrap_up:
    cmp     $0, %r10
    je      .number_read_u_error
    mov     %r10, %rbx # also return the number of digit read
    ret
.number_read_u_error:
    mov     $EC_NUMBER_READ, %rdi
    call    exit_ec

mark_current_position:
    movzx   16(%rdi), %rax
    mov     $CHALLENGE_MAP_SIDE_SIZE, %rbx
    mul     %rbx
    addl    12(%rdi), %eax
    mov     $map, %rbx
    add     %rax, %rbx
    movzb   (%rbx), %rax
    movb    $1, (%rbx) # mark the position even if already marked (%rax)
    ret

advance:
    push    %rdi
    mov     (%rdi), %rdi
    call    number_read_u
    pop     %rdi
    add     %rbx, (%rdi) # consume characters
    mov     %rax, %r8
    xor     %rax, %rax
.advance_loop:
    cmp     $0, %r8
    je      .advance_wrap_up
    cmp     $1, %rax
    je      .advance_wrap_up
    movl    8(%rdi), %ecx
    cmp     $0, %ecx
    je      .advance_n
    cmp     $1, %ecx
    je      .advance_e
    cmp     $2, %ecx
    je     .advance_s
    cmp     $3, %ecx
    je     .advance_w
    jmp     .advance_error_direction
.advance_n:
    cmpl    $CHALLENGE_MAP_POS_MIN, 16(%rdi)
    je      .advance_error_out_of_bounds
    decl    16(%rdi)
    call    mark_current_position
    jmp     .advance_loop_next
.advance_e:
    cmpl    $CHALLENGE_MAP_POS_MAX, 12(%rdi)
    je      .advance_error_out_of_bounds
    incl    12(%rdi)
    call    mark_current_position
    jmp     .advance_loop_next
.advance_s:
    cmpl    $CHALLENGE_MAP_POS_MAX, 16(%rdi)
    je      .advance_error_out_of_bounds
    incl    16(%rdi)
    call    mark_current_position
    jmp     .advance_loop_next
.advance_w:
    cmpl    $CHALLENGE_MAP_POS_MIN, 12(%rdi)
    je      .advance_error_out_of_bounds
    decl    12(%rdi)
    call    mark_current_position
    jmp     .advance_loop_next
.advance_loop_next:
    dec     %r8
    jmp     .advance_loop
.advance_wrap_up:
    ret
.advance_error_out_of_bounds:
    mov     $EC_CHALLENGE_ADVANCE_OUT_OF_BOUNDS, %rdi
    call    exit_ec
.advance_error_direction:
    mov     $EC_CHALLENGE_ADVANCE_DIRECTION, %rdi
    call    exit_ec

direction_update:
    mov     (%rdi), %rax
    movzb   (%rax), %rcx
    movzb   (%rdi), %rbx
.direction_update_test_r:
    cmp     $CHAR_R, %rcx
    jne     .direction_update_test_l
    mov     $1, %eax
    jmp     .direction_update_value
.direction_update_test_l:
    cmp     $CHAR_L, %rcx
    jne     .direction_update_error
    mov     $-1, %eax
.direction_update_value:
    add     8(%rdi), %eax
    cmp     $4, %eax
    je      .direction_update_force_0
    cmp     $-1, %eax
    je      .direction_update_force_3
    jmp     .direction_update_update_pointed
.direction_update_force_0:
    mov     $0, %eax
    jmp     .direction_update_update_pointed
.direction_update_force_3:
    mov     $3, %eax
    jmp     .direction_update_update_pointed
.direction_update_update_pointed:
    movl    %eax, 8(%rdi)
    incq    (%rdi)
    ret
.direction_update_error:
    mov     $EC_CHALLENGE_DIRECTION, %rdi
    call    exit_ec

compute_distance:
    # x
    xor     %rbx, %rbx # hack to ensure that high bits (>32) are set to 0 and no movzl?
    movl    12(%rdi), %ebx
    subl    $CHALLENGE_MAP_POS_CENTER, %ebx
    push    %rdi
    mov     %rbx, %rdi
    call    number_absolute_u32
    pop     %rdi
    # y
    push    %rax
    xor     %rbx, %rbx
    movl    16(%rdi), %ebx
    subl    $CHALLENGE_MAP_POS_CENTER, %ebx
    push    %rdi
    mov     %rbx, %rdi
    call    number_absolute_u32
    pop     %rdi
    pop     %rbx
    add     %rbx, %rax
    ret

challenge:
    # rdi: buffer to parse
    push    %rbp
    mov     %rsp, %rbp
    sub     $20, %rsp
    mov     %rdi, -20(%rbp) # buffer pointer
    movl    $0, -12(%rbp) # direction: 0 = N, 1 = E, 2 = S, 3 = W
    movl    $CHALLENGE_MAP_POS_CENTER, -8(%rbp) # current x
    movl    $CHALLENGE_MAP_POS_CENTER, -4(%rbp) # current y
    lea     -20(%rbp), %rdi
    call    mark_current_position
.challenge_loop:
    lea     -20(%rbp), %rdi
    call    direction_update
    lea     -20(%rbp), %rdi
    call    advance
    cmp     $1, %rax
    je      .challenge_location_found
    # check eof
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $0x00, %rdi
    je      .challenge_location_not_found
    # check comma
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $CHAR_COMMA, %rdi
    jne     .challenge_loop
    incq    -20(%rbp) # consume comma
    # check eof
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $0x00, %rdi
    je      .challenge_location_not_found
    # check space
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $CHAR_SPACE, %rdi
    jne     .challenge_loop
    incq    -20(%rbp) # consume space
    # check eof
    mov     -20(%rbp), %rax
    movzb   (%rax), %rdi
    cmp     $0x00, %rdi
    je      .challenge_location_not_found
    jmp     .challenge_loop
.challenge_location_found:
    lea     -20(%rbp), %rdi
    call    compute_distance
    mov     %rax, %rdi
    call    number_print_s64
    mov     %rbp, %rsp
    pop     %rbp
    ret
.challenge_location_not_found:
    mov     $EC_CHALLENGE_LOCATION_NOT_FOUND, %rdi
    call    exit_ec

.global _start
_start:
    cmpl    $2, (%rsp)
    jne     .start_error
    mov     16(%rsp), %rdi
    call    challenge
    mov     $0, %rdi
    call    exit_ec
.start_error:
    mov     $EC_CHALLENGE_ARGS, %rdi
    call    exit_ec
