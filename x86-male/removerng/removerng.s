        section .text
        global  removerng
removerng:
; prologue
        push    ebp
        mov     ebp, esp

; push saved registers
        ;push    ebx

; function body
        mov     esi, DWORD [ebp+8]      ; store current char of input at esi
        mov     esi, DWORD [ebp+8]      ; store next place to write a char
        ;call    strlen                  ; call strlen
        ;mov     edx, eax
removerng_next_char:


; pop saved registers
        ;pop     ebx

; epilogue
        mov     esp, ebp
        pop     ebp
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
