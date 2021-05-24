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
        push    rbp
        push    rbx
        push    rsi
        push    rdi

;        mov     edi, rdi                   ; edi = grid
        xor     ebx, ebx                        ; bh = row = 0; bl = col = 0;

        xor     rax, rax
        xor     rcx, rcx
        xor     rdx, rdx
        xor     rbx, rbx
        xor     rsi, rsi
;        xor     rdi, rdi

        call    .sudoku                         ; call recursive helper

        ; restore callee-saved registers
        pop     rdi
        pop     rsi
        pop     rbx
        pop     rbp

        ret

; ============================================================================
; .sudoku (recursive helper for sudoku)
; description:
;   solves given sudoku matrix
; arguments:
;   - char grid[N][N]   rdi
;   - unsigned int row  bh
;   - unsigned int col  bl
; registers:
;   - rdi: grid argument
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
        movzx   rsi, bh                         ; esi = row
        lea     rax, [rsi+rsi*8]                ; eax = 9 * row
        lea     rax, [rax+rdi]                  ; eax = pointer to grid's row

        movzx   rsi, bl                         ; esi = col
        cmp     BYTE [rax+rsi], '#'             ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop         ; if equal, goto .sudoku_find_value_loop

        inc     bl                              ; col++
        jmp     .sudoku_find_next_cell          ; if not equal, try next col
.sudoku_find_value_loop:
        call    isSafe                          ; call isSafe(row, col, num)

        je     .sudoku_find_value_loop_next_num ; if isSafe returned 0, try next number
                                                ; if returned 1, put that number into sudoku matrix

        ; setCellValue at [row][col] <- num
        movzx   rsi, bh                         ; esi = row
        lea     rax, [rsi+rsi*8]                ; eax = 9 * row
        lea     rax, [rax+rdi]                  ; eax = pointer to grid's row

        movzx   rsi, bl                         ; esi = col
        mov     [rax+rsi], cl                   ; grid[row][col] = cl (num)

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
        movzx   rsi, bh                         ; esi = row
        lea     rax, [rsi+rsi*8]                ; eax = 9 * row
        lea     rax, [rax+rdi]                  ; eax = pointer to grid's row

        movzx   rsi, bl                         ; esi = col
        mov     [rax+rsi], BYTE '#'             ; grid[row][col] = '#'

        inc     cl                              ; num++, try next char
        cmp     cl, '9'                         ; test if num <= '9'
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
;   - rdi: grid
;   - esi: j local variable/temp register
;   - ebp: temp register
; returns:
;   - ZF flag: 1 if illegal, 0 if legal
isSafe:
        push    rbx

        mov     ah, 8                           ; int x = 8
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        movzx   rbp, bh                         ; ebp = row
        lea     rbp, [rbp+rbp*8]                ; ebp = 9 * row
        lea     rbp, [rbp+rdi]                  ; ebp = pointer to grid's row

        movzx   rsi, ah                         ; esi = x
        cmp     [rbp+rsi], cl                   ; test if grid[row][x] == num
        je      .isSafe_return                  ; if equal, num illegal, return ZF

        dec     ah                              ; x--
        jns     .isSafe_row_loop                ; goto loop if condition met

        mov     ah, 8                           ; int x = 8
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        movzx   rsi, ah                         ; esi = x
        lea     rbp, [rsi+rsi*8]                ; ebp = 9 * x
        lea     rbp, [rbp+rdi]                  ; ebp = pointer to grid's row

        movzx   rsi, bl                         ; esi = col
        mov     al, [rbp+rsi]                   ; al = char from grid's tile at [x][col]

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
        movzx   rax, dh                         ; eax = startRow
        movzx   rbx, ch                         ; ebx = i
        lea     rbx, [rbx+rax]                  ; ebx = i + startRow
        lea     rbx, [rbx+rbx*8]                ; ebx = grid[i + startRow]
        lea     rbx, [rbx+rdi]                  ; ebx = pointer to grid's row

        movzx   rbp, dl                         ; ebp = startCol
        lea     rax, [rsi+rbp]                  ; eax = j + startCol
        cmp     [rbx+rax], cl                   ; test if grid[i + startRow][j + startCol] == num

        je     .isSafe_return                   ; if equal, return ZF

        dec     rsi                             ; j--
        jge     .isSafe_box_loop                ; if j > 0, go back to loop

        dec     ch                              ; else i--
        jge     .isSafe_box_loop_init           ; if i > 0, go back to loop
                                                ; else, escape loop, return no ZF flag
.isSafe_return:
        pop     rbx

        ret