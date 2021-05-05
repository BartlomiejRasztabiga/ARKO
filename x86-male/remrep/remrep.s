        section .bss
buffer: resb    32


        section .text
        global  remrep

remrep:
; description:
;       deletes repeated characters from given string
; arguments:
;	    char *s - pointer to an input string
; returns:
;	    char *  - address of input string
; local variables:
;       char *source        - ebp-4
;       char *dest          - ebp-8
;       char currentChar    - ebp-9

; prologue
        push    ebp
        mov     ebp, esp
        sub     esp, 12

; push saved registers

; function body
        mov     eax, DWORD [ebp+8]      ; s argument
        mov     DWORD [ebp-4], eax      ; source = s
        mov     DWORD [ebp-8], eax      ; dest = s
remrep_next_char:
        mov     eax, DWORD [ebp-4]      ; get address of source to eax
        movzx   eax, BYTE [eax]         ; read char to eax
        mov     BYTE [ebp-9], al        ; char currentChar = *source;

        add     DWORD [ebp-4], 1        ; source++ (next char)

        cmp     BYTE [ebp-9], 0         ; check if currentChar is NULL
        je      remrep_ret              ; if char is NULL, goto removerng_ret

        movzx   eax, BYTE [ebp-9]       ; eax = currentChar
        cmp     al, BYTE [ebp-10]       ; compare current char with A
        jl      remrep_write_char       ; if currentChar < A, write that char

        movzx   eax, BYTE [ebp-9]       ; eax = currentChar
        cmp     al, BYTE [ebp-11]       ; compare current char with B
        jle     remrep_next_char        ; if currentChar <= B, go back to loop
                                        ; if currentChar > B, write that char
remrep_write_char:
        mov     eax, DWORD [ebp-8]      ; eax = dest
        movzx   edx, BYTE [ebp-9]       ; edx = currentChar
        mov     BYTE [eax], dl          ; *dest = currentChar;

        add     DWORD [ebp-8], 1        ; dest++

        jmp     remrep_next_char        ; read next char
remrep_ret:
        mov     eax, DWORD [ebp-8]      ; eax = dest
        mov     BYTE [eax], 0           ; store NULL at dest, TODO: change to xor

        mov     eax, DWORD [ebp+8]      ; return s (in eax)

; pop saved registers

; epilogue
        leave                           ; restore esp and ebp
        ret