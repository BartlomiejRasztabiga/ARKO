        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   ebp+8
; returns:
;   - eax: 1 if found solution, 0 otherwise
sudoku:
        push    ebp
        mov     ebp, esp

        ; save callee-saved registers
        push    ebx
        push    esi
        push    edi

        mov     edi, [ebp+8]                    ; edi = grid
        xor     esi, esi                        ; esi = row = 0
        xor     ebx, ebx                        ; ebx = col = 0
        call    .sudoku                         ; call recursive helper

        ; restore callee-saved registers
        pop     edi
        pop     esi
        pop     ebx

        leave
        ret

; ============================================================================
; .sudoku (recursive helper for sudoku)
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   ebp+8
;   - unsigned int row  esi
;   - unsigned int col  ebx
; variables: none
; registers:
;   - edi: grid argument from ebp+8
;   - esi: row argument from  ebp+12
;   - ebx: col argument from  ebp+16
;   - ecx: num (char) local variable
; returns:
;   - eax: 1 if found solution, 0 otherwise
.sudoku:
        push    ebp
        mov     ebp, esp

        push    ebx
        push    esi
        push    edi

        mov     ecx, '1'                        ; num = '1'
.sudoku_find_next_cell:
        cmp     ebx, 9                          ; test if col == 9
        jne     .sudoku_not_finished            ; if not equal, goto .sudoku_not_finished

        inc     esi                             ; row++
        xor     ebx, ebx                        ; col = 0

        cmp     esi, 9                          ; test if row == 9

        mov     eax, 1
        je     .sudoku_return                   ; if last row, return 1
                                                ; if not equal, goto .sudoku_not_finished
.sudoku_not_finished:
        ; al = getCellValue at [row][x]
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        mov     al, BYTE [eax+ebx]              ; al = char from grid's tile at [row][x]

        cmp     al, '#'                         ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop         ; if equal, goto .sudoku_find_value_loop

        inc     ebx                             ; col++
        jmp     .sudoku_find_next_cell          ; if not equal, try next col
.sudoku_find_value_loop:
        push    ecx                             ; push num
        push    ebx                             ; push col
        push    esi                             ; push row
        push    edi                             ; push grid
        call    isSafe                          ; call isSafe(grid, row, col, num)
        add     esp, 12                         ; free stack
        pop     ecx                             ; restore ecx

        cmp     eax, 1                          ; test if isSafe returned 1 (true)
        jne     .sudoku_find_value_loop_next_num; if false, try next number
                                                ; if true, put that number into sudoku matrix

        ; setCellValue at [row][col] <- num
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        lea     eax, [eax+ebx]                  ; eax = pointer to grid's tile at [row][col]
        mov     [eax], cl                       ; grid[row][col] = cl (num)

        ; solve next column
        mov     eax, ebx                        ; eax = int col
        inc     eax                             ; eax = col + 1
        push    ecx                             ; save ecx (num)

        push    eax                             ; push (col+1)
        push    esi                             ; push row
        push    edi                             ; push grid
        call    .sudoku                         ; call .sudoku(grid, row, col+1)
        add     esp, 12                         ; free stack

        pop     ecx                             ; restore ecx (num)
        cmp     eax, 1                          ; test if sudoku returned 1 (true)

        je     .sudoku_return                   ; if true, return 1 (1 already in eax)
                                                ; if false, try next number
.sudoku_find_value_loop_next_num:
        ; setCellValue at [row][col] <- '#'
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        lea     eax, [eax+ebx]                  ; eax = pointer to grid's tile at [row][col]
        mov     [eax], BYTE '#'                 ; grid[row][col] = '#'

        inc     ecx                             ; num++, try next char
        cmp     ecx, '9'                        ; test if num <= '9'
        jle     .sudoku_find_value_loop         ; if true, goto loop
        xor     eax, eax                        ; return 0
.sudoku_return:
        pop     edi
        pop     esi
        pop     ebx

        leave
        ret

; ============================================================================
; isSafe
; description:
;   checks whether it will be legal to assign num to the given [row][col]
; arguments:
;   - char grid[N][N]   ebp+8
;   - int row           ebp+12
;   - int col           ebp+16
;   - char num          ebp+20
; registers:
;   - bh: int i <- local variable
;   - bl: char num from ebp+20
;   - ecx: int x/int startRow
;   - edi: char **grid/int startCol
; returns:
;   - eax: 1 if legal, 0 otherwise
; TODO try to pass arguments through registers
; TODO try to return by EFLAGS, not return value
isSafe:
        push    ebp
        mov     ebp, esp

        push    ebx
        push    esi
        push    edi

        mov     bl, [ebp+20]                    ; ebx (bl) = char num
        xor     ecx, ecx                        ; int x = 0
        mov     edi, [ebp+8]                    ; edi = grid
        ; TODO decrement from 8 down to 0
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        mov     eax, [ebp+12]                   ; eax = row
        lea     eax, [eax+eax*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        mov     al, BYTE [eax+ecx]              ; al = char from grid's tile at [row][x]

        cmp     al, bl                          ; test if grid[row][x] == num
        je      .isSafe_return                  ; if equal, num illegal, return 0

        inc     ecx                             ; x++
        cmp     ecx, 8                          ; if x <= 8
        jle     .isSafe_row_loop                ; goto loop if condition met

        xor     ecx, ecx                        ; int x = 0
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        lea     eax, [ecx+ecx*8]                ; eax = 9 * x
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        mov     esi, [ebp+16]                   ; esi = col
        mov     al, BYTE [eax+esi]              ; al = char from grid's tile at [x][col]

        cmp     al, bl                          ; test if grid[x][col] == num
        je      .isSafe_return                  ; if equal, num illegal, return 0

        inc     ecx                             ; x++
        cmp     ecx, 8                          ; if x <= 8
        jle     .isSafe_col_loop                ; goto loop if condition met

; int startRow = row - row % 3
        mov     esi, 3
        mov     eax, [ebp+12]                   ; eax = int row
        xor     edx, edx                        ; edx = 0
        div     esi                             ; edx = row % 3
        mov     esi, [ebp+12]                   ; esi = int row
        sub     esi, edx                        ; esi = esi - edx
        mov     ecx, esi                        ; startRow = esi

; int startCol = col - col % 3
        mov     esi, 3
        mov     eax, [ebp+16]                   ; eax = int col
        xor     edx, edx                        ; edx = 0
        div     esi                             ; edx = col % 3
        mov     esi, [ebp+16]                   ; esi = int col
        sub     esi, edx                        ; esi = esi - edx
        mov     edi, esi                        ; startCol = esi

        mov     bh, 0                           ; i = 0
.isSafe_box_loop_init:
        xor     esi, esi                        ; j = 0
.isSafe_box_loop:
        movzx   edx, bh                         ; edx = i
        lea     edx, [edx+ecx]                  ; edx = i + startRow
        lea     edx, [edx+edx*8]                ; edx = grid[i + startRow]
        add     edx, [ebp+8]                    ; edx = pointer to grid's row

        lea     eax, [esi+edi]                  ; eax = j + startCol
        cmp     BYTE [edx+eax], bl              ; test if grid[i + startRow][j + startCol] == num

        mov     eax, 0                          ; cannot use xor here as it sets ZF flag
        je     .isSafe_return                   ; if equal, return 0

        inc     esi                             ; j++
        cmp     esi, 2                          ; test j <= 2
        jbe     .isSafe_box_loop                ; if true, go back to loop

        inc     bh                              ; else i++
        cmp     bh, 2                           ; test i <= 2
        jbe     .isSafe_box_loop_init           ; if true, go back to loop
        mov     eax, 1                          ; else, escape loop, return 1
.isSafe_return:
        pop     edi
        pop     esi
        pop     ebx

        leave
        ret