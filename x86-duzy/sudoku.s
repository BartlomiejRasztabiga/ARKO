        section .data
N:      equ     9

        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char arr[N][N]
; variables: none
; returns: none
sudoku:




; ============================================================================
; isSafe
; description:
;   checks whether it will be legal to assign num to the given row, col
; arguments:
;   - char arr[N][N]    ebp+8
;   - int row           ebp+12
;   - int col           ebp+16
;   - char num          ebp+20
; variables:
;   - int x             ebp-4
;   - int startRow      ebp-8
;   - int startCol      ebp-12
;   - int i             ebp-16
;   - int j             ebp-20
; registers:
;   -
; returns:
;   - eax: 1 if legal, 0 if otherwise
isSafe:
        push    ebp
        mov     ebp, esp
        sub     esp, 36

        mov     eax, DWORD [ebp+20]
        mov     BYTE [ebp-36], al           ; ebp-36 = char num
        mov     DWORD [ebp-4], 0            ; int x = 0
.isSafe_row_loop:
        mov     edx, DWORD [ebp+12]         ; edx = int row
        lea     edx, [edx+edx*8]            ; edx = 9 * row
        mov     eax, DWORD [ebp+8]          ; eax = pointer to grid
        add     edx, eax                    ; edx = pointer to grid's row
        mov     eax, DWORD [ebp-4]          ; eax = x
        add     eax, edx                    ; eax = pointer to grid's tile at [row][x]
        movzx   eax, BYTE [eax]             ; eax = char from grid's tile at [row][x]
        cmp     BYTE [ebp-36], al           ; test if grid[row][x] == num
        jne     .isSafe_row_loop_increment  ; if not equal, get next col
        mov     eax, 0
        jmp     .isSafe_return              ; if equal, num illegal, return 0
.isSafe_row_loop_increment:
        add     DWORD [ebp-4], 1            ; x++
.isSafe_row_loop_condition:
        cmp     DWORD [ebp-4], 8            ; if x <= 8
        jle     .isSafe_row_loop            ; jmp to loop if condition met

        mov     DWORD [ebp-4], 0            ; int x = 0
.isSafe_col_loop:
        mov     edx, DWORD [ebp-4]          ; edx = x
        lea     edx, [edx, edx*8]           ; edx = 9 * x
        mov     eax, DWORD [ebp+8]          ; eax = pointer to grid
        add     edx, eax                    ; edx = pointer to grid's row
        mov     eax, DWORD [ebp+16]         ; eax = int col;
        add     eax, edx                    ; eax = pointer to grid's tile at [x][col]
        movzx   eax, BYTE [eax]             ; eax = char from grid' tile at [x][col]
        cmp     BYTE [ebp-36], al           ; test if grid[x][col] == num
        jne     .isSafe_col_loop_increment  ; if not equal, get next row
        mov     eax, 0
        jmp     .isSafe_return              ; if equal, num illegal, return 0
.isSafe_col_loop_increment:
        add     DWORD [ebp-4], 1
.isSafe_col_loop_condition:
        cmp     DWORD [ebp-4], 8
        jle     .isSafe_col_loop

; TODO: Possible optimisations
; int startRow = row // 3
        mov     ecx, 3
        mov     eax, DWORD [ebp+12]
        div     ecx                         ; eax = eax // ecx
        xor     edx, edx                    ; remainder = 0
        mov     DWORD [ebp-8], eax          ; startRow = quotient

; int startCol = col // 3
        mov     ecx, 3
        mov     eax, DWORD [ebp+16]
        div     ecx                         ; eax = eax // ecx
        xor     edx, edx                    ; remainder = 0
        mov     DWORD [ebp-12], eax         ; startRow = quotient

        mov     DWORD [ebp-16], 0           ; i = 0
        jmp     .isSafe_3_3matrix_row_loop_condition

.isSafe_3_3matrix_col_loop_init:
        mov     DWORD [ebp-20], 0           ; j = 0
        jmp     .isSafe_3_3matrix_col_loop_condition
.isSafe_3_3matrix_col_loop:
        ; TODO: finished here
        mov     edx, DWORD PTR [ebp-12]
        mov     eax, DWORD PTR [ebp-20]
        add     edx, eax
        mov     eax, edx
        sal     eax, 3
        add     edx, eax
        mov     eax, DWORD PTR [ebp+8]
        add     edx, eax
        mov     ecx, DWORD PTR [ebp-16]
        mov     eax, DWORD PTR [ebp-24]
        add     eax, ecx
        movzx   eax, BYTE PTR [edx+eax]
        cmp     BYTE PTR [ebp-36], al
        jne     .L11

        mov     eax, 0
        jmp     .L4


.isSafe_3_3matrix_row_loop_condition:

.isSafe_3_3matrix_col_loop_condition:

.isSafe_return:
        leave
        ret