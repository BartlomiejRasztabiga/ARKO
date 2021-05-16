        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   ebp+8
;   - unsigned int row  ebp+12
;   - unsigned int col  ebp+16
; variables: none
; registers:
;   - ebx: grid argument from ebp+8
;   - esi: row argument from  ebp+12
;   - edi: col argument from  ebp+16
;   - ecx: num (char) local variable
; returns:
;   - eax: 1 if found solution, 0 otherwise
; TODO: przejsc bardziej na uzycie rejestrów?
; TODO: uzywac krotszych przesłań (WORD zamiast DOWRD)?
; TODO: uzywac krotszych rejestrów (AX zamiast EAX)
sudoku:
        push    ebp
        mov     ebp, esp
        sub     esp, 8                          ; stack has to be aligned to 16 due to calling convention

        push    ebx
        push    esi
        push    edi

        mov     ebx, [ebp+8]                    ; ebx = grid
        mov     esi, [ebp+12]                   ; esi = row
        mov     edi, [ebp+16]                   ; edi = col
        mov     ecx, '1'                        ; num = '1'
.sudoku_find_next_cell:
        cmp     edi, 9                          ; test if col == 9
        jne     .sudoku_not_finished            ; if not equal, goto .sudoku_not_finished

        inc     esi                             ; row++
        xor     edi, edi                        ; col = 0

        cmp     esi, 9                          ; test if row == 9

        mov     eax, 1
        je     .sudoku_return                   ; if last row, return 1
                                                ; if not equal, goto .sudoku_not_finished
.sudoku_not_finished:
        push    edi                             ; push col
        push    esi                             ; push row
        push    ebx                             ; push grid
        call    getCellValue                    ; call getCellValue(grid, row, col)
        add     esp, 12                         ; free stack

        cmp     al, '#'                         ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop         ; if equal, goto .sudoku_find_value_loop

        inc     edi                             ; col++
        jmp     .sudoku_find_next_cell          ; if not equal, try next col
.sudoku_find_value_loop:
        push    ecx                             ; push num
        push    edi                             ; push col
        push    esi                             ; push row
        push    ebx                             ; push grid
        call    isSafe                          ; call isSafe(grid, row, col, num)
        add     esp, 12                         ; free stack
        pop     ecx                             ; restore ecx
        cmp     eax, 1                          ; test if isSafe returned 1 (true)
        jne     .sudoku_find_value_loop_next_num; if false, try next number
                                                ; if true, put that number into sudoku matrix
        push    ecx                             ; push num
        push    edi                             ; push col
        push    esi                             ; push row
        push    ebx                             ; push grid
        call    setCellValue                    ; call setCellValue(grid, row, col, num)
        add     esp, 16                         ; free stack
                                                ; solve next column
        mov     eax, edi                        ; eax = int col
        inc     eax                             ; eax = col + 1
        push    ecx                             ; save ecx (num)
        push    eax                             ; push (col+1)
        push    esi                             ; push row
        push    ebx                             ; push grid
        call    sudoku                          ; call sudoku(grid, row, col+1)
        add     esp, 12                         ; free stack
        pop     ecx                             ; restore ecx (num)
        cmp     eax, 1                          ; test if sudoku returned 1 (true)

        mov     eax, 1
        je     .sudoku_return                   ; if true, return 1
                                                ; if false, try next number
.sudoku_find_value_loop_next_num:
        push    '#'                             ; push '#' - num
        push    edi                             ; push col
        push    esi                             ; push row
        push    ebx                             ; push grid
        call    setCellValue                    ; call setCellValue(grid, row, col, num)
        add     esp, 16                         ; free stack

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
;   checks whether it will be legal to assign num to the given row, col
; arguments:
;   - char grid[N][N]   ebp+8
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

        mov     bl, [ebp+20]                    ; ebx (bl) = char num
        xor     esi, esi                        ; int x = 0
.isSafe_row_loop:
        push    esi                             ; push x
        push    DWORD [ebp+12]                  ; push row
        push    DWORD [ebp+8]                   ; push grid
        call    getCellValue                    ; call getCellValue(grid, row, col)
        add     esp, 12                         ; free stack

        cmp     al, bl                          ; test if grid[row][x] == num
        je      .isSafe_return                  ; if equal, num illegal, return 0

        inc     esi                             ; x++
        cmp     esi, 8                          ; if x <= 8
        jle     .isSafe_row_loop                ; goto loop if condition met

        mov     esi, 0                          ; int x = 0
.isSafe_col_loop:
        push    DWORD [ebp+16]                  ; push col
        push    esi                             ; push x
        push    DWORD [ebp+8]                   ; push grid
        call    getCellValue                    ; call getCellValue(grid, row, col)
        add     esp, 12                         ; free stack

        cmp     al, bl                          ; test if grid[x][col] == num
        je      .isSafe_return                  ; if equal, num illegal, return 0

        inc     esi                             ; x++
        cmp     esi, 8                          ; if x <= 8
        jle     .isSafe_col_loop                ; goto loop if condition met

; int startRow = row - row % 3
        mov     ecx, 3
        mov     eax, [ebp+12]                   ; eax = int row
        xor     edx, edx                        ; edx = 0
        div     ecx                             ; edx = row % 3
        mov     ecx, [ebp+12]                   ; ecx = int row
        sub     ecx, edx                        ; ecx = ecx - edx
        mov     [ebp-4], ecx                    ; startRow = ecx

; int startCol = col - col % 3
        mov     ecx, 3
        mov     eax, [ebp+16]                   ; eax = int col
        xor     edx, edx                        ; edx = 0
        div     ecx                             ; edx = col % 3
        mov     ecx, [ebp+16]                   ; ecx = int col
        sub     ecx, edx                        ; ecx = ecx - edx
        mov     [ebp-8], ecx                    ; startCol = ecx
; TODO: optimisation, replace i and j with one variable
        mov     DWORD [ebp-12], 0               ; i = 0
.isSafe_3_3matrix_col_loop_init:
        mov     DWORD [ebp-16], 0               ; j = 0
.isSafe_3_3matrix_col_loop:
        mov     edx, [ebp-12]                   ; edx = i
        mov     eax, [ebp-4]                    ; eax = startRow
        add     edx, eax                        ; edx = i + startRow
        lea     edx, [edx+edx*8]                ; edx = grid[i + startRow]
        mov     eax, [ebp+8]                    ; eax = pointer to grid
        add     edx, eax                        ; edx = pointer to grid's row

        mov     ecx, [ebp-16]                   ; ecx = j
        mov     eax, [ebp-8]                    ; eax = startCol
        add     eax, ecx                        ; eax = j + startCol
        mov     eax, [edx+eax]                  ; eax = char from grid' tile at [i + startRow][j + startCol]
        cmp     al, bl                          ; test if grid[i + startRow][j + startCol] == num

        mov     eax, 0                          ; cannot use xor here as it sets ZF flag
        je     .isSafe_return                   ; if equal, return 0

        inc     DWORD [ebp-16]                  ; j++
        cmp     DWORD [ebp-16], 2               ; test j <= 2
        jbe     .isSafe_3_3matrix_col_loop      ; if true, go back to loop

        inc     DWORD [ebp-12]                  ; else i++
        cmp     DWORD [ebp-12], 2               ; test i <= 2
        jbe     .isSafe_3_3matrix_col_loop_init ; if true, go back to loop
        mov     eax, 1                          ; else, escape loop, return 1
.isSafe_return:
        pop     esi
        pop     ebx

        leave
        ret

; ============================================================================
; getCellValue
; description:
;   return char from sudoku grid at [row][col]
; arguments:
;   - char grid[N][N]   ebp+8
;   - unsigned int row  ebp+12
;   - unsigned int col  ebp+16
; returns:
;   - eax: char from grid[row][col]
getCellValue:
        push    ebp
        mov     ebp, esp

        mov     edx, [ebp+12]                   ; edx = int row
        lea     edx, [edx+edx*8]                ; edx = 9 * row
        mov     eax, [ebp+8]                    ; eax = pointer to grid
        lea     edx, [edx+eax]                  ; edx = pointer to grid's row
        mov     eax, [ebp+16]                   ; eax = int col
        mov     eax, [eax+edx]                  ; eax = char from grid's tile at [row][x]

        leave
        ret                                     ; return eax

; ============================================================================
; setCellValue
; description:
;   set char at sudoku[row][col]
; arguments:
;   - char grid[N][N]   ebp+8
;   - unsigned int row  ebp+12
;   - unsigned int col  ebp+16
;   - char value        ebp+20
; returns: none
setCellValue:
        push    ebp
        mov     ebp, esp

        mov     edx, [ebp+12]                   ; edx = int row
        lea     edx, [edx+edx*8]                ; edx = 9 * row
        mov     eax, [ebp+8]                    ; eax = pointer to grid
        lea     edx, [edx+eax]                  ; edx = pointer to grid's row
        mov     eax, [ebp+16]                   ; eax = int col
        lea     edx, [edx+eax]                  ; edx = pointer to grid's tile at [row][col]
        mov     eax, [ebp+20]                   ; eax = char to insert
        mov     [edx], al                       ; grid[row][col] = eax (num)

        leave
        ret                                     ; return