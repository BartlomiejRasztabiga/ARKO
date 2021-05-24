        section .text
        global  sudoku

; ============================================================================
; sudoku
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   rdi
; returns:
;   - eax: 1 if found solution, 0 otherwise
sudoku:
        ; save callee-saved registers
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15

;        mov     rdi, rdi                   ; rdi = grid
;        xor     ebx, ebx                        ; bh = row = 0; bl = col = 0;

;        xor     rax, rax
;        xor     rcx, rcx
;        xor     rdx, rdx
;        xor     rbx, rbx
;        xor     rsi, rsi
;        xor     rdi, rdi

        xor     r10, r10
        xor     r11, r11

        call    .sudoku                         ; call recursive helper

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
;   - eax: 1 if found solution, 0 otherwise
.sudoku:
        mov     r12b, '1'                         ; num = '1'
.sudoku_find_next_cell:
        cmp     r11b, 9                           ; test if col == 9
        jne     .sudoku_not_finished            ; if not equal, goto .sudoku_not_finished

        inc     r10b                              ; row++
        xor     r11b, r11b                          ; col = 0

        cmp     r10b, 9                           ; test if row == 9

        mov     eax, 1
        je     .sudoku_return                   ; if last row, return 1
                                                ; if not equal, goto .sudoku_not_finished
.sudoku_not_finished:
        ; al = getCellValue at [row][x]
        movzx   rsi, r10b                         ; rsi = row
        lea     rax, [rsi+rsi*8]                ; eax = 9 * row
        lea     rax, [rax+rdi]                  ; eax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col
        cmp     BYTE [rax+rsi], '#'             ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop         ; if equal, goto .sudoku_find_value_loop

        inc     r11b                              ; col++
        jmp     .sudoku_find_next_cell          ; if not equal, try next col
.sudoku_find_value_loop:
        call    isSafe                          ; call isSafe(row, col, num)

        je     .sudoku_find_value_loop_next_num ; if isSafe returned 0, try next number
                                                ; if returned 1, put that number into sudoku matrix

        ; setCellValue at [row][col] <- num
        movzx   rsi, r10b                         ; rsi = row
        lea     rax, [rsi+rsi*8]                ; eax = 9 * row
        lea     rax, [rax+rdi]                  ; eax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col
        mov     [rax+rsi], r12b                   ; grid[row][col] = r12 (num)

        ; solve next column
        push    r10                             ; save row
        push    r11                             ; save col
        push    r12                             ; save num

        inc     r11b                              ; col++
        call    .sudoku                         ; call .sudoku(grid, row, col+1)

        pop     r12                             ; restore num
        pop     r11                             ; restore col
        pop     r10                             ; restore row

        cmp     rax, 1                           ; test if sudoku returned 1 (true)

        je     .sudoku_return                   ; if true, return 1 (1 already in eax)
                                                ; if false, try next number
.sudoku_find_value_loop_next_num:
        ; setCellValue at [row][col] <- '#'
        movzx   rsi, r10b                         ; rsi = row
        lea     rax, [rsi+rsi*8]                ; eax = 9 * row
        lea     rax, [rax+rdi]                  ; eax = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col
        mov     [rax+rsi], BYTE '#'             ; grid[row][col] = '#'

        inc     r12b                              ; num++, try next char
        cmp     r12b, '9'                         ; test if num <= '9'
        jle     .sudoku_find_value_loop         ; if true, goto loop
        xor     rax, rax                        ; return 0
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
;   - r13: x local variable
;   - r10b: row argument
;   - r11b: col argument
;   - r13: startRow local variable
;   - r14: startCol local variable
;   - r15: i local variable
;   - r12b: num
;   - rdi: grid
;   - rsi: j local variable/temp register
;   - rcx: temp register
; returns:
;   - ZF flag: 1 if illegal, 0 if legal
isSafe:
        push    rbx

        mov     r13, 8                           ; int x = 8
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        movzx   rcx, r10b                         ; rcx = row
        lea     rcx, [rcx+rcx*8]                ; rcx = 9 * row
        lea     rcx, [rcx+rdi]                  ; rcx = pointer to grid's row

        cmp     [rcx+r13], r12b                   ; test if grid[row][x] == num
        je      .isSafe_return                  ; if equal, num illegal, return ZF

        dec     r13                              ; x--
        jns     .isSafe_row_loop                ; goto loop if condition met

        mov     r13, 8                           ; int x = 8
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        mov   rcx, r13                         ; rsi = x
        lea     rcx, [rcx+rsi*8]                ; rcx = 9 * x
        lea     rcx, [rcx+rdi]                  ; rcx = pointer to grid's row

        movzx   rsi, r11b                         ; rsi = col

        cmp     [rcx+rsi], r12b                 ; test if grid[x][col] == num
        je      .isSafe_return                  ; if equal, num illegal, return ZF

        dec     r13                              ; x--
        jns     .isSafe_col_loop                ; goto loop if x >= 0

; int startRow = row - row % 3

        mov     r13, 3
        xor     rdx, rdx
        movzx     rax, r10b                          ; ax = int row
        div     r13                              ; rdx = row % 3
        movzx     r13, r10b                          ; r13 = int row
        sub     r13, rdx                          ; startRow = r13 - ah  (row - row % 3)

; int startCol = col - col % 3
        mov     r14, 3
        xor     rdx, rdx
        movzx   rax, r11b                          ; ax = int col
        div     r14                              ; ah = col % 3
        movzx     r14, r11b                          ; r14 = int col
        sub     r14, rdx                          ; startCol = r14 - ah  (col - col % 3)

        mov     r15, 2                           ; i = 2
.isSafe_box_loop_init:
        mov     rsi, 2                          ; j = 2
.isSafe_box_loop:
        mov   rax, r13                         ; eax = startRow
        mov   rbx, r15                         ; ebx = i
        lea     rbx, [rbx+rax]                  ; ebx = i + startRow
        lea     rbx, [rbx+rbx*8]                ; ebx = grid[i + startRow]
        lea     rbx, [rbx+rdi]                  ; ebx = pointer to grid's row

        mov   rcx, r14                         ; rcx = startCol
        lea     rax, [rsi+rcx]                  ; eax = j + startCol
        cmp     [rbx+rax], r12b                   ; test if grid[i + startRow][j + startCol] == num

        je     .isSafe_return                   ; if equal, return ZF

        dec     rsi                             ; j--
        jge     .isSafe_box_loop                ; if j > 0, go back to loop

        dec     r15                              ; else i--
        jge     .isSafe_box_loop_init           ; if i > 0, go back to loop
                                                ; else, escape loop, return no ZF flag
.isSafe_return:
        pop     rbx

        ret