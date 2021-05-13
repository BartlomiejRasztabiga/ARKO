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
unsigned int isSafe_(char grid[N][N], unsigned int row, unsigned int col, char num) {
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
    unsigned int startRow = row - row % 3;
    unsigned int startCol = col - col % 3;

    for (unsigned int i = 0; i < 3; i++) {
        for (unsigned int j = 0; j < 3; j++) {
            if (grid[i + startRow][j + startCol] == num) {
                return 0;
            }
        }
    }

    return 1;
}

unsigned int sudoku_(char grid[N][N], unsigned int row, unsigned int col) {
    // TODO: remove recursion?

    // check if we have finished filling all columns for the row
    if (col == N) {
        // if we're at last column and last row, then we've finished the sudoku, return 1
        if (row == N - 1) {
            return 1;
        }
        // if we're not at last row, go to next row
        row++;
        col = 0;
    }

    // Check if the current position of the grid already contains value, if yes, fill next column
    if (grid[row][col] != '#') {
        return sudoku_(grid, row, col + 1);
    }

    for (char num = '1'; num <= '9'; num++) {
        // Check if it is safe to place the num (1-9) in the given [row][col]. Then move to next column.
        if (isSafe(grid, row, col, num) == 1) {
            grid[row][col] = num;

            // Solving next column
            if (sudoku_(grid, row, col + 1) == 1) {
                return 1;
            }
        }

        // Removing the assigned num, our solution was wrong
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

    if (sudoku_(grid, 0, 0) == 1) {
        printGrid(grid);
    } else {
        printf("No solution exists");
    }

    printf("%c", '\n');

    return 0;
}