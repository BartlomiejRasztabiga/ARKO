#include <stdio.h>

#define N 9

extern unsigned int isSafe(char grid[N][N], unsigned int row, unsigned int col, char num);

void printGrid(char arr[N][N]) {
    for (unsigned int i = 0; i < N; i++) {
        for (unsigned int j = 0; j < N; j++) {
            printf("%c", arr[i][j]);
        }
        printf("\n");
    }
}

// Checks whether it will be legal to assign num to the given row, col
unsigned int isSafe1(char grid[N][N], unsigned int row, unsigned int col, char num) {

    // Check if we find the same num in the similar row , we return 0
    for (unsigned int x = 0; x <= 8; x++) {
        if (grid[row][x] == num) {
            return 0;
        }
    }


    // Check if we find the same num in the similar column , we return 0
    for (unsigned int x = 0; x <= 8; x++) {
        if (grid[x][col] == num) {
            return 0;
        }
    }

    // Check if we find the same num in the particular 3*3 matrix, we return 0
    // TODO: can modulo be replaced?
    unsigned int startRow = row - row % 3;
    unsigned int startCol = col - col % 3;

    // new code
//    unsigned int startRow = 0;
//    if (row >= 6) {
//        startRow = 6;
//    } else if (row >= 3) {
//        startRow = 3;
//    }
//
//    unsigned int startCol = 0;
//    if (col >= 6) {
//        startCol = 6;
//    } else if (col >= 3) {
//        startCol = 3;
//    }
    // new code

    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 3; j++) {
            if (grid[i + startRow][j + startCol] == num) {
                return 0;
            }
        }
    }

    return 1;
}

unsigned int solveSudoku(char grid[N][N], unsigned int row, unsigned int col) {
    // Check if we have reached the 8th row and 9th column, returning true to avoid backtracking
    if (row == N - 1 && col == N) {
        return 1;
    }

    //  Check if column value is 9, then move to the next row and new column
    if (col == N) {
        row++;
        col = 0;
    }

    // Check if the current position of the grid already contains value, if yes, fill next column
    if (grid[row][col] != '#') {
        return solveSudoku(grid, row, col + 1);
    }

    for (char num = '1'; num <= '9'; num++) {
        // Check if it is safe to place the num (1-9) in the given row ,col. Then move to next column
        if (isSafe(grid, row, col, num) == 1) {
            grid[row][col] = num;

            //  Checking for next possibility with next column
            if (solveSudoku(grid, row, col + 1) == 1) {
                return 1;
            }
        }

        // Removing the assigned num, since our assumption was wrong
        grid[row][col] = '#';
    }

    return 0;
}

int main() {
    char grid[N][N];
    char dummy;
    for (unsigned int i = 0; i < N; ++i) {
        for (unsigned int j = 0; j < N; ++j) {
            scanf("%c", &grid[i][j]);
        }
        scanf("%c", &dummy); // consume LF
    }

    if (solveSudoku(grid, 0, 0) == 1) {
        printGrid(grid);
    } else {
        printf("No solution exists");
    }

    printf("%c", '\n');

    return 0;
}