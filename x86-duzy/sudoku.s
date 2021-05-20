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
; TODO Use shorter registers?
; TODO lea with 8/16 bits?
        ; save callee-saved registers
        push    ebx
        push    esi
        push    edi

        mov     edi, [esp+16]                   ; edi = grid
        xor     ebx, ebx                        ; bh = row = 0; bl = col = 0;

        call    .sudoku                         ; call recursive helper

        ; restore callee-saved registers
        pop     edi
        pop     esi
        pop     ebx

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
        movzx   esi, bh
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        movzx   esi, bl
        mov     al, BYTE [eax+esi]              ; al = char from grid's tile at [row][x]

        cmp     al, '#'                         ; test if grid[row][col] == '#' - no value at tile
        je      .sudoku_find_value_loop         ; if equal, goto .sudoku_find_value_loop

        inc     bl                              ; col++
        jmp     .sudoku_find_next_cell          ; if not equal, try next col
.sudoku_find_value_loop:
        call    isSafe                          ; call isSafe(row, col, num)

        cmp     al, 1                           ; test if isSafe returned 1 (true)
        jne     .sudoku_find_value_loop_next_num; if false, try next number
                                                ; if true, put that number into sudoku matrix

        ; setCellValue at [row][col] <- num
        movzx   esi, bh
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        movzx   esi, bl
        lea     eax, [eax+esi]                  ; eax = pointer to grid's tile at [row][col]
        mov     [eax], cl                       ; grid[row][col] = cl (num)

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
        movzx   esi, bh
        lea     eax, [esi+esi*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        movzx   esi, bl
        lea     eax, [eax+esi]                  ; eax = pointer to grid's tile at [row][col]
        mov     [eax], BYTE '#'                 ; grid[row][col] = '#'

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
; variables:
;   - byte startCol     esp+12
;   - byte x/startRow   esp+13
; registers:
;   - al: temp register
;   - ah: byte x <- local variable
;   - bh: row argument
;   - bl: col argument
;   - ch: int i <- local variable
;   - cl: char num
;   - edi: char **grid
;   - esi: int j <- local variable
;   - ebp: temp register
; returns:
;   - al: 1 if legal, 0 otherwise
; TODO try to return by EFLAGS, not return valueSave ebp in isSafe

; TODO use ebp to avoid using local variables
; TODO check if we can simplify after refactor
; TODO try to delete local variables
isSafe:
        sub     esp, 2

        push    ebx
        push    esi
        push    ebp

        mov     ah, 8                           ; int x = 8
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        movzx   ebp, bh                         ; ebp = row
        lea     ebp, [ebp+ebp*8]                ; ebp = 9 * row
        lea     ebp, [ebp+edi]                  ; ebp = pointer to grid's row
        movzx   esi, ah                         ; esi = x
        mov     al, [ebp+esi]                   ; al = char from grid's tile at [row][x]

        cmp     al, cl                          ; test if grid[row][x] == num
        mov     al, 0                           ; cannot use xor here as it sets ZF flag
        je      .isSafe_return                  ; if equal, num illegal, return 0

        dec     ah                              ; x--
        cmp     ah, 0                           ; if x > 0
        jge     .isSafe_row_loop                ; goto loop if condition met

        mov     ah, 8                           ; int x = 8
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        movzx   esi, ah                         ; esi = x
        lea     ebp, [esi+esi*8]                ; ebp = 9 * x
        lea     ebp, [ebp+edi]                  ; ebp = pointer to grid's row
        movzx   esi, bl                         ; esi = col
        mov     al, [ebp+esi]                   ; al = char from grid's tile at [x][col]

        cmp     al, cl                          ; test if grid[x][col] == num
        mov     al, 0                           ; cannot use xor here as it sets ZF flag
        je      .isSafe_return                  ; if equal, num illegal, return 0

        dec     ah                              ; x--
        cmp     ah, 0                           ; if x > 0
        jge     .isSafe_col_loop                ; goto loop if condition met

; int startRow = row - row % 3
        mov     esi, 3
        movzx   eax, bh                         ; eax = int row
        xor     edx, edx                        ; edx = 0
        div     esi                             ; edx = row % 3
        movzx   esi, bh                         ; esi = int row
        sub     esi, edx                        ; esi = esi - edx
        mov     eax, esi                        ; eax = esi
        mov     [esp+12], al                    ; startRow = al

; int startCol = col - col % 3
        mov     esi, 3
        movzx   eax, bl                         ; eax = int col
        xor     edx, edx                        ; edx = 0
        div     esi                             ; edx = col % 3
        movzx   esi, bl                         ; esi = int col
        sub     esi, edx                        ; esi = esi - edx
        mov     ebp, esi                        ; startCol = esi

        mov     ch, 2                           ; i = 2
.isSafe_box_loop_init:
        mov     esi, 2                          ; j = 2
.isSafe_box_loop:
        movzx   edx, ch                         ; edx = i
        movzx   ebx, BYTE [esp+12]              ; ebx = startRow
        lea     edx, [edx+ebx]                  ; edx = i + startRow
        lea     edx, [edx+edx*8]                ; edx = grid[i + startRow]
        lea     edx, [edx+edi]                  ; edx = pointer to grid's row

        mov   eax, ebp                          ; eax = startCol
        lea     eax, [esi+eax]                  ; eax = j + startCol
        cmp     BYTE [edx+eax], cl              ; test if grid[i + startRow][j + startCol] == num

        mov     al, 0                           ; cannot use xor here as it sets ZF flag
        je     .isSafe_return                   ; if equal, return 0

        dec     esi                             ; j--
        cmp     esi, 0                          ; test j > 0
        jge     .isSafe_box_loop                ; if true, go back to loop

        dec     ch                              ; else i--
        cmp     ch, 0                           ; test i > 0
        jge     .isSafe_box_loop_init           ; if true, go back to loop
        mov     al, 1                           ; else, escape loop, return 1
.isSafe_return:
        pop     ebp
        pop     esi
        pop     ebx

        add     esp, 2

        ret