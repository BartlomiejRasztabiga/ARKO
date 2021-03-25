#include <stdio.h>

#define BUF_SIZE 50

char buf[BUF_SIZE];
char digits_buf[BUF_SIZE];

int is_digit(const char c) {
    return c >= '0' && c <= '9';
}

int strlen_(const char str[], int max_size) {
    for (int i = 0; i < max_size; i++) {
        if (str[i] == '\0') {
            return i;
        }
    }
    return max_size;
}

int main() {
    scanf("%s", buf);

    int digit_count = 0;
    int len = strlen_(buf, BUF_SIZE);

    for (int i = len - 1; i >= 0; i--) {
        char current = buf[i];
        if (is_digit(current)) {
            digits_buf[digit_count] = current;
            digit_count++;
        }
    }

    digit_count = 0;

    for (int i = 0; i < len; i++) {
        char current = buf[i];
        if (is_digit(current)) {
            buf[i] = digits_buf[digit_count];
            digit_count++;
        }
    }

    printf("%s", buf);
    return 0;
}
