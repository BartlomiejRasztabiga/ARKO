        section .text
        global  removerng
removerng:
; prologue
        ;push    ebp
        ;mov     ebp, esp
        enter   8, 0                    ; equivalent of two instructions above

; push saved registers
        push    ebx
        push    esi
        push    edi

; function body
        mov     eax, DWORD [ebp+8]      ; s argument
        mov     DWORD [ebp-4], eax      ; source = s
        mov     DWORD [ebp-8], eax      ; dest = s
removerng_next_char:
        mov     eax, DWORD [ebp-4]      ; get address of source
        movzx   eax, BYTE [eax]         ; read char
        inc     DWORD [ebp-4]           ; source++

        cmp     eax, 0                  ; check if char is NULL
        jz      removerng_ret           ; if char is NULL, goto removerng_ret

        ; TODO: revert condition - currentChar >= a && currentChar <= b

        cmp     al, BYTE [ebp+12]       ; compare current char with A
        jl      removerng_write_char    ; if less, write that char

        cmp     al, BYTE [ebp+16]       ; compare current char with B
        jg      removerng_write_char    ; if greater, write that char

        jmp     removerng_next_char     ; read next char
removerng_write_char:
        mov     edx, DWORD [ebp-8]      ; edx = dest
        movzx   edx, BYTE al            ; store current char to dest
        inc     DWORD [ebp-8]           ; dest++

        jmp     removerng_next_char     ; read next char
removerng_ret:
        mov     eax, DWORD [ebp-8]      ; eax = dest
        mov     BYTE [eax], 0           ; store NULL at dest

; pop saved registers
        pop     edi
        pop     esi
        pop     ebx

; epilogue
        ;mov     esp, ebp
        ;pop     ebp
        leave                           ; equivalent of two instructions above
        ret

strlen:
; REFACTOR TO USE SCASB

        push    ecx                     ; push ecx
        xor     ecx, ecx                ; ecx = 0
strlen_next:
        cmp     [edi], byte 0           ; is char a NULL
        jz      strlen_ret              ; goto return

        inc     ecx                     ; ecx++
        inc     edi                     ; next char
        jmp     strlen_next             ; goto loop
strlen_ret:
        mov     eax, ecx                ; return length in eax

        pop     ecx                     ; pop ecx
        ret                             ; return
