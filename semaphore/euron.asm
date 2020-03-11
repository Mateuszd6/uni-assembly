; States of the exchange used to spinlock syncing threads.
EXCHG_NONE equ 0
EXCHG_READY equ 1
EXCHG_TAKING equ 2
EXCHG_FINISHED equ 3

global euron

extern get_value, put_value

section .data
align 8
    waiting_for times N*N dq 0
    stack_top   times N*N dq 0

section .text
align 8
euron:
    ; These callee-saved regs. are used by the fucntion so we save them.
    push    rbx
    push    r12
    push    r13

    ; Store the current point in the stack in the frame pointer reg.
    ; We accualy dont store the base of the frame (as we already pushed)
    ; some regs onto the stack, but doing it this way will be easier for
    ; us when returning the value.
    push    rbp
    mov     rbp, rsp

    ; Store n value in the in the rbx.
    ; Store the address of the asciiz command in the r12.
    mov     rbx, rdi
    mov     r12, rsi

    ; This is the loop where we proceed every command in the input string.
    ; r12 holds the pointer to the input string, rdi (in the body) holds
    ; the current command (as a char extended into 64 bit reg).
command_loop_init:
    sub     r12, 1
    jmp     commnad_loop_cond

command_loop_body:
    ; Check special values.
    cmp     rdi, '+'
    je      comm_add
    cmp     rdi, '*'
    je      comm_mult
    cmp     rdi, '-'
    je      comm_neg
    cmp     rdi, 'n'
    je      comm_numb
    cmp     rdi, 'B'
    je      comm_branch
    cmp     rdi, 'C'
    je      comm_clean
    cmp     rdi, 'D'
    je      comm_duplicate
    cmp     rdi, 'E'
    je      comm_exchange
    cmp     rdi, 'G'
    je      comm_get
    cmp     rdi, 'P'
    je      comm_put
    cmp     rdi, 'S'
    je      comm_sync

    ; Push value 0-9 (stored in rdx) to the stack (default branch)
comm_value:
    lea     rdi, [rdi-48]       ; This substract ascii '0' from the value.
    push    rdi
    jmp     comm_exit

    ; Push the euron number (stored in rbx) to the stack.
comm_numb:
    push    rbx
    jmp     comm_exit

    ; Add two top values from the stack and push the result.
comm_add:
    pop     rdi
    pop     rsi
    add     rdi, rsi
    push    rdi
    jmp     comm_exit

    ; Multiply two top values from the stack and push the result.
comm_mult:
    pop     rdi
    pop     rsi
    imul    rdi, rsi
    push    rdi
    jmp     comm_exit

    ; Negate the top value from test stack.
comm_neg:
    neg     QWORD [rsp]
    jmp     comm_exit

    ; Move ptr stored in r12 (program) by number stored on the top if
    ; the second value is different than 0.
comm_branch:
    pop     rdi
    cmp     QWORD [rsp], 0
    je      comm_branch.skip
    add     r12, rdi
comm_branch.skip:
    jmp     comm_exit

    ; Pop the stack top.
comm_clean:
    pop     rdi
    jmp     comm_exit

    ; Duplicate the value on the top.
comm_duplicate:
    push    QWORD [rsp]
    jmp     comm_exit

    ; Swap two top value of the stack.
comm_exchange:
    pop     rdi
    pop     rsi
    push    rdi
    push    rsi
    jmp     comm_exit

    ; Call 'get_value' method.
comm_get:
    mov     rdi, rbx

    ; Saved stack ptr and align it to 16 byte boundary as ABI tells us to do.
    ; Alignment is done by masking last bits of the pointer (and ~0xF).
    ; The original value of the stack ptr is saved in callee-saved r13.
    mov     r13, rsp
    and     rsp, ~0xF
    call    get_value
    mov     rsp, r13

    ; Push the result onto the stack.
    push    rax
    jmp     comm_exit

    ; Call 'put_value' method.
comm_put:
    mov     rdi, rbx
    pop     rsi

    ; Same trick as above (with get).
    mov     r13, rsp
    and     rsp, ~0xF
    call    put_value
    mov     rsp, r13

    jmp     comm_exit

comm_sync:
    pop     rsi

    ; This takes a lot of indexing into 2-dim arrays, the result is:
    ; (r13 is used as a temp register throughout whole fucntion)
    ; me    - rbx
    ; they  - rsi
    ; rcx   - my spinlock for him
    ; rdx   - his spinlock for me
    ; r8    - my value for him
    ; r9    - his value for me

    mov     r13, rbx
    imul    r13, 8*N

    mov     rcx, waiting_for
    add     rcx, r13
    lea     rcx, [rcx+8*rsi]

    mov     r8, stack_top
    add     r8, r13
    lea     r8, [r8+8*rsi]

    mov     r13, rsi
    imul    r13, 8*N

    mov     rdx, waiting_for
    add     rdx, r13
    lea     rdx, [rdx+8*rbx]

    mov     r9, stack_top
    add     r9, r13
    lea     r9, [r9+8*rbx]

    ; Set my value for him
    mov     r10, [rsp]
    mov     [r8], r10

    ; I'm ready
    mov     QWORD [rcx], EXCHG_READY

    ; Wait until he is ready
loop1:
    mov     rax, EXCHG_READY
    mov     r13, EXCHG_TAKING
    lock    \
    cmpxchg [rdx], r13
    jne     loop1

    ; Take his value
    mov     r10, [r9]
    mov     [rsp], r10

    ; Tell him that I've finished.
    mov     QWORD [rdx], EXCHG_FINISHED

    ; Wait until he is finished
loop2:
    mov     rax, EXCHG_FINISHED
    mov     r13, EXCHG_NONE
    lock    \
    cmpxchg [rcx], r13
    jne     loop2

    jmp     comm_exit

comm_exit:

commnad_loop_cond:
    ; Move to the next char in the string.
    add     r12, 1

    ; Take value of the next char, 64-bit extend and not 0, loop.
    movsx   rdi, BYTE [r12]
    test    dil, dil
    jne     command_loop_body

cleanup:
    ; Move the result to rax reg, and bring back stack ptr value from
    ; before the loop in which we put values onto the stack.
    mov     rax, [rsp]
    mov     rsp, rbp
    pop     rbp

    ; Bring back saved callee-saved regs.
    pop     r13
    pop     r12
    pop     rbx

    ret
