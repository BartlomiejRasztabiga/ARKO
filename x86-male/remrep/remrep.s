        section .bss
visited: resb    32


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
;       char visitedPointer - ebp-12
;       char isVisited      - ebp-16
;       char currentChar    - ebp-17
;       char visitedChar    - ebp-18

; prologue
        push    ebp
        mov     ebp, esp
        sub     esp, 18

; push saved registers

; function body
        mov     eax, DWORD [ebp+8]      ; s argument
        mov     DWORD [ebp-4], eax      ; source = s
        mov     DWORD [ebp-8], eax      ; dest = s
remrep_next_char:
        mov     eax, DWORD [ebp-4]      ; get address of source to eax
        movzx   eax, BYTE [eax]         ; read char to eax
        mov     BYTE [ebp-17], al       ; char currentChar = *source;

        cmp     BYTE [ebp-17], 0        ; check if currentChar is NULL
        je      remrep_ret              ; if char is NULL, goto removerng_ret

        mov     DWORD [ebp-12], visited ; *visitedPointer = visited
        mov     DWORD [ebp-16], 0       ; isVisited = false
remrep_is_visited:
        mov     eax, DWORD [ebp-12]     ; eax = visitedPointer
        movzx   eax, BYTE [eax]         ; eax = *visitedPointer
        mov     BYTE [ebp-18], al       ; visitedChar = *visitedPointer

        cmp     BYTE [ebp-18], 0        ; compare visitedChar with NULL
        je      remrep_after_is_visited ; if visitedChar is NULL, goto remrep_after_is_visited

        movzx   eax, BYTE [ebp-18]      ; eax = visitedChar
        cmp     al, BYTE [ebp-17]       ; compare visitedChar with currentChar
        jne     remrep_is_visited_next_char; if not equal, get next char from visited
        mov     DWORD  [ebp-16], 1      ; isVisited = true
        jmp     remrep_after_is_visited
remrep_is_visited_next_char:
        add     DWORD [ebp-12], 1       ; visitedPointer++
        jmp     remrep_is_visited ; exit isVisited loop
remrep_after_is_visited:
        cmp     DWORD [ebp-16], 0       ; compare isVisited with false
        jne     remrep_get_next_char    ; if isVisited is true, goto remrep_get_next_char

        mov     eax, DWORD [ebp-8]      ; eax = dest
        movzx   edx, BYTE [ebp-17]      ; edx = currentChar
        mov     BYTE [eax], dl          ; *dest = currentChar

        add     DWORD [ebp-8], 1        ; dest++

        ; add char to visited
        mov     eax, DWORD [ebp-12]     ; eax = visitedPointer
        mov     BYTE [eax], dl          ; *visitedPointer = currentChar
remrep_get_next_char:
        add     DWORD [ebp-4], 1        ; source++
        jmp     remrep_next_char        ; go back to loop
remrep_ret:
        mov     eax, DWORD [ebp-8]      ; eax = dest
        mov     BYTE [eax], 0           ; store NULL at dest, TODO: change to xor

        mov     eax, DWORD [ebp+8]      ; return s (in eax)

; pop saved registers

; epilogue
        leave                           ; restore esp and ebp
        ret