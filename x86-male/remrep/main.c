#include <stdio.h>

extern char *remrep(char *s, char a, char b);

extern int strlen(char *s);


int main() {

    char src[] = "ala ma kota";

    char *out = remrep(src, 'a', 'b');

    printf("%s", out);

    return 0;
}
