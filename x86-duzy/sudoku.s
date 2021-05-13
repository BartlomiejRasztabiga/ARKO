        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char arr[N][N]    ebp+8
;   - unsigned int row  ebp+12
;   - unsigned int col  ebp+16
; variables:
;   - char num          ebp-4
; returns:
;   - eax: 1 if found solution, 0 otherwise
sudoku:
        push    ebp
        mov     ebp, esp
        sub     esp, 24                         ; stack has to be aligned to 16 according to calling convention

; TODO: rearrange jumps?
        cmp     DWORD [ebp+16], 9               ; test if col == 9
        jne     .sudoku_not_last_col            ; if not equal, goto .sudoku_not_last_col

        cmp     DWORD [ebp+12], 8               ; test if row == 8
        jne     .sudoku_not_last_row            ; if not equal, goto .sudoku_not_last_row

        mov     eax, 1
        jmp     .sudoku_return                  ; if last row, return 1
.sudoku_not_last_row:
        inc     DWORD [ebp+12]                  ; row++
        mov     DWORD [ebp+16], 0               ; col = 0
.sudoku_not_last_col:
        mov     edx, DWORD [ebp+12]             ; edx = row
        lea     edx, [edx, edx*8]               ; edx = 9 * x
        mov     eax, DWORD [ebp+8]              ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row
        mov     eax, DWORD [ebp+16]             ; eax = int col;
        add     eax, edx                        ; eax = pointer to grid's tile at [x][col]
        movzx   eax, BYTE [eax]                 ; eax = char from grid' tile at [x][col]
        cmp     al, '#'                         ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value              ; if equal, goto .sudoku_find_value

        ; if not equal, return sudoku(grid, row, col + 1);
        mov     eax, DWORD [ebp+16]             ; eax = col
        inc     eax                             ; eax = col + 1
        sub     esp, 4                          ; stack has to be aligned to 16, 3*4 + 4 = 16
        push    eax                             ; push (col+1)
        push    DWORD [ebp+12]                  ; push row
        push    DWORD [ebp+8]                   ; push grid
        call    sudoku                          ; call sudoku(grid, row, col)
        add     esp, 16                         ; free stack
        jmp     .sudoku_return                  ; return eax (return value from sudoku(grid, row, col + 1))
; TODO: Rearrange jumps
.sudoku_find_value:
        mov     BYTE [ebp-4], '1'               ; num = '1'
.sudoku_find_value_loop:
        movsx   eax, BYTE [ebp-4]               ; eax = char num
        push    eax                             ; push num
        push    DWORD [ebp+16]                  ; push col
        push    DWORD [ebp+12]                  ; push row
        push    DWORD [ebp+8]                   ; push grid
        call    isSafe                          ; call isSafe(grid, row, col, num)
        add     esp, 16                         ; free stack
        cmp     eax, 1                          ; test if isSafe returned 1 (true)
        jne     .sudoku_find_value_loop_next_num; if false, try next number
                                                ; if true, put that number into sudoku matrix
        ; TODO: replace getCharFromMatrix, setCharToMatrix with functions or macros?
        mov     edx, DWORD [ebp+12]             ; edx = row
        lea     edx, [edx, edx*8]               ; edx = 9 * x
        mov     eax, DWORD [ebp+8]              ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row
        mov     eax, DWORD [ebp+16]             ; eax = int col;
        add     edx, eax                        ; eax = pointer to grid's tile at [row][col]
        movzx   eax, BYTE [ebp-4]               ; eax = char from grid' tile at [row][col]
        mov     BYTE [edx], al                  ; grid[row][col] = eax (num)
                                                ; solve next column
        mov     eax, DWORD [ebp+16]             ; eax = int col
        inc     eax                             ; eax = col + 1
        sub     esp, 4                          ; stack has to be aligned to 16, 3*4 + 4 = 16
        push    eax                             ; push (col+1)
        push    DWORD [ebp+12]                  ; push row
        push    DWORD [ebp+8]                   ; push grid
        call    sudoku                          ; call sudoku(grid, row, col+1)
        add     esp, 16                         ; free stack
        cmp     eax, 1                          ; test if sudoku returned 1 (true)
        jne     .sudoku_find_value_loop_next_num; if false, try next number
                                                ; if true, return 1
        mov     eax, 1
        jmp     .sudoku_return                  ; return 1
.sudoku_find_value_loop_next_num:
        mov     edx, DWORD [ebp+12]             ; edx = row
        lea     edx, [edx, edx*8]               ; edx = 9 * x
        mov     eax, DWORD [ebp+8]              ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row
        mov     eax, DWORD [ebp+16]             ; eax = int col;
        add     eax, edx                        ; eax = pointer to grid's tile at [row][col]
        mov     BYTE [eax], '#'                 ; grid[row][col] = '#'

        ; num++, try next char
        movzx   eax, BYTE [ebp-4]               ; eax = num
        inc     eax                             ; eax++
        mov     BYTE [ebp-4], al                ; num = num + 1

.sudoku_find_value_loop_condition:
        cmp     BYTE [ebp-4], '9'               ; test if num <= '9'
        jle     .sudoku_find_value_loop         ; if true, goto loop
        xor     eax, eax                        ; return 0
.sudoku_return:
        leave
        ret


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
;   - int startRow      ebp-4
;   - int startCol      ebp-8
;   - int i             ebp-12
;   - int j             ebp-16
; registers:
;   - ebx: char num from ebp+20
;   - esi: int x
; returns:
;   - eax: 1 if legal, 0 otherwise
isSafe:
        push    ebp
        mov     ebp, esp
        sub     esp, 16

        push    ebx
        push    esi

        mov     bl, BYTE [ebp+20]               ; ebx (bl) = char num
        xor     esi, esi                        ; int x = 0
.isSafe_row_loop:
        mov     edx, DWORD [ebp+12]             ; edx = int row
        lea     edx, [edx+edx*8]                ; edx = 9 * row
        mov     eax, DWORD [ebp+8]              ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row
        mov     eax, esi                        ; eax = x
        add     eax, edx                        ; eax = pointer to grid's tile at [row][x]
        movzx   eax, BYTE [eax]                 ; eax = char from grid's tile at [row][x]
        cmp     bl, al                          ; test if grid[row][x] == num
        je      .isSafe_return                  ; if equal, num illegal, return 0
                                                ; if not equal, get next col
.isSafe_row_loop_increment:
        inc     esi                             ; x++
.isSafe_row_loop_condition:
        cmp     esi, 8                          ; if x <= 8
        jle     .isSafe_row_loop                ; goto loop if condition met

        mov     esi, 0                          ; int x = 0
.isSafe_col_loop:
        mov     edx, esi                        ; edx = x
        lea     edx, [edx, edx*8]               ; edx = 9 * x
        mov     eax, DWORD [ebp+8]              ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row
        mov     eax, DWORD [ebp+16]             ; eax = int col;
        add     eax, edx                        ; eax = pointer to grid's tile at [x][col]
        movzx   eax, BYTE [eax]                 ; eax = char from grid' tile at [x][col]
        cmp     bl, al                          ; test if grid[x][col] == num
        je      .isSafe_return                  ; if equal, num illegal, return 0
                                                ; if not equal, get next row
.isSafe_col_loop_increment:
        inc     esi                             ; x++
.isSafe_col_loop_condition:
        cmp     esi, 8                          ; if x <= 8
        jle     .isSafe_col_loop                ; goto loop if condition met

; int startRow = row - row % 3
        mov     ecx, 3
        mov     eax, DWORD [ebp+12]             ; eax = int row
        xor     edx, edx                        ; edx = 0
        div     ecx                             ; edx = row % 3
        mov     ecx, DWORD [ebp+12]             ; ecx = int row
        sub     ecx, edx                        ; ecx = ecx - edx
        mov     DWORD [ebp-4], ecx              ; startRow = ecx

; int startCol = col - col % 3
        mov     ecx, 3
        mov     eax, DWORD [ebp+16]             ; eax = int col
        xor     edx, edx                        ; edx = 0
        div     ecx                             ; edx = col % 3
        mov     ecx, DWORD [ebp+16]             ; ecx = int col
        sub     ecx, edx                        ; ecx = ecx - edx
        mov     DWORD [ebp-8], ecx              ; startCol = ecx

        mov     DWORD [ebp-12], 0               ; i = 0

; TODO: rearrange jumps?
.isSafe_3_3matrix_col_loop_init:
        mov     DWORD [ebp-16], 0               ; j = 0
.isSafe_3_3matrix_col_loop:
        mov     edx, DWORD [ebp-12]             ; edx = i
        mov     eax, DWORD [ebp-4]              ; eax = startRow
        add     edx, eax                        ; edx = i + startRow
        lea     edx, [edx+edx*8]                ; edx = grid[i + startRow]
        mov     eax, DWORD [ebp+8]              ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row

        mov     ecx, DWORD [ebp-16]             ; ecx = j
        mov     eax, DWORD [ebp-8]              ; eax = startCol
        add     eax, ecx                        ; eax = j + startCol
        movzx   eax, BYTE [edx+eax]             ; eax = char from grid' tile at [i + startRow][j + startCol]
        cmp     bl, al                          ; test if grid[i + startRow][j + startCol] == num
        jne     .isSafe_3_3matrix_col_loop_increment    ; if not equal, try next column

        xor     eax, eax                        ; if equal, return 0
        jmp     .isSafe_return                  ; goto return
.isSafe_3_3matrix_col_loop_increment:
        inc     DWORD [ebp-16]                  ; j++
.isSafe_3_3matrix_col_loop_condition:
        cmp     DWORD [ebp-16], 2               ; test j <= 2
        jbe     .isSafe_3_3matrix_col_loop      ; if true, go back to loop
        inc     DWORD [ebp-12]                  ; else i++

.isSafe_3_3matrix_row_loop_condition:
        cmp     DWORD [ebp-12], 2               ; test i <= 2
        jbe     .isSafe_3_3matrix_col_loop_init ; if true, go back to loop
        mov     eax, 1                          ; else, escape loop, return 1

.isSafe_return:
        pop     esi
        pop     ebx

        leave
        ret