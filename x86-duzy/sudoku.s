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
        xor     ebx, ebx                        ; bh = row = 0; bl = col = 0;

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
        push    ebp
        mov     ebp, esp

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

        cmp     eax, 1                          ; test if isSafe returned 1 (true)
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

        cmp     eax, 1                          ; test if sudoku returned 1 (true)

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

        inc     cl                             ; num++, try next char
        cmp     cl, '9'                        ; test if num <= '9'
        jle     .sudoku_find_value_loop         ; if true, goto loop
        xor     eax, eax                        ; return 0
.sudoku_return:
        leave
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
;   - bh: row argument
;   - bl: col argument
;   - ch: int i <- local variable
;   - cl: char num from ebp+8
;   - edi: char **grid
;   - esi: int j <- local variable
; returns:
;   - eax: 1 if legal, 0 otherwise
; TODO try to return by EFLAGS, not return value

; TODO use ebp to avoid using local variables
; TODO check if we can simplify after refactor
; TODO try to delete local variables
isSafe:
        sub     esp, 2

        push    ebx
        push    esi
        push    edi

        mov     BYTE [esp+12], 0                ; int x = 0
        ; TODO decrement from 8 down to 0
.isSafe_row_loop:
        ; al = getCellValue at [row][x]
        movzx   eax, bh                         ; eax = row
        lea     eax, [eax+eax*8]                ; eax = 9 * row
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        movzx   esi, BYTE [esp+12]              ; esi = x
        mov     al, [eax+esi]                   ; al = char from grid's tile at [row][x]

        cmp     al, cl                          ; test if grid[row][x] == num
        mov     eax, 0                          ; cannot use xor here as it sets ZF flag
        je      .isSafe_return                  ; if equal, num illegal, return 0

        inc     BYTE [esp+12]                   ; x++
        cmp     BYTE [esp+12], 8                ; if x <= 8
        jle     .isSafe_row_loop                ; goto loop if condition met

        mov     BYTE [esp+12], 0                ; int x = 0
.isSafe_col_loop:
        ; al = getCellValue at [x][col]
        movzx   esi, BYTE [esp+12]              ; esi = x
        lea     eax, [esi+esi*8]                ; eax = 9 * x
        lea     eax, [eax+edi]                  ; eax = pointer to grid's row
        movzx   esi, bl                         ; esi = col
        mov     al, [eax+esi]                   ; al = char from grid's tile at [x][col]

        cmp     al, cl                          ; test if grid[x][col] == num
        mov     eax, 0                          ; cannot use xor here as it sets ZF flag
        je      .isSafe_return                  ; if equal, num illegal, return 0

        inc     BYTE [esp+12]                   ; x++
        cmp     BYTE [esp+12], 8                ; if x <= 8
        jle     .isSafe_col_loop                ; goto loop if condition met

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
        mov     eax, esi                        ; eax = esi
        mov     [esp+13], al                    ; startCol = esi

        mov     ch, 0                           ; i = 0
.isSafe_box_loop_init:
        xor     esi, esi                        ; j = 0
.isSafe_box_loop:
        movzx   edx, ch                         ; edx = i
        movzx   ebx, BYTE [esp+12]              ; ebx = startRow
        lea     edx, [edx+ebx]                  ; edx = i + startRow
        lea     edx, [edx+edx*8]                ; edx = grid[i + startRow]
        lea     edx, [edx+edi]                  ; edx = pointer to grid's row

        movzx   eax, BYTE [esp+13]              ; eax = startCol
        lea     eax, [esi+eax]                  ; eax = j + startCol
        cmp     BYTE [edx+eax], cl              ; test if grid[i + startRow][j + startCol] == num

        mov     eax, 0                          ; cannot use xor here as it sets ZF flag
        je     .isSafe_return                   ; if equal, return 0

        inc     esi                             ; j++
        cmp     esi, 2                          ; test j <= 2
        jbe     .isSafe_box_loop                ; if true, go back to loop

        inc     ch                              ; else i++
        cmp     ch, 2                           ; test i <= 2
        jbe     .isSafe_box_loop_init           ; if true, go back to loop
        mov     eax, 1                          ; else, escape loop, return 1
.isSafe_return:
        pop     edi
        pop     esi
        pop     ebx

        add     esp, 2

        ret