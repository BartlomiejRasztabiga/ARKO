#include <stdio.h>

#define N 9

extern unsigned int sudoku(char grid[N][N], unsigned int row, unsigned int col);

void printGrid(char arr[N][N]) {
    for (unsigned int i = 0; i < N; i++) {
        for (unsigned int j = 0; j < N; j++) {
            printf("%c", arr[i][j]);
        }
        printf("\n");
    }
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

    if (sudoku(grid, 0, 0) == 1) {
        printGrid(grid);
    } else {
        printf("No solution exists");
    }

    printf("%c", '\n');

    return 0;
}