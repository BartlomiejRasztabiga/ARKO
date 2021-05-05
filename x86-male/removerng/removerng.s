        section .text
        global  removerng


removerng:
; arguments:
;	    char *s - pointer to an input string
;       char  a - start of char range
;       char  b - end of char range
; returns:
;	    char *  - address of input string
; local variables:
;       char *source        - ebp-4
;       char *dest          - ebp-8
;       char currentChar    - ebp-9

; prologue
        push    ebp
        mov     ebp, esp
        sub     esp, 9

; push saved registers
        ;push    ebx
        ;push    esi
        ;push    edi

; function body
        mov     eax, DWORD [ebp+8]      ; s argument
        mov     DWORD [ebp-4], eax      ; source = s
        mov     DWORD [ebp-8], eax      ; dest = s
removerng_next_char:
        mov     eax, DWORD [ebp-4]      ; get address of source to eax
        movzx   eax, BYTE [eax]         ; read char to eax
        mov     BYTE [ebp-9], al        ; char currentChar = *source;

        add     DWORD [ebp-4], 1        ; source++ (next char)

        cmp     BYTE [ebp-9], 0         ; check if currentChar is NULL
        je      removerng_ret           ; if char is NULL, goto removerng_ret

        movzx   eax, BYTE [ebp-9]       ; eax = currentChar
        cmp     eax, [ebp+12]           ; compare current char with A
        jl      removerng_write_char    ; if currentChar < A, write that char

        movzx   eax, BYTE [ebp-9]       ; eax = currentChar
        cmp     eax, [ebp+16]           ; compare current char with B
        jle     removerng_next_char     ; if currentChar <= B, go back to loop
                                        ; if currentChar > B, write that char
removerng_write_char:
        mov     eax, DWORD [ebp-8]      ; eax = dest
        mov     [eax], edx              ; *dest = currentChar;

        add     DWORD [ebp-8], 1        ; dest++

        jmp     removerng_next_char     ; read next char
removerng_ret:
        mov     eax, DWORD [ebp-8]      ; eax = dest
        mov     BYTE [eax], 0           ; store NULL at dest, TODO: change to xor

        mov     eax, DWORD [ebp+8]      ; return s (in eax)

; pop saved registers
        ;pop     edi
        ;pop     esi
        ;pop     ebx

; epilogue
        leave                           ; restore esp and ebp
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
