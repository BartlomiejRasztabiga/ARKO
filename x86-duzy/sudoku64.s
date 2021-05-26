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
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15

        xor     r10b, r10b                        ; row = 0
        xor     r11b, r11b                        ; col = 0

        call    .sudoku                           ; call recursive helper

        ; restore callee-saved registers
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx

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
;   - r12b: num (char) local variable
;   - rsi: tmp register
; returns:
;   - rax: 1 if found solution, 0 otherwise
.sudoku:
        mov     r12b, '1'                         ; num = '1'
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
        ; al = getCellValue at [row][x]
        movzx   rax, r10b                         ; rax = row
        lea     rax, [rax+rax*8]                  ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col
        cmp     BYTE [rax+rsi], '#'               ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop           ; if equal, goto .sudoku_find_value_loop

        inc     r11b                              ; col++
        jmp     .sudoku_find_next_cell            ; if not equal, try next col
.sudoku_find_value_loop:
        call    isSafe                            ; call isSafe(row, col, num)

        je     .sudoku_find_value_loop_next_num   ; if isSafe returned 0, try next number
                                                  ; if returned 1, put that number into sudoku matrix

        ; setCellValue at [row][col] <- num
        movzx   rax, r10b                         ; rax = row
        lea     rax, [rax+rax*8]                  ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col
        mov     [rax+rsi], r12b                   ; grid[row][col] = r12 (num)

        ; solve next column
        push    r10w                              ; save row
        push    r11w                              ; save col
        push    r12w                              ; save num

        inc     r11b                              ; col++
        call    .sudoku                           ; call .sudoku(grid, row, col+1)

        pop     r12w                              ; restore num
        pop     r11w                              ; restore col
        pop     r10w                              ; restore row

        cmp     rax, 1                            ; test if sudoku returned 1 (true)

        je     .sudoku_return                     ; if true, return 1 (1 already in rax)
                                                  ; if false, try next number
.sudoku_find_value_loop_next_num:
        ; setCellValue at [row][col] <- '#'
        movzx   rax, r10b                         ; rax = row
        lea     rax, [rax+rax*8]                  ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col
        mov     [rax+rsi], BYTE '#'               ; grid[row][col] = '#'

        inc     r12b                              ; num++, try next char
        cmp     r12b, '9'                         ; test if num <= '9'
        jle     .sudoku_find_value_loop           ; if true, goto loop
        xor     rax, rax                          ; return 0
.sudoku_return:
        ret

; ============================================================================
; isSafe(row, col, num)
; description:
;   checks whether it will be legal to assign num to the given [row][col]
; arguments:
;   - char grid[N][N]   rdi
;   - int col           r11b
;   - int row           r10b
;   - char num          r12b
; registers:
;   - r9:   temp register
;   - r13b: x local variable
;   - r10b: row argument
;   - r11b: col argument
;   - r13b: startRow local variable
;   - r14b: startCol local variable
;   - r15: i local variable
;   - r12b: num
;   - rdi: grid
;   - rsi: j local variable/temp register
; returns:
;   - ZF flag: 1 if illegal, 0 if legal
isSafe:

        mov     r13b, 8                           ; int x = 8
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        movzx   rax, r10b                         ; rax = row
        lea     rax, [rax+rax*8]                  ; rax = 9 * row
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row

        movzx   rsi, r13b
        cmp     [rax+rsi], r12b                   ; test if grid[row][x] == num
        je      .isSafe_return                    ; if equal, num illegal, return ZF

        dec     r13b                              ; x--
        jge     .isSafe_row_loop                  ; goto loop if condition met

        mov     r13b, 8                           ; int x = 8
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        movzx   rax, r13b                         ; rax = x
        lea     rax, [rax+rax*8]                  ; rax = 9 * x
        lea     rax, [rax+rdi]                    ; rax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col

        cmp     [rax+rsi], r12b                   ; test if grid[x][col] == num
        je      .isSafe_return                    ; if equal, num illegal, return ZF

        dec     r13b                              ; x--
        jge     .isSafe_col_loop                  ; goto loop if x >= 0

; int startRow = row - row % 3
        mov     cl, 3
        movzx   ax, r10b                          ; ax = row
        div     cl                                ; ah = row % 3
        mov     cl, r10b                          ; cl = row
        sub     cl, ah                            ; cl = cl - ah  (row - row % 3)
        movzx   r13, cl                           ; startRow = cl

; int startCol = col - col % 3
        mov     cl, 3
        movzx   ax, r11b                          ; ax = col
        div     cl                                ; ah = col % 3
        mov     cl, r11b                          ; cl = col
        sub     cl, ah                            ; cl = cl - ah  (col - col % 3)
        movzx   r14, cl                           ; startCol = cl

        mov     r15, 2                            ; i = 2
.isSafe_box_loop_init:
        mov     rsi, 2                            ; j = 2
.isSafe_box_loop:
        mov     r9, r15                           ; r9 = i
        lea     r9, [r9+r13]                      ; r9 = i + startRow
        lea     r9, [r9+r9*8]                     ; r9 = grid[i + startRow]
        lea     r9, [r9+rdi]                      ; r9 = pointer to grid's row

        lea     rax, [rsi+r14]                    ; rax = j + startCol
        cmp     [r9+rax], r12b                    ; test if grid[i + startRow][j + startCol] == num

        je     .isSafe_return                     ; if equal, return ZF

        dec     rsi                               ; j--
        jge     .isSafe_box_loop                  ; if j > 0, go back to loop

        dec     r15                               ; else i--
        jge     .isSafe_box_loop_init             ; if i > 0, go back to loop
                                                  ; else, escape loop, return no ZF flag
.isSafe_return:

        ret