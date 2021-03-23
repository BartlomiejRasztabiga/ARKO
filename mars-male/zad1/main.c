#include <stdio.h>

int main() {
    char buff[50];
    scanf("%s49", buff);

    for (int i = 0; i < 50; ++i) {
        char current = buff[i];
        if (current >= '0' & current <= '9') {
            char new_char = (char) (105 - current);
            buff[i] = new_char;
        }

        if (current == '\0') {
            break;
        }
    }

    printf("%s", buff);

    return 0;
}
