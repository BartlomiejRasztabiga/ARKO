        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   esp+20
; returns:
;   - eax: 1 if found solution, 0 otherwise
sudoku:
        ; save callee-saved registers
        push    ebp
        push    ebx
        push    esi
        push    edi

        mov     edi, [esp+20]                   ; edi = grid
        xor     ebx, ebx                        ; bh = row = 0; bl = col = 0;

        call    .sudoku                         ; call recursive helper

        ; restore callee-saved registers
        pop     edi
        pop     esi
        pop     ebx
        pop     ebp

        ret

; ============================================================================
; .sudoku (recursive helper for sudoku)
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   edi
;   - unsigned int row  bh
;   - unsigned int col  bl
; registers:
;   - edi: grid argument
;   - bh: row argument
;   - bl: col argument
;   - cl: num (char) local variable
;   - esi: tmp register
; returns:
;   - eax: 1 if found solution, 0 otherwise
.sudoku:
        mov     cl, '1'                         ; num = '1'
.sudoku_find_next_cell:
        cmp     bl, 9                           ; test if col == 9
        jne     .sudoku_not_finished            ; if not equal, goto .sudoku_not_finished

        inc     bh                              ; row++
        xor     bl, bl                          ; col = 0

        cmp     bh, 9                           ; test if row == 9

        mov     eax, 1
        je     .sudoku_return                   ; if last row, return 1
                                                ; if not equal, goto .sudoku_not_finished
.sudoku_not_finished:
        ; al = getCellValue at [row][x]
        movzx   esi, bh                         ; esi = row
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row

        movzx   esi, bl                         ; esi = col
        cmp     BYTE [eax+esi], '#'             ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop         ; if equal, goto .sudoku_find_value_loop

        inc     bl                              ; col++
        jmp     .sudoku_find_next_cell          ; if not equal, try next col
.sudoku_find_value_loop:
        call    isSafe                          ; call isSafe(row, col, num)

        je     .sudoku_find_value_loop_next_num ; if isSafe returned 0, try next number
                                                ; if returned 1, put that number into sudoku matrix

        ; setCellValue at [row][col] <- num
        movzx   esi, bh                         ; esi = row
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row

        movzx   esi, bl                         ; esi = col
        mov     [eax+esi], cl                   ; grid[row][col] = cl (num)

        ; solve next column
        push    bx                              ; save row,col
        push    cx                              ; save cx (char num)

        inc     bl                              ; col++
        call    .sudoku                         ; call .sudoku(grid, row, col+1)

        pop     cx                              ; restore cx (char num)
        pop     bx                              ; restore row,col

        cmp     al, 1                           ; test if sudoku returned 1 (true)

        je     .sudoku_return                   ; if true, return 1 (1 already in eax)
                                                ; if false, try next number
.sudoku_find_value_loop_next_num:
        ; setCellValue at [row][col] <- '#'
        movzx   esi, bh                         ; esi = row
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row

        movzx   esi, bl                         ; esi = col
        mov     [eax+esi], BYTE '#'             ; grid[row][col] = '#'

        inc     cl                              ; num++, try next char
        cmp     cl, '9'                         ; test if num <= '9'
        jle     .sudoku_find_value_loop         ; if true, goto loop
        xor     eax, eax                        ; return 0
.sudoku_return:
        ret

; ============================================================================
; isSafe(row, col, num)
; description:
;   checks whether it will be legal to assign num to the given [row][col]
; arguments:
;   - char grid[N][N]   edi
;   - int col           bl
;   - int row           bh
;   - char num          cl
; registers:
;   - al: temp register
;   - ah: x local variable
;   - bh: row argument
;   - bl: col argument
;   - dh: startRow local variable
;   - dl: startCol local variable
;   - ch: i local variable
;   - cl: num
;   - edi: grid
;   - esi: j local variable/temp register
;   - ebp: temp register
; returns:
;   - ZF flag: 1 if illegal, 0 if legal
isSafe:
        push    ebx

        mov     ah, 8                           ; int x = 8
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        movzx   ebp, bh                         ; ebp = row
        lea     ebp, [ebp+ebp*8]                ; ebp = 9 * row
        lea     ebp, [ebp+edi]                  ; ebp = pointer to grid's row

        movzx   esi, ah                         ; esi = x
        cmp     [ebp+esi], cl                   ; test if grid[row][x] == num
        je      .isSafe_return                  ; if equal, num illegal, return ZF

        dec     ah                              ; x--
        jns     .isSafe_row_loop                ; goto loop if condition met

        mov     ah, 8                           ; int x = 8
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        movzx   esi, ah                         ; esi = x
        lea     ebp, [esi+esi*8]                ; ebp = 9 * x
        lea     ebp, [ebp+edi]                  ; ebp = pointer to grid's row

        movzx   esi, bl                         ; esi = col
        mov     al, [ebp+esi]                   ; al = char from grid's tile at [x][col]

        cmp     al, cl                          ; test if grid[x][col] == num
        je      .isSafe_return                  ; if equal, num illegal, return ZF

        dec     ah                              ; x--
        jns     .isSafe_col_loop                ; goto loop if x >= 0

; int startRow = row - row % 3
        mov     dh, 3
        movzx   ax, bh                          ; ax = int row
        div     dh                              ; ah = row % 3
        mov     dh, bh                          ; dh = int row
        sub     dh, ah                          ; startRow = dh - ah  (row - row % 3)

; int startCol = col - col % 3
        mov     dl, 3
        movzx   ax, bl                          ; ax = int col
        div     dl                              ; ah = col % 3
        mov     dl, bl                          ; dl = int col
        sub     dl, ah                          ; startCol = dl - ah  (col - col % 3)

        mov     ch, 2                           ; i = 2
.isSafe_box_loop_init:
        mov     esi, 2                          ; j = 2
.isSafe_box_loop:
        movzx   eax, dh                         ; eax = startRow
        movzx   ebx, ch                         ; ebx = i
        lea     ebx, [ebx+eax]                  ; ebx = i + startRow
        lea     ebx, [ebx+ebx*8]                ; ebx = grid[i + startRow]
        lea     ebx, [ebx+edi]                  ; ebx = pointer to grid's row

        movzx   ebp, dl                         ; ebp = startCol
        lea     eax, [esi+ebp]                  ; eax = j + startCol
        cmp     [ebx+eax], cl                   ; test if grid[i + startRow][j + startCol] == num

        je     .isSafe_return                   ; if equal, return ZF

        dec     esi                             ; j--
        jge     .isSafe_box_loop                ; if j > 0, go back to loop

        dec     ch                              ; else i--
        jge     .isSafe_box_loop_init           ; if i > 0, go back to loop
                                                ; else, escape loop, return no ZF flag
.isSafe_return:
        pop     ebx

        ret