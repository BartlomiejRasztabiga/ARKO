#include <stdio.h>

extern char *removerng(char *s, char a, char b);

int main() {
    char *src = "Ala ma kota";

    removerng(src, 'a', 'z');

//    printf("%s", out);

    return 0;
}
