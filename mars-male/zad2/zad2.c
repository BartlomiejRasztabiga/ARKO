#include <stdio.h>

#define BUF_SIZE 50

int main() {
    char buf[BUF_SIZE];
    scanf("%s", buf);

    int largest = 0;
    int current_size = 0;
    int largest_start = 0;
    int largest_end = 0;

    int i = 0;
    for (; i < BUF_SIZE; ++i) {
        char current = buf[i];

        if (current >= '0' && current <= '9') {
            current_size++;
        } else {
            if (current_size > largest) {
                largest = current_size;
                largest_end = i;
                largest_start = i - current_size;
            }
            current_size = 0;
        }

        if (current == '\0') {
            break;
        }
    }

    for (int j = largest_start; j < largest_end; ++j) {
        printf("%c", buf[j]);
    }

    return 0;
}
