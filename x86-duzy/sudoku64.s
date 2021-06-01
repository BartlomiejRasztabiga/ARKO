        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   rdi
; returns:
;   - rax: 1 if found solution, 0 otherwise
sudoku:
        ; save callee-saved registers
        push    r12

        ; zeroing registers so we can use whole (REX) registers later on while addressing
        xor     r10, r10                          ; row = 0
        xor     r11, r11                          ; col = 0

        call    .sudoku                           ; call recursive helper

        ; restore callee-saved registers
        pop     r12

        ret

; ============================================================================
; .sudoku (recursive helper for sudoku)
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   rdi
;   - unsigned int row  r10b
;   - unsigned int col  r11b
; registers:
;   - rdi: grid argument
;   - r10b: row argument
;   - r11b: col argument
;
;   - dl: num (char) local variable
; returns:
;   - rax: 1 if found solution, 0 otherwise
.sudoku:
        mov     dl, '1'                           ; num = '1'
.sudoku_find_next_cell:
        cmp     r11b, 9                           ; test if col == 9
        jne     .sudoku_not_finished              ; if not equal, goto .sudoku_not_finished

        inc     r10b                              ; row++
        xor     r11b, r11b                        ; col = 0

        cmp     r10b, 9                           ; test if row == 9

        mov     rax, 1
        je     .sudoku_return                     ; if last row, return 1
                                                  ; if not equal, goto .sudoku_not_finished
.sudoku_not_finished:
        ; getCellValue at [row][x]
        lea     rax, [r10d+r10d*8]                ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row
        cmp     BYTE [rax+r11], '#'               ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop           ; if equal, goto .sudoku_find_value_loop

        inc     r11b                              ; col++
        jmp     .sudoku_find_next_cell            ; if not equal, try next col
.sudoku_find_value_loop:
        call    isSafe                            ; call isSafe(row, col, num)

        je     .sudoku_find_value_loop_next_num   ; if isSafe returned 0, try next number
                                                  ; if returned 1, put that number into sudoku matrix
        ; setCellValue at [row][col] <- num
        lea     rax, [r10d+r10d*8]                ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row
        mov     [rax+r11], dl                     ; grid[row][col] = dl (num)

        ; solve next column (save [row, col, num] for backtracking)
        push    r10w                              ; save row
        push    r11w                              ; save col
        push    dx                                ; save num

        inc     r11b                              ; col++
        call    .sudoku                           ; call .sudoku(grid, row, col+1)

        pop     dx                                ; restore num
        pop     r11w                              ; restore col
        pop     r10w                              ; restore row

        cmp     rax, 1                            ; test if sudoku returned 1 (true)

        je     .sudoku_return                     ; if true, return 1 (1 already in rax)
                                                  ; if false, try next number
.sudoku_find_value_loop_next_num:
        ; setCellValue at [row][col] <- '#'
        lea     rax, [r10d+r10d*8]                ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row
        mov     [rax+r11], BYTE '#'               ; grid[row][col] = '#'

        inc     dl                                ; num++, try next char
        cmp     dl, '9'                           ; test if num <= '9'
        jle     .sudoku_find_value_loop           ; if true, goto loop
        xor     rax, rax                          ; return 0
.sudoku_return:
        ret

; ============================================================================
; isSafe(grid, row, col, num)
; description:
;   checks whether it will be legal to assign num to the given [row][col]
; arguments:
;   - char grid[N][N]   rdi
;   - int row           r10b
;   - int col           r11b
;   - char num          dl
; registers:
;   - rdi: grid argument
;   - r10b: row argument
;   - r11b: col argument
;   - dl: num argument
;
;   - al: startCol local variable
;   - cl: temp register for division (cannot use rex registers)
;   - cl: i local variable
;   - rsi: temp register
;   - r8b: j local variable
;   - r9b: x local variable
;   - r9: temp register
;   - r12b: startRow local variable
; returns:
;   - ZF flag: 1 if illegal, 0 if legal
isSafe:
        mov     r9, 8                             ; int x = 8
.isSafe_row_loop:
        ; getCellValue at [row][x]
        lea     rsi, [r10d+r10d*8]                ; rsi = 9 * row
        lea     rsi, [rsi+rdi]                    ; rsi = pointer to grid's row
        cmp     [rsi+r9], dl                      ; test if grid[row][x] == num
        je      .isSafe_return                    ; if equal, num illegal, return ZF

        dec     r9b                               ; x--
        jns     .isSafe_row_loop                  ; goto loop if x >= 0

        mov     r9b, 8                            ; int x = 8
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        lea     rsi, [r9d+r9d*8]                  ; rsi = 9 * x
        lea     rsi, [rsi+rdi]                    ; rsi = pointer to grid's row
        cmp     [rsi+r11], dl                     ; test if grid[x][col] == num
        je      .isSafe_return                    ; if equal, num illegal, return ZF

        dec     r9b                               ; x--
        jns     .isSafe_col_loop                  ; goto loop if x >= 0
; int startRow = row - row % 3
        mov     cl, 3
        movzx   ax, r10b                          ; ax = row
        div     cl                                ; ah = row % 3
        mov     cl, r10b                          ; cl = row
        sub     cl, ah                            ; cl = cl - ah  (row - row % 3)
        movzx   r12, cl                           ; startRow = cl

; int startCol = col - col % 3
        mov     cl, 3
        movzx   ax, r11b                          ; ax = col
        div     cl                                ; ah = col % 3
        mov     cl, r11b                          ; cl = col
        sub     cl, ah                            ; cl = cl - ah  (col - col % 3)
        mov     al, cl                            ; startCol = cl

        mov     cl, 2                             ; i = 2
.isSafe_box_loop_init:
        mov     r8b, 2                            ; j = 2
.isSafe_box_loop:
        movzx   rsi, cl                           ; rsi = i
        lea     r9, [rsi+r12]                     ; r9 = i + startRow
        lea     r9, [r9+r9*8]                     ; r9 = grid[i + startRow]
        lea     r9, [r9+rdi]                      ; r9 = pointer to grid's row
        movzx   rsi, al                           ; rsi = startCol
        lea     rsi, [r8+rsi]                     ; rsi = j + startCol
        cmp     [r9+rsi], dl                      ; test if grid[i + startRow][j + startCol] == num

        je     .isSafe_return                     ; if equal, return ZF

        dec     r8b                               ; j--
        jns     .isSafe_box_loop                  ; if j > 0, go back to loop

        dec     cl                                ; else i--
        jns     .isSafe_box_loop_init             ; if i > 0, go back to loop
                                                  ; else, escape loop, return no ZF flag
.isSafe_return:

        ret