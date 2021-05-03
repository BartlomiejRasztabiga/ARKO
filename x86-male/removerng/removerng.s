        section .data
hello:          db 'Hello world!',10    ; LF na końcu
hello_len:      equ $-hello             ; stała - długość łańcucha

        section .text
        global  removerng
removerng:
; prolog
        push    ebp
        mov     ebp, esp

; push saved registers
        push    ebx

; function body
        mov     eax, 4                  ; numer funkcji sys_write
        mov     ebx, 1                  ; uchwyt pliku stdout
        mov     ecx, hello              ; adres łańcucha
        mov     edx, hello_len          ; długość łańcucha
        int     0x80                    ; syscall

; pop saved registers
        pop     ebx

; epilog
        mov     esp, ebp
        pop     ebp
        ret
