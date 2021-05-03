#include <stdio.h>

extern char *removerng(char *s, char a, char b);

extern int strlen(char *s);

char *removerng1(char *s, char a, char b) {
    char *source = s;
    char *dest = s;

    while (1) {
        char currentChar = *source;

        if (currentChar == 0) {
            break;
        }

        if (currentChar < a || currentChar > b) {
            *dest = currentChar;
            dest++;
        }

        source++;
    }

    *dest = 0;

    return s;
}

int main() {

    char src[] = "ala ma kota";

    char *out = removerng1(src, 'a', 'b');

    printf("%s", out);

    return 0;
}
