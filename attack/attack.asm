SYS_READ equ 0
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_EXIT equ 60

DFA_LEN equ 5

BUFFER_SIZE equ 8192

; These flags will be set while parsing to indicate what criteria have
; already been fullfiled.
FLAG_PATTERN_FOUND equ 1
FLAG_INRANGE_FOUND equ 2
FLAG_SUM_FOUND equ 4
FLAG_ALL_FOUND equ 7            ; All flags or-ed togeather

global      _start

section     .rodata
    dfa     dd  6, 8, 0, 2, 0

section     .bss
    buffer  resb BUFFER_SIZE

; These registers are pinned down and store given values:
; * r12 - Opened FD,
; * r13 - Current pattern match state,
; * r14 - Flags described above conatining info about fullfiled criteria,
; * r15 - Sum of all input numbers mod 2^32 (stored as 32-bit number).
section     .text
_start:
    ; Get the argc from the stack. If argc differs from 2, instantly exit.
    pop     rax
    cmp     rax, 2
    jne     emergency_exit

    ; pop arg0, which is the executable
    pop     rax

    ; Open syscall:
    ; * rdi - filename
    ; * rsi - flags
    ; * rdx - mode
    ; * rax - syscall number
    pop     rdi            ; Place the filename (arg1) into the rdi reg.
    mov     rsi, 0         ; O_RDONLY
    mov     rdx, 0         ; Not important, used when file is created
    mov     rax, SYS_OPEN
    syscall

    ; Non-positive number being returned means open failed and we exit.
    cmp     rax, 0
    jle     emergency_exit

    ; r12 will stores file descriptor for the whole program lifetime.
    mov     r12, rax
    jmp     process_file_cond

    ; This is the outer loop that break when full file is processed.
process_file_body:

    ; This is the inner loop that process one loaded buffer.
    ; It assumes the number to process is loaded into eax reg.
process_number_body:
    ; Move loaded var into eax and swap its bytes because of big endianesse.
    mov     eax, [rbx]
    bswap   eax

    ; If we find magic number we just exit safetly with 1 as error code.
    cmp     eax, 68020
    je      exit_invalid_while_loading

    ; Add the currently computed value to the sum stored is r15.
    add     r15d, eax

    ; Check if the value is in range [68021 - (2^31 - 1)]. Move the value to
    ; temp reg. and then substract 68021 so that we do only 1 comparition
    ; instead of two. Unsigned compare is used (jump if above).
    mov     ecx, eax
    sub     ecx, 68021
    cmp     ecx, 2147415626
    ja      not_in_range
    or      r14, FLAG_INRANGE_FOUND

not_in_range:
    ; If FLAG_PATTERN_FOUND is set, pattern was found, so match is skipped.
    test    r14, FLAG_PATTERN_FOUND
    jne     endof_pattern_match

    ; Advance dfa state by getting the curr state and comparing it with
    ; the next state from the dfa array. Store the next state in the ecx,
    ; then compare it with eax. If they are the same advace the state.
    mov     ecx, [dfa + r13d * 4]
    cmp     eax, ecx
    je      pattern_match

    ; In the case of missmatch our state is 0, or 1 (value is first in the dfa).
    ; ecx is used to avoid branching and conditionally move 1 into r13.
pattern_missmatch:
    mov     ecx, 1
    mov     r13d, 0
    cmp     eax, [dfa]           ; Check if the first is still ok.
    cmove   r13d, ecx
    jmp     endof_pattern_match

pattern_match:
    inc     r13d
    cmp     r13d, DFA_LEN        ; If pattern is found, set the flag in the r14.
    jne     endof_pattern_match
    mov     r13d, 0
    or      r14, FLAG_PATTERN_FOUND

endof_pattern_match:

process_number_cond:
    ; If end is not reached, process the next number.
    add     rbx, 4
    cmp     rbx, rdx
    jne     process_number_body

    ; This loads the buffer, and if it is valid jumps to process_buffer loop
process_file_cond:

    ; When loading buffer use rbx to store how many bytes loaded. Due to docs,
    ; it is possible that less bytes than asked is loaded, but some are still
    ; available, so we read until we get 0. In practice, this never happens.
    mov     rbx, 0

load_buffer_body:
    ; Read syscall:
    ; * rdi - file descriptor
    ; * rsi - pointer to the buffer
    ; * rdx - max bytes to load
    ; * rax - syscall number
    mov     rdi, r12
    lea     rsi, [buffer+rbx]
    mov     rdx, BUFFER_SIZE
    sub     rdx, rbx
    mov     rax, SYS_READ
    syscall

    ; If no bytes were read, we break the loop. If number of bytes is less than
    ; we asked we read again until we hit 0. If negative number is returned we
    ; exit the program with an error.
    cmp     rax, 0
    je      endof_load_buffer
    jl      emergency_exit

    add     rbx, rax
    cmp     rbx, BUFFER_SIZE
    jne     load_buffer_body

    ; Move the number of loaded bytes into rx, as rbx will store something else.
endof_load_buffer:
    mov     rax, rbx
    cmp     rax, 0
    je      exit

    ; Test if the number of loaded bytes is divisable by 4 (should be).
    ; Otherwise the file has invalid length, and we have to return an error.
    ; This trick allows us to avoid expensive division (check 2 lowest bits)
    test    al, 3
    jne     exit_invalid_while_loading

    ; rbx holds pointer to the beginning of the buffer, rdx to one-past-end
    mov     rbx, buffer
    sub     rbx, 4
    mov     rdx, buffer
    add     rdx, rax            ; rax still holds the size of the buffer.
    jmp     process_number_cond

exit:
    ; If the sum stored in r15 is equal to the magic number we set up FLAG_SUM_FOUND.
    ; To avoid branching rcx is used to store the value or'ed with the flag and
    ; then value is conditionally moved back to the r14 (flag register).
    mov     rcx, r14
    or      rcx, FLAG_SUM_FOUND
    cmp     r15, 68020
    cmove   r14, rcx

    ; Close the file syscall:
    ; * rdi - file descriptor (we store it in r12 for the program lifetime).
    ; * rax - syscall number
    mov     rdi, r12
    mov     rax, SYS_CLOSE
    syscall

    ; Check if all interesting bits were set. If so, we must return 0. eax
    ; register will store the program return value (for now). We set the low
    ; byte if the flags don't match and the zero-extend it to whole reg.
    cmp     r14, FLAG_ALL_FOUND
    setne   al
    movzx   eax, al

    ; Ends the program with the error code being the value in eax.
prog_exit:
    ; Exit syscall:
    ; * rdi - the program exit code, precomputed in rax reg.
    ; * rax - syscall number
    mov     rdi, rax
    mov     rax, SYS_EXIT
    syscall

    ; This is called when we encouter error while loading the file. r14 is
    ; zeroed to make sure that exit code is 1, then goes to the exit branch.
exit_invalid_while_loading:
    mov     r14, 0
    jmp     exit

    ; This is called if we fail before openning the file so fd is not closed.
emergency_exit:
    mov     rax, 1
    jmp     prog_exit
